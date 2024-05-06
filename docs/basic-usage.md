---
sidebar_position: 2
---

# Basic Usage

---

# AnimationIds
Configure your [`AnimationIds`](/api/AnimationIds) module:
```lua
-- In ReplicatedStorage.Animations.Deps.AnimationIds
local ninjaJumpR15AnimationId = 656117878

local AnimationIds = {
    Player = { -- Rig type of "Player" (required for any animations that will run on player characters)
        Jump = ninjaJumpR15AnimationId -- Path of "Jump"
    }
}
```
# AnimationsServer
Playing the animation when it gets auto loaded on a player character:
```lua
-- In a ServerScript
local Players = game:GetService("Players")

local Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsServer)

Animations:Init({
	AutoLoadPlayerTracks = true, -- Defaults to false
	TimeToLoadPrints = true -- Defaults to false (on the server)
})

local function onPlayerAdded(player)
	Animations:AwaitLoaded(player)

	print("Finished loading animations for", player.Name)

	-- Roblox's r15 ninja jump animation is looped.

	-- `AnimationTrack.Looped = false` doesn't replicate clients, so
	-- it is impossible to make this not loop from the server.
	
	print("Playing looped ninja jump animation for", player.Name)
	Animations:PlayTrack(player, "Jump")
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
```

# AnimationsClient
Playing the animation when it gets auto loaded on the client:
```lua
-- In a LocalScript
local Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsClient)

Animations:Init({
	AutoLoadPlayerTracks = true, -- Defaults to false
	TimeToLoadPrints = true -- Defaults to true (on the client)
})

local player = game.Players.LocalPlayer

local function onCharacterAdded(char)
	Animations:AwaitLoaded()

	print("Finished loading client animations")

	Animations:GetTrack("Jump").Looped = false -- Roblox's r15 ninja jump animation is looped.

	while true do
		print("Playing ninja jump client animation")
		Animations:PlayTrack("Jump")

		task.wait(3)
	end
end

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)
```