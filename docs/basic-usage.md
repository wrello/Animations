---
sidebar_position: 2
---

# Basic Usage

---

## Initialization
This is the same on the client and the server, but **the server must be initialized first in order for the client to.** The client will automatically wait until the server has finished initializing before starting its own initialization.
```lua
local Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsServer)

Animations:Init({
	AutoLoadAllPlayerTracks = true -- Defaults to false
})
```

## AnimationIds
Add your animation ids to the [`Animations\Deps\AnimationIds`](/api/AnimationIds) module:
```lua
local AnimationIds = {
    Player = { -- "Player" is required here for player animations (see 'rigType' in the AnimationIds API for more info)
        Jump = 00000000
    },

	Monster = {
		Run = 00000000
	}
}

return AnimationIds
```


## Player Animations

On the server:
```lua
...

local player = game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()

Animations:AwaitAllTracksLoaded(player) -- Needed if the player has just spawned
Animations:PlayTrack(player, "Jump")
```

On the client:
```lua
...

Animations:AwaitAllTracksLoaded() -- Needed if the player has just spawned
Animations:PlayTrack("Jump")
```

## Rig Animations

On the server:
```lua
...

local monsterChar = workspace.Monster

Animations:Register(monsterChar, "Monster") -- In order to use "Monster" animations (in AnimationIds) on this rig
Animations:LoadAllTracks(player)

Animations:PlayTrack(monsterChar, "Run")
```

On the client:
```lua
...

local monsterChar = workspace.Monster

Animations:RegisterRig(monsterChar, "Monster") -- In order to use "Monster" animations (in AnimationIds) on this rig
Animations:LoadAllRigTracks(player)

Animations:PlayRigTrack(monsterChar, "Run")
```