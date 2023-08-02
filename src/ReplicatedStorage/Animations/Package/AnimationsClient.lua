-- made by wrello

--//
local TIME_TO_LOAD_PRINTS = false
local AUTO_LOAD_ON_PLAYER_SPAWN = true -- If set to true, animations will be loaded/pre-loaded each time the local player spawns
--//

local Players = game:GetService("Players")

local Types = require(script.Parent.Util.Types)
local AnimationsClass = require(script.Parent.Util.AnimationsClass)

local player = Players.LocalPlayer

local Animations = AnimationsClass.new()
Animations.TimeToLoadPrints = TIME_TO_LOAD_PRINTS

local AnimationsClient = Animations

--[[
	@yields
]]
function AnimationsClient:Init()
	-- Creates two versions of each method in the AnimationsClass module, one for the LocalPlayer to use on themselves, and one for them to use on a rig
	
	-- Example 1 - 'AnimationsClass:LoadTracks()'
	
	-- ORIGINAL DOCUMENTED VERSION - AnimationsClass:LoadTracks(player_or_rig: Player | Model, rig_type: String)
	
	-- Client version 1 - AnimationsClient:LoadTracks() -- Loads the LocalPlayer's animation tracks
	-- Client version 2 - AnimationsClient:LoadRigTracks(rig: Model, rig_type: String) -- Loads a rig's animation tracks
	
	
	-- Example 2 - 'AnimationsClass:PlayTrack()'
	
	-- ORIGINAL DOCUMENTED VERSION - Animations:PlayTrack(player_or_rig: Player | Model, path: any, fadeTime: number?, weight: number?, speed: number?)
	
	-- Client version 1 - AnimationsClient:PlayTrack(path: any, fadeTime: number?, weight: number?, speed: number?) -- Plays the animation track found at 'path' for the LocalPlayer
	-- Client version 2 - AnimationsClient:PlayRigTrack(rig: Model, path: any, fadeTime: number?, weight: number?, speed: number?) -- Plays the animation track found at 'path' for the given 'rig'
	
	for k, v in pairs(AnimationsClass) do
		if type(v) == "function" and not k:match("^_") then
			local playerMethodName = k
			local rigMethodName = playerMethodName:gsub("^(%L[^%L]+)(%L[^%L]+)", "%1Rig%2")
			
			if playerMethodName == "LoadTracks" then
				self[playerMethodName] = function(self, ...)
					return v(self, player, "Player", ...)
				end
				
				self[rigMethodName] = function(self, rig, rig_type, ...)
					return v(self, rig, rig_type, ...)
				end
			else
				self[playerMethodName] = function(self, ...)
					return v(self, player, ...)
				end
				
				self[rigMethodName] = function(self, rig, ...)
					return v(self, rig, ...)
				end
			end
		end
	end

	script.Parent.AnimationsServer:Destroy()

	if not AUTO_LOAD_ON_PLAYER_SPAWN then 
		return
	end

	if player.Character then
		self:LoadTracks()
	end

	player.CharacterAdded:Connect(function(char)
		self:LoadTracks()
	end)
end

return AnimationsClient :: Types.AnimationsClientType