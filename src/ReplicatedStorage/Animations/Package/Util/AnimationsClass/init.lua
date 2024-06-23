-- made by wrello

local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

local AnimationIds = require(script.Parent.Parent.Parent.Deps.AnimationIds)
local Signal = require(script.Parent.Signal)
local Await = require(script.Parent.Await)
local ChildFromPath = require(script.Parent.ChildFromPath)
local CustomAssert = require(script.Parent.CustomAssert)
local Zip = require(script.Parent.Zip)
local Queue = require(script.Parent.Queue)
local Types = require(script.Parent.Parent.Util.Types)
local AnimatedObject = require(script.AnimatedObject)
local AnimatedObjectsCache = require(script.AnimatedObjectsCache)

local ANIM_ID_STR = "rbxassetid://%i"
local ANIMATED_OBJECT_INFO_ARR_STR = "animated object info array"

local animatedObjectsFolder = script.Parent.Parent.Parent.Deps.AnimatedObjects
local animationProfiles = Zip.children(script.Parent.Parent.Parent.Deps.AnimationProfiles)

local function isPlayer(player_or_rig)
	if player_or_rig:IsA("Player") then
		return true
	elseif Players:GetPlayerFromCharacter(player_or_rig) then
		return true
	end
end

local function getRig(player_or_rig)
	local playerCharacter 

	if player_or_rig:IsA("Player") then
		task.delay(3, function()
			-- This can happen if
			-- `Players.CharacterAutoLoads` is disabled and
			-- this function gets called before it has a
			-- chance to load in.
			if not playerCharacter then
				warn("Infinite yield possible on 'player_or_rig.CharacterAdded:Wait()'")
			end
		end)

		playerCharacter = player_or_rig.Character or player_or_rig.CharacterAdded:Wait()
	end

	return playerCharacter or player_or_rig
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
	animation.AnimationId = ANIM_ID_STR:format(animationId)

	return animation
end

local function getAnimator(player_or_rig, rig)
	local animatorParent = (player_or_rig:IsA("Player") and rig:WaitForChild("Humanoid")) or rig:FindFirstChild("Humanoid") or rig:FindFirstChild("AnimationController")

	CustomAssert(animatorParent, "No animator parent (Humanoid or AnimationController) found [", rig:GetFullName(), "]")

	local animator = animatorParent:FindFirstChild("Animator")

	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = animatorParent
	end

	CustomAssert(animator, "No animator found [", rig:GetFullName(), "]")

	return animator
end

local function isAnimatedObjectInfoArray(v)
	return getmetatable(v) == ANIMATED_OBJECT_INFO_ARR_STR
end

local function createAnimatedObjectInfoArray()
	return setmetatable({}, { __metatable = ANIMATED_OBJECT_INFO_ARR_STR })
end

local AnimationsClass = {}
AnimationsClass.__index = AnimationsClass

--------------------
-- INITIALIZATION --
--------------------
function AnimationsClass:_animationIdsToInstances()
	local hasAnimatedObjectUnpackQueue = Queue.new()

	local function hasAnimatedObjectUnpackAll()
		for unpackFn in hasAnimatedObjectUnpackQueue:DequeueIter() do
			unpackFn()
		end
	end

	local function replaceAnimationIdWithAnimationInstance(idTable, animationIndex, animationId)
		self.AnimationInstancesCache[animationId] = self.AnimationInstancesCache[animationId] or createAnimationInstance(tostring(animationIndex), animationId)

		idTable[animationIndex] = self.AnimationInstancesCache[animationId]
	end

	local function mapAnimationInstanceToAnimatedObjectInfo(animationInstance, newAnimatedObjectInfo)
		local oldAnimatedObjectInfo = self.AnimationInstanceToAnimatedObjectInfo[animationInstance]

		if oldAnimatedObjectInfo ~= nil then -- Allow multiple animated objects to be attached to the same animation
			if isAnimatedObjectInfoArray(oldAnimatedObjectInfo) then
				local animatedObjectInfoArray = oldAnimatedObjectInfo

				table.insert(animatedObjectInfoArray, newAnimatedObjectInfo)
			else
				local animatedObjectInfoArray = createAnimatedObjectInfoArray()

				table.insert(animatedObjectInfoArray, oldAnimatedObjectInfo)
				table.insert(animatedObjectInfoArray, newAnimatedObjectInfo)

				self.AnimationInstanceToAnimatedObjectInfo[animationInstance] = animatedObjectInfoArray
			end
		else
			self.AnimationInstanceToAnimatedObjectInfo[animationInstance] = newAnimatedObjectInfo
		end
	end

	local function mapAnimationInstancesToAnimatedObjectInfo(animationInstancesTable, animatedObjectInfo)
		-- `idTable` becomes `animationInstancesTable` after
		-- calling `replaceAnimationIdWithAnimationInstance`
		-- on key-value pairs.
		for _, animationInstance in pairs(animationInstancesTable) do
			if type(animationInstance) == "table" then
				local nextIdTable = animationInstance

				mapAnimationInstancesToAnimatedObjectInfo(nextIdTable, animatedObjectInfo)
			else
				mapAnimationInstanceToAnimatedObjectInfo(animationInstance, animatedObjectInfo)
			end
		end
	end

	local function loadAnimations(idTable)		
		for animationIndex, animationId in pairs(idTable) do
			if type(animationId) == "table" then
				local nextIdTable = animationId
				local animatedObjectInfo = nextIdTable._animatedObjectInfo

				if animatedObjectInfo then
					nextIdTable._animatedObjectInfo = nil

					if nextIdTable._singleAnimationId then -- If there is only 1 animation id in the table, just replace the table itself with an animation instance (also don't need to worry about setting to nil because the whole table gets overloaded with the `_singleAnimationId`)
						replaceAnimationIdWithAnimationInstance(idTable, animationIndex, nextIdTable._singleAnimationId)
						mapAnimationInstanceToAnimatedObjectInfo(idTable[animationIndex], animatedObjectInfo)
					else
						-- Moving all keys out of the table sent to `HasAnimatedObject`
						-- function and up one level. Need a queue for this because we still
						-- need it to happen from top down, but after all animations are loaded.
						local doUnpack = animatedObjectInfo.AnimatedObjectSettings.DoUnpack

						if doUnpack then
							hasAnimatedObjectUnpackQueue:Enqueue(function()
								idTable[animationIndex] = nil

								for k, v in nextIdTable do
									--print("setting", k, "in parent table", idTable)
									idTable[k] = v
								end
							end)
						end
						
						loadAnimations(nextIdTable)
						mapAnimationInstancesToAnimatedObjectInfo(nextIdTable, animatedObjectInfo)
					end
				else
					loadAnimations(nextIdTable)
				end
			elseif type(animationId) ~= "userdata" then -- The `animationId` was already turned into an animation instance (happens when multiple references to the same animation id table occur)
				replaceAnimationIdWithAnimationInstance(idTable, animationIndex, animationId)
			end
		end
	end

	for _, animations in pairs(AnimationIds) do
		loadAnimations(animations)
	end

	hasAnimatedObjectUnpackAll()
end

-----------------
-- CONSTRUCTOR --
-----------------
function AnimationsClass.new(moduleName)
	local self = setmetatable({}, AnimationsClass)

	self._moduleName = moduleName

	self.FinishedLoadingRigSignal = Signal.new()
	self.AnimationInstanceToAnimatedObjectInfo = {}
	self.AnimationInstancesCache = {}

	self.Aliases = {} -- Per player and npc rig

	self.PerPlayer = {
		Connections = {}
	}
	
	self.PerRig = {
		TrackToAnimatedObjectInfo = {},
		LoadedTracks = {},
		Connections = {},
		AnimatedObjectsCache = {},
		IsLoaded = {},
	}

	self:_animationIdsToInstances()

	return self
end

-------------
-- PRIVATE --
-------------
function AnimationsClass:_initializedAssertion()
	assert(self._initialized, "Call " .. self._moduleName .. ":Init() before calling any methods")
end

function AnimationsClass:_tracksLoadedAssertion(rig, ...)
	CustomAssert(self.PerRig.IsLoaded[rig], "[", rig:GetFullName(), "] animation tracks are not loaded -", ...)
end

function AnimationsClass:_mockLoadPlayer(player)
	if not self.PerPlayer.Connections[player] then
		local connections = {}
		self.PerPlayer.Connections[player] = connections
		
		table.insert(connections, player.AncestryChanged:Connect(function(_, newParent)
			if newParent == nil then
				for _, conn in ipairs(connections) do
					conn:Disconnect()
				end
				
				-- Release memory
				self.PerPlayer.Connections[player] = nil
				self.Aliases[player] = nil
			end
		end))
	end
end

function AnimationsClass:_getTrack(player_or_rig, path, isAlias)
	local rig = getRig(player_or_rig)

	self:_tracksLoadedAssertion(rig, "unable to get track [", path, "]")

	local parent

	if isAlias then
		parent = self.Aliases[player_or_rig]
	else
		parent = self.PerRig.LoadedTracks[rig]
	end

	local track_or_id_table = ChildFromPath(parent, path)

	return track_or_id_table
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
		
		if isPlayer(player_or_rig) then
			self:_mockLoadPlayer(player_or_rig)
		end
	end

	self.Aliases[player_or_rig][alias] = track_or_table
end

function AnimationsClass:_removeTrackAlias(player_or_rig, alias)
	self.Aliases[player_or_rig][alias] = nil
end

function AnimationsClass:_attachDetachAnimatedObject(attach_detach, player_or_rig, animatedObjectPath, animatedObjectInfo)
	local rig = getRig(player_or_rig)
	
	self:_tracksLoadedAssertion(rig, "unable to", attach_detach, "animated object [", animatedObjectPath, "]")
	
	local animatedObjectsCache = self.PerRig.AnimatedObjectsCache[rig]
	
	if attach_detach == "detach" then
		local animatedObjectTable = animatedObjectsCache:Get(animatedObjectPath)

		if not animatedObjectTable then
			if self.AnimatedObjectsDebugMode then
				print("[ANIM_OBJ_DEBUG] Unable to detach animated object - no attached animated objects found under path [", animatedObjectPath, "]")
			end
			return
		end

		animatedObjectTable:Detach()
	elseif attach_detach == "attach" then
		if animatedObjectsCache:Get(animatedObjectPath) then
			if self.AnimatedObjectsDebugMode then
				print("[ANIM_OBJ_DEBUG] Unable to attach animated object - attached animated object already found under path [", animatedObjectPath, "]")
			end
			return
		end
		
		local animatedObjectSrc = ChildFromPath(animatedObjectsFolder, animatedObjectPath)
		
		CustomAssert(animatedObjectSrc, "Unable to attach animated object - no animated objects found under path [", animatedObjectPath, "]")

		local animatedObjectTable = AnimatedObject.new(rig, animatedObjectSrc, animatedObjectInfo, self.AnimatedObjectsDebugMode)

		-- No need to error because if an animation id is
		-- auto attaching multiple animated objects then one
		-- is bound to fail attaching
		if not animatedObjectTable:Attach() then
			return
		end
		
		animatedObjectTable:ListenToDetach(function()
			animatedObjectsCache:Remove(animatedObjectPath)
		end)
		
		animatedObjectsCache:Map(animatedObjectPath, animatedObjectTable)
		
		if self.AnimatedObjectsDebugMode then
			print(`[ANIM_OBJ_DEBUG] Cache after adding new {RunService:IsClient() and "client" or "server"} sided animated object`, animatedObjectsCache.Cache)
		end
		
		return true
	end
end

function AnimationsClass:_applyCustomRBXAnimationIds(player_or_rig, humanoidRigTypeToCustomRBXAnimationIds)
	local rig = getRig(player_or_rig)
	local animator = getAnimator(player_or_rig, rig)
	
	-- These two things (hum + animatedScript) are traits of
	-- R6/R15 NPCs and player characters, the only rigs this
	-- function should be called on. They might not exist
	-- for custom rigs and therefore this could produce an
	-- infinite yield error.
	local hum = rig:WaitForChild("Humanoid")
	local animateScript = rig:WaitForChild("Animate")

	local humRigTypeCustomRBXAnimationIds = humanoidRigTypeToCustomRBXAnimationIds[hum.RigType]

	if humRigTypeCustomRBXAnimationIds then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop(0)
		end
		
		for animName, animId in pairs(humRigTypeCustomRBXAnimationIds) do
			local rbxAnimInstancesContainer = animateScript:FindFirstChild(animName)

			if rbxAnimInstancesContainer then
				for _, animInstance in ipairs(rbxAnimInstancesContainer:GetChildren()) do
					local animInstance = animInstance :: Animation

					if type(animId) == "table" then
						local animId = animId[animInstance.Name]

						if animId then
							animInstance.AnimationId = ANIM_ID_STR:format(animId)
						end
					else
						animInstance.AnimationId = ANIM_ID_STR:format(animId)
					end
				end
			end
		end

		local player = Players:GetPlayerFromCharacter(rig)

		if player then
			if RunService:IsClient() then
				self.ApplyCustomRBXAnimationIdsSignal:Fire()
			else
				self.ApplyCustomRBXAnimationIdsSignal:FireClient(player)
			end
		else
			-- WARNING: Undefined behavior if the NPC rig is
			-- of auto/server network ownership and or has a
			-- server "Animate" script and the client calls
			-- `Animations:ApplyRigAnimationProfile()` or
			-- `Animations:ApplyRigCustomRBXAnimationIds()`
			-- on it.
			RunService.Stepped:Wait() -- Without a task.wait() or a RunService.Stepped:Wait() the running animation bugs if the NPC is moving when this function is called.
			hum:ChangeState(Enum.HumanoidStateType.Landed) -- Hack to force apply the new animations.
		end
	end
end

-------------
-- PUBLIC --
-------------
function AnimationsClass:AttachAnimatedObject(player_or_rig: Player | Model, animatedObjectPath: {any} | string)
	self:_initializedAssertion()
		
	self:_attachDetachAnimatedObject("attach", player_or_rig, animatedObjectPath)
end

function AnimationsClass:DetachAnimatedObject(player_or_rig: Player | Model, animatedObjectPath: {any} | string)
	self:_initializedAssertion()

	self:_attachDetachAnimatedObject("detach", player_or_rig, animatedObjectPath)
end

function AnimationsClass:AwaitLoaded(player_or_rig: Player | Model)
	self:_initializedAssertion()

	local rig = getRig(player_or_rig)

	if not self.PerRig.IsLoaded[rig] then
		Await.Args(nil, self.FinishedLoadingRigSignal, rig)
	end
end

function AnimationsClass:AreTracksLoaded(player_or_rig: Player | Model): boolean
	self:_initializedAssertion()

	return not not self.PerRig.LoadedTracks[getRig(player_or_rig)]
end

function AnimationsClass:LoadTracks(player_or_rig: Player | Model, rigType: string?)
	self:_initializedAssertion()

	local isPlayer = isPlayer(player_or_rig)

	rigType = rigType or isPlayer and "Player"

	CustomAssert(AnimationIds[rigType], "No animations found for [", player_or_rig:GetFullName(), "] under rig type [", rigType, "]")

	local rig = getRig(player_or_rig)

	rig:SetAttribute("AnimationsRigType", rigType)

	CustomAssert(not self.PerRig.IsLoaded[rig], "Animation tracks already loaded for [", rig:GetFullName(), "] !")

	local animator: Animator = getAnimator(player_or_rig, rig)

	local tracks = self.PerRig.LoadedTracks[rig]

	local s = os.clock()

	if self.TimeToLoadPrints then
		print("Started pre-loading animations for [", rig:GetFullName(), "]")
	end

	-- Pre-loading animation tracks
	do
		local function loadTracks(animationsTable, currentSet)
			for animationName, animationInstance in pairs(animationsTable) do
				if type(animationInstance) == "table" then
					currentSet[animationName] = {}

					loadTracks(animationInstance, currentSet[animationName])
				else
					ContentProvider:PreloadAsync({animationInstance})

					local track = animator:LoadAnimation(animationInstance)

					currentSet[animationName] = track

					local animatedObjectInfo = self.AnimationInstanceToAnimatedObjectInfo[animationInstance]

					if animatedObjectInfo then
						self.PerRig.TrackToAnimatedObjectInfo[rig][track.Animation.AnimationId] = animatedObjectInfo
					end
				end
			end
		end

		if not tracks then
			self.PerRig.LoadedTracks[rig] = {}
		else
			clearTracks(tracks)
		end

		self.PerRig.TrackToAnimatedObjectInfo[rig] = {}

		loadTracks(AnimationIds[rigType], self.PerRig.LoadedTracks[rig])
	end
	
	-- Connection to per rig events
	do
		local connections = {}
		self.PerRig.Connections[rig] = connections

		local animatedObjectsCache = AnimatedObjectsCache.new()
		self.PerRig.AnimatedObjectsCache[rig] = animatedObjectsCache

		-- Destroy the client-sided animated object clone
		-- when the server-sided one gets added. We also
		-- destroy the server-sided one before the server
		-- does. This makes for 0 latency when the player
		-- plays animations on their character.
		if RunService:IsClient() then
			table.insert(connections, rig.ChildAdded:Connect(function(newChild)
				local serverAnimatedObject = newChild
				local serverAnimatedObjectPathType = serverAnimatedObject:GetAttribute(AnimatedObject.SERVER_ANIM_OBJ_AUTO_ATTACH_STR)

				if serverAnimatedObjectPathType then
					local serverAnimatedObjectPath = 
						if serverAnimatedObjectPathType == "string" then
							serverAnimatedObject.Name
						else
							{serverAnimatedObject.Name}

					local clientSidedAnimatedObject = animatedObjectsCache:Get(serverAnimatedObjectPath)

					if clientSidedAnimatedObject then
						clientSidedAnimatedObject:TransferToServerAnimatedObject(serverAnimatedObject)
						
						if self.AnimatedObjectsDebugMode then
							print("[ANIM_OBJ_DEBUG] Cache after transfering client sided animated object lifeline to server animated object", animatedObjectsCache.Cache)
						end
					end
				end
			end))
		end

		-- When a track gets played attach an animated
		-- object if required
		table.insert(connections, animator.AnimationPlayed:Connect(function(track)
			if self.AnimatedObjectsDebugMode then
				print(`[ANIM_OBJ_DEBUG] Animation track [ {track.Animation.AnimationId:match("%d.*")} ] played on rig [ {rig:GetFullName()} ]`)
			end

			local animatedObjectInfo = self.PerRig.TrackToAnimatedObjectInfo[rig][track.Animation.AnimationId]

			if animatedObjectInfo then
				local function tryAttach(animatedObjectInfo)
					local isAttached = false

					if animatedObjectInfo.AnimatedObjectSettings.AutoAttach then
						isAttached = self:_attachDetachAnimatedObject("attach", player_or_rig, animatedObjectInfo.AnimatedObjectPath, animatedObjectInfo) -- Pass in `animatedObjectInfo` to indicate it was an auto attach
					end

					if animatedObjectInfo.AnimatedObjectSettings.AutoDetach then
						track.Stopped:Once(function()
							if self.AnimatedObjectsDebugMode then
								print(`[ANIM_OBJ_DEBUG] Animation track [ {track.Animation.AnimationId:match("%d.*")} ] stopped on rig [ {rig:GetFullName()} ]`)
							end

							self:_attachDetachAnimatedObject("detach", player_or_rig, animatedObjectInfo.AnimatedObjectPath)
						end)
					end

					return isAttached
				end

				if isAnimatedObjectInfoArray(animatedObjectInfo) then
					local animatedObjectInfoArray = animatedObjectInfo

					for _, animatedObjectInfo in animatedObjectInfoArray do -- Attaches the first associated animated object
						if tryAttach(animatedObjectInfo) then
							break
						end
					end
				else
					tryAttach(animatedObjectInfo)
				end
			end
		end))

		-- When the rig gets destroyed the animation tracks
		-- are no longer loaded
		table.insert(connections, rig.AncestryChanged:Connect(function(_, newParent)
			if newParent == nil then
				for _, conn in ipairs(connections) do
					conn:Disconnect()
				end

				self.PerRig.IsLoaded[rig] = false

				-- Release memory
				if not isPlayer then
					self.Aliases[rig] = nil
				end
				self.PerRig.Connections[rig] = nil
				self.PerRig.LoadedTracks[rig] = nil
				self.PerRig.AnimatedObjectsCache[rig] = nil
				self.PerRig.TrackToAnimatedObjectInfo[rig] = nil
			end
		end))
	end
	
	self.PerRig.IsLoaded[rig] = true

	if self.TimeToLoadPrints then
		print("Finished pre-loading animations for [", rig:GetFullName(), "] -", os.clock()-s, "seconds taken")
	end

	self.FinishedLoadingRigSignal:Fire(rig)
end

function AnimationsClass:GetTrack(player_or_rig: Player | Model, path: {any} | string): AnimationTrack?
	self:_initializedAssertion()

	return self:_getTrack(player_or_rig, path)
end

function AnimationsClass:PlayTrack(player_or_rig: Player | Model, path: {any} | string, fadeTime: number?, weight: number?, speed: number?): AnimationTrack
	self:_initializedAssertion()

	return self:_playStopTrack("Play", player_or_rig, path, false, fadeTime, weight, speed)
end

function AnimationsClass:StopTrack(player_or_rig: Player | Model, path: {any} | string, fadeTime: number?): AnimationTrack
	self:_initializedAssertion()

	return self:_playStopTrack("Stop", player_or_rig, path, false, fadeTime)
end

function AnimationsClass:StopTracksOfPriority(player_or_rig: Player | Model, animationPriority: Enum.AnimationPriority, fadeTime: number?): {AnimationTrack?}
	self:_initializedAssertion()
	
	local animator = getAnimator(player_or_rig, getRig(player_or_rig))
	
	local stoppedTracks = {}
	
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track.Priority == animationPriority then
			track:Stop(fadeTime)
			
			table.insert(stoppedTracks, track)
		end
	end
	
	return stoppedTracks
end

function AnimationsClass:StopAllTracks(player_or_rig: Player | Model, fadeTime: number?): {AnimationTrack?}
	self:_initializedAssertion()

	local animator = getAnimator(player_or_rig, getRig(player_or_rig))

	local stoppedTracks = {}

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		track:Stop(fadeTime)

		table.insert(stoppedTracks, track)
	end

	return stoppedTracks
end

function AnimationsClass:GetTrackFromAlias(player_or_rig: Player | Model, alias: any): AnimationTrack?
	self:_initializedAssertion()

	return self:_getTrack(player_or_rig, alias, true)
end

function AnimationsClass:PlayTrackFromAlias(player_or_rig: Player | Model, alias: any, fadeTime: number?, weight: number?, speed: number?): AnimationTrack
	self:_initializedAssertion()

	return self:_playStopTrack("Play", player_or_rig, alias, true, fadeTime, weight, speed)
end

function AnimationsClass:StopTrackFromAlias(player_or_rig: Player | Model, alias: any, fadeTime: number?): AnimationTrack
	self:_initializedAssertion()

	return self:_playStopTrack("Stop", player_or_rig, alias, true, fadeTime)
end

function AnimationsClass:SetTrackAlias(player_or_rig: Player | Model, alias: any, path: {any} | string)
	self:_initializedAssertion()

	self:_setTrackAlias(player_or_rig, alias, path)
end

function AnimationsClass:RemoveTrackAlias(player_or_rig: Player | Model, alias: any)
	self:_initializedAssertion()

	self:_removeTrackAlias(player_or_rig, alias)
end

function AnimationsClass:ApplyCustomRBXAnimationIds(player_or_rig: Player | Model, humanoidRigTypeToCustomRBXAnimationIds: Types.HumanoidRigTypeToCustomRBXAnimationIdsType)
	self:_initializedAssertion()

	self:_applyCustomRBXAnimationIds(player_or_rig, humanoidRigTypeToCustomRBXAnimationIds)
end

function AnimationsClass:GetAnimationProfile(animationProfileName: string): Types.HumanoidRigTypeToCustomRBXAnimationIdsType?
	self:_initializedAssertion()

	local animationProfile = animationProfiles[animationProfileName]
	
	return animationProfile
end

function AnimationsClass:ApplyAnimationProfile(player_or_rig: Player | Model, animationProfileName: string)
	self:_initializedAssertion()
	
	local animationProfile = animationProfiles[animationProfileName]

	self:_applyCustomRBXAnimationIds(player_or_rig, animationProfile)
end

return AnimationsClass