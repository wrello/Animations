---
sidebar_position: 1
---

# Install

---

# Command bar
Paste the following command into your Roblox Studio command bar:
```lua
game:GetService("InsertService"):LoadAsset(14292949504).Animations.Parent = game.ReplicatedStorage
```

# Roblox model
or get the [Roblox model](https://create.roblox.com/marketplace/asset/14292949504/Animations) and put it into your `ReplicatedStorage`.

# Wally/Pesde
:::caution
If using a package manager, make sure to move the `Deps` folder somewhere safe after installation, so it doesn't get overriden by new package versions. Then use the [`BootstrapDepsFolder`](/api/AnimationsServer#BootstrapDepsFolder) initialization option to specify its new location.
:::
| |  |
| ---          | --- |
| Wally | `Animations = "wrello/animations@^3"` |
| Pesde | `Animations = { name = "wrello/animations", version = "^3" }` |

*Note: These versions may be out of date.*