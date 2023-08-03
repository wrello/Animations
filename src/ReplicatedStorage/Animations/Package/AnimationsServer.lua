-- made by wrello

local Players = game:GetService("Players")

local Types = require(script.Parent.Util.Types)
local AutoCustomRBXAnimationIds = require(script.Parent.Parent.Deps.AutoCustomRBXAnimationIds)
local AnimationsClass = require(script.Parent.Util.AnimationsClass)
local CustomAssert = require(script.Parent.Util.CustomAssert)

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

local ASSET_ID_STR = "rbxassetid://%f"

local Animations = AnimationsClass.new()

--[=[
	@class AnimationsServer
	@server
]=]
local AnimationsServer = Animations

--[=[
	@prop AutoLoadTracks false
	@within AnimationsServer

	If set to true, player animation tracks will be loaded for each player character on spawn.
]=]
AnimationsServer.AutoLoadTracks = false

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
	Initializes `AnimationsServer`.
	
	:::info
	Should be called once before any other method.
	:::
]=]
function AnimationsServer:Init()
	if self._initialized then
		warn("AnimationsServer:Init() only needs to be called once")
		return
	end
	
	self._initialized = true
	
	local function onPlayerAdded(player)
		local function onCharacterAdded(char)
			local hum = char.Humanoid
			
			if self.EnableAutoCustomRBXAnimationIds then
				self:ApplyCustomRBXAnimationIds(player, AutoCustomRBXAnimationIds)
			end
			
			if self.AutoLoadTracks then 
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

	Applies the animation ids specified in the given `customRBXAnimationIds` table on the given `player`'s character. Yields if the `player`'s character, humanoid, animator, or animate script aren't immediately available.
]=]
function AnimationsServer:ApplyCustomRBXAnimationIds(player: Player, customRBXAnimationIds: CustomRBXAnimationIdsType)
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	local animator = hum:WaitForChild("Animator")
	local animateScript = char:WaitForChild("Animate")
	
	for _, track in pairs(animator:GetPlayingAnimationTracks()) do
		track:Stop(0)
	end
	
	for animName, animId in pairs(customRBXAnimationIds) do
		for _, animInstance in ipairs(animateScript[animName]) do
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
	@param path any
	@return AnimationTrack?
	
	Returns a player or rig's animation track or nil.
]=]

--[=[
	@method PlayTrack
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param path any
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
	@param path any
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
	@param path any

	Sets an alias to be the equivalent of the given path for a player or rig's animation track.
]=]

--[=[
	@method RemoveTrackAlias
	@within AnimationsServer
	@param player_or_rig Player | Model
	@param alias any

	Removes the alias for a player or rig's animation track.
]=]

return AnimationsServer :: Types.AnimationsServerType