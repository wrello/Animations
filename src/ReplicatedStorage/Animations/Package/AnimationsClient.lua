-- made by wrello

local Players = game:GetService("Players")

local Types = require(script.Parent.Util.Types)
local AnimationsClass = require(script.Parent.Util.AnimationsClass)

local player = Players.LocalPlayer

--[=[
	@interface initOptions
	@within AnimationsClient
	.AutoLoadPlayerTracks boolean -- Defaults to false
	.TimeToLoadPrints boolean -- Defaults to true (on the client)
	
	Gets applied to [`Properties`](#properties).
]=]
type AnimationsClientInitOptionsType = Types.AnimationsClientInitOptionsType

--[=[
	@type path any
	@within AnimationsClient
	
	```lua
	local Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsClient)
	
	
	-- These are all valid options for retrieving an animation track
	local animationPath = "Jump" -- A single key (any type)
	
	local animationPath = {"Dodge", Vector3.xAxis} -- An array path (values of any type)

	local animationPath = "Climb.Right" -- A path seperated by "." (string)


	local animationTrack = Animations:GetTrack(animationPath)
	```
]=]

local Animations = AnimationsClass.new()

--[=[
	@class AnimationsClient
	@client
	
	:::note
	Roblox model path: `Animations.Package.AnimationsClient`
	:::
	
	:::info
	Any reference to "client animation tracks" is referring to animation ids found under [`rigType`](/api/AnimationIds#rigType) of **"Player"** in the [`AnimationIds`](/api/AnimationIds) module
	:::
]=]
local AnimationsClient = Animations :: Types.AnimationsClientType

--[=[
	@prop AutoLoadPlayerTracks false
	@within AnimationsClient

	If set to true, client animation tracks will be loaded each time the client spawns.
	
	:::warning
	Must have animation ids under [`rigType`](/api/AnimationIds#rigType) of **"Player"** in the [`AnimationIds`](/api/AnimationIds) module.
	:::
]=]
AnimationsClient.AutoLoadPlayerTracks = false

--[=[
	@prop TimeToLoadPrints true
	@within AnimationsClient

	If set to true, prints will be made on each call to [`AnimationsClient:LoadTracks()`](#LoadTracks) to indicate the start, stop and elapsed time of pre-loading the client animation tracks.

	:::caution
	It is suggested to keep this as true because a lot of client animation tracks results in a significant yield time which is difficult to debug if forgotten.
	:::
]=]
AnimationsClient.TimeToLoadPrints = true

--[=[
	@yields
	@param initOptions initOptions?

	Initializes `AnimationsClient`. Yields if [`AnimationsClient.AutoLoadTracks`](#AutoLoadTracks) is set to true and the player's character already exists.

	:::info
	Should be called once before any other method.
	:::
]=]
function AnimationsClient:Init(initOptions: AnimationsClientInitOptionsType?)
	if self._initialized then
		warn("AnimationsClient:Init() only needs to be called once")
		return
	end

	self._initialized = true
	
	if initOptions.AutoLoadPlayerTracks ~= nil then
		self.AutoLoadPlayerTracks = initOptions.AutoLoadPlayerTracks
	end
	
	if initOptions.TimeToLoadPrints ~= nil then
		self.TimeToLoadPrints = initOptions.TimeToLoadPrints
	end
	
	for k, v in pairs(AnimationsClass) do
		if type(v) == "function" and not k:match("^_") then
			local clientMethodName = k
			local rigMethodName = clientMethodName:gsub("^(%L[^%L]+)(%L[^%L]+)", "%1Rig%2")
			
			if clientMethodName == "LoadTracks" then
				self[clientMethodName] = function(self, ...)
					return v(self, player, "Player", ...)
				end
				
				self[rigMethodName] = function(self, rig, rigType, ...)
					return v(self, rig, rigType, ...)
				end
			else
				self[clientMethodName] = function(self, ...)
					return v(self, player, ...)
				end
				
				self[rigMethodName] = function(self, rig, ...)
					return v(self, rig, ...)
				end
			end
		end
	end

	script.Parent.AnimationsServer:Destroy()

	if self.AutoLoadPlayerTracks then
		if player.Character then
			self:LoadTracks()
		end
	end

	player.CharacterAdded:Connect(function(char)
		if self.AutoLoadPlayerTracks then
			self:LoadTracks()
		end
	end)
end

--[=[
	@method AwaitLoaded
	@yields
	@within AnimationsClient
	
	Yields until the client animation tracks have loaded.
]=]
--[=[
	@method AwaitRigLoaded
	@yields
	@within AnimationsClient
	@param rig Model
	
	Yields until the rig animation tracks have loaded.
]=]

--[=[
	@method AreTracksLoaded
	@within AnimationsClient
	@return boolean
	
	Returns if the client has had its animation tracks loaded.
]=]
--[=[
	@method AreRigTracksLoaded
	@within AnimationsClient
	@param rig Model
	@return boolean
	
	Returns if the rig has had its animation tracks loaded.
]=]

--[=[
	@method LoadTracks
	@within AnimationsClient
	@yields
	
	Yields while client animation tracks load.
]=]
--[=[
	@method LoadRigTracks
	@within AnimationsClient
	@yields
	@param rig Model
	@param rigType string
	
	Yields while the rig animation tracks load.
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
	
	Returns a rig animation track or nil.
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

	Returns a playing rig animation track.
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

	Returns a stopped rig animation track.
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

	Returns a rig animation track or nil.
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

	Returns a playing rig animation track.
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

	Returns a stopped rig animation track.
]=]

--[=[
	@method SetTrackAlias
	@within AnimationsClient
	@param alias any
	@param path path

	Sets an alias to be the equivalent of the given path for a client animation track.
]=]
--[=[
	@method SetRigTrackAlias
	@within AnimationsClient
	@param rig Model
	@param alias any
	@param path path

	Sets an alias to be the equivalent of the given path for a rig animation track.
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

	Removes the alias for a rig animation track.
]=]

return AnimationsClient