-- made by wrello

--//
local TIME_TO_LOAD_PRINTS = false
local AUTO_LOAD_ON_PLAYER_SPAWN = false -- If set to true, animations will be loaded/pre-loaded each time a player spawns
local ENABLE_CUSTOM_DEFAULT_R6_ANIMATIONS = false
--//

local Players = game:GetService("Players")

local Types = require(script.Parent.Util.Types)
local CustomDefaultR6Animations = require(script.Parent.Parent.Deps.CustomDefaultR6Animations)
local AnimationsClass = require(script.Parent.Util.AnimationsClass)

local Animations = AnimationsClass.new()
Animations.TimeToLoadPrints = TIME_TO_LOAD_PRINTS

local AnimationsServer = Animations

function AnimationsServer:Init()
	local function onPlayerAdded(player)
		local function onCharacterAdded(char)
			if ENABLE_CUSTOM_DEFAULT_R6_ANIMATIONS then
				CustomDefaultR6Animations(char)
			end
			
			if AUTO_LOAD_ON_PLAYER_SPAWN then 
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

return AnimationsServer :: Types.AnimationsServerType