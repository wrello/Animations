---
sidebar_position: 2
---

# Basic Usage

---

# AnimationIds
Configure your [`AnimationIds`](/api/AnimationIds) module:
```lua
-- Inside of `ReplicatedStorage.Animations.Deps.AnimationIds`

local ninjaJumpR15AnimationId = 656117878

local AnimationIds = {
    Player = { -- Rig type of "Player" (required for any animations that will run on player characters)
        Jump = ninjaJumpR15AnimationId -- Path of "Jump"
    }
}

return AnimationIds
```
# AnimationsServer
Playing an animation on the server on a **Player**:
```lua
-- In a ServerScript

local Players = game:GetService("Players")

local Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsServer)

Animations:Init({
	AutoLoadAllPlayerTracks = true, -- Defaults to false
	TimeToLoadPrints = true -- Defaults to true
})

local function onPlayerAdded(player)
	Animations:AwaitAllTracksLoaded(player)

	print("Finished loading animations for", player.Name)

	-- Roblox's r15 ninja jump animation is looped.

	-- `AnimationTrack.Looped = false` doesn't replicate to clients, so
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
Playing an animation on the client on the **LocalPlayer**:
```lua
-- In a LocalScript

local Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsClient)

Animations:Init({
	AutoLoadAllPlayerTracks = true, -- Defaults to false
	TimeToLoadPrints = true -- Defaults to true
})

local player = game.Players.LocalPlayer

local function onCharacterAdded(char)
	Animations:AwaitAllTracksLoaded()

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

- [Basic Usage Monster/NPC](/docs/basic-usage-monster-npc)