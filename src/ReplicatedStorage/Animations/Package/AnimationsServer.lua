--!strict
-- made by wrello

assert(game:GetService("RunService"):IsServer(), "Attempt to require AnimationsServer on the client")

local Players = game:GetService("Players")

local Types = require(script.Parent.Util.Types)
local AutoCustomRBXAnimationIds = require(script.Parent.Parent.Deps.AutoCustomRBXAnimationIds)
local AnimationsClass = require(script.Parent.Util.AnimationsClass)
local CustomAssert = require(script.Parent.Util.CustomAssert)

--[=[
	@interface initOptions
	@within AnimationsServer
	.AutoLoadPlayerTracks false
	.TimeToLoadPrints false
	.EnableAutoCustomRBXAnimationIds false
	.AnimatedObjectsDebugMode false

	Gets applied to [`Properties`](#properties).
]=]
type AnimationsServerInitOptionsType = Types.AnimationsServerInitOptionsType

--[=[
	@type path {any} | string
	@within AnimationsServer
	
	```lua
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
	@prop AutoLoadPlayerTracks false
	@within AnimationsServer

	If set to true, player animation tracks will be loaded for each player character on spawn.
	
	:::warning
	Must have animation ids under [`rigType`](/api/AnimationIds#rigType) of **"Player"** in the [`AnimationIds`](/api/AnimationIds) module.
	:::
]=]
AnimationsServer.AutoLoadPlayerTracks = false

--[=[
	@prop TimeToLoadPrints true
	@within AnimationsServer

	If set to true, prints will be made on each call to [`AnimationsServer:LoadTracks()`](#LoadTracks) to indicate the start, stop and elapsed time of pre-loading the player or rig's animation tracks.
]=]
AnimationsServer.TimeToLoadPrints = false

--[=[
	@tag Server Only
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
	@param initOptions initOptions?

	Initializes `AnimationsServer`.
	
	:::info
	Should be called once before any other method. Clients are unable to initialize until this gets called.
	:::
]=]
function AnimationsServer:Init(initOptions: AnimationsServerInitOptionsType?)
	if self._initialized then
		warn("AnimationsServer:Init() only needs to be called once")
		return
	end
	
	self._initialized = true
	
	if initOptions then
		if initOptions.AutoLoadPlayerTracks ~= nil then
			self.AutoLoadPlayerTracks = initOptions.AutoLoadPlayerTracks
		end

		if initOptions.TimeToLoadPrints ~= nil then
			self.TimeToLoadPrints = initOptions.TimeToLoadPrints
		end
		
		if initOptions.AnimatedObjectsDebugMode ~= nil then
			self.AnimatedObjectsDebugMode = initOptions.AnimatedObjectsDebugMode
		end

		if initOptions.EnableAutoCustomRBXAnimationIds ~= nil then
			self.EnableAutoCustomRBXAnimationIds = initOptions.EnableAutoCustomRBXAnimationIds
		end
	end

	local function initCustomRBXAnimationIdsSignal()
		local applyCustomRBXAnimationIdsRE = Instance.new("RemoteEvent")
		applyCustomRBXAnimationIdsRE.Name = "ApplyCustomRBXAnimationIds"
		applyCustomRBXAnimationIdsRE.Parent = script.Parent
		
		self.ApplyCustomRBXAnimationIdsSignal = applyCustomRBXAnimationIdsRE
	end

	local function initOnPlayerAdded()
		local function onPlayerAdded(player)
			local function onCharacterAdded(char)
				local hum = char:FindFirstChild("Humanoid")

				if self.EnableAutoCustomRBXAnimationIds then
					self:ApplyCustomRBXAnimationIds(player, AutoCustomRBXAnimationIds)
				end

				if self.AutoLoadPlayerTracks then 
					self:LoadTracks(player, "Player") 
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
	
	initCustomRBXAnimationIdsSignal()
	initOnPlayerAdded()
	
	script:SetAttribute("Initialized", true)
end

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
	@method ApplyCustomRBXAnimationIds
	@within AnimationsServer
	@yields
	@param player_or_rig Player | Model
	@param humanoidRigTypeToCustomRBXAnimationIds humanoidRigTypeToCustomRBXAnimationIds

	Applies the animation ids specified in the [`humanoidRigTypeToCustomRBXAnimationIds`](#humanoidRigTypeToCustomRBXAnimationIds) table on the player or rig. Yields if the player's character, player or rig's humanoid, player's animator, or player or rig's animate script aren't immediately available.

	:::warning
	This function only works for players and R6/R15 NPCs that have an `"Animate"` script in their model.
	:::
	:::tip
	See [`ApplyAnimationProfile()`](#ApplyAnimationProfile) for a more convenient way of overriding default roblox character animations.
	:::

	```lua
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
	
	Applies the animation ids found in the animation profile on the player or rig. Yields if the player's character, player or rig's humanoid, player's animator, or player or rig's animate script aren't immediately available.
	
	:::warning
	This function only works for players and R6/R15 NPCs that have an `"Animate"` script in their model.
	:::
	:::info
	For more information on setting up animated objects check out [animation profiles tutorial](/docs/animation-profiles).
	:::
]=]

--[=[
	@method AwaitLoaded
	@yields
	@within AnimationsServer
	@param player_or_rig Player | Model
	
	Yields until the player or rig's animation tracks have loaded.
	
	```lua
	-- [WARNING] For this to work you need animation ids under the rig type of "Player" in the 'AnimationIds' module
	local Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsServer)

	Animations:Init()

	Animations.AutoLoadTracks = true
	Animations.TimeToLoadPrints = true

	local player = game.Players:WaitForChild("MyName")

	Animations:AwaitLoaded(player)

	print("Animation tracks finished loading on the server!")
	```
]=]

--[=[
	@method AreTracksLoaded
	@within AnimationsServer
	@param player_or_rig Player | Model
	@return boolean
	
	Returns if the player or rig has had its animation tracks loaded.
]=]

--[=[
	@method LoadTracks
	@within AnimationsServer
	@yields
	@param player_or_rig Player | Model
	@param rigType string?
	
	Yields while the player or rig's animation tracks load. If `rigType` is not provided and `player_or_rig` is a player or player's character then it will default to `"Player"`.

	:::tip
	Automatically gives the rig an attribute `"AnimationsRigType"` set to the [`rigType`](/api/AnimationIds#rigType).
	:::
]=]

--[=[
	@method GetTrack
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param path path
	@return AnimationTrack?
	
	Returns a player or rig's animation track or nil.
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

	Returns a playing player or rig's animation track.
]=]

--[=[
	@method StopTrack
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param path path
	@param fadeTime number?
	@return AnimationTrack

	Returns a stopped player or rig's animation track.
]=]

--[=[
	@method StopAllTracks
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param fadeTime number?
	@return {AnimationTrack?}

	Returns the stopped player or rig animation tracks.
]=]

--[=[
	@method StopTracksOfPriority
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param animationPriority Enum.AnimationPriority
	@param fadeTime number?
	@return {AnimationTrack?}

	Returns the stopped player or rig animation tracks.
]=]

--[=[
	@method GetTrackFromAlias
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param alias any
	@return AnimationTrack?

	Returns a player or rig's animation track or nil.
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

	Returns a playing player or rig's animation track.
]=]

--[=[
	@method StopTrackFromAlias
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param alias any
	@param fadeTime number?
	@return AnimationTrack

	Returns a stopped player or rig's animation track.
]=]

--[=[
	@method SetTrackAlias
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param alias any
	@param path path

	Sets an alias to be the equivalent of the path for a player or rig's animation track.

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

	Removes the alias for a player or rig's animation track.
]=]

--[=[
	@tag Beta
	@method AttachAnimatedObject
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param animatedObjectPath path

	Attaches the animated object to the player or rig.

	:::tip
	Enable [`initOptions.AnimatedObjectsDebugMode`](/api/AnimationsServer/#initOptions) for detailed prints about animated objects.
	:::
	:::info
	For more information on setting up animated objects check out [animated objects tutorial](/docs/animated-objects).
	:::
]=]

--[=[
	@tag Beta
	@method DetachAnimatedObject
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param animatedObjectPath path

	Detaches the animated object from the player or rig.

	:::tip
	Enable [`initOptions.AnimatedObjectsDebugMode`](/api/AnimationsServer/#initOptions) for detailed prints about animated objects.
	:::
	:::info
	For more information on setting up animated objects check out [animated objects tutorial](/docs/animated-objects).
	:::
]=]

return AnimationsServer :: Types.AnimationsServerType