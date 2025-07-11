--!strict
-- made by wrello
-- GitHub: https://github.com/wrello/Animations

assert(game:GetService("RunService"):IsServer(), "Attempt to require AnimationsServer on the client")

local Players = game:GetService("Players")

local Types = require(script.Parent.Util.Types)
local AnimationsClass = require(script.Parent.Util.AnimationsClass)
local ChildFromPath = require(script.Parent.Util.ChildFromPath)

local AutoCustomRBXAnimationIds = nil

--[=[
	@interface initOptions
	@within AnimationsServer
	.AutoLoadAllPlayerTracks false
	.TimeToLoadPrints false
	.EnableAutoCustomRBXAnimationIds false
	.AnimatedObjectsDebugMode false
	.DepsFolderPath string? -- Only use if you've moved the 'Deps' folder from its original location.

	Gets applied to [`Properties`](#properties).
]=]
type AnimationsServerInitOptionsType = Types.AnimationsServerInitOptionsType

--[=[
	@type path {any} | string
	@within AnimationsServer
	
	```lua
	-- In a ServerScript
	local Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsServer)
	
	
	-- These are all valid options for retrieving an animation track
	local animationPath = "Jump" -- A single key (any type)
	
	local animationPath = {"Dodge", Vector3.xAxis} -- An array path (values of any type)

	local animationPath = "Climb.Right" -- A path seperated by "." (string)


	local animationTrack = Animations:GetTrack(player, animationPath)
	```
]=]

local Animations = AnimationsClass.new(script.Name)

--[=[
	@class AnimationsServer
	@server
	
	:::note
	Roblox model path: `Animations.Package.AnimationsServer`
	:::
]=]
local AnimationsServer = Animations

--[=[
	@prop DepsFolderPath nil
	@within AnimationsServer

	Set the path to the dependencies folder if you have moved it from its original location inside of the root `Animations` folder.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]
AnimationsServer.DepsFolderPath = nil

--[=[
	@prop AutoLoadAllPlayerTracks false
	@within AnimationsServer

	If set to true, all player animation tracks will be loaded for each player character on spawn.
	
	:::warning
	Must have animation ids under [`rigType`](/api/AnimationIds#rigType) of **"Player"** in the [`AnimationIds`](/api/AnimationIds) module.
	:::

	:::caution *changed in version 2.0.0-rc1*
	Renamed: ~~`AutoLoadPlayerTracks`~~ -> `AutoLoadAllPlayerTracks`
	:::
]=]
AnimationsServer.AutoLoadAllPlayerTracks = false

--[=[
	@prop TimeToLoadPrints true
	@within AnimationsServer

	If set to true, makes helpful prints about the time it takes to pre-load and load animations.

	:::caution *changed in version 2.0.0-rc1*
	Defaults to `true`.
	:::
]=]
AnimationsServer.TimeToLoadPrints = true

--[=[
	@prop EnableAutoCustomRBXAnimationIds false
	@within AnimationsServer

	If set to true, applies the [`AutoCustomRBXAnimationIds`](/api/AutoCustomRBXAnimationIds) module table to each player character on spawn.
]=]
AnimationsServer.EnableAutoCustomRBXAnimationIds = false

--[=[
	@prop AnimatedObjectsDebugMode false
	@within AnimationsServer

	If set to true, prints will be made to help debug attaching and detaching animated objects.
]=]
AnimationsServer.AnimatedObjectsDebugMode = false

--[=[
	@yields
	@param initOptions initOptions?

	Initializes `AnimationsServer`. Clients are unable to initialize until this gets called.
	
	Yields when...
	- ...animations are being pre-loaded with `ContentProvider:PreloadAsync()` (could take a while).

	:::info
	Should be called once before any other method.
	:::
]=]
function AnimationsServer:Init(initOptions: AnimationsServerInitOptionsType?)
	if self._initialized then
		warn("AnimationsServer:Init() only needs to be called once")
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

	local function initInitOptions()
		if initOptions then
			for k, v in pairs(initOptions) do
				self[k] = v
			end
		end
	end
	
	local function initCustomRBXAnimationIdsSignal()
		local applyCustomRBXAnimationIdsRE = Instance.new("RemoteEvent")
		applyCustomRBXAnimationIdsRE.Name = "ApplyCustomRBXAnimationIds"
		applyCustomRBXAnimationIdsRE.Parent = script.Parent
		
		self.ApplyCustomRBXAnimationIdsSignal = applyCustomRBXAnimationIdsRE
	end

	local function initOnPlayerSpawn()
		local function onPlayerAdded(player)
			local function onCharacterAdded(char)
				self:Register(player, "Player")

				if self.AutoLoadAllPlayerTracks then
					self:LoadAllTracks(player)
				end

				if self.EnableAutoCustomRBXAnimationIds then
					self:ApplyCustomRBXAnimationIds(player, AutoCustomRBXAnimationIds)
				end
			end

			if player.Character then
				onCharacterAdded(player.Character)
			end

			player.CharacterAdded:Connect(onCharacterAdded)
		end
		
		for _, player in pairs(Players:GetPlayers()) do
			task.spawn(onPlayerAdded, player)
		end

		Players.PlayerAdded:Connect(onPlayerAdded)
	end
	
	initInitOptions()
	bootstrapDepsFolder()
	initCustomRBXAnimationIdsSignal()
	script:SetAttribute("InitializedForClients", true) -- Set initialized for clients to be able to initialize
	self:_animationIdsToInstances()
	self._initialized = true -- Need to initialize before using methods in the function below
	initOnPlayerSpawn()
end

--[=[
	@tag Beta

	Equips the `tool` for the `player_or_rig` and then attaches the `motor6d` found in the `AnimatedObjects` folder to it.

	:::caution
	This method is in beta testing. Use with caution.
	:::
	:::tip *added in version 2.4.0*
	:::
]=]
function AnimationsServer:EquipAnimatedTool(player_or_rig: Player | Model, toolToEquip: Tool, motor6dName: Motor6D)
	self:_initializedAssertion()

	self:_attachDetachAnimatedObject("attach", player_or_rig, motor6dName, nil, toolToEquip)
end

--[=[
	@method GetTrackStartSpeed
	@within AnimationsServer
	@param player_or_rig Player | Model
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
	@within AnimationsServer
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
	@within AnimationsServer
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
	@within AnimationsServer 
	@param rig Model
	@param path path
	@return AnimationTrack?

	Returns a playing animation track found in
	`rig.Humanoid.Animator:GetPlayingAnimationTracks()`
	matching the animation id found at `path` in the
	[`AnimationIds`](/api/AnimationIds) module or `nil`.

	```lua
	-- [WARNING] For this to work, `enemyCharacter` would have to be registered (on the server) and "Blocking" would need to be a valid animation name defined in the `AnimationIds` module.
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
	@within AnimationsServer
	@param rig Model
	@param path path
	@param timeout number?
	@return AnimationTrack?

	Yields until a playing animation track is found in
	`rig.Humanoid.Animator:GetPlayingAnimationTracks()`
	matching the animation id found at `path` in the
	[`AnimationIds`](/api/AnimationIds) module then returns it or returns `nil` after
	`timeout` seconds if provided.

	:::tip
	Especially useful on the client if the animation needs time to replicate from server to client and you want to specify a maximum time to wait until it replicates.
	:::

	:::tip *added in version 2.1.0*
	:::
]=]

--[=[
	@method GetAppliedProfileName
	@within AnimationsServer
	@param player_or_rig Player | Model
	@return string?

	Returns the `player_or_rig`'s currently applied animation profile name or `nil`.

	:::tip *added in version 2.0.0*
	:::
]=]

--[=[
	@method AwaitPreloadAsyncFinished
	@yields
	@within AnimationsServer
	@return {Animation?}

	Yields until `ContentProvider:PreloadAsync()` finishes pre-loading all animation instances.

	```lua
	-- In a ServerScript
	local loadedAnimInstances = Animations:AwaitPreloadAsyncFinished()
		
	print("ContentProvider:PreloadAsync() finished pre-loading all:", loadedAnimInstances)
	```

	:::tip *added in version 2.0.0-rc1*
	:::
]=]
--[=[
	@prop PreloadAsyncProgressed RBXScriptSignal
	@within AnimationsServer

	Fires when `ContentProvider:PreloadAsync()` finishes pre-loading one animation instance.

	```lua
	-- In a ServerScript
	Animations.PreloadAsyncProgressed:Connect(function(n, total, loadedAnimInstance)
		print("ContentProvider:PreloadAsync() finished pre-loading one:", n, total, loadedAnimInstance)
	end)
	```

	:::tip *added in version 2.0.0-rc1*
	:::
]=]

--[=[
	@interface customRBXAnimationIds
	@within AnimationsServer
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
	@within AnimationsServer
	.[Enum.HumanoidRigType.R6] customRBXAnimationIds?
	.[Enum.HumanoidRigType.R15] customRBXAnimationIds?
	
	A table mapping a humanoid rig type to its supported animation ids that will replace the default roblox animation ids.
]=]

--[=[
	@method Register
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param rigType string

	Registers the player's character/rig so that methods using animation tracks can be called.

	:::note
	All player characters get automatically registered through `player.CharacterAdded` events.
	:::

	:::tip
	Automatically gives the character/rig an attribute `"AnimationsRigType"` set to the [`rigType`](/api/AnimationIds#rigType).
	:::

	:::tip *added in version 2.0.0-rc1*
	:::
]=]

--[=[
	@method AwaitRegistered
	@yields
	@within AnimationsServer
	@param player_or_rig Player | Model

	Yields until the `player_or_rig` gets registered.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]

--[=[
	@method IsRegistered
	@within AnimationsServer
	@param player_or_rig Player | Model
	@return boolean

	Returns if the `player_or_rig` is registered.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]

--[=[
	@method ApplyCustomRBXAnimationIds
	@within AnimationsServer
	@yields
	@param player_or_rig Player | Model
	@param humanoidRigTypeToCustomRBXAnimationIds humanoidRigTypeToCustomRBXAnimationIds

	Applies the animation ids specified in the [`humanoidRigTypeToCustomRBXAnimationIds`](#humanoidRigTypeToCustomRBXAnimationIds) table on the `player_or_rig`.

	Yields when...
	- ...the player's character, player or rig's humanoid, player's animator, or player or rig's animate script aren't immediately available.

	:::warning
	This function only works for players and R6/R15 NPCs that have an `"Animate"` script in their model.
	:::
	:::tip
	See [`ApplyAnimationProfile()`](#ApplyAnimationProfile) for a more convenient way of overriding default roblox character animations.
	:::

	```lua
	-- In a ServerScript
	local Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsServer)

	Animations:Init()

	task.wait(5)

	print("Applying r15 ninja jump & idle animations")

	-- These animations will only work if your character is R15
	Animations:ApplyCustomRBXAnimationIds(game.Players.YourName, {
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
	@method GetAnimationProfile
	@within AnimationsServer
	@param animationProfileName string
	@return animationProfile humanoidRigTypeToCustomRBXAnimationIds?
	
	Returns the [`humanoidRigTypeToCustomRBXAnimationIds`](api/AnimationsServer#humanoidRigTypeToCustomRBXAnimationIds) table found in the profile module `Deps.<animationProfileName>`, or not if it doesn't exist.
]=]
--[=[
	@method ApplyAnimationProfile
	@within AnimationsServer
	@yields
	@param player_or_rig Player | Model
	@param animationProfileName string
	
	Applies the animation ids found in the animation profile on the `player_or_rig`.
	
	Yields when...
	- ...the player's character, player or rig's humanoid, player's animator, or player or rig's animate script aren't immediately available.

	:::note
	The `player_or_rig` does not need to be registered or have its tracks loaded for this to work.
	:::
	:::warning
	This function only works for players and R6/R15 NPCs that have an `"Animate"` script in their model.
	:::
	:::info
	For more information on setting up animated objects check out [animation profiles tutorial](/docs/animation-profiles).
	:::
]=]

--[=[
	@method AwaitAllTracksLoaded
	@yields
	@within AnimationsServer
	@param player_or_rig Player | Model

	Yields until all the `player_or_rig`'s animation tracks have loaded.

	:::caution *changed in version 2.0.0-rc1*
	Renamed: ~~`AwaitLoaded`~~ -> `AwaitAllTracksLoaded`
	:::

	```lua
	-- In a ServerScript
	-- [WARNING] For this to work you need animation ids under the rig type of "Player" in the 'AnimationIds' module
	local Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsServer)

	Animations:Init({
		AutoLoadAllPlayerTracks = true -- Defaults to false
	})

	local player = game.Players:WaitForChild("MyName")

	Animations:AwaitAllTracksLoaded(player)

	print("Animation tracks finished loading on the server!")
	```
]=]
--[=[
	@method AwaitTracksLoadedAt
	@yields
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param path path

	Yields until the `player_or_rig`'s animation tracks have loaded at `path`.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]

--[=[
	@method AreAllTracksLoaded
	@within AnimationsServer
	@param player_or_rig Player | Model
	@return boolean
	
	Returns if the `player_or_rig` has had all its animation tracks loaded.

	:::caution *changed in version 2.0.0-rc1*
	Renamed: ~~`AreTracksLoaded`~~ -> `AreAllTracksLoaded`
	:::
]=]
--[=[
	@method AreTracksLoadedAt
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param path path
	@return boolean
	
	Returns if the `player_or_rig` has had its animation tracks loaded at `path`.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]

--[=[
	@yields
	@method LoadAllTracks
	@within AnimationsServer
	@param player_or_rig Player | Model
	
	Creates animation tracks from all animation ids in [`AnimationIds`](/api/AnimationIds) for the `player_or_rig`.

	Yields when...
	- ...`player_or_rig`'s animator is not a descendant of `game`.

	:::caution *changed in version 2.0.0-rc1*
	Renamed: ~~`LoadTracks`~~ -> `LoadAllTracks`

	If `player_or_rig` is a rig, this requires `Animations:Register()` before usage.
	:::
]=]
--[=[
	@yields
	@method LoadTracksAt
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param path path
	
	Creates animation tracks from animation ids in [`AnimationIds`](/api/AnimationIds) for the `player_or_rig` at `path`.

	Yields when...
	- ...`player_or_rig`'s animator is not a descendant of `game`.

	:::tip *added in version 2.0.0-rc1*
	:::
]=]

--[=[
	@method GetTrack
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param path path
	@return AnimationTrack?
	
	Returns a `player_or_rig`'s animation track or `nil`.
]=]

--[=[
	@method PlayTrack
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param path path
	@param fadeTime number?
	@param weight number?
	@param speed number?
	@return AnimationTrack

	Returns a playing `player_or_rig`'s animation track.
]=]

--[=[
	@method StopTrack
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param path path
	@param fadeTime number?
	@return AnimationTrack

	Returns a stopped `player_or_rig`'s animation track.
]=]

--[=[
	@method StopPlayingTracks
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param fadeTime number?
	@return {AnimationTrack?}

	Returns the stopped `player_or_rig` animation tracks.

	:::caution *changed in version 2.0.0-rc1*
	Renamed: ~~`StopAllTracks`~~ -> `StopPlayingTracks`
	:::
]=]

--[=[
	@method GetPlayingTracks
	@within AnimationsServer
	@param player_or_rig Player | Model
	@return {AnimationTrack?}

	Returns playing `player_or_rig` animation tracks.
]=]

--[=[
	@method StopTracksOfPriority
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param animationPriority Enum.AnimationPriority
	@param fadeTime number?
	@return {AnimationTrack?}

	Returns the stopped `player_or_rig` animation tracks.
]=]

--[=[
	@method GetTrackFromAlias
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param alias any
	@return AnimationTrack?

	Returns a `player_or_rig`'s animation track or `nil`.
]=]

--[=[
	@method PlayTrackFromAlias
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param alias any
	@param fadeTime number?
	@param weight number?
	@param speed number?
	@return AnimationTrack

	Returns a playing `player_or_rig`'s animation track.
]=]

--[=[
	@method StopTrackFromAlias
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param alias any
	@param fadeTime number?
	@return AnimationTrack

	Returns a stopped `player_or_rig`'s animation track.
]=]

--[=[
	@method SetTrackAlias
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param alias any
	@param path path

	Sets an alias to be the equivalent of the path for a `player_or_rig`'s animation track.

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
	-- In a ServerScript
	local player = game.Players.wrello

	-- After the player's animation tracks are loaded...

	local heavyAttackAlias = "HeavyAttack" -- We want this alias in order to call Animations:PlayTrackFromAlias(player, heavyAttackAlias) regardless what weapon is equipped

	local currentEquippedWeapon
	
	local function updateHeavyAttackAliasPath()
		local alias = heavyAttackAlias
		local path = currentEquippedWeapon .. "Combat"

		Animations:SetTrackAlias(player, alias, path) -- Running this will search first "path.alias" and then search "path" if it didn't find "path.alias"
	end

	local function equipNewWeapon(weaponName)
		currentEquippedWeapon = weaponName

		updateHeavyAttackAliasPath()
	end

	equipNewWeapon("Fists")

	Animations:PlayTrackFromAlias(player, heavyAttackAlias) -- Plays "FistsCombat.HeavyAttack" on the player's character

	equipNewWeapon("Sword")

	Animations:PlayTrackFromAlias(player, heavyAttackAlias) -- Plays "SwordCombat.HeavyAttack" on the player's character
	```
	:::
]=]

--[=[
	@method RemoveTrackAlias
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param alias any

	Removes the alias for a `player_or_rig`'s animation track.
]=]

--[=[
	@tag Beta
	@method AttachAnimatedObject
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param animatedObjectPath path

	Attaches the animated object to the `player_or_rig`.

	:::tip
	Enable [`initOptions.AnimatedObjectsDebugMode`](/api/AnimationsServer/#initOptions) for detailed prints about animated objects.
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
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param animatedObjectPath path

	Detaches the animated object from the `player_or_rig`.

	:::tip
	Enable [`initOptions.AnimatedObjectsDebugMode`](/api/AnimationsServer/#initOptions) for detailed prints about animated objects.
	:::
	:::info
	For more information on setting up animated objects check out [animated objects tutorial](/docs/animated-objects).
	:::
	:::caution
	This method is in beta testing. Use with caution.
	:::
]=]

return AnimationsServer :: Types.AnimationsServerType