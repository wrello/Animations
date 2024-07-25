-- made by wrello

local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

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
		local type = type(track)

		if type == "table" then
			clearTracks(track)
		elseif type == "userdata" then
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

local AnimationsClass = {}
AnimationsClass.__index = AnimationsClass

--------------------
-- INITIALIZATION --
--------------------
function AnimationsClass:_createAnimationInstance(animationName, animationId)
	local animation = Instance.new("Animation")
	animation.Name = animationName
	animation.AnimationId = ANIM_ID_STR:format(animationId)
	
	table.insert(self._preloadAsyncArray, animation)
	
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

	local hasAnimatedObjectUnpackQueue = Queue.new()

	local function hasAnimatedObjectUnpackAll()
		for unpackFn in hasAnimatedObjectUnpackQueue:DequeueIter() do
			unpackFn()
		end
	end

	local function replaceAnimationIdWithAnimationInstance(idTable, animationIndex, animationId)
		self.AnimationInstancesCache[animationId] = self.AnimationInstancesCache[animationId] or self:_createAnimationInstance(tostring(animationIndex), animationId)

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
			local type = type(animationInstance)

			if type == "table" then
				local nextIdTable = animationInstance

				mapAnimationInstancesToAnimatedObjectInfo(nextIdTable, animatedObjectInfo)
			elseif type == "userdata" then
				mapAnimationInstanceToAnimatedObjectInfo(animationInstance, animatedObjectInfo)
			end
		end
	end

	local function initializeAnimationIds(idTable)
		for animationIndex, animationId in pairs(idTable) do
			local type = type(animationId)

			if type == "table" then
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
									idTable[k] = v
								end
							end)
						end

						initializeAnimationIds(nextIdTable)
						mapAnimationInstancesToAnimatedObjectInfo(nextIdTable, animatedObjectInfo)
					end
				else
					initializeAnimationIds(nextIdTable)
				end
			elseif type == "number" then -- The `animationId` was already turned into an animation instance (happens when multiple references to the same animation id table occur)
				replaceAnimationIdWithAnimationInstance(idTable, animationIndex, animationId)
			end
		end
	end

	local function preloadAsync()
		local len = #self._preloadAsyncArray
		for i, animation in ipairs(self._preloadAsyncArray) do
			ContentProvider:PreloadAsync({animation})
			self.PreloadAsyncProgressed:Fire(i, len, animation)
		end

		local clone = table.clone(self._preloadAsyncArray)

		table.clear(self._preloadAsyncArray)
		self._preloadAsyncArray = nil

		self.PreloadAsyncFinishedSignal:Fire(clone)
	end

	for _, idTable in pairs(AnimationIds) do
		initializeAnimationIds(idTable)
	end

	hasAnimatedObjectUnpackAll()
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

	track[play_stop](track, fadeTime, weight, speed)

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

function AnimationsClass:_attachDetachAnimatedObject(attach_detach, player_or_rig, animatedObjectPath, animatedObjectInfo)
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
		if animatedObjectsCache:Get(animatedObjectPath) then
			if self.AnimatedObjectsDebugMode then
				print("[ANIM_OBJ_DEBUG] Unable to attach animated object - attached animated object already found under path [", animatedObjectPath, "]")
			end
			return
		end

		local ok, animatedObjectSrc = pcall(ChildFromPath, animatedObjectsFolder, animatedObjectPath)
		CustomAssert(ok, "Unable to attach animated object - no animated objects found under path [", animatedObjectPath, "]")

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

function AnimationsClass:_editAnimateScriptValues(animator, animateScript, humRigTypeCustomRBXAnimationIds)
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
		local player = Players:GetPlayerFromCharacter(rig)

		if player then
			local clientSidedAnimateScript = animateScript.ClassName == "LocalScript" or animateScript.RunContext == Enum.RunContext.Client

			if RunService:IsClient() then
				if clientSidedAnimateScript then
					self.ApplyCustomRBXAnimationIdsSignal:Fire(animator, animateScript, humRigTypeCustomRBXAnimationIds)
				else
					self.ApplyCustomRBXAnimationIdsSignal:Fire()
				end
			else
				if not clientSidedAnimateScript then -- Forced to make changes on the server because the client can't make them
					self:_editAnimateScriptValues(animator, animateScript, humRigTypeCustomRBXAnimationIds)
					self.ApplyCustomRBXAnimationIdsSignal:FireClient(player)
				else
					self.ApplyCustomRBXAnimationIdsSignal:FireClient(player, animator, animateScript, humRigTypeCustomRBXAnimationIds)
				end
			end
		else
			self:_editAnimateScriptValues(animator, animateScript, humRigTypeCustomRBXAnimationIds)

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

	local animator = getAnimator(rig, rig)

	while not animator:IsDescendantOf(workspace) do
		animator.AncestryChanged:Wait()
	end

	if type(instance_or_id_table) == "userdata" then
		if instance_or_id_table.ClassName == "AnimationTrack" then
			if self.TimeToLoadPrints then
				print("Finished loading animation tracks for [", rig:GetFullName(), "] at path [", path or ALL_ANIMS_MARKER, "] in 0 seconds (already loaded)")
			end

			return RAN_FULL_METHOD.No
		else
			local animationInstance = instance_or_id_table
			local track = animator:LoadAnimation(animationInstance)

			parent_id_table[animationName] = track

			local animatedObjectInfo = self.AnimationInstanceToAnimatedObjectInfo[animationInstance]
			if animatedObjectInfo then
				self.PerRig.TrackToAnimatedObjectInfo[rig][animationInstance.AnimationId] = animatedObjectInfo
			end

			if self.TimeToLoadPrints then
				print("Finished loading animation tracks for [", rig:GetFullName(), "] at path [", path or ALL_ANIMS_MARKER, "] in ", os.clock() - s, "seconds")
			end
		end
	elseif instance_or_id_table[DESCENDANT_ANIMS_LOADED_MARKER] then
		if self.TimeToLoadPrints then
			print("Finished loading animation tracks for [", rig:GetFullName(), "] at path [", path or ALL_ANIMS_MARKER, "] in 0 seconds (already loaded)")
		end

		return RAN_FULL_METHOD.No
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
					loadTracks(animationInstance)
				elseif type == "userdata" and animationInstance.ClassName == "Animation" then
					if loadedATrack == false then
						loadedATrack = true
					end

					local track = animator:LoadAnimation(animationInstance)
					animationsTable[animationName] = track

					local animatedObjectInfo = self.AnimationInstanceToAnimatedObjectInfo[animationInstance]
					if animatedObjectInfo then
						self.PerRig.TrackToAnimatedObjectInfo[rig][animationInstance.AnimationId] = animatedObjectInfo
					end
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
		CustomAssert(ok, "No track or id table found at path [", path, "in", parent, "]")
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

-------------
-- PUBLIC --
-------------
function AnimationsClass:AwaitPreloadAsyncFinished()
	if self._preloadAsyncArray then
		return self.PreloadAsyncFinishedSignal:Wait()
	end

	return RAN_FULL_METHOD.No
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
	table.insert(connections, getAnimator(player_or_rig, rig).AnimationPlayed:Connect(function(track)
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

			clearTracks(self.PerRig.LoadedTracks[rig])

			if not isPlayer then
				self.Aliases[rig] = nil
			end

			self.PerRig.IsRegistered[rig] = nil
			self.PerRig.Connections[rig] = nil
			self.PerRig.LoadedTracks[rig] = nil
			self.PerRig.AnimatedObjectsCache[rig] = nil
			self.PerRig.TrackToAnimatedObjectInfo[rig] = nil
		end
	end))

	-- Set an attribute for convenience's sake to determine
	-- a rig's "type"
	rig:SetAttribute("AnimationsRigType", rigType)

	-- Tie the player object to aliases instead of their
	-- character with `_aliasesRegisterPlayer()`
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

function AnimationsClass:ApplyAnimationProfile(player_or_rig: Player | Model, animationProfileName: string)
	self:_initializedAssertion()

	local animationProfile = animationProfiles[animationProfileName]
	CustomAssert(animationProfile, "No animation profile found at name [", animationProfileName, "]")

	self:_applyCustomRBXAnimationIds(player_or_rig, animationProfile)
end

return AnimationsClass