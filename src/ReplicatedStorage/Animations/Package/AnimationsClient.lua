--!strict
-- made by wrello

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
	.AutoRegisterPlayer true
	.AutoLoadAllPlayerTracks false
	.TimeToLoadPrints true
	.EnableAutoCustomRBXAnimationIds false
	.AnimatedObjectsDebugMode false

	Gets applied to [`Properties`](/api/AnimationsClient/#properties).
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
	@prop DepsFolderPath nil
	@within AnimationsClient

	Set the path to the dependencies folder if you have moved it from its original location inside of the root `Animations` folder.

	:::tip *added in version 2.0.0*
	:::
]=]
AnimationsClient.DepsFolderPath = nil

--[=[
	@prop AutoRegisterPlayer true
	@within AnimationsClient

	If set to true, the client will automatically be registered on spawn. See [`Animations:Register()`](/api/AnimationsClient/#Register) for more info.

	:::warning
	Must have animation ids under [`rigType`](/api/AnimationIds#rigType) of **"Player"** in the [`AnimationIds`](/api/AnimationIds) module.
	:::

	:::tip *added in version 2.0.0*
	:::
]=]
AnimationsClient.AutoRegisterPlayer = true

--[=[
	@prop AutoLoadAllPlayerTracks false
	@within AnimationsClient

	If set to true, client animation tracks will be loaded each time the client spawns.

	:::warning
	Must have animation ids under [`rigType`](/api/AnimationIds#rigType) of **"Player"** in the [`AnimationIds`](/api/AnimationIds) module.
	:::

	:::caution *changed in version 2.0.0*
	Renamed: ~~`AutoLoadPlayerTracks`~~ -> `AutoLoadAllPlayerTracks`

	Will automatically register client as well if [`AutoRegisterPlayer`](/api/AnimationsClient/#AutoRegisterPlayer) is not already set to true.
	:::
]=]
AnimationsClient.AutoLoadAllPlayerTracks = false

--[=[
	@prop TimeToLoadPrints true
	@within AnimationsClient

	If set to true, makes helpful prints about the time it takes to pre-load and load animations.
]=]
AnimationsClient.TimeToLoadPrints = true

--[=[
	@prop EnableAutoCustomRBXAnimationIds false
	@within AnimationsClient

	If set to true, applies the [`AutoCustomRBXAnimationIds`](/api/AutoCustomRBXAnimationIds) module table to the client on spawn.

	:::tip *added in version 2.0.0*
	:::
]=]
AnimationsClient.EnableAutoCustomRBXAnimationIds = false

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

		if self.DepsFolderPath then
			local ok
			ok, depsFolder = pcall(ChildFromPath, game, self.DepsFolderPath)
			assert(ok and depsFolder, "No animation deps folder found at path '" .. self.DepsFolderPath .. "'")
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

		for k: string, v in pairs(AnimationsClass) do
			if type(v) == "function" and not k:match("^_") then
				local clientMethodName = k

				if clientMethodName ~= "GetAnimationProfile" then
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

		print("finished")
	end

	local function initOnPlayerSpawn()
		local function onCharacterAdded(char)
			if self.AutoRegisterPlayer then
				self:Register("Player")
			end

			if self.AutoLoadAllPlayerTracks then
				self:Register("Player")
				self:LoadAllTracks()
			end

			if self.EnableAutoCustomRBXAnimationIds then
				self:ApplyCustomRBXAnimationIds(player, AutoCustomRBXAnimationIds)
			end
		end

		onCharacterAdded(player.Character or player.CharacterAdded:Wait())
		player.CharacterAdded:Connect(onCharacterAdded)
	end

	local function initCustomRBXAnimationIdsSignal()
		local function applyCustomRBXAnimationIds(animator, animateScript, humRigTypeCustomRBXAnimationIds)
			if humRigTypeCustomRBXAnimationIds then
				self:_editAnimateScriptValues(animator, animateScript, humRigTypeCustomRBXAnimationIds)
			end

			RunService.Stepped:Wait() -- Without a task.wait() or a RunService.Stepped:Wait(), the running animation bugs if they are moving when this function is called.

			local char = player.Character
			local hum = char:FindFirstChild("Humanoid")

			if hum then
				hum:ChangeState(Enum.HumanoidStateType.Landed) -- Hack to force apply the new animations.
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

	:::tip
	Automatically gives the `rig` (the client's character) an attribute `"AnimationsRigType"` set to the [`rigType`](/api/AnimationIds#rigType) (which is "Player" in this case).
	:::

	:::tip *added in version 2.0.0*
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

	:::tip *added in version 2.0.0*
	:::
]=]

--[=[
	@method AwaitRegistered
	@yields
	@within AnimationsClient

	Yields until the client gets registered.

	:::tip *added in version 2.0.0*
	:::
]=]
--[=[
	@method AwaitRigRegistered
	@yields
	@within AnimationsClient
	@param rig Model

	Yields until the `rig` gets registered.

	:::tip *added in version 2.0.0*
	:::
]=]

--[=[
	@method IsRegistered
	@within AnimationsClient
	@return boolean

	Returns if the client is registered.

	:::tip *added in version 2.0.0*
	:::
]=]
--[=[
	@method IsRigRegistered
	@within AnimationsClient
	@param rig Model
	@return boolean

	Returns if the `rig` is registered.

	:::tip *added in version 2.0.0*
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

	:::caution *changed in version 2.0.0*
	Renamed: ~~`AwaitLoaded`~~ -> `AwaitAllTracksLoaded`
	:::

	```lua
	-- In a LocalScript
	-- [WARNING] For this to work you need animation ids under the rig type of "Player" in the 'AnimationIds' module
	local Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsClient)

	Animations:Init({
		AutoRegisterPlayer = true, -- Defaults to true (on the client)
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

	:::caution *changed in version 2.0.0*
	Renamed: ~~`AwaitRigTracksLoaded`~~ -> `AwaitAllRigTracksLoaded`
	:::
]=]

--[=[
	@method AwaitTracksLoadedAt
	@yields
	@within AnimationsClient
	@param path path

	Yields until the client has been registered and then until all animation tracks have loaded at `path`.

	:::tip *added in version 2.0.0*
	:::
]=]
--[=[
	@method AwaitRigTracksLoadedAt
	@yields
	@within AnimationsClient
	@param rig Model
	@param path path

	Yields until the `rig` has been registered and then until all animation tracks have loaded at `path`.

	:::tip *added in version 2.0.0*
	:::
]=]

--[=[
	@method AreAllTracksLoaded
	@within AnimationsClient
	@return boolean

	Returns if the client has had all its animation tracks loaded.

	:::caution *changed in version 2.0.0*
	Renamed: ~~`AreTracksLoaded`~~ -> `AreAllTracksLoaded`
	:::
]=]
--[=[
	@method AreAllRigTracksLoaded
	@within AnimationsClient
	@param rig Model
	@return boolean

	Returns if the `rig` has had all its animation tracks loaded.

	:::caution *changed in version 2.0.0*
	Renamed: ~~`AreRigTracksLoaded`~~ -> `AreAllRigTracksLoaded`
	:::
]=]

--[=[
	@method AreTracksLoadedAt
	@within AnimationsClient
	@param path path
	@return boolean

	Returns if the client has had its animation tracks loaded at `path`.

	:::tip *added in version 2.0.0*
	:::
]=]
--[=[
	@method AreRigTracksLoadedAt
	@within AnimationsClient
	@param rig Model
	@param path path
	@return boolean

	Returns if the `rig` has had its animation tracks loaded at `path`.

	:::tip *added in version 2.0.0*
	:::
]=]

--[=[
	@method LoadAllTracks
	@within AnimationsClient

	Creates animation tracks from all animation ids in [`AnimationIds`](/api/AnimationIds) for the client.

	:::caution *changed in version 2.0.0*
	Renamed: ~~`LoadTracks`~~ -> `LoadAllTracks`

	Now requires `Animations:Register()` before usage unless [`Animations.AutoRegisterPlayer`](/api/AnimationsClient/#AutoRegisterPlayer) is enabled.
	:::
]=]
--[=[
	@method LoadAllRigTracks
	@within AnimationsClient
	@param rig Model

	Creates animation tracks from all animation ids in [`AnimationIds`](/api/AnimationIds) for the `rig`.

	:::caution *changed in version 2.0.0*
	Renamed: ~~`LoadRigTracks`~~ -> `LoadAllRigTracks`

	Now requires `Animations:RegisterRig()` before usage.
	:::
]=]

--[=[
	@method LoadTracksAt
	@within AnimationsClient
	@param path path

	Creates animation tracks from all animation ids in [`AnimationIds`](/api/AnimationIds) for the client at `path`.

	:::tip *added in version 2.0.0*
	:::
]=]
--[=[
	@method LoadRigTracksAt
	@within AnimationsClient
	@param rig Model
	@param path path

	Creates animation tracks from all animation ids in [`AnimationIds`](/api/AnimationIds) for the `rig` at `path`.

	:::tip *added in version 2.0.0*
	:::
]=]

--[=[
	@method GetTrack
	@within AnimationsClient
	@param path path
	@return AnimationTrack?

	Returns a client animation track or nil.
]=]
--[=[
	@method GetRigTrack
	@within AnimationsClient
	@param rig Model
	@param path path
	@return AnimationTrack?

	Returns a `rig` animation track or nil.
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

	:::caution *changed in version 2.0.0*
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

	:::caution *changed in version 2.0.0*
	Renamed: ~~`StopRigAllTracks`~~ -> `StopRigPlayingTracks`
	:::
]=]
--[=[
	@method GetPlayingTracks
	@within AnimationsClient
	@return {AnimationTrack?}

	Returns the playing client animation tracks.

	:::tip *added in version 2.0.0*
	:::
]=]
--[=[
	@method GetRigPlayingTracks
	@within AnimationsClient
	@param rig Model
	@return {AnimationTrack?}

	Returns the playing `rig` animation tracks.

	:::tip *added in version 2.0.0*
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

	Returns a client animation track or nil.
]=]
--[=[
	@method GetRigTrackFromAlias
	@within AnimationsClient
	@param rig Model
	@param alias any
	@return AnimationTrack?

	Returns a `rig` animation track or nil.
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
]=]

return AnimationsClient :: Types.AnimationsClientType