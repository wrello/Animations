-- made by wrello

local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

local AnimationIds = require(script.Parent.Parent.Parent.Deps.AnimationIds)
local Signal = require(script.Parent.Signal)
local Await = require(script.Parent.Await)
local ChildFromPath = require(script.Parent.ChildFromPath)
local CustomAssert = require(script.Parent.CustomAssert)
local AnimatedObjectsFolder = script.Parent.Parent.Parent.Deps.AnimatedObjects
local Zip = require(script.Parent.Zip)

local ANIMATED_OBJECT_MOTOR6D_NAME = "AnimatedObjectMotor6D"
local ANIM_ID_STR = "rbxassetid://%i"

local animationProfiles = Zip.children(script.Parent.Parent.Parent.Deps.AnimationProfiles)

local function getRig(player_or_rig)
	local playerCharacter 

	if player_or_rig:IsA("Player") then
		task.delay(5, function()
			if not playerCharacter then -- Can happen if `Players.CharacterAutoLoads` is disabled and this function gets called before it has a chance to load in
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

local function setToolRightGripWeldEnabled(rig, tool, enabled)
	if not tool:IsA("Tool") then
		return
	end
	
	local rightGripWeld = (rig:FindFirstChild("Right Arm") or rig:FindFirstChild("RightHand")):FindFirstChild("RightGrip")
	
	if rightGripWeld then
		rightGripWeld.Enabled = enabled
	end	
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

local AnimationsClass = {}
AnimationsClass.__index = AnimationsClass

--------------------
-- INITIALIZATION --
--------------------
function AnimationsClass:_animationIdsToInstances()
	local function replaceAnimationIdWithAnimationInstance(idTable, animationIndex, animationId)
		self.AnimationInstancesCache[animationId] = self.AnimationInstancesCache[animationId] or createAnimationInstance(tostring(animationIndex), animationId)

		idTable[animationIndex] = self.AnimationInstancesCache[animationId]
	end

	local function mapAnimationInstanceToAnimatedObjectInfo(animationInstance, animatedObjectInfo)
		local oldAnimatedObjectPath = self.AnimationInstanceToAnimatedObjectInfo[animationInstance]

		if oldAnimatedObjectPath ~= nil then
			CustomAssert(oldAnimatedObjectPath == animatedObjectInfo, "Conflicting `animatedObjectInfo` for `animationId` [", animationInstance.AnimationId, "]")
		else
			self.AnimationInstanceToAnimatedObjectInfo[animationInstance] = animatedObjectInfo
		end
	end

	local function mapAnimationInstancesToAnimatedObjectInfo(animationInstancesTable, animatedObjectInfo)
		-- `idTable` becomes `animationInstancesTable` after calling `replaceAnimationIdWithAnimationInstance` on key-value pairs
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
	self.CurrentAnimationProfiles = {}
	self.Aliases = {}
	self.AnimationInstanceToAnimatedObjectInfo = {}
	self.TrackToAnimatedObjectInfo = {}
	self.AnimationInstancesCache = {}
	self.IsRigLoaded = {}

	self:_animationIdsToInstances()
	self:_createInitializedAssertionFn()

	return self
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
	end

	self.Aliases[player_or_rig][alias] = track_or_table
end

function AnimationsClass:_removeTrackAlias(player_or_rig, alias)
	self.Aliases[player_or_rig][alias] = nil
end

function AnimationsClass:_attachDetachAnimatedObject(attach_detach, player_or_rig, animatedObjectSourcePath_or_animationTrack_or_animatedObject)
	local rig = getRig(player_or_rig)

	local animatedObjectSourcePath = nil

	if typeof(animatedObjectSourcePath_or_animationTrack_or_animatedObject) == "Instance" then
		if animatedObjectSourcePath_or_animationTrack_or_animatedObject:IsA("AnimationTrack") then
			local animationTrack = animatedObjectSourcePath_or_animationTrack_or_animatedObject

			animatedObjectSourcePath = self.TrackToAnimatedObjectInfo[rig][animationTrack.Animation.AnimationId].AnimatedObjectPath
		end
	else
		animatedObjectSourcePath = animatedObjectSourcePath_or_animationTrack_or_animatedObject
	end

	local animatedObjectSource 
		
	if animatedObjectSourcePath then
		animatedObjectSource = ChildFromPath(AnimatedObjectsFolder, animatedObjectSourcePath)
	else
		animatedObjectSource = animatedObjectSourcePath_or_animationTrack_or_animatedObject
	end

	CustomAssert(animatedObjectSource, "No animated objects found under path [", animatedObjectSourcePath, "]")

	local animatedObjectSourceIsMotor6D = animatedObjectSource:IsA("Motor6D")

	local animatedObjectMotor6DSource = animatedObjectSourceIsMotor6D and animatedObjectSource or animatedObjectSource:FindFirstChild(ANIMATED_OBJECT_MOTOR6D_NAME, true)

	if not animatedObjectSourceIsMotor6D then
		CustomAssert(animatedObjectMotor6DSource, "No AnimatedObjectMotor6D (\"" .. ANIMATED_OBJECT_MOTOR6D_NAME .. "\") found for animated object [", animatedObjectSource:GetFullName(), "]")
	end

	local part0NameStringValue = animatedObjectMotor6DSource:FindFirstChild("Part0Name")
	local part0Name = part0NameStringValue and part0NameStringValue.Value

	CustomAssert(part0Name, "No AnimatedObjectMotor6D.Part0Name found for [", animatedObjectMotor6DSource:GetFullName(), "]")

	local part1NameStringValue = animatedObjectMotor6DSource:FindFirstChild("Part1Name")
	local part1Name = part1NameStringValue and part1NameStringValue.Value

	CustomAssert(part1Name, "No AnimatedObjectMotor6D.Part1Name found for [", animatedObjectMotor6DSource:GetFullName(), "]")

	local attachedAnimatedObject = rig:FindFirstChild(animatedObjectSource.Name)
	local attachedAnimatedObjectMotor6D = attachedAnimatedObject and attachedAnimatedObject:FindFirstChild(ANIMATED_OBJECT_MOTOR6D_NAME)

	local function attach(animatedObjectSource, parent)
		local animatedObject

		if animatedObjectSourceIsMotor6D then
			animatedObject = attachedAnimatedObject
		else
			animatedObject = animatedObjectSource:Clone()
			animatedObject.Parent = parent
		end

		setToolRightGripWeldEnabled(rig, animatedObject, false)

		local animatedObjectMotor6D

		if animatedObjectSourceIsMotor6D then
			animatedObjectMotor6D = animatedObjectSource:Clone()
			animatedObjectMotor6D.Name = ANIMATED_OBJECT_MOTOR6D_NAME
			animatedObjectMotor6D.Parent = animatedObject
		else
			animatedObjectMotor6D = animatedObject:FindFirstChild(ANIMATED_OBJECT_MOTOR6D_NAME, true)
		end

		-- Setting the motor6D's Part0 to the correct body part so it will work with the animation
		animatedObjectMotor6D.Part0 = rig:FindFirstChild(part0Name, true)

		-- Setting the motor6D's Part1 to the correct tool part so it will work with the animation
		animatedObjectMotor6D.Part1 = animatedObject.Name == part1Name and animatedObject or animatedObject:FindFirstChild(part1Name, true)	
	end

	if attach_detach == "detach" then
		if attachedAnimatedObject then
			setToolRightGripWeldEnabled(rig, attachedAnimatedObject, true)

			if animatedObjectSourceIsMotor6D then
				if attachedAnimatedObjectMotor6D then
					if self.AnimatedObjectsDebugMode then
						print(`Detaching AnimatedObjectMotor6D [ {attachedAnimatedObjectMotor6D:GetFullName()} ]`)
					end

					attachedAnimatedObjectMotor6D:Destroy()
				end
			else
				if self.AnimatedObjectsDebugMode then
					print(`Detaching animated object [ {attachedAnimatedObject:GetFullName()} ]`)
				end

				attachedAnimatedObject:Destroy()
			end
		end
	elseif attach_detach == "attach" then
		if animatedObjectSourceIsMotor6D then
			if attachedAnimatedObjectMotor6D then
				if self.AnimatedObjectsDebugMode then
					print(`Unable to attach AnimatedObjectMotor6D [ {animatedObjectMotor6DSource.Name} ] because [ {attachedAnimatedObjectMotor6D:GetFullName()} ] is already attached`)
				end

				return
			end

			if not attachedAnimatedObject then
				if self.AnimatedObjectsDebugMode then
					print(`Unable to attach AnimatedObjectMotor6D [ {animatedObjectMotor6DSource.Name} ] because [ {animatedObjectMotor6DSource.Name} ] is not an attached animated object (child of the rig)`)
				end

				return
			end
		elseif attachedAnimatedObject then
			if self.AnimatedObjectsDebugMode then
				print(`Unable to attach animated object [ {animatedObjectSource.Name} ] because [ {attachedAnimatedObject:GetFullName()} ] is already attached`)
			end

			return
		end

		if self.AnimatedObjectsDebugMode then
			if animatedObjectSourceIsMotor6D then
				print(`Attaching AnimatedObjectMotor6D [ {animatedObjectMotor6DSource.Name} ]`)
			else
				print(`Attaching animated object [ {animatedObjectSource.Name} ]`)
			end
		end

		if animatedObjectSource:IsA("Folder") then
			local animatedObjectFolder = Instance.new("Folder")
			animatedObjectFolder.Name = animatedObjectSource.Name
			animatedObjectFolder.Parent = rig

			for _, animatedObjectSourceChild in ipairs(animatedObjectSource:GetChildren()) do
				attach(animatedObjectSourceChild, animatedObjectFolder)
			end
		else
			attach(animatedObjectSource, rig)
		end
	end
end

function AnimationsClass:_applyCustomRBXAnimationIds(player, humanoidRigTypeToCustomRBXAnimationIds)
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	local animator = hum:WaitForChild("Animator") :: Animator
	local animateScript = char:WaitForChild("Animate")

	for _, track in pairs(animator:GetPlayingAnimationTracks()) do
		track:Stop(0)
	end

	local humRigTypeCustomRBXAnimationIds = humanoidRigTypeToCustomRBXAnimationIds[hum.RigType]

	if humRigTypeCustomRBXAnimationIds then
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

		if RunService:IsClient() then
			self.ApplyCustomRBXAnimationIdsSignal:Fire()
		else
			self.ApplyCustomRBXAnimationIdsSignal:FireClient(player)
		end
	end
end

-------------
-- PUBLIC --
-------------
function AnimationsClass:AttachAnimatedObject(player_or_rig: Player | Model, animatedObjectSourcePath_or_animationTrack_or_animatedObject: ({any} | string) | AnimationTrack | any)
	self._initializedAssertion()
		
	self:_attachDetachAnimatedObject("attach", player_or_rig, animatedObjectSourcePath_or_animationTrack_or_animatedObject)
end

function AnimationsClass:DetachAnimatedObject(player_or_rig: Player | Model, animatedObjectSourcePath_or_animationTrack_or_animatedObject: ({any} | string) | AnimationTrack | any)
	self._initializedAssertion()

	self:_attachDetachAnimatedObject("detach", player_or_rig, animatedObjectSourcePath_or_animationTrack_or_animatedObject)
end

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

	local animator: Animator = getAnimator(player_or_rig, rig)

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
					self.TrackToAnimatedObjectInfo[rig][track.Animation.AnimationId] = animatedObjectInfo
				end
			end
		end
	end

	self.TrackToAnimatedObjectInfo[rig] = {}

	loadTracks(AnimationIds[rigType], self.LoadedTracks[rig])

	animator.AnimationPlayed:Connect(function(track) -- When a track gets played attach an animated object if required
		if self.AnimatedObjectsDebugMode then
			print(`Animation track [ {track.Animation.AnimationId:match("%d.*")} ] played on rig [ {rig.Name} ]`)
		end
		
		local animatedObjectInfo = self.TrackToAnimatedObjectInfo[rig][track.Animation.AnimationId]

		if animatedObjectInfo then
			local autoAttachDetachSettings = animatedObjectInfo.AutoAttachDetachSettings
			
			if autoAttachDetachSettings then
				local runContext = autoAttachDetachSettings.RunContext
				
				CustomAssert(runContext == "Client" or runContext == "Server", "Invalid AutoAttachDetachSettings.RunContext [", runContext,"] for animation track [", track.Animation.AnimationId:match("%d.*"), "]")
				
				local isCorrectRunContext = RunService["Is" .. runContext](RunService)
				
				if isCorrectRunContext then
					if autoAttachDetachSettings.AutoAttach then
						self:_attachDetachAnimatedObject("attach", player_or_rig, animatedObjectInfo.AnimatedObjectPath)
					end

					if autoAttachDetachSettings.AutoDetach then
						track.Stopped:Once(function()
							if self.AnimatedObjectsDebugMode then
								print(`Animation track [ {track.Animation.AnimationId:match("%d.*")} ] stopped on rig [ {rig.Name} ]`)
							end

							self:_attachDetachAnimatedObject("detach", player_or_rig, animatedObjectInfo.AnimatedObjectPath)
						end)
					end
				end
			end
		end
	end)
	
	self.IsRigLoaded[rig] = true

	rig.Destroying:Connect(function() -- When the rig gets destroyed the animation tracks are no longer loaded
		self.IsRigLoaded[rig] = false
		self.LoadedTracks[rig] = nil -- Release memory
		self.TrackToAnimatedObjectInfo[rig] = nil -- Release memory
	end)

	if self.TimeToLoadPrints then
		print("Finished pre-loading animations for [", rig, "] -", os.clock()-s, "seconds taken")
	end

	self.FinishedLoadingRigSignal:Fire(rig)
end

function AnimationsClass:GetTrack(player_or_rig: Player | Model, path: {any} | string): AnimationTrack?
	self._initializedAssertion()

	return self:_getTrack(player_or_rig, path)
end

function AnimationsClass:PlayTrack(player_or_rig: Player | Model, path: {any} | string, fadeTime: number?, weight: number?, speed: number?): AnimationTrack
	self._initializedAssertion()

	return self:_playStopTrack("Play", player_or_rig, path, false, fadeTime, weight, speed)
end

function AnimationsClass:StopTrack(player_or_rig: Player | Model, path: {any} | string, fadeTime: number?): AnimationTrack
	self._initializedAssertion()

	return self:_playStopTrack("Stop", player_or_rig, path, false, fadeTime)
end

function AnimationsClass:StopTracksOfPriority(player_or_rig: Player | Model, animationPriority: Enum.AnimationPriority, fadeTime: number?): {AnimationTrack?}
	self._initializedAssertion()
	
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

function AnimationsClass:SetTrackAlias(player_or_rig: Player | Model, alias: any, path: {any} | string)
	self._initializedAssertion()

	self:_setTrackAlias(player_or_rig, alias, path)
end

function AnimationsClass:RemoveTrackAlias(player_or_rig: Player | Model, alias: any)
	self._initializedAssertion()

	self:_removeTrackAlias(player_or_rig, alias)
end

function AnimationsClass:ApplyCustomRBXAnimationIds(player: Player, humanoidRigTypeToCustomRBXAnimationIds: HumanoidRigTypeToCustomRBXAnimationIdsType)
	self._initializedAssertion()

	self:_applyCustomRBXAnimationIds(player, humanoidRigTypeToCustomRBXAnimationIds)
end

function AnimationsClass:ApplyAnimationProfile(player: Player, animationProfileName: string)
	self._initializedAssertion()
	
	local animationProfile = animationProfiles[animationProfileName]

	self:_applyCustomRBXAnimationIds(player, animationProfile)
end

return AnimationsClass