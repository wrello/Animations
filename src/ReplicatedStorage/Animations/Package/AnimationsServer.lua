--!strict
-- made by wrello
-- GitHub: https://github.com/wrello/Animations

assert(game:GetService("RunService"):IsServer(), "Attempt to require AnimationsServer on the client")

local Players = game:GetService("Players")

local Types = require(script.Parent.Util.Types)
local AnimationsClass = require(script.Parent.Util.AnimationsClass)
local ChildFromPath = require(script.Parent.Util.ChildFromPath)

--[=[
	@interface initOptions
	@within AnimationsServer
	.AutoLoadAllPlayerTracks false
	.AutoRegisterPlayers true
	.BootstrapDepsFolder Folder?
	.TimeToLoadPrints false

	For more info, see [`Properties`](/api/AnimationsServer/#properties).
]=]
type AnimationsServerInitOptionsType = Types.AnimationsServerInitOptionsType

--[=[
	@type path {any} | string
	@within AnimationsServer
	
	These are all valid forms of paths to animation tracks you have defined in the [`AnimationIds`](/api/AnimationIds) module:

	```lua
	local path = "Jump" -- A single key (any type)

	local path = {"Dodge", Vector3.xAxis} -- An array path (values of any type)

	local path = "Climb.Right" -- A string path separated by "."

	Animations:PlayTrack(player, path)
	```
]=]

local Animations = AnimationsClass.new(script.Name)

--[=[
	@class AnimationsServer
	@server
	
	:::note
	Roblox model path: `Animations\Package\AnimationsServer`
	:::
]=]
local AnimationsServer = Animations

--[=[
	@prop AutoLoadAllPlayerTracks false
	@within AnimationsServer

	If set to true, all player animation tracks will be loaded for each player character on spawn.
]=]
AnimationsServer.AutoLoadAllPlayerTracks = false

--[=[
	@prop AutoRegisterPlayers true
	@within AnimationsServer

	If set to true, all player characters will be auto registered with [`rigType`](/api/AnimationIds#rigType) of `"Player"` when they spawn.
]=]
AnimationsServer.AutoRegisterPlayers = true

--[=[
	@prop BootstrapDepsFolder Folder?
	@within AnimationsServer

	Set to the dependencies folder if you have moved it from its original location inside of the root `Animations` folder.
]=]
AnimationsServer.BootstrapDepsFolder = nil

--[=[
	@prop TimeToLoadPrints true
	@within AnimationsServer

	If set to true, makes helpful prints about the time it takes to pre-load and load animations.
]=]
AnimationsServer.TimeToLoadPrints = true

--[=[
	@yields
	@param initOptions initOptions?

	Initializes `AnimationsServer`. Clients are unable to initialize until this gets called.
	
	Yields when...
	- ...animations are being pre-loaded with `ContentProvider:PreloadAsync()` (could take a while).

	:::warning important
	Must be called once before any other method.
	:::
]=]
function AnimationsServer:Init(initOptions: AnimationsServerInitOptionsType?)
	if self._initialized then
		warn("AnimationsServer:Init() only needs to be called once")
		return
	end
	
	local function bootstrapDepsFolder()
		local depsFolder
		
		if self.BootstrapDepsFolder then
			depsFolder = self.BootstrapDepsFolder
		else
			depsFolder = script.Parent.Parent.Deps
		end

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
				if self.AutoRegisterPlayers then
					self:Register(player, "Player")
				end

				if self.AutoLoadAllPlayerTracks then
					self:LoadAllTracks(player)
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
	@method GetTrackStartSpeed
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param path path
	@return number?

	If set with [`HasProperties`](/api/AnimationIds#HasProperties), returns the animation track's `StartSpeed`.
]=]

--[=[
	@method GetTimeOfMarker
	@within AnimationsServer
	@param animTrack_or_IdString AnimationTrack | string
	@param markerName string
	@return number?

	This method can yield if the
	initialization process that caches all of the marker
	times is still going on when this method is called. If
	after 3 seconds the initialization process has still not
	finished, this method will return `nil`.

	:::warning
	This method only works on animations which you give
	the [`MarkerTimes`](api/AnimationIds#propertiesSettings) property to.
	:::

	```lua
	local attackAnim = Animations:PlayTrack("Attack")
	local timeOfHitStart = Animations:GetTimeOfMarker(attackAnim, "HitStart")

	print("Time of hit start:", timeOfHitStart)

	-- or

	local animIdStr = Animations:GetAnimationIdString("Player", "Attack")
	local timeOfHitStart = Animations:GetTimeOfMarker(animIdStr, "HitStart")

	print("Time of hit start:", timeOfHitStart)
	```
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

	:::warning
	For this to work, `rig` needs to be registered.
	:::

	```lua
	local isBlocking = Animations:FindFirstRigPlayingTrack(rig, "Blocking")

	if isBlocking then
		warn("We can't hit the enemy, they're blocking!")
	end
	```
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

	:::warning
	For this to work, `rig` needs to be registered.
	:::

	```lua
	local isBlocking = Animations:WaitForRigPlayingTrack(rig, "Blocking", 1)

	if isBlocking then
		warn("We can't hit the enemy, they're blocking!")
	end
	```
]=]

--[=[
	@method GetAppliedProfileName
	@within AnimationsServer
	@param player_or_rig Player | Model
	@return string?

	Returns the `player_or_rig`'s currently applied animation profile name or `nil`.
]=]

--[=[
	@method AwaitPreloadAsyncFinished
	@yields
	@within AnimationsServer
	@return {Animation?}

	Yields until `ContentProvider:PreloadAsync()` finishes pre-loading all animation instances.

	```lua
	local loadedAnimInstances = Animations:AwaitPreloadAsyncFinished()
		
	print("ContentProvider:PreloadAsync() finished pre-loading all animations:", loadedAnimInstances)
	```
]=]
--[=[
	@prop PreloadAsyncProgressed RBXScriptSignal
	@within AnimationsServer

	Fires when `ContentProvider:PreloadAsync()` finishes pre-loading one animation instance.

	```lua
	Animations.PreloadAsyncProgressed:Connect(function(n, total, loadedAnimInstance)
		print("ContentProvider:PreloadAsync() finished pre-loading one animation:", n, total, loadedAnimInstance)
	end)
	```
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
	
	:::note
	The `"walk"` animation is used for both walking and running on `R6` characters.
	:::
]=]

--[=[
	@interface humanoidRigTypeToCustomRBXAnimationIds
	@within AnimationsServer
	.[Enum.HumanoidRigType.R6] customRBXAnimationIds?
	.[Enum.HumanoidRigType.R15] customRBXAnimationIds?
	
	A table mapping a `Enum.HumanoidRigType` to its supported animation ids that will replace the default roblox animation ids.
]=]

--[=[
	@method Register
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param rigType string

	Registers the `player_or_rig` so that methods using animation tracks can be called.

	:::tip
	Automatically calls `rig:SetAttribute("AnimationsRigType", rigType)` which is useful for determining rig types.
	:::
]=]

--[=[
	@method AwaitRegistered
	@yields
	@within AnimationsServer
	@param player_or_rig Player | Model

	Yields until the `player_or_rig` gets registered.
]=]

--[=[
	@method IsRegistered
	@within AnimationsServer
	@param player_or_rig Player | Model
	@return boolean

	Returns `true` if the `player_or_rig` is registered.
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
	This function only works for players and `R6`/`R15` NPCs that have an `"Animate"` script in their model.
	:::

	```lua
	Animations:ApplyCustomRBXAnimationIds(player, {
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
	
	Returns the [`humanoidRigTypeToCustomRBXAnimationIds`](#humanoidRigTypeToCustomRBXAnimationIds) table from the animation profile module or `nil`.

	:::info
	For more info, see [animation profiles](/docs/animation-profiles).
	:::
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

	:::warning
	This function only works for players and `R6`/`R15` NPCs that have an `"Animate"` script in their model.
	:::
	:::info
	For more info, see [animation profiles](/docs/animation-profiles).
	:::
]=]

--[=[
	@method AwaitAllTracksLoaded
	@yields
	@within AnimationsServer
	@param player_or_rig Player | Model

	Yields until all the `player_or_rig`'s animation tracks have loaded.
]=]
--[=[
	@method AwaitTracksLoadedAt
	@yields
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param path path

	Yields until the `player_or_rig`'s animation tracks have loaded at `path`.
]=]

--[=[
	@method AreAllTracksLoaded
	@within AnimationsServer
	@param player_or_rig Player | Model
	@return boolean
	
	Returns `true` if the `player_or_rig` has had all its animation tracks loaded.
]=]
--[=[
	@method AreTracksLoadedAt
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param path path
	@return boolean
	
	Returns `true` if the `player_or_rig` has had its animation tracks loaded at `path`.
]=]

--[=[
	@yields
	@method LoadAllTracks
	@within AnimationsServer
	@param player_or_rig Player | Model
	
	Creates animation tracks from all animation ids in [`AnimationIds`](/api/AnimationIds) for the `player_or_rig`.

	Yields when...
	- ...`player_or_rig`'s animator is not a descendant of `game`.
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
	local AnimationIds = {
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

	return AnimationIds
	```

	```lua
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
	@method AttachWithMotor6d
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param model Model | Tool
	@param motor6dToClone Motor6D?

	Attaches the `model` to the `player_or_rig` using the `motor6dToClone` or the first `motor6d` found as a child of the `model` in order to animate it.

	In either case, the `motor6d` used must have the following attributes set:
	- `"Part0Name"` - the name of the `Part0` of the `motor6d` during the animation.
	- `"Part1Name"` - the name of the `Part1` of the `motor6d` during the animation.
]=]

--[=[
	@method SetRightGripWeldEnabled
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param isEnabled boolean

	Enables/disables the `RightGrip` weld that is automatically added to a character's right hand when a tool is equipped.
]=]

--[=[
	@method FindRightGripWeld
	@within AnimationsServer
	@param player_or_rig Player | Model
	@return Weld?

	Returns the `RightGrip` weld that is automatically added to a character's right hand when a tool is equipped or `nil`.
]=]

--[=[
	@yields
	@method WaitForRightGripWeld
	@param player_or_rig Player | Model
	@within AnimationsServer
	@return Weld

	Yields until the `RightGrip` weld that is automatically added to a character's right hand when a tool is equipped is found and then returns it.
]=]

return AnimationsServer :: Types.AnimationsServerType