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
	.AutoLoadPlayerTracks boolean -- Defaults to false
	.TimeToLoadPrints boolean -- Defaults to false (on the server)
	.AutoCustomRBXAnimationIds boolean -- Defaults to false
	
	Gets applied to [`Properties`](#properties).
]=]
type AnimationsServerInitOptionsType = Types.AnimationsServerInitOptionsType

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
	
	A table of animation ids to apply to player character's animate script, replacing default roblox animation ids.
]=]
type CustomRBXAnimationIdsType = Types.CustomRBXAnimationIdsType

--[=[
	@type path any
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

local ASSET_ID_STR = "rbxassetid://%f"

local Animations = AnimationsClass.new()

--[=[
	@class AnimationsServer
	@server
	
	:::note
	Roblox model path: `Animations.Package.AnimationsServer`
	:::
]=]
local AnimationsServer = Animations :: Types.AnimationsServerType

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
	@param initOptions initOptions?

	Initializes `AnimationsServer`.
	
	:::info
	Should be called once before any other method.
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
		
		if initOptions.AutoCustomRBXAnimationIds ~= nil then
			self.AutoCustomRBXAnimationIds = initOptions.AutoCustomRBXAnimationIds
		end
	end

	local function onPlayerAdded(player)
		local function onCharacterAdded(char)
			local hum = char.Humanoid
			
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

--[=[
	@tag Server Only
	@yields
	@param player Player
	@param customRBXAnimationIds customRBXAnimationIds

	Applies the animation ids specified in the given [`customRBXAnimationIds`](#customRBXAnimationIds) table on the given `player`'s character. Yields if the `player`'s character, humanoid, animator, or animate script aren't immediately available.

	```lua
	local Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsServer)

	Animations:Init()

	task.wait(5)

	print("Applying r15 ninja jump animation")

	Animations:ApplyCustomRBXAnimationIds(game.Players.YourName, {
		jump = 656117878, -- This is an r15 ninja jump animation
	})
	```

	:::caution
	Be aware that if the animation was created on a different `HumanoidRigType` than that of the player's character, the animation will not work. If you don't know what `HumanoidRigType` the player has, you can get around this by formatting the [`customRBXAnimationIds`](#customRBXAnimationIds) table like the [`AutoCustomRBXAnimationIds`](/api/AutoCustomRBXAnimationIds) module table (with [Enum.HumanoidRigType] keys corresponding to animation ids created for that `HumanoidRigType`).
	:::
]=]
function AnimationsServer:ApplyCustomRBXAnimationIds(player: Player, customRBXAnimationIds: CustomRBXAnimationIdsType)
	self._initializedAssertion()
	
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	local animator = hum:WaitForChild("Animator")
	local animateScript = char:WaitForChild("Animate")
	
	for _, track in pairs(animator:GetPlayingAnimationTracks()) do
		track:Stop(0)
	end
	
	local humRigTypeSupportedAnimationIds = customRBXAnimationIds[hum.RigType]
	
	if humRigTypeSupportedAnimationIds then
		customRBXAnimationIds = humRigTypeSupportedAnimationIds
	end
	
	for animName, animId in pairs(customRBXAnimationIds) do
		for _, animInstance in ipairs(animateScript[animName]:GetChildren()) do
			if type(animId) == "table" then
				animInstance.AnimationId = ASSET_ID_STR:format(animId[animInstance.Name])
			else
				animInstance.AnimationId = ASSET_ID_STR:format(animId)
			end
		end
	end
end

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
	@param rigType string
	
	Yields while the player or rig's animation tracks load.
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

	Sets an alias to be the equivalent of the given path for a player or rig's animation track.

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

return AnimationsServer