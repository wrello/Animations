-- made by wrello

local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local AsyncInfoCache = require(script.Parent.AsyncInfoCache)
local Signal = require(script.Parent.Signal)
local Await = require(script.Parent.Await)
local ChildFromPath = require(script.Parent.ChildFromPath)
local CustomAssert = require(script.Parent.CustomAssert)
local Zip = require(script.Parent.Zip)
local Queue = require(script.Parent.Queue)
local Types = require(script.Parent.Parent.Util.Types)
local AnimatedObject = require(script.AnimatedObject)
local AnimatedObjectsCache = require(script.AnimatedObjectsCache)
local GetAttributeAsync = require(script.Parent.Parent.Util.GetAttributeAsync)

local ANIM_ID_STR = "rbxassetid://%i"
local ANIMATED_OBJECT_INFO_ARR_STR = "animated object info array"

local RAN_FULL_METHOD = {
	Yes = true,
	No = false,
}

local DESCENDANT_ANIMS_LOADED_MARKER = newproxy(true)
getmetatable(DESCENDANT_ANIMS_LOADED_MARKER).__tostring = function()
	return "DESCENDANT_ANIMS_LOADED_MARKER"
end

local ALL_ANIMS_MARKER = newproxy(true)
getmetatable(ALL_ANIMS_MARKER).__tostring = function()
	return "ALL_ANIMS_MARKER"
end

local AnimationIds = nil
local animatedObjectsFolder = nil
local animationProfiles = nil

local allMarkerTimes = {}
local markerTimesLoadedSignal = Signal.new()

local function isPlayer(player_or_rig)
	if player_or_rig.ClassName == "Player" then
		return true
	elseif Players:GetPlayerFromCharacter(player_or_rig) then
		return true
	end
end

local function getRig(player_or_rig)
	local playerCharacter

	if player_or_rig.ClassName == "Player" then
		task.delay(3, function()
			-- This can happen if `Players.CharacterAutoLoads` is disabled and
			-- this function gets called before it has a chance to load in.
			if not playerCharacter then
				warn(`Infinite yield possible on '{player_or_rig.Name}.CharacterAdded:Wait()'`)
			end
		end)

		playerCharacter = player_or_rig.Character or player_or_rig.CharacterAdded:Wait()
	end

	return playerCharacter or player_or_rig
end

local function clearTracks(currentSet)
	for _, track in pairs(currentSet) do
		local type = typeof(track)

		if type == "table" then
			clearTracks(track)
		elseif type == "Instance" then
			track:Destroy()
		end
	end

	table.clear(currentSet)
end

local function getAnimator(player_or_rig, rig)
	local animatorParent = (player_or_rig.ClassName == "Player" and rig:WaitForChild("Humanoid")) or rig:FindFirstChild("Humanoid") or rig:FindFirstChild("AnimationController")

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

local function getAnimIdNumber(animIdString)
	return tonumber(animIdString:match("%d+$"))
end

local function deepClone(t)
	local clone = {}

	for k, v in pairs(t) do
		if type(v) == "table" then
			clone[k] = deepClone(v)
		else
			clone[k] = v
		end
	end

	return clone
end

local function isSubPath(subPath, mainPath)
	if type(mainPath) ~= type(subPath) then
		return
	end

	if type(mainPath) == "string" then
		return #subPath == 0 or mainPath:sub(1, #subPath) == subPath
	else
		for i, v in pairs(subPath) do
			if v ~= mainPath[i] then
				return
			end
		end

		return true
	end
end

local function customClientNPCEquipTool(rig, toolToEquip)
	-- Roblox doesn't support client-side NPC tool equipping at
	-- all.

	-- Custom client-side NPC tool equip method:

	-- 1. Unequip any currently held tools
	for _, child in ipairs(rig:GetChildren()) do
		if child:IsA("Tool") then
			child.Parent = nil
		end
	end

	-- Also ensure any existing grip weld/motor is removed
	local rightHand = rig:FindFirstChild("RightHand") or rig:FindFirstChild("Right Arm")
	if rightHand then
		local oldGrip = rightHand:FindFirstChild("RightGrip")
		if oldGrip then
			oldGrip:Destroy()
		end
	end

	-- 2. Equip the new tool
	local handle = toolToEquip:FindFirstChild("Handle")
	if handle and rightHand then
		local grip = Instance.new("Motor6D")
		grip.Name = "RightGrip"
		grip.Part0 = rightHand
		grip.Part1 = handle
		grip.C0 = toolToEquip.Grip or CFrame.new() -- Use tool's CFrame or default
		grip.Parent = rightHand
	end

	toolToEquip.Parent = rig
end

local AnimationsClass = {}
AnimationsClass.__index = AnimationsClass

--------------------
-- INITIALIZATION --
--------------------
function AnimationsClass:_createAnimationInstance(animationName, animationId)
	local animation = self.AnimationInstancesCache[animationId]
	if not animation then
		animation = Instance.new("Animation")
		animation.Name = tostring(animationName)
		animation.AnimationId = ANIM_ID_STR:format(animationId)

		self.AnimationInstancesCache[animationId] = animation
		table.insert(self._preloadAsyncArray, animation)
	end

	return animation
end

function AnimationsClass:_bootstrapDepsFolder(depsFolder)
	AnimationIds = require(depsFolder.AnimationIds)
	animatedObjectsFolder = depsFolder.AnimatedObjects
	animationProfiles = Zip.children(depsFolder.AnimationProfiles)
end

function AnimationsClass:_animationIdsToInstances()
	local s = os.clock()
	if self.TimeToLoadPrints then
		print("Started ContentProvider:PreloadAsync() on animations...")
	end

	local unpackQueue = Queue.new()

	local function unpackQueueDoAll()
		for unpackFn in unpackQueue:DequeueIter() do
			unpackFn()
		end
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

	local function initializeAnimationIds(idTable, state)
		for animationIndex, animationId in pairs(idTable) do
			local type = type(animationId)
			local newAnimationInstance = nil

			if type == "table" then
				if animationId._singleAnimationId then
					newAnimationInstance = self:_createAnimationInstance(animationIndex, animationId._singleAnimationId)

					if animationId._runtimeProps then
						state.runtimeProps = animationId._runtimeProps
					elseif animationId._animatedObjectInfo then
						state.animatedObjectInfo = animationId._animatedObjectInfo
					end
				else
					local nextIdTable = animationId -- We are inside of a normal id table

					-- Moving all keys out of the table sent to
					-- `HasAnimatedObject` and `HasProperties` functions and up
					-- one level. Need a queue for this because we still need it
					-- to happen from top down, but after all animations are
					-- loaded.
					local doUnpack = nextIdTable._doUnpack
					nextIdTable._doUnpack = nil
					if doUnpack then
						unpackQueue:Enqueue(function()
							idTable[animationIndex] = nil

							for k, v in pairs(nextIdTable) do
								idTable[k] = v
							end
						end)
					end

					-- First replace all descendant animation ids within
					-- `nextIdTable` with { _singleAnimation and _runtimeProps }
					local runtimeProps = nextIdTable._runtimeProps
					nextIdTable._runtimeProps = nil
					if runtimeProps then
						state.runtimeProps = runtimeProps
					end

					-- Then map all descendant animation instances (or ids ->
					-- instances) within `nextIdTable` to their animated object
					-- infos
					local animatedObjectInfo = nextIdTable._animatedObjectInfo
					nextIdTable._animatedObjectInfo = nil
					if animatedObjectInfo then
						state.animatedObjectInfo = animatedObjectInfo
					end

					-- CONTINUE RECURSION | AFTER CONFIGURING STATE FOR DESCENDANT ANIMATION IDS
					initializeAnimationIds(nextIdTable, state)
					continue
				end
			elseif type == "number" then
				newAnimationInstance = self:_createAnimationInstance(animationIndex, animationId)
			elseif type == "userdata" then -- It's an already created animation instance
				continue
			end

			if state.animatedObjectInfo then
				mapAnimationInstanceToAnimatedObjectInfo(newAnimationInstance, state.animatedObjectInfo)
			end

			local runtimeProps = state.runtimeProps
			if runtimeProps then
				if runtimeProps.MarkerTimes then -- Cache animation marker times for this animation
					runtimeProps.MarkerTimes = nil
					self:_cacheAnimationMarkerTimes(newAnimationInstance.AnimationId)
				end

				idTable[animationIndex] = {
					_runtimeProps = runtimeProps,
					_singleAnimation = newAnimationInstance
				}
			else
				idTable[animationIndex] = newAnimationInstance
			end

			-- END RECURSION | AFTER CONFIGURING A SINGLE ANIMATION ID
		end
	end

	local function preloadAsync()
		local len = #self._preloadAsyncArray

		local loaded = 0
		for i, animation in ipairs(self._preloadAsyncArray) do
			task.spawn(function()
				ContentProvider:PreloadAsync({animation})
				loaded += 1

				self.PreloadAsyncProgressed:Fire(loaded, len, animation)

				if loaded == len then
					local clone = table.clone(self._preloadAsyncArray)

					table.clear(self._preloadAsyncArray)
					self._preloadAsyncArray = nil

					self.PreloadAsyncFinishedSignal:Fire(clone)
				end
			end)
		end

		self.PreloadAsyncFinishedSignal:Wait()
	end

	local initialized = {}
	for _, idTable in pairs(AnimationIds) do
		if initialized[idTable] then
			continue
		end
		
		initialized[idTable] = true

		initializeAnimationIds(idTable, {})
	end

	unpackQueueDoAll()
	preloadAsync()

	if self.TimeToLoadPrints then
		print(string.format("Finished ContentProvider:PreloadAsync() on animations after %.2f seconds", os.clock() - s))
	end
end

-----------------
-- CONSTRUCTOR --
-----------------
function AnimationsClass.new(moduleName)
	local self = setmetatable({}, AnimationsClass)

	self._moduleName = moduleName
	self._preloadAsyncArray = {}

	self.PreloadAsyncProgressed = Signal.new()

	self.PreloadAsyncFinishedSignal = Signal.new()
	self.FinishedLoadingSignal = Signal.new()
	self.RegisteredRigSignal = Signal.new()
	self.AnimationInstanceToAnimatedObjectInfo = {}
	self.AnimationInstancesCache = {}

	self.Aliases = {} -- Per player and npc rig

	self.PerPlayer = {
		Connections = {}
	}

	self.PerRig = {
		AppliedProfile = {},
		TrackToAnimatedObjectInfo = {},
		LoadedTracks = {},
		Connections = {},
		AnimatedObjectsCache = {},
		IsRegistered = {},
	}

	return self
end

-------------
-- PRIVATE --
-------------
function AnimationsClass:_rigRegisteredAssertion(rig, ...)
	CustomAssert(self.PerRig.IsRegistered[rig], "Rig not registered error [", rig:GetFullName(), "] -", ...)
end

function AnimationsClass:_cacheAnimationMarkerTimes(animId)
	if allMarkerTimes[animId] == nil then
		task.spawn(function()
			allMarkerTimes[animId] = false -- Mark that we are loading this particular `animId`

			local keyframeSequence: KeyframeSequence = AsyncInfoCache.asyncCall(3, KeyframeSequenceProvider, "GetKeyframeSequenceAsync", {animId})

			if keyframeSequence then
				local thisMarkerTimes = {}
				local keyframes = keyframeSequence:GetKeyframes()

				for _, v: Keyframe in ipairs(keyframes) do
					local markers = v:GetMarkers()

					for _, m: KeyframeMarker in ipairs(markers) do
						thisMarkerTimes[m.Name] = v.Time
					end
				end

				allMarkerTimes[animId] = thisMarkerTimes
				markerTimesLoadedSignal:Fire(animId, thisMarkerTimes)
			else
				allMarkerTimes[animId] = nil
				warn(self._moduleName, "failed to cache animation marker times for animation id", animId)
			end
		end)
	end
end

function AnimationsClass:_initializedAssertion()
	assert(self._initialized, "Call " .. self._moduleName .. ":Init() before calling any methods")
end

function AnimationsClass:_aliasesRegisterPlayer(player)
	if self.Aliases[player] then
		return
	end

	self.Aliases[player] = {}

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

function AnimationsClass:_getTrack(player_or_rig, path, isAlias)
	CustomAssert(path ~= nil, "Path is nil")

	local rig = getRig(player_or_rig)
	self:_rigRegisteredAssertion(rig, "unable to get track at path [", path, "]")

	local parent
	if isAlias then
		parent = self.Aliases[player_or_rig]
	else
		parent = self.PerRig.LoadedTracks[rig]
	end

	local areTracksLoaded, track_or_table = self:_areTracksLoadedAt(player_or_rig, path, parent, true)
	CustomAssert(areTracksLoaded, "Track(s) not loaded at path [", path, "in", parent, "]")

	return track_or_table
end

function AnimationsClass:_playStopTrack(play_stop, player_or_rig, path, isAlias, fadeTime, weight, speed)
	CustomAssert(path ~= nil, "Path is nil")

	local track = self:_getTrack(player_or_rig, path, isAlias)
	CustomAssert(track, "No track found at path [", path, "]", "for [", player_or_rig:GetFullName(), "]")

	track[play_stop](track, fadeTime, weight, speed or track:GetAttribute("StartSpeed"))

	return track
end

function AnimationsClass:_setTrackAlias(player_or_rig, alias, path)
	CustomAssert(path ~= nil, "Path is nil")

	local modifiedPath

	if type(path) == "table" then
		modifiedPath = table.clone(path)

		table.insert(modifiedPath, alias)
	else
		modifiedPath = path

		modifiedPath ..= "." .. alias
	end

	local track_or_table = self:_getTrack(player_or_rig, modifiedPath) or self:_getTrack(player_or_rig, path)
	CustomAssert(track_or_table, "No track or table found at path [", path, "] with alias [", alias, "] for [", player_or_rig:GetFullName(), "]")

	self.Aliases[player_or_rig][alias] = track_or_table
end

function AnimationsClass:_removeTrackAlias(player_or_rig, alias)
	self.Aliases[player_or_rig][alias] = nil
end

function AnimationsClass:_attachDetachAnimatedObject(attach_detach, player_or_rig, animatedObjectPath, animatedObjectInfo, toolToEquip)
	CustomAssert(animatedObjectPath ~= nil, "Path is nil")

	local rig = getRig(player_or_rig)
	self:_rigRegisteredAssertion(rig, "unable to", attach_detach, "animated object [", animatedObjectPath, "]")

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
		local ok, animatedObjectSrc = pcall(ChildFromPath, animatedObjectsFolder, animatedObjectPath)
		CustomAssert(ok, "Unable to attach animated object to [", rig:GetFullName(), "] - no animated objects found under path [", animatedObjectPath, "]")

		if toolToEquip then
			if RunService:IsServer() then
				if isPlayer(player_or_rig) then
					CustomAssert(toolToEquip:IsDescendantOf(game), "Unable to equip animated tool to [", rig:GetFullName(), "] - tool [", toolToEquip:GetFullName(), "] must be a descendant of the game")
				end

				rig.Humanoid:EquipTool(toolToEquip) -- Need to do this before 'animatedObjectsCache:Get(animatedObjectPath)' below because this unequips the current tools which will potentially uncache an animated object with the same motor6d name allowing us to continue past it
			elseif RunService:IsClient() then
				-- if isPlayer(player_or_rig) then
				-- 	local client = player_or_rig
				-- 	CustomAssert(toolToEquip.Parent == client.Backpack or toolToEquip.Parent == rig, "Unable to equip animated tool to [", rig:GetFullName(), "] - tool [", toolToEquip:GetFullName(), "] must be in client's backpack or character")
					
				-- 	rig.Humanoid:EquipTool(toolToEquip) -- Need to do this before 'animatedObjectsCache:Get(animatedObjectPath)' below because this unequips the current tools which will potentially uncache an animated object with the same motor6d name allowing us to continue past it
				-- else
					customClientNPCEquipTool(rig, toolToEquip) -- Need to do this before 'animatedObjectsCache:Get(animatedObjectPath)' below because this unequips the current tools which will potentially uncache an animated object with the same motor6d name allowing us to continue past it
				-- end
			end
		else
			local isAutoAttaching = animatedObjectInfo
			local motor6dOnly = animatedObjectSrc.ClassName == "Motor6D" and not isAutoAttaching
			if RunService:IsServer() then
				CustomAssert(not motor6dOnly, "Unable to attach animated object to [", rig:GetFullName(), "] - attaching single motor6d could fail to find the equipped tool if directly after 'humanoid:EquipTool()'. Use 'Animations:EquipAnimatedTool()' instead.")
			elseif RunService:IsClient() then
				CustomAssert(not motor6dOnly, "Unable to attach animated object to [", rig:GetFullName(), "] - attaching single motor6d manually is not available on client. Use 'Animations:EquipAnimatedTool()' on server instead.")
			end
		end
		
		if animatedObjectsCache:Get(animatedObjectPath) then
			if self.AnimatedObjectsDebugMode then
				print("[ANIM_OBJ_DEBUG] Unable to attach animated object - attached animated object already found under path [", animatedObjectPath, "]")
			end
			return
		end

		local animatedObjectTable = AnimatedObject.new(rig, animatedObjectSrc, animatedObjectInfo, self.AnimatedObjectsDebugMode)

		-- No need to error because if an animation id is auto attaching
		-- multiple animated objects then one is bound to fail attaching
		if not animatedObjectTable:Attach(toolToEquip) then
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

function AnimationsClass:_editAnimateScriptValues(animator, animateScript, humRigTypeCustomRBXAnimationIds)
	for _, track: AnimationTrack in ipairs(animator:GetPlayingAnimationTracks()) do
		track:Stop(0)
	end

	for animName, animId in pairs(humRigTypeCustomRBXAnimationIds) do
		local rbxAnimInstancesContainer = animateScript:FindFirstChild(animName)

		if rbxAnimInstancesContainer then
			for _, animInstance in ipairs(rbxAnimInstancesContainer:GetChildren()) do
				local animInstance = animInstance :: Animation
				local oldAnimId = getAnimIdNumber(animInstance.AnimationId)

				if type(animId) == "table" then
					local animIdTable = animId
					local newAnimId = animIdTable[animInstance.Name]
					local animIdChanged = newAnimId and newAnimId ~= oldAnimId

					if animIdChanged then
						animInstance.AnimationId = ANIM_ID_STR:format(newAnimId)
					end
				else
					local newAnimId = animId
					local animIdChanged = newAnimId ~= oldAnimId

					if animIdChanged then
						animInstance.AnimationId = ANIM_ID_STR:format(newAnimId)
					end
				end
			end
		end
	end
end

function AnimationsClass:_applyCustomRBXAnimationIds(player_or_rig, humanoidRigTypeToCustomRBXAnimationIds)
	local rig = getRig(player_or_rig)
	local animator = getAnimator(player_or_rig, rig)

	-- These two things (Humanoid + Animate script) are traits of R6/R15 NPCs and
	-- player characters, the only rigs this function should be called on. They
	-- might not exist for custom rigs and therefore this could produce an
	-- infinite yield error.
	local hum = rig:WaitForChild("Humanoid")
	local animateScript = rig:WaitForChild("Animate")

	local humRigTypeCustomRBXAnimationIds = humanoidRigTypeToCustomRBXAnimationIds[hum.RigType]

	if humRigTypeCustomRBXAnimationIds then
		local player = Players:GetPlayerFromCharacter(rig)

		if player then
			local clientSidedAnimateScript = animateScript.ClassName == "LocalScript" or animateScript.RunContext == Enum.RunContext.Client

			if RunService:IsClient() then
				if clientSidedAnimateScript then
					self.ApplyCustomRBXAnimationIdsSignal:Fire(humRigTypeCustomRBXAnimationIds)
				else
					self.ApplyCustomRBXAnimationIdsSignal:Fire()
				end
			else
				if not clientSidedAnimateScript then
					-- Forced to make changes on the server because the client
					-- can't make them
					self:_editAnimateScriptValues(animator, animateScript, humRigTypeCustomRBXAnimationIds)
					self.ApplyCustomRBXAnimationIdsSignal:FireClient(player)
				else
					-- Tell the client to make the changes
					self.ApplyCustomRBXAnimationIdsSignal:FireClient(player, humRigTypeCustomRBXAnimationIds)
				end
			end
		else
			-- WARNING: Undefined behavior if the NPC rig is of auto/server
			-- network ownership and or has a server "Animate" script and the
			-- client calls `Animations:ApplyRigAnimationProfile()` or
			-- `Animations:ApplyRigCustomRBXAnimationIds()` on it.
			self:_editAnimateScriptValues(animator, animateScript, humRigTypeCustomRBXAnimationIds)
		
			RunService.Stepped:Wait() -- Without a task.wait() or a RunService.Stepped:Wait() the running animation bugs if the rig is moving when this function is called

			hum:ChangeState(Enum.HumanoidStateType.Landed) -- Hack to force apply the new animations.
		end
	end
end

function AnimationsClass:_loadTracksAt(player_or_rig, path)
	CustomAssert(path ~= nil, "Path is nil")

	local rig = getRig(player_or_rig)
	self:_rigRegisteredAssertion(rig, "unable to load tracks at path [", path or ALL_ANIMS_MARKER, "]")

	local parent = self.PerRig.LoadedTracks[rig]
	local instance_or_id_table, parent_id_table, animationName = parent, nil, nil

	if path ~= ALL_ANIMS_MARKER then
		if type(path) == "string" then
			parent_id_table = ChildFromPath(parent, path:gsub("(%.?[^.]+)$", function(s)
				animationName = s:sub(-#s-1)
				return ""
			end))
		else
			animationName = table.remove(path)
			parent_id_table = ChildFromPath(parent, path)
			table.insert(path, animationName)
		end

		instance_or_id_table = parent_id_table and animationName and parent_id_table[animationName]
		CustomAssert(instance_or_id_table, "No track or id table found at path [", path, "in", parent, "]")
	end

	local s = os.clock()
	if self.TimeToLoadPrints then
		print("Started loading animation tracks for [", rig:GetFullName(), "] at path [", path or ALL_ANIMS_MARKER, "]")
	end

	-- Wait for the animator to be a descendant of the game before using
	-- 'animator:LoadAnimation()'
	local animator = getAnimator(rig, rig)
	local done = false
	task.delay(3, function()
		if not done then
			warn(`Infinite yield possible - animator for {rig:GetFullName()} is still not descendant of game after 3 seconds`)
		end
	end)
	while true do
		if animator:IsDescendantOf(game) then
			done = true
			break
		end
		animator.AncestryChanged:Wait()
	end

	local function animator_LoadAnimation(animationInstance, animationName, parent_id_table, runtimeProps)
		local track = animator:LoadAnimation(animationInstance)
		track.Name = animationInstance.Name

		parent_id_table[animationName] = track

		local animatedObjectInfo = self.AnimationInstanceToAnimatedObjectInfo[animationInstance]
		if animatedObjectInfo then
			self.PerRig.TrackToAnimatedObjectInfo[rig][animationInstance.AnimationId:match("%d+$")] = animatedObjectInfo
		end

		if runtimeProps then
			if runtimeProps.Looped ~= nil then
				track.Looped = runtimeProps.Looped
			end
			if runtimeProps.Priority ~= nil then
				track.Priority = runtimeProps.Priority
			end
			if runtimeProps.StartSpeed ~= nil then
				track:SetAttribute("StartSpeed", runtimeProps.StartSpeed) -- Make it easier to access
			end
		end
	end

	if type(instance_or_id_table) == "userdata" then
		if instance_or_id_table.ClassName == "AnimationTrack" then
			if self.TimeToLoadPrints then
				print("Finished loading animation tracks for [", rig:GetFullName(), "] at path [", path or ALL_ANIMS_MARKER, "] in 0 seconds (already loaded)")
			end

			return RAN_FULL_METHOD.No
		else
			animator_LoadAnimation(instance_or_id_table, animationName, parent_id_table)

			if self.TimeToLoadPrints then
				print("Finished loading animation tracks for [", rig:GetFullName(), "] at path [", path or ALL_ANIMS_MARKER, "] in ", os.clock() - s, "seconds")
			end
		end
	elseif instance_or_id_table[DESCENDANT_ANIMS_LOADED_MARKER] then
		if self.TimeToLoadPrints then
			print("Finished loading animation tracks for [", rig:GetFullName(), "] at path [", path or ALL_ANIMS_MARKER, "] in 0 seconds (already loaded)")
		end

		return RAN_FULL_METHOD.No
	elseif instance_or_id_table._singleAnimation then
		animator_LoadAnimation(instance_or_id_table._singleAnimation, animationName, parent_id_table, instance_or_id_table._runtimeProps)

		if self.TimeToLoadPrints then
			print("Finished loading animation tracks for [", rig:GetFullName(), "] at path [", path or ALL_ANIMS_MARKER, "] in ", os.clock() - s, "seconds")
		end
	else
		local idTable = instance_or_id_table
		local loadedATrack = false

		local function loadTracks(animationsTable)
			if animationsTable[DESCENDANT_ANIMS_LOADED_MARKER] then
				return
			end

			animationsTable[DESCENDANT_ANIMS_LOADED_MARKER] = true

			for animationName, animationInstance in pairs(animationsTable) do
				local type = type(animationInstance)

				if type == "table" then
					if animationInstance._singleAnimation then
						loadedATrack = true
						animator_LoadAnimation(animationInstance._singleAnimation, animationName, animationsTable, animationInstance._runtimeProps)
					else
						loadTracks(animationInstance)
					end
				elseif type == "userdata" and animationInstance.ClassName == "Animation" then
					loadedATrack = true
					animator_LoadAnimation(animationInstance, animationName, animationsTable)
				end
			end
		end

		loadTracks(idTable)

		self.FinishedLoadingSignal:Fire(rig, path or ALL_ANIMS_MARKER)

		if not loadedATrack then
			if self.TimeToLoadPrints then
				print("Finished loading animation tracks for [", rig:GetFullName(), "] at path [", path or ALL_ANIMS_MARKER, "] in 0 seconds (already loaded)")
			end
			return false
		elseif self.TimeToLoadPrints then
			print("Finished loading animation tracks for [", rig:GetFullName(), "] at path [", path or ALL_ANIMS_MARKER, "] in ", os.clock() - s, "seconds")
		end
	end

	return RAN_FULL_METHOD.Yes
end

function AnimationsClass:_awaitTracksLoadedAt(player_or_rig, path)
	CustomAssert(path ~= nil, "Path is nil")

	local rig = getRig(player_or_rig)
	self:AwaitRegistered(player_or_rig)

	local parent = self.PerRig.LoadedTracks[rig]
	local instance_or_id_table = parent
	if path ~= ALL_ANIMS_MARKER then
		local ok
		ok, instance_or_id_table = pcall(ChildFromPath, parent, path)
		CustomAssert(ok and instance_or_id_table, "No track or id table found at path [", path, "in", parent, "]")
	end

	if type(instance_or_id_table) == "userdata" then
		if instance_or_id_table.ClassName ~= "AnimationTrack" then
			Await.Args(nil, self.FinishedLoadingSignal, Await.AllArgumentsCheck(function(loadedRig, loadedPath)
				return loadedRig == rig
					and (loadedPath == ALL_ANIMS_MARKER or isSubPath(loadedPath, path))
			end))
			return RAN_FULL_METHOD.Yes
		end
	elseif not instance_or_id_table[DESCENDANT_ANIMS_LOADED_MARKER] then
		Await.Args(nil, self.FinishedLoadingSignal)
		return RAN_FULL_METHOD.Yes
	end

	return RAN_FULL_METHOD.No
end

function AnimationsClass:_areTracksLoadedAt(player_or_rig, path, parent, retIfNotFound)
	CustomAssert(path ~= nil, "Path is nil")

	local rig = getRig(player_or_rig)
	self:_rigRegisteredAssertion(rig, "unable to check are tracks loaded at path [", path or ALL_ANIMS_MARKER, "]")

	parent = parent or self.PerRig.LoadedTracks[rig]
	local instance_or_id_table = parent
	if path ~= ALL_ANIMS_MARKER then
		local ok
		ok, instance_or_id_table = pcall(ChildFromPath, parent, path)

		if retIfNotFound
			and not (ok and instance_or_id_table)
		then
			return true, nil -- Return that the track is loaded but doesn't exist to prevent errors when there shouldn't be for `_getTrack()`
		end

		CustomAssert(ok and instance_or_id_table, "No track or id table found at path [", path, "in", parent, "]")
	end

	if type(instance_or_id_table) == "userdata" then
		return instance_or_id_table.ClassName == "AnimationTrack", instance_or_id_table
	else
		return instance_or_id_table[DESCENDANT_ANIMS_LOADED_MARKER], instance_or_id_table
	end
end

function AnimationsClass:_getAnimId(rigType, path)
	local newPath = path
	if type(path) == "table" then
		newPath = table.clone(path)
		table.insert(newPath, 1, rigType)
	else
		newPath = rigType .. '.' .. path
	end

	-- `animDescriptor` is either an animation instance or table with runtime
	-- props as created when the module runs `_animationIdsToInstances()`
	local ok, animDescriptor = pcall(ChildFromPath, AnimationIds, newPath)
	CustomAssert(ok and (type(animDescriptor) == "userdata" or type(animDescriptor) == "table" and animDescriptor._singleAnimation), "No animation id found at path [", path, `] in [ AnimationIds.{rigType} ]`)

	local animId
	if type(animDescriptor) == "userdata" then
		animId = animDescriptor.AnimationId
	else
		animId = animDescriptor._singleAnimation.AnimationId
	end

	return animId
end

-------------
-- PUBLIC --
-------------
function AnimationsClass:AwaitPreloadAsyncFinished()
	if self._preloadAsyncArray then
		return self.PreloadAsyncFinishedSignal:Wait()
	end

	return RAN_FULL_METHOD.No
end

function AnimationsClass:GetTrackStartSpeed(player_or_rig: Player | Model, path: {any} | string): number?
	self:_initializedAssertion()
	
	return self:_getTrack(player_or_rig, path):GetAttribute("StartSpeed")
end

function AnimationsClass:AttachAnimatedObject(player_or_rig: Player | Model, animatedObjectPath: {any} | string)
	self:_initializedAssertion()

	self:_attachDetachAnimatedObject("attach", player_or_rig, animatedObjectPath)
end

function AnimationsClass:DetachAnimatedObject(player_or_rig: Player | Model, animatedObjectPath: {any} | string)
	self:_initializedAssertion()

	self:_attachDetachAnimatedObject("detach", player_or_rig, animatedObjectPath)
end

function AnimationsClass:AreTracksLoadedAt(player_or_rig: Player | Model, path: {any} | string): boolean
	self:_initializedAssertion()

	return not not self:_areTracksLoadedAt(player_or_rig, path)
end

function AnimationsClass:AreAllTracksLoaded(player_or_rig: Player | Model): boolean
	self:_initializedAssertion()

	return not not self:_areTracksLoadedAt(player_or_rig, ALL_ANIMS_MARKER)
end

function AnimationsClass:AwaitTracksLoadedAt(player_or_rig: Player | Model, path: {any} | string): Types.RanFullMethodType
	self:_initializedAssertion()

	return self:_awaitTracksLoadedAt(player_or_rig, path)
end

function AnimationsClass:AwaitAllTracksLoaded(player_or_rig: Player | Model): Types.RanFullMethodType
	self:_initializedAssertion()

	return self:_awaitTracksLoadedAt(player_or_rig, ALL_ANIMS_MARKER)
end

function AnimationsClass:LoadTracksAt(player_or_rig: Player | Model, path: {any} | string): Types.RanFullMethodType
	self:_initializedAssertion()

	return self:_loadTracksAt(player_or_rig, path)
end

function AnimationsClass:LoadAllTracks(player_or_rig: Player | Model): Types.RanFullMethodType
	self:_initializedAssertion()

	return self:_loadTracksAt(player_or_rig, ALL_ANIMS_MARKER)
end

function AnimationsClass:Register(player_or_rig: Player | Model, rigType: string?)
	self:_initializedAssertion()

	local rig = getRig(player_or_rig)
	if self.PerRig.IsRegistered[rig] then
		return
	end

	local isPlayer = isPlayer(player_or_rig)
	rigType = rigType or isPlayer and "Player"

	local animationIdsToClone = AnimationIds[rigType]
	CustomAssert(animationIdsToClone, "No animations found for [", player_or_rig:GetFullName(), "] under rig type [", rigType, "]")

	local connections = {}
	self.PerRig.Connections[rig] = connections

	local animatedObjectsCache = AnimatedObjectsCache.new()
	self.PerRig.AnimatedObjectsCache[rig] = animatedObjectsCache

	-- Destroy the client-sided animated object clone when the server-sided one
	-- gets added. We also destroy the server-sided one before the server does.
	-- This makes for 0 latency when the player plays animations on their
	-- character.
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

	-- When a track gets played attach an animated object if required
	table.insert(connections, getAnimator(player_or_rig, rig).AnimationPlayed:Connect(function(track)
		if self.AnimatedObjectsDebugMode then
			print(`[ANIM_OBJ_DEBUG] Animation track [ {track.Animation.AnimationId:match("%d.*")} ] played on rig [ {rig:GetFullName()} ]`)
		end

		local animatedObjectInfo = self.PerRig.TrackToAnimatedObjectInfo[rig][track.Animation.AnimationId:match("%d+$")]

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

	-- When the rig gets destroyed the animation tracks are no longer loaded
	table.insert(connections, rig.AncestryChanged:Connect(function(_, newParent)
		if newParent == nil then
			for _, conn in ipairs(connections) do
				conn:Disconnect()
			end

			clearTracks(self.PerRig.LoadedTracks[rig])

			if not isPlayer then
				self.Aliases[rig] = nil
			end

			self.PerRig.IsRegistered[rig] = nil
			self.PerRig.Connections[rig] = nil
			self.PerRig.LoadedTracks[rig] = nil
			self.PerRig.AppliedProfile[rig] = nil
			self.PerRig.AnimatedObjectsCache[rig] = nil
			self.PerRig.TrackToAnimatedObjectInfo[rig] = nil
		end
	end))

	-- Set an attribute for convenience's sake to determine a rig's "type"
	rig:SetAttribute("AnimationsRigType", rigType)

	-- Tie the player object to aliases instead of their character with
	-- `_aliasesRegisterPlayer()`
	if isPlayer then
		self:_aliasesRegisterPlayer(player_or_rig)
	else
		self.Aliases[rig] = {}
	end

	self.PerRig.TrackToAnimatedObjectInfo[rig] = {}
	self.PerRig.LoadedTracks[rig] = deepClone(animationIdsToClone)
	self.PerRig.IsRegistered[rig] = true
	self.RegisteredRigSignal:Fire(rig)
end

function AnimationsClass:AwaitRegistered(player_or_rig: Player | Model): Types.RanFullMethodType
	self:_initializedAssertion()

	local rig = getRig(player_or_rig)

	if not self.PerRig.IsRegistered[rig] then
		local done = false
		task.delay(3, function()
			if not done then
				warn(`Infinite yield possible on {self._moduleName}:AwaitRegistered({player_or_rig:GetFullName()})`)
			end
		end)
		Await.Args(nil, self.RegisteredRigSignal, rig)
		done = true
		return RAN_FULL_METHOD.Yes
	end

	return RAN_FULL_METHOD.No
end

function AnimationsClass:IsRegistered(player_or_rig: Player | Model): boolean
	self:_initializedAssertion()

	return not not self.PerRig.IsRegistered[getRig(player_or_rig)]
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

function AnimationsClass:StopPlayingTracks(player_or_rig: Player | Model, fadeTime: number?): {AnimationTrack?}
	self:_initializedAssertion()

	local animator = getAnimator(player_or_rig, getRig(player_or_rig))

	local stoppedTracks = {}

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		track:Stop(fadeTime)

		table.insert(stoppedTracks, track)
	end

	return stoppedTracks
end

function AnimationsClass:FindFirstRigPlayingTrack(rig: Model, path: {any} | string): AnimationTrack?
	self:_initializedAssertion()

	local animator = getAnimator(rig, rig)
	local rigType = GetAttributeAsync(rig, "AnimationsRigType")
	local animId = self:_getAnimId(rigType, path)

	local playingTracks = animator:GetPlayingAnimationTracks()
	for _, v in playingTracks do
		if v.Animation.AnimationId == animId then
			return v
		end
	end

	return nil
end

function AnimationsClass:GetAnimationIdString(rigType: string, path: {any} | string)
	self:_initializedAssertion()
	
	return self:_getAnimId(rigType, path)
end

function AnimationsClass:GetTimeOfMarker(animTrack_or_IdString: AnimationTrack | string, markerName: string): number?
	self:_initializedAssertion()

	local animId = animTrack_or_IdString
	if type(animTrack_or_IdString) == "userdata" then
		animId = animTrack_or_IdString.Animation.AnimationId
	end

	local thisMarkerTimes = allMarkerTimes[animId]
	if thisMarkerTimes == false then -- Indicating that it's currently loading
		-- task.delay(3, function() -- If we were going to yield forever we'd want a warning
		-- 	if not thisMarkerTimes then
		-- 		warn(`Infinite yield possible on Animations:GetTimeOfMarker({animTrack}, {markerName})`)
		-- 	end
		-- end)

		local _
		_, thisMarkerTimes = Await.Args(3, markerTimesLoadedSignal, animId)
	end

	return thisMarkerTimes and thisMarkerTimes[markerName]
end

function AnimationsClass:WaitForRigPlayingTrack(rig: Model, path: {any} | string, timeout: number?): AnimationTrack?
	self:_initializedAssertion()

	local animator = getAnimator(rig, rig)
	local rigType = GetAttributeAsync(rig, "AnimationsRigType")
	local animId = self:_getAnimId(rigType, path)

	local playingTracks = animator:GetPlayingAnimationTracks()
	for _, v in playingTracks do
		if v.Animation.AnimationId == animId then
			return v
		end
	end

	local anim = nil

	if not timeout then
		task.delay(3, function()
			if not anim then
				warn(`Infinite yield possible on 'Animations:WaitForRigPlayingTrack({rig}, {path})'`)
			end
		end)
	end

	local _
	_, anim = Await.Args(timeout, animator.AnimationPlayed, function(v)
		return v.Animation.AnimationId == animId
	end)

	return anim
end

function AnimationsClass:GetPlayingTracks(player_or_rig: Player | Model, fadeTime: number?): {AnimationTrack?}
	self:_initializedAssertion()

	local animator = getAnimator(player_or_rig, getRig(player_or_rig))

	return animator:GetPlayingAnimationTracks()
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

function AnimationsClass:GetAppliedProfileName(player_or_rig: Player | Model): string?
	self:_initializedAssertion()

	return self.PerRig.AppliedProfile[getRig(player_or_rig)]
end

function AnimationsClass:ApplyAnimationProfile(player_or_rig: Player | Model, animationProfileName: string)
	self:_initializedAssertion()

	local animationProfile = animationProfiles[animationProfileName]
	CustomAssert(animationProfile, "No animation profile found at name [", animationProfileName, "]")

	local rig = getRig(player_or_rig)
	self.PerRig.AppliedProfile[rig] = animationProfileName

	self:_applyCustomRBXAnimationIds(rig, animationProfile)
end

return AnimationsClass
