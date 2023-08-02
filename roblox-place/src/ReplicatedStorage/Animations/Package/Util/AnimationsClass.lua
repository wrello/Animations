-- made by wrello

local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")

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
	self.TimeToLoadPrints = true

	self:_animationIdsToInstances()

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
		parent = self.Aliases[rig]
	else
		parent = self.LoadedTracks[rig]
	end

	local firstKey = path

	if typeof(path) == "table" then
		if #path > 1 then
			firstKey = path[1]
		end
	else
		if path:match("%.") then
			firstKey = path:match("^[^%.]+")
		end
	end

	CustomAssert(parent and parent[firstKey], "no track or table found under path [", path, "] for player or rig [", player_or_rig:GetFullName(), "]")
	
	local track_or_table = ChildFromPath(parent, path)

	return track_or_table
end

function AnimationsClass:_playStopTrack(play_stop, player_or_rig, path, isAlias, fadeTime, weight, speed)
	local track = self:_getTrack(player_or_rig, path, isAlias)

	CustomAssert(track, "no track found under path [", path, "]", "for [", player_or_rig:GetFullName(), "]")

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

	CustomAssert(track_or_table, "no track or table found under path [", path, "] with alias [", alias, "] for [", player_or_rig:GetFullName(), "]")
	
	if not self.Aliases[player_or_rig] then
		self.Aliases[player_or_rig] = {}
	end
	
	self.Aliases[player_or_rig][alias] = track_or_table
end

function AnimationsClass:_removeTrackAlias(player_or_rig, alias)
	self.Aliases[player_or_rig][alias] = nil
end

-------------
-- PUBLIC --
-------------

-- Yields until the player or rig's animation tracks have loaded
function AnimationsClass:AwaitLoaded(player_or_rig: Player | Model)
	local rig = getRig(player_or_rig)

	if not self.IsRigLoaded[rig] then
		Await.Args(nil, self.FinishedLoadingRigSignal, rig)
	end
end

-- Checks if the player or rig has had its animation tracks loaded
function AnimationsClass:AreTracksLoaded(player_or_rig: Player | Model): boolean
	return not not self.LoadedTracks[getRig(player_or_rig)]
end

-- Yields while animations pre-load for the player or rig
function AnimationsClass:LoadTracks(player_or_rig: Player | Model, rig_type: string)
	CustomAssert(AnimationIds[rig_type], "no animations found for [", player_or_rig:GetFullName(), "] under rig type [", rig_type, "]")

	local rig = getRig(player_or_rig)

	CustomAssert(not self.IsRigLoaded[rig], "animation tracks already loaded for [", rig:GetFullName(), "] !")

	local animator, animationController
	
	local hum = player_or_rig:IsA("Player") and rig:WaitForChild("Humanoid") or rig:FindFirstChild("Humanoid")
	
	if hum then
		animator = hum:FindFirstChild("Animator")

		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = hum
		end
	else
		animationController = rig:FindFirstChild("AnimationController")
	end

	CustomAssert(animator or animationController, "no animator or animation controller found [", rig:GetFullName(), "]")

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
				currentSet[animationName] = (animator or animationController):LoadAnimation(animation)
			end
		end
	end

	loadTracks(AnimationIds[rig_type], self.LoadedTracks[rig])

	self.IsRigLoaded[rig] = true
	self.FinishedLoadingRigSignal:Fire(rig)

	rig.Destroying:Connect(function() -- When the rig gets destroyed the animation tracks are no longer loaded
		self.IsRigLoaded[rig] = false
	end)

	if self.TimeToLoadPrints then
		print("Finished pre-loading animations for [", rig, "] -", os.clock()-s, "seconds taken")
	end
end

-- Returns an animation track for the player or rig; no error if not found
function AnimationsClass:GetTrack(player_or_rig: Player | Model, path: any): AnimationTrack?
	return self:_getTrack(player_or_rig, path)
end

-- Returns a playing animation track; errors if not found for the player or rig
function AnimationsClass:PlayTrack(player_or_rig: Player | Model, path: any, fadeTime: number?, weight: number?, speed: number?): AnimationTrack
	return self:_playStopTrack("Play", player_or_rig, path, false, fadeTime, weight, speed)
end

-- Returns a stopped animation track; errors if not found for the player or rig
function AnimationsClass:StopTrack(player_or_rig: Player | Model, path: any, fadeTime: number?): AnimationTrack
	return self:_playStopTrack("Stop", player_or_rig, path, false, fadeTime)
end

-- Returns an animation track for the player or rig; no error if not found
function AnimationsClass:GetTrackFromAlias(player_or_rig: Player | Model, alias: any): AnimationTrack?
	return self:_getTrack(player_or_rig, alias, true)
end

-- Returns a playing animation track; errors if not found for the player or rig
function AnimationsClass:PlayTrackFromAlias(player_or_rig: Player | Model, alias: any, fadeTime: number?, weight: number?, speed: number?): AnimationTrack
	return self:_playStopTrack("Play", player_or_rig, alias, true, fadeTime, weight, speed)
end

-- Returns a stopped animation track; errors if not found for the player or rig
function AnimationsClass:StopTrackFromAlias(player_or_rig: Player | Model, alias: any, fadeTime: number?): AnimationTrack
	return self:_playStopTrack("Stop", player_or_rig, alias, true, fadeTime)
end

-- Sets an alias to be the equivalent of the given path for an animation track
function AnimationsClass:SetTrackAlias(player_or_rig: Player | Model, alias: any, path: any)
	self:_setTrackAlias(player_or_rig, alias, path)
end

-- Removes the alias for an animation track for the player or rig
function AnimationsClass:RemoveTrackAlias(player_or_rig: Player | Model, alias: any)
	self:_removeTrackAlias(player_or_rig, alias)
end

return AnimationsClass