--!strict
-- made by wrello
-- GitHub: https://github.com/wrello/Animations

assert(game:GetService("RunService"):IsClient(), "Attempt to require AnimationsClient on the server")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Types = require(script.Parent.Util.Types)
local Signal = require(script.Parent.Util.Signal)
local AnimationsClass = require(script.Parent.Util.AnimationsClass)
local ChildFromPath = require(script.Parent.Util.ChildFromPath)

local player = Players.LocalPlayer

local AutoCustomRBXAnimationIds = nil

--[=[
	@interface initOptions
	@within AnimationsClient
	.AutoLoadAllPlayerTracks false
	.AutoRegisterPlayer true
	.BootstrapDepsFolder Folder?
	.EnableAutoCustomRBXAnimationIds false
	.TimeToLoadPrints true
	.AnimatedObjectsDebugMode false

	For more info, see [`Properties`](/api/AnimationsClient/#properties).
]=]
type AnimationsClientInitOptionsType = Types.AnimationsClientInitOptionsType

--[=[
	@type path {any} | string
	@within AnimationsClient

	```lua
	-- In a LocalScript
	local Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsClient)


	-- These are all valid options for retrieving an animation track
	local animationPath = "Jump" -- A single key (any type)

	local animationPath = {"Dodge", Vector3.xAxis} -- An array path (values of any type)

	local animationPath = "Climb.Right" -- A path seperated by "." (string)


	local animationTrack = Animations:GetTrack(animationPath)
	```
]=]
local Animations = AnimationsClass.new(script.Name)

--[=[
	@class AnimationsClient
	@client

	:::note
	Roblox model path: `Animations.Package.AnimationsClient`
	:::

	:::info
	Any reference to "client animation tracks" is referring to animation ids found under [`rigType`](/api/AnimationIds#rigType) of **"Player"** in the [`AnimationIds`](/api/AnimationIds) module.
	:::
]=]
local AnimationsClient = Animations

--[=[
	@prop AutoLoadAllPlayerTracks false
	@within AnimationsClient

	If set to true, client animation tracks will be loaded each time the client spawns.

	:::warning
	Must have animation ids under [`rigType`](/api/AnimationIds#rigType) of **"Player"** in the [`AnimationIds`](/api/AnimationIds) module.
	:::

	:::caution *changed in version 2.0.0-rc1*
	Renamed: ~~`AutoLoadPlayerTracks`~~ -> `AutoLoadAllPlayerTracks`
	:::
]=]
AnimationsClient.AutoLoadAllPlayerTracks = false

--[=[
	@prop AutoRegisterPlayer true
	@within AnimationsClient

	If set to true, the client will be auto registered with [`rigType`](/api/AnimationIds#rigType) of **"Player"** each time they spawn.

	:::tip *added in version 2.6.0*
	:::
]=]
AnimationsClient.AutoRegisterPlayer = true

--[=[
	@prop BootstrapDepsFolder nil
	@within AnimationsClient

	Set the to the dependencies folder if you have moved it from its original location inside of the root `Animations` folder.

	:::tip *added in version 2.0.0-rc1*
	:::

	:::caution *changed in version 2.6.0*
	Deprecated `DepsFolderPath`
	:::
]=]
AnimationsClient.BootstrapDepsFolder = nil

--[=[
	@prop EnableAutoCustomRBXAnimationIds false
	@within AnimationsClient

	If set to true, applies the [`AutoCustomRBXAnimationIds`](/api/AutoCustomRBXAnimationIds) module table to the client on spawn.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]
AnimationsClient.EnableAutoCustomRBXAnimationIds = false

--[=[
	@prop TimeToLoadPrints true
	@within AnimationsClient

	If set to true, makes helpful prints about the time it takes to pre-load and load animations.
]=]
AnimationsClient.TimeToLoadPrints = true

--[=[
	@prop AnimatedObjectsDebugMode false
	@within AnimationsClient

	If set to true, prints will be made to help debug attaching and detaching animated objects.
]=]
AnimationsClient.AnimatedObjectsDebugMode = false

--[=[
	@yields
	@param initOptions initOptions?

	Initializes `AnimationsClient`.

	Yields when...
	- ...server has not initialized.
	- ...animations are being pre-loaded with `ContentProvider:PreloadAsync()` (could take a while).

	:::info
	Should be called once before any other method.
	:::
]=]
function AnimationsClient:Init(initOptions: AnimationsClientInitOptionsType?)
	if self._initialized then
		warn("AnimationsClient:Init() only needs to be called once")
		return
	end

	local function bootstrapDepsFolder()
		local depsFolder

		if self.DepsFolderPath then -- Maintain for backwards compatability
			local ok
			ok, depsFolder = pcall(ChildFromPath, game, self.DepsFolderPath)
			assert(ok and depsFolder, "No animation deps folder found at path '" .. self.DepsFolderPath .. "'")
		elseif self.BootstrapDepsFolder then
			depsFolder = self.BootstrapDepsFolder
		else
			depsFolder = script.Parent.Parent.Deps
		end

		AutoCustomRBXAnimationIds = require(depsFolder.AutoCustomRBXAnimationIds)

		self:_bootstrapDepsFolder(depsFolder)
	end

	local function awaitServerInitialized()
		local serverInitialized = script.Parent.AnimationsServer:GetAttribute("InitializedForClients")
		if not serverInitialized then
			task.delay(3, function()
				if not serverInitialized then
					warn("Infinite yield possible waiting for AnimationsServer:Init()")
				end
			end)

			script.Parent.AnimationsServer:GetAttributeChangedSignal("InitializedForClients"):Wait()

			serverInitialized = true
		end
	end

	local function initInitOptions()
		if initOptions then
			for k, v in pairs(initOptions) do
				self[k] = v
			end
		end
	end

	local function initMethods()
		local manualRigMethodNames = {
			["AreAllTracksLoaded"] = "AreAllRigTracksLoaded",
			["LoadAllTracks"] = "LoadAllRigTracks",
			["AwaitAllTracksLoaded"] = "AwaitAllRigTracksLoaded",
		}

		local noAlternative = {"GetAnimationProfile", "AwaitPreloadAsyncFinished", "FindFirstRigPlayingTrack", "WaitForRigPlayingTrack", "GetTimeOfMarker", "GetAnimationIdString"}

		for k: string, v in pairs(AnimationsClass) do
			if type(v) == "function" and not k:match("^_") and not table.find(noAlternative, k) then
				local clientMethodName = k
				local rigMethodName = manualRigMethodNames[clientMethodName] or clientMethodName:gsub("^(%L[^%L]+)(%L?[^%L]*)", "%1Rig%2")

				self[clientMethodName] = function(self, ...)
					return v(self, player, ...)
				end

				self[rigMethodName] = function(self, rig, ...)
					return v(self, rig, ...)
				end
			end
		end
	end

	local function initOnPlayerSpawn()
		local function onCharacterAdded(char)
			if self.AutoRegisterPlayer then
				self:Register("Player")
			end

			if self.AutoLoadAllPlayerTracks then
				self:LoadAllTracks()
			end

			if self.EnableAutoCustomRBXAnimationIds then
				self:ApplyCustomRBXAnimationIds(AutoCustomRBXAnimationIds)
			end
		end

		if player.Character then
			onCharacterAdded(player.Character)
		end

		player.CharacterAdded:Connect(onCharacterAdded)
	end

	local function initCustomRBXAnimationIdsSignal()
		local function applyCustomRBXAnimationIds(humRigTypeCustomRBXAnimationIds)
			local hum = nil

			if humRigTypeCustomRBXAnimationIds then
				local char = player.Character or player.CharacterAdded:Wait()
				local animator = char:WaitForChild("Humanoid"):WaitForChild("Animator")
				local animateScript = char:WaitForChild("Animate")

				self:_editAnimateScriptValues(animator, animateScript, humRigTypeCustomRBXAnimationIds)
			end

			local char = player.Character
			hum = char:FindFirstChild("Humanoid")

			if hum then
				-- Here we have to hack the state system to force apply the new
				-- animation ids if we don't want to modify the 'Animate' script
				if hum:GetState() == Enum.HumanoidStateType.Freefall then -- Can't change to 'Landed' mid-air because it will freeze the character
					hum:ChangeState(Enum.HumanoidStateType.Running)
				else
					hum:ChangeState(Enum.HumanoidStateType.Landed)
				end
			end
		end

		self.ApplyCustomRBXAnimationIdsSignal = Signal.new()

		local signals = {self.ApplyCustomRBXAnimationIdsSignal, script.Parent:WaitForChild("ApplyCustomRBXAnimationIds").OnClientEvent}

		for _, signal in ipairs(signals) do
			signal:Connect(applyCustomRBXAnimationIds)
		end
	end

	local function destroyAnimationsServer()
		script.Parent.AnimationsServer:Destroy()
	end

	awaitServerInitialized()
	initInitOptions()
	bootstrapDepsFolder()
	self:_animationIdsToInstances()
	destroyAnimationsServer()
	initCustomRBXAnimationIdsSignal()
	initMethods()
	self._initialized = true -- Need to initialize before using methods in the function below
	initOnPlayerSpawn()
end



--
-- Note: Replication behavior of tool from client->server

-- Requirement for any replication to happen from client -> server: The tool
-- must be already in their character or backpack *on the server*.

-- The client must only reparent the tool to their character or backpack. As
-- soon as the client reparents the tool elsewhere, the replication of
-- reparenting will stop.
--

-- Not available on client because the motor6d attaching will not replicate but
-- reparenting can so it creates weird behavior
-- --[=[
-- 	@tag Beta
-- 	@method EquipAnimatedTool
-- 	@within AnimationsClient
-- 	@param tool: Tool
-- 	@param motor6dName: string

-- 	Equips the `tool` for the client and then attaches the `motor6d` found in the `AnimatedObjects` folder to it.

-- 	:::caution
-- 	This method is in beta testing. Use with caution.
-- 	:::
-- 	:::tip *added in version 2.4.0*
-- 	:::
-- ]=]
--[=[
	@tag Beta

	Equips the `tool` for the `rig` and then attaches the `motor6d` found in the `AnimatedObjects` folder to it.

	:::note
	This does not replicate to the server.
	:::
	:::caution
	This method is in beta testing. Use with caution.
	:::
	:::tip *added in version 2.4.0*
	:::
]=]
function AnimationsClient:EquipRigAnimatedTool(player_or_rig: Player | Model, toolToEquip: Tool, motor6dName: Motor6D)
	self:_initializedAssertion()

	self:_attachDetachAnimatedObject("attach", player_or_rig, motor6dName, nil, toolToEquip)
end

--[=[
	@method GetTrackStartSpeed
	@within AnimationsClient
	@param path path
	@return number?

	Returns the animation track's `StartSpeed` (if set in [`HasProperties`](/api/AnimationIds#HasProperties)) or `nil`.

	:::tip *added in version 2.3.0*
	:::
]=]
--[=[
	@method GetRigTrackStartSpeed
	@within AnimationsClient
	@param rig Model
	@param path path
	@return number?

	Returns the animation track's `StartSpeed` (if set in [`HasProperties`](/api/AnimationIds#HasProperties)) or `nil`.

	:::tip *added in version 2.3.0*
	:::
]=]

--[=[
	@yields
	@tag Beta
	@method GetTimeOfMarker
	@within AnimationsClient
	@param animTrack_or_IdString AnimationTrack | string
	@param markerName string
	@return number?

	The only reason this would yield is if the
	initialization process that caches all of the marker
	times is still going on when this method gets called. If
	after 3 seconds the initialization process still has not
	finished, this method will return `nil`.
	
	```lua
	local attackAnim = Animations:PlayTrack("Attack")
	local timeOfHitStart = Animations:GetTimeOfMarker(attackAnim, "HitStart")

	print("Time of hit start:", timeOfHitStart)

	-- or

	local animIdStr = Animations:GetAnimationIdString("Player", "Attack")
	local timeOfHitStart = Animations:GetTimeOfMarker(animIdStr, "HitStart")

	print("Time of hit start:", timeOfHitStart)
	```

	:::info
	You must first modify your
	[`AnimationIds`](/api/AnimationIds) module to specify
	which animations this method will work on.
	:::
	:::caution
	This method is in beta testing. Use with caution.
	:::
	:::tip *added in version 2.1.0*
	:::
]=]
--[=[
	@method GetAnimationIdString
	@within AnimationsClient
	@param rigType rigType
	@param path path
	@return string

	Returns the animation id string under `rigType` at `path` in the [`AnimationIds`](/api/AnimationIds) module.

	```lua
	local animIdStr = Animations:GetAnimationIdString("Player", "Run")
	print(animIdStr) --> "rbxassetid://89327320"
	```

	:::tip *added in version 2.1.0*
	:::
]=]

--[=[
	@method FindFirstRigPlayingTrack 
	@within AnimationsClient 
	@param rig Model
	@param path path
	@return AnimationTrack?

	Returns a playing animation track found in
	`rig.Humanoid.Animator:GetPlayingAnimationTracks()`
	matching the animation id found at `path` in the
	[`AnimationIds`](/api/AnimationIds) module or `nil`.

	```lua
	-- [WARNING] For this to work, `enemyCharacter` would have to be registered (most likely on the server) and "Blocking" would need to be a valid animation name defined in the `AnimationIds` module.
	local isBlocking = Animations:FindFirstRigPlayingTrack(enemyCharacter, "Blocking")

	if isBlocking then
		warn("We can't hit the enemy, they're blocking!")
	end
	```

	:::tip *added in version 2.1.0*
	:::
]=]
--[=[
	@yields
	@method WaitForRigPlayingTrack
	@within AnimationsClient
	@param rig Model
	@param path path
	@param timeout number?
	@return AnimationTrack?

	Yields until a playing animation track is found in
	`rig.Humanoid.Animator:GetPlayingAnimationTracks()`
	matching the animation id found at `path` in the
	[`AnimationIds`](/api/AnimationIds) module then returns it or returns `nil` after
	`timeout` seconds if provided.

	Especially useful if the animation needs time to replicate from server to client and you want to specify a maximum time to wait until it replicates.

	```lua
	-- [WARNING] For this to work, `enemyCharacter` would have to be registered (on the server) and "Blocking" would need to be a valid animation name defined in the `AnimationIds` module.
	local isBlocking = Animations:WaitForRigPlayingTrack(enemyCharacter, "Blocking", 1)

	if isBlocking then
		warn("We can't hit the enemy, they're blocking!")
	end
	```

	:::tip *added in version 2.1.0*
	:::
]=]

--[=[
	@method GetAppliedProfileName
	@within AnimationsClient
	@return string?

	Returns the client's currently applied animation profile name or `nil`.

	:::tip *added in version 2.0.0*
	:::
]=]
--[=[
	@method GetRigAppliedProfileName
	@within AnimationsClient
	@param rig Model
	@return string?

	Returns the `rig`'s currently applied animation profile name or `nil`.

	:::tip *added in version 2.0.0*
	:::
]=]

--[=[
	@method AwaitPreloadAsyncFinished
	@yields
	@within AnimationsClient
	@return {Animation?}

	Yields until `ContentProvider:PreloadAsync()` finishes pre-loading all animation instances.

	```lua
	-- In a LocalScript
	local loadedAnimInstances = Animations:AwaitPreloadAsyncFinished()
		
	print("ContentProvider:PreloadAsync() finished pre-loading all:", loadedAnimInstances)
	```

	:::tip *added in version 2.0.0-rc1*
	:::
]=]
--[=[
	@prop PreloadAsyncProgressed RBXScriptSignal
	@within AnimationsClient

	Fires when `ContentProvider:PreloadAsync()` finishes pre-loading one animation instance.

	```lua
	-- In a LocalScript
	Animations.PreloadAsyncProgressed:Connect(function(n, total, loadedAnimInstance)
		print("ContentProvider:PreloadAsync() finished pre-loading one:", n, total, loadedAnimInstance)
	end)
	```

	:::tip *added in version 2.0.0-rc1*
	:::
]=]

--[=[
	@interface customRBXAnimationIds
	@within AnimationsClient
	.run number?
	.walk number?
	.jump number?
	.idle {Animation1: number?, Animation2: number?}?
	.fall number?
	.swim number?
	.swimIdle number?
	.climb number?

	A table of animation ids to replace the default roblox animation ids.

	:::info
	Roblox applies the `"walk"` animation id for `R6` characters and the `"run"` animation id for `R15` characters (instead of both).
	:::
]=]

--[=[
	@interface humanoidRigTypeToCustomRBXAnimationIds
	@within AnimationsClient
	.[Enum.HumanoidRigType.R6] customRBXAnimationIds?
	.[Enum.HumanoidRigType.R15] customRBXAnimationIds?

	A table mapping a `Enum.HumanoidRigType` to its supported animation ids that will replace the default roblox animation ids.
]=]

--[=[
	@method Register
	@within AnimationsClient

	Registers the client's character so that methods using animation tracks can be called.

	:::note
	The client's character gets automatically registered through the `client.CharacterAdded` event.
	:::

	:::tip
	Automatically gives the `rig` (the client's character) an attribute `"AnimationsRigType"` set to the [`rigType`](/api/AnimationIds#rigType) (which is "Player" in this case).
	:::

	:::tip *added in version 2.0.0-rc1*
	:::
]=]
--[=[
	@method RegisterRig
	@within AnimationsClient
	@param rig Model
	@param rigType string

	Registers the `rig` so that rig methods using animation tracks can be called.

	:::tip
	Automatically gives the `rig` an attribute `"AnimationsRigType"` set to the [`rigType`](/api/AnimationIds/#rigType).
	:::

	:::tip *added in version 2.0.0-rc1*
	:::
]=]

--[=[
	@method AwaitRegistered
	@yields
	@within AnimationsClient

	Yields until the client gets registered.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]
--[=[
	@method AwaitRigRegistered
	@yields
	@within AnimationsClient
	@param rig Model

	Yields until the `rig` gets registered.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]

--[=[
	@method IsRegistered
	@within AnimationsClient
	@return boolean

	Returns if the client is registered.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]
--[=[
	@method IsRigRegistered
	@within AnimationsClient
	@param rig Model
	@return boolean

	Returns if the `rig` is registered.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]

--[=[
	@method ApplyCustomRBXAnimationIds
	@within AnimationsClient
	@yields
	@param humanoidRigTypeToCustomRBXAnimationIds humanoidRigTypeToCustomRBXAnimationIds

	Applies the animation ids specified in the [`humanoidRigTypeToCustomRBXAnimationIds`](#humanoidRigTypeToCustomRBXAnimationIds) table on the client's character.

	Yields when...
	- ...the client's character, humanoid, animator, or animate script aren't immediately available.

	:::tip
	See [`ApplyAnimationProfile()`](#ApplyAnimationProfile) for a more convenient way of overriding default roblox character animations.
	:::

	```lua
	-- In a LocalScript
	local Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsClient)

	Animations:Init()

	task.wait(5)

	print("Applying r15 ninja jump & idle animations")

	-- These animations will only work if your character is R15
	Animations:ApplyCustomRBXAnimationIds({
		[Enum.HumanoidRigType.R15] = {
			jump = 656117878,
			idle = {
				Animation1 = 656117400,
				Animation2 = 656118341
			}
		}
	})
	```
]=]
--[=[
	@method ApplyRigCustomRBXAnimationIds
	@within AnimationsClient
	@yields
	@param rig Model
	@param humanoidRigTypeToCustomRBXAnimationIds humanoidRigTypeToCustomRBXAnimationIds

	Applies the animation ids specified in the [`humanoidRigTypeToCustomRBXAnimationIds`](#humanoidRigTypeToCustomRBXAnimationIds) table on the `rig`.

	Yields when...
	- ...the `rig`'s humanoid or animate script aren't immediately available.

	:::warning
	This function only works for R6/R15 NPCs that are local to the client or network-owned by the client and have a client-side `"Animate"` script in their model.
	:::
	:::tip
	See [`ApplyRigAnimationProfile()`](#ApplyRigAnimationProfile) for a more convenient way of overriding default roblox character animations.
	:::
]=]

--[=[
	@method GetAnimationProfile
	@within AnimationsClient
	@param animationProfileName string
	@return animationProfile humanoidRigTypeToCustomRBXAnimationIds?

	Returns the [`humanoidRigTypeToCustomRBXAnimationIds`](api/AnimationsServer#humanoidRigTypeToCustomRBXAnimationIds) table found in the profile module script `Deps.<animationProfileName>`, or not if it doesn't exist.
]=]

--[=[
	@method ApplyAnimationProfile
	@within AnimationsClient
	@yields
	@param animationProfileName string

	Applies the animation ids found in the animation profile on the client's character.

	Yields when...
	- ...the client's character, humanoid, animator, or animate script aren't immediately available.

	:::note
	The client does not need to be registered or have its tracks loaded for this to work.
	:::
	:::info
	For more information on setting up animation profiles check out [animation profiles tutorial](/docs/animation-profiles).
	:::
]=]
--[=[
	@method ApplyRigAnimationProfile
	@within AnimationsClient
	@yields
	@param rig Model
	@param animationProfileName string

	Applies the animation ids found in the animation profile on the `rig`.

	Yields when...
	- ...the `rig`'s humanoid or animate script aren't immediately available.

	:::note
	The `rig` does not need to be registered or have its tracks loaded for this to work.
	:::
	:::warning
	This function only works for R6/R15 NPCs that are local to the client or network-owned by the client and have a client-side `"Animate"` script in their model.
	:::
	:::info
	For more information on setting up animation profiles check out [animation profiles tutorial](/docs/animation-profiles).
	:::
]=]

--[=[
	@method AwaitAllTracksLoaded
	@yields
	@within AnimationsClient

	Yields until the client has been registered and then until all animation tracks have loaded.

	:::caution *changed in version 2.0.0-rc1*
	Renamed: ~~`AwaitLoaded`~~ -> `AwaitAllTracksLoaded`
	:::

	```lua
	-- In a LocalScript
	-- [WARNING] For this to work you need animation ids under the rig type of "Player" in the 'AnimationIds' module
	local Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsClient)

	Animations:Init({
		AutoLoadAllPlayerTracks = true -- Defaults to false
	})

	Animations:AwaitAllTracksLoaded()

	print("Animation tracks finished loading on the client!")
	```
]=]
--[=[
	@method AwaitAllRigTracksLoaded
	@yields
	@within AnimationsClient
	@param rig Model

	Yields until the `rig` has been registered and then until all animation tracks have loaded.

	:::caution *changed in version 2.0.0-rc1*
	Renamed: ~~`AwaitRigTracksLoaded`~~ -> `AwaitAllRigTracksLoaded`
	:::
]=]

--[=[
	@method AwaitTracksLoadedAt
	@yields
	@within AnimationsClient
	@param path path

	Yields until the client has been registered and then until all animation tracks have loaded at `path`.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]
--[=[
	@method AwaitRigTracksLoadedAt
	@yields
	@within AnimationsClient
	@param rig Model
	@param path path

	Yields until the `rig` has been registered and then until all animation tracks have loaded at `path`.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]

--[=[
	@method AreAllTracksLoaded
	@within AnimationsClient
	@return boolean

	Returns if the client has had all its animation tracks loaded.

	:::caution *changed in version 2.0.0-rc1*
	Renamed: ~~`AreTracksLoaded`~~ -> `AreAllTracksLoaded`
	:::
]=]
--[=[
	@method AreAllRigTracksLoaded
	@within AnimationsClient
	@param rig Model
	@return boolean

	Returns if the `rig` has had all its animation tracks loaded.

	:::caution *changed in version 2.0.0-rc1*
	Renamed: ~~`AreRigTracksLoaded`~~ -> `AreAllRigTracksLoaded`
	:::
]=]

--[=[
	@method AreTracksLoadedAt
	@within AnimationsClient
	@param path path
	@return boolean

	Returns if the client has had its animation tracks loaded at `path`.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]
--[=[
	@method AreRigTracksLoadedAt
	@within AnimationsClient
	@param rig Model
	@param path path
	@return boolean

	Returns if the `rig` has had its animation tracks loaded at `path`.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]

--[=[
	@yields
	@method LoadAllTracks
	@within AnimationsClient

	Creates animation tracks from all animation ids in [`AnimationIds`](/api/AnimationIds) for the client.

	Yields when...
	- ...client's animator is not a descendant of `game`.

	:::caution *changed in version 2.0.0-rc1*
	Renamed: ~~`LoadTracks`~~ -> `LoadAllTracks`
	:::
]=]
--[=[
	@yields
	@method LoadAllRigTracks
	@within AnimationsClient
	@param rig Model

	Creates animation tracks from all animation ids in [`AnimationIds`](/api/AnimationIds) for the `rig`.

	Yields when...
	- ...`rig`'s animator is not a descendant of `game`.

	:::caution *changed in version 2.0.0-rc1*
	Renamed: ~~`LoadRigTracks`~~ -> `LoadAllRigTracks`

	Requires `Animations:RegisterRig()` before usage.
	:::
]=]

--[=[
	@yields
	@method LoadTracksAt
	@within AnimationsClient
	@param path path

	Creates animation tracks from all animation ids in [`AnimationIds`](/api/AnimationIds) for the client at `path`.

	Yields when...
	- ...client's animator is not a descendant of `game`.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]
--[=[
	@yields
	@method LoadRigTracksAt
	@within AnimationsClient
	@param rig Model
	@param path path

	Creates animation tracks from all animation ids in [`AnimationIds`](/api/AnimationIds) for the `rig` at `path`.

	Yields when...
	- ...`rig`'s animator is not a descendant of `game`.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]

--[=[
	@method GetTrack
	@within AnimationsClient
	@param path path
	@return AnimationTrack?

	Returns a client animation track or `nil`.
]=]
--[=[
	@method GetRigTrack
	@within AnimationsClient
	@param rig Model
	@param path path
	@return AnimationTrack?

	Returns a `rig` animation track or `nil`.
]=]

--[=[
	@method PlayTrack
	@within AnimationsClient
	@param path path
	@param fadeTime number?
	@param weight number?
	@param speed number?
	@return AnimationTrack

	Returns a playing client animation track.
]=]
--[=[
	@method PlayRigTrack
	@within AnimationsClient
	@param rig Model
	@param path path
	@param fadeTime number?
	@param weight number?
	@param speed number?
	@return AnimationTrack

	Returns a playing `rig` animation track.

	```lua
	-- `rigType` of "Spider":
	Animations:RegisterRig(rig, "Spider")
	Animations:LoadAllRigTracks(rig)
	Animations:PlayRigTrack(rig, "Crawl")

	-- or if you're doing `:RegisterRig()` and
	-- `:LoadAllTracks()` for the `rig` somewhere else:
	Animations:AwaitAllRigTracksLoaded(rig)
	Animations:PlayRigTrack(rig)
	```
]=]

--[=[
	@method StopTrack
	@within AnimationsClient
	@param path path
	@param fadeTime number?
	@return AnimationTrack

	Returns a stopped client animation track.
]=]
--[=[
	@method StopRigTrack
	@within AnimationsClient
	@param rig Model
	@param path path
	@param fadeTime number?
	@return AnimationTrack

	Returns a stopped `rig` animation track.
]=]

--[=[
	@method StopPlayingTracks
	@within AnimationsClient
	@param fadeTime number?
	@return {AnimationTrack?}

	Returns the stopped client animation tracks.

	:::caution *changed in version 2.0.0-rc1*
	Renamed: ~~`StopAllTracks`~~ -> `StopPlayingTracks`
	:::
]=]
--[=[
	@method StopRigPlayingTracks
	@within AnimationsClient
	@param rig Model
	@param fadeTime number?
	@return {AnimationTrack?}

	Returns the stopped `rig` animation tracks.

	:::caution *changed in version 2.0.0-rc1*
	Renamed: ~~`StopRigAllTracks`~~ -> `StopRigPlayingTracks`
	:::
]=]
--[=[
	@method GetPlayingTracks
	@within AnimationsClient
	@return {AnimationTrack?}

	Returns the playing client animation tracks.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]
--[=[
	@method GetRigPlayingTracks
	@within AnimationsClient
	@param rig Model
	@return {AnimationTrack?}

	Returns the playing `rig` animation tracks.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]

--[=[
	@method StopTracksOfPriority
	@within AnimationsClient
	@param animationPriority Enum.AnimationPriority
	@param fadeTime number?
	@return {AnimationTrack?}

	Returns the stopped client animation tracks.
]=]
--[=[
	@method StopRigTracksOfPriority
	@within AnimationsClient
	@param rig Model
	@param animationPriority Enum.AnimationPriority
	@param fadeTime number?
	@return {AnimationTrack?}

	Returns the stopped `rig` animation tracks.
]=]

--[=[
	@method GetTrackFromAlias
	@within AnimationsClient
	@param alias any
	@return AnimationTrack?

	Returns a client animation track or `nil`.
]=]
--[=[
	@method GetRigTrackFromAlias
	@within AnimationsClient
	@param rig Model
	@param alias any
	@return AnimationTrack?

	Returns a `rig` animation track or `nil`.
]=]

--[=[
	@method PlayTrackFromAlias
	@within AnimationsClient
	@param alias any
	@param fadeTime number?
	@param weight number?
	@param speed number?
	@return AnimationTrack

	Returns a playing client animation track.
]=]
--[=[
	@method PlayRigTrackFromAlias
	@within AnimationsClient
	@param rig Model
	@param alias any
	@param fadeTime number?
	@param weight number?
	@param speed number?
	@return AnimationTrack

	Returns a playing `rig` animation track.
]=]

--[=[
	@method StopTrackFromAlias
	@within AnimationsClient
	@param alias any
	@param fadeTime number?
	@return AnimationTrack

	Returns a stopped client animation track.
]=]
--[=[
	@method StopRigTrackFromAlias
	@within AnimationsClient
	@param rig Model
	@param alias any
	@param fadeTime number?
	@return AnimationTrack

	Returns a stopped `rig` animation track.
]=]

--[=[
	@method SetTrackAlias
	@within AnimationsClient
	@param alias any
	@param path path

	Sets an alias to be the equivalent of the path for a client animation track.

	:::tip
	You can use the alias as the last key in the path. Useful for a table of animations. Example:

	```lua
	-- In ReplicatedStorage.Animations.Deps.AnimationIds
	local animationIds = {
		Player = {
			FistsCombat = {
				-- Fists 3 hit combo
				Combo = {
					[1] = 1234567,
					[2] = 1234567,
					[3] = 1234567
				},

				-- Fists heavy attack
				HeavyAttack = 1234567
			},

			SwordCombat = {
				-- Sword 3 hit combo
				Combo = {
					[1] = 1234567,
					[2] = 1234567,
					[3] = 1234567
				},

				-- Sword heavy attack
				HeavyAttack = 1234567
			}
		}
	}
	```

	```lua
	-- In a LocalScript

	-- After the client's animation tracks are loaded...

	local heavyAttackAlias = "HeavyAttack" -- We want this alias in order to call Animations:PlayTrackFromAlias(heavyAttackAlias) regardless what weapon is equipped

	local currentEquippedWeapon

	local function updateHeavyAttackAliasPath()
		local alias = heavyAttackAlias
		local path = currentEquippedWeapon .. "Combat"

		Animations:SetTrackAlias(alias, path) -- Running this will search first "path.alias" and then search "path" if it didn't find "path.alias"
	end

	local function equipNewWeapon(weaponName)
		currentEquippedWeapon = weaponName

		updateHeavyAttackAliasPath()
	end

	equipNewWeapon("Fists")

	Animations:PlayTrackFromAlias(heavyAttackAlias) -- Plays "FistsCombat.HeavyAttack" on the client's character

	equipNewWeapon("Sword")

	Animations:PlayTrackFromAlias(heavyAttackAlias) -- Plays "SwordCombat.HeavyAttack" on the client's character
	```
	:::
]=]
--[=[
	@method SetRigTrackAlias
	@within AnimationsClient
	@param rig Model
	@param alias any
	@param path path

	Sets an alias to be the equivalent of the path for a `rig` animation track.

	:::tip
	Same tip for [`Animations:SetTrackAlias()`](#SetTrackAlias) applies here.
	:::
]=]

--[=[
	@method RemoveTrackAlias
	@within AnimationsClient
	@param alias any

	Removes the alias for a client animation track.
]=]
--[=[
	@method RemoveRigTrackAlias
	@within AnimationsClient
	@param rig Model
	@param alias any

	Removes the alias for a `rig` animation track.
]=]

--[=[
	@tag Beta
	@method AttachAnimatedObject
	@within AnimationsClient
	@param animatedObjectPath path

	Attaches the animated object to the client's character.

	:::note
	This does not replicate to the server.
	:::
	:::tip
	Enable [`initOptions.AnimatedObjectsDebugMode`](/api/AnimationsClient/#initOptions) for detailed prints about animated objects.
	:::
	:::info
	For more information on setting up animated objects check out [animated objects tutorial](/docs/animated-objects).
	:::
	:::caution
	This method is in beta testing. Use with caution.
	:::
	:::warning *changed in version 2.4.0*
	You can no longer attach animated objects of type "motor6d only" ([explanation](/changelog#v2.4.0)).
	:::
]=]
--[=[
	@tag Beta
	@method AttachRigAnimatedObject
	@within AnimationsClient
	@param rig Model
	@param animatedObjectPath path

	Attaches the animated object to the `rig`.

	:::note
	This does not replicate to the server.
	:::
	:::tip
	Enable [`initOptions.AnimatedObjectsDebugMode`](/api/AnimationsClient/#initOptions) for detailed prints about animated objects.
	:::
	:::info
	For more information on setting up animated objects check out [animated objects tutorial](/docs/animated-objects).
	:::
	:::caution
	This method is in beta testing. Use with caution.
	:::
	:::warning *changed in version 2.4.0*
	You can no longer attach animated objects of type "motor6d only" ([explanation](/changelog#v2.4.0)).
	:::
]=]

--[=[
	@tag Beta
	@method DetachAnimatedObject
	@within AnimationsClient
	@param animatedObjectPath path

	Detaches the animated object from the client's character.

	:::note
	This does not replicate to the server.
	:::
	:::tip
	Enable [`initOptions.AnimatedObjectsDebugMode`](/api/AnimationsClient/#initOptions) for detailed prints about animated objects.
	:::
	:::info
	For more information on setting up animated objects check out [animated objects tutorial](/docs/animated-objects).
	:::
	:::caution
	This method is in beta testing. Use with caution.
	:::
]=]
--[=[
	@tag Beta
	@method DetachRigAnimatedObject
	@within AnimationsClient
	@param rig Model
	@param animatedObjectPath path

	Detaches the animated object from the `rig`.

	:::note
	This does not replicate to the server.
	:::
	:::tip
	Enable [`initOptions.AnimatedObjectsDebugMode`](/api/AnimationsClient/#initOptions) for detailed prints about animated objects.
	:::
	:::info
	For more information on setting up animated objects check out [animated objects tutorial](/docs/animated-objects).
	:::
	:::caution
	This method is in beta testing. Use with caution.
	:::
]=]

return AnimationsClient :: Types.AnimationsClientType