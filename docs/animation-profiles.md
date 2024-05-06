---
sidebar_position: 3
---

# Animation Profiles

---

## Animation Profiles Setup

First create a module inside of the `Animations.Deps.AnimationProfiles` folder. It's name will be the name of the animation profile:

![tutorial-1](/images/animation-profiles-tutorial-1.png)

The animation profile (what the `Zombie` module returns) is just a [`humanoidRigTypeToCustomRBXAnimationIds`](http://localhost:3000/Animations/api/AnimationsServer#humanoidRigTypeToCustomRBXAnimationIds) table, as seen below:
```lua
-- Inside of `Animations.Deps.AnimationProfiles.Zombie`
return {
	[Enum.HumanoidRigType.R15] = {
		run = 616163682,
		walk = 616168032,
		jump = 616161997,
		idle = {
			Animation1 = 616158929,
			Animation2 = 616160636
		},
		fall = 616157476,
		swim = 616165109,
		swimIdle = 616166655,
		climb = 616156119
	}
}
```
:::info
These animations will only work for an `R15` character. Animation ids found here: https://create.roblox.com/docs/animation/using#catalog-animations
:::
Now you can use the `Zombie` animation profile. Example:
```lua
-- In a LocalScript in StarterPlayerScripts
local Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsClient)

Animations:Init()

Animations:ApplyAnimationProfile("Zombie") -- We now have zombie animations instead of the default roblox ones.
```