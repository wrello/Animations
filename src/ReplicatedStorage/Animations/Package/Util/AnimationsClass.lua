-- made by wrello

local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

local AnimationIds = require(script.Parent.Parent.Parent.Deps.AnimationIds)
local Signal = require(script.Parent.Signal)
local Await = require(script.Parent.Await)
local ChildFromPath = require(script.Parent.ChildFromPath)
local CustomAssert = require(script.Parent.CustomAssert)

local function getRig(player_or_rig)
	return player_or_rig:IsA("Player") and (player_or_rig.Character or player_or_rig.CharacterAdded:Wait()) or player_or_rig
end

local function clearTracks(currentSet)
	for _, track in pairs(currentSet) do
		if type(track) == "table" then
			clearTracks(track)
		else
			track:Destroy()
		end
	end

	table.clear(currentSet)
end

local function createAnimationInstance(animationName, animationId)
	local animation = Instance.new("Animation")
	animation.Name = animationName
	animation.AnimationId = "rbxassetid://" .. animationId

	return animation
end

local AnimationsClass = {}
AnimationsClass.__index = AnimationsClass

--------------------
-- INITIALIZATION --
--------------------
function AnimationsClass:_animationIdsToInstances()
	local function loadAnimations(idTable, currentSet)
		for animationName, animationId in pairs(idTable) do
			if type(animationId) == "table" then
				loadAnimations(animationId, animationId)
			else
				self.AnimationInstancesCache[animationId] = self.AnimationInstancesCache[animationId] or createAnimationInstance(tostring(animationName), animationId)
				currentSet[animationName] = self.AnimationInstancesCache[animationId]
			end
		end
	end

	for _, animations in pairs(AnimationIds) do
		loadAnimations(animations, animations)
	end
end

function AnimationsClass:_createInitializedAssertionFn()
	local instanceName

	if RunService:IsServer() then
		instanceName = "AnimationsServer"
	else
		instanceName = "AnimationsClient"
	end
	
	self._initializedAssertion = function()
		assert(self._initialized, "Call " .. instanceName .. ":Init() before calling any methods")
	end
end
	
-----------------
-- CONSTRUCTOR --
-----------------
function AnimationsClass.new()
	local self = setmetatable({}, AnimationsClass)

	self.FinishedLoadingRigSignal = Signal.new()
	self.LoadedTracks = {}
	self.Aliases = {}
	self.AnimationInstancesCache = {}
	self.IsRigLoaded = {}	

	self:_animationIdsToInstances()
	self:_createInitializedAssertionFn()

	return self :: AnimationsClassType
end

-------------
-- PRIVATE --
-------------
function AnimationsClass:_getTrack(player_or_rig, path, isAlias)
	local rig = getRig(player_or_rig)

	CustomAssert(self.IsRigLoaded[rig], "Cannot retrieve [", path, "] for [", player_or_rig:GetFullName(), "] at this time because animations are not loaded")

	local parent

	if isAlias then
		parent = self.Aliases[player_or_rig]
	else
		parent = self.LoadedTracks[rig]
	end

	--local firstKey = path

	--if typeof(path) == "table" then
	--	if #path > 1 then
	--		firstKey = path[1]
	--	end
	--else
	--	if path:match("%.") then
	--		firstKey = path:match("^[^%.]+")
	--	end
	--end

	--CustomAssert(parent, "no track or table found under path [", path, "] for player or rig [", player_or_rig:GetFullName(), "]")
	
	local track_or_table = ChildFromPath(parent, path)

	return track_or_table
end

function AnimationsClass:_playStopTrack(play_stop, player_or_rig, path, isAlias, fadeTime, weight, speed)
	local track = self:_getTrack(player_or_rig, path, isAlias)

	CustomAssert(track, "No track found under path [", path, "]", "for [", player_or_rig:GetFullName(), "]")

	track[play_stop](track, fadeTime, weight, speed)

	return track
end

function AnimationsClass:_setTrackAlias(player_or_rig, alias, path)
	local modifiedPath

	if type(path) == "table" then
		modifiedPath = table.clone(path)

		table.insert(modifiedPath, alias)
	else
		modifiedPath = path

		modifiedPath ..= "." .. alias
	end

	local track_or_table = self:_getTrack(player_or_rig, modifiedPath) or self:_getTrack(player_or_rig, path)	

	CustomAssert(track_or_table, "No track or table found under path [", path, "] with alias [", alias, "] for [", player_or_rig:GetFullName(), "]")
	
	if not self.Aliases[player_or_rig] then
		self.Aliases[player_or_rig] = {}
	end
	
	self.Aliases[player_or_rig][alias] = track_or_table
end

function AnimationsClass:_removeTrackAlias(player_or_rig, alias)
	self.Aliases[player_or_rig][alias] = nil
end

function AnimationsClass:_getAnimatorOrAnimationController(player_or_rig, rig)
	local animator_or_animation_controller

	local hum = player_or_rig:IsA("Player") and rig:WaitForChild("Humanoid") or rig:FindFirstChild("Humanoid")

	if hum then
		animator_or_animation_controller = hum:FindFirstChild("Animator")

		if not animator_or_animation_controller then
			animator_or_animation_controller = Instance.new("Animator")
			animator_or_animation_controller.Parent = hum
		end
	else
		animator_or_animation_controller = rig:FindFirstChild("AnimationController")
	end

	CustomAssert(animator_or_animation_controller, "No animator or animation controller found [", rig:GetFullName(), "]")
	
	return animator_or_animation_controller
end

-------------
-- PUBLIC --
-------------
function AnimationsClass:AwaitLoaded(player_or_rig: Player | Model)
	self._initializedAssertion()
	
	local rig = getRig(player_or_rig)

	if not self.IsRigLoaded[rig] then
		Await.Args(nil, self.FinishedLoadingRigSignal, rig)
	end
end

function AnimationsClass:AreTracksLoaded(player_or_rig: Player | Model): boolean
	self._initializedAssertion()
	
	return not not self.LoadedTracks[getRig(player_or_rig)]
end

function AnimationsClass:LoadTracks(player_or_rig: Player | Model, rigType: string)
	self._initializedAssertion()
	
	CustomAssert(AnimationIds[rigType], "No animations found for [", player_or_rig:GetFullName(), "] under rig type [", rigType, "]")

	local rig = getRig(player_or_rig)

	rig:SetAttribute("AnimationsRigType", rigType)

	CustomAssert(not self.IsRigLoaded[rig], "Animation tracks already loaded for [", rig:GetFullName(), "] !")
	
	local animator_or_animation_controller = self:_getAnimatorOrAnimationController(player_or_rig, rig)
	
	local tracks = self.LoadedTracks[rig]

	if not tracks then
		self.LoadedTracks[rig] = {}
	else
		clearTracks(tracks)
	end

	local s = os.clock()

	if self.TimeToLoadPrints then
		print("Started pre-loading animations for [", rig, "]")
	end

	local function loadTracks(animationsTable, currentSet)
		for animationName, animation in pairs(animationsTable) do
			if type(animation) == "table" then
				currentSet[animationName] = {}

				loadTracks(animation, currentSet[animationName])
			else
				ContentProvider:PreloadAsync({animation})
				currentSet[animationName] = animator_or_animation_controller:LoadAnimation(animation)
			end
		end
	end

	loadTracks(AnimationIds[rigType], self.LoadedTracks[rig])

	self.IsRigLoaded[rig] = true

	rig.Destroying:Connect(function() -- When the rig gets destroyed the animation tracks are no longer loaded
		self.IsRigLoaded[rig] = false
	end)

	if self.TimeToLoadPrints then
		print("Finished pre-loading animations for [", rig, "] -", os.clock()-s, "seconds taken")
	end
	
	self.FinishedLoadingRigSignal:Fire(rig)
end

function AnimationsClass:GetTrack(player_or_rig: Player | Model, path: any): AnimationTrack?
	self._initializedAssertion()
	
	return self:_getTrack(player_or_rig, path)
end

function AnimationsClass:PlayTrack(player_or_rig: Player | Model, path: any, fadeTime: number?, weight: number?, speed: number?): AnimationTrack
	self._initializedAssertion()
	
	return self:_playStopTrack("Play", player_or_rig, path, false, fadeTime, weight, speed)
end

function AnimationsClass:StopTrack(player_or_rig: Player | Model, path: any, fadeTime: number?): AnimationTrack
	self._initializedAssertion()
	
	return self:_playStopTrack("Stop", player_or_rig, path, false, fadeTime)
end

function AnimationsClass:GetTrackFromAlias(player_or_rig: Player | Model, alias: any): AnimationTrack?
	self._initializedAssertion()
	
	return self:_getTrack(player_or_rig, alias, true)
end

function AnimationsClass:PlayTrackFromAlias(player_or_rig: Player | Model, alias: any, fadeTime: number?, weight: number?, speed: number?): AnimationTrack
	self._initializedAssertion()
	
	return self:_playStopTrack("Play", player_or_rig, alias, true, fadeTime, weight, speed)
end

function AnimationsClass:StopTrackFromAlias(player_or_rig: Player | Model, alias: any, fadeTime: number?): AnimationTrack
	self._initializedAssertion()
	
	return self:_playStopTrack("Stop", player_or_rig, alias, true, fadeTime)
end

function AnimationsClass:SetTrackAlias(player_or_rig: Player | Model, alias: any, path: any)
	self._initializedAssertion()
	
	self:_setTrackAlias(player_or_rig, alias, path)
end

function AnimationsClass:RemoveTrackAlias(player_or_rig: Player | Model, alias: any)
	self._initializedAssertion()
	
	self:_removeTrackAlias(player_or_rig, alias)
end

return AnimationsClass