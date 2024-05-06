---
sidebar_position: 4
---

# Animated Objects

---

# Warning

This system is in beta, you may experience bugs. 

If you do run into one, or have any ideas/suggestions, it would help everyone if you could please create [an issue](https://github.com/wrello/Animations/issues).

## Animated Object Setup

:::danger
If at any point the `motor6d.Part1.Name` is not the same as it was in the uploaded animation, **the animated object will not animate**.
:::

:::info
If at any point an attached animated object is a `tool`, the `Rig.Right Arm.RightGrip` or `Rig.RightHand.RightGrip` `Weld` will be disabled. It will be be re-enabled upon detaching (if just the `motor6d` gets detached).
:::

![tutorial-1](/images/tutorial-1.png)

:::note
The explanations below use the image above as an example.
:::

### `motor6d` only

Useful if you have a `tool` that is already equipped and just want to attach the `motor6d` to it and the rig for animating (works for `models` too). [(jump to "motor6d only" finished product)](#motor6d-only-finished-product)

---

1. Copy the old `motor6d` (`"Handle"`) that was used for attaching the `tool` (`"Sword"`) to the rig during animating.

2. Paste the new `motor6d` into `Animations.Deps.AnimatedObjects`.
3. Rename the new `motor6d` to `tool.Name`.
4. Create two `StringValues` inside of the new `motor6d` and name them `"Part0Name"` and `"Part1Name"`.
5. Set `Part0Name.Value` to `motor6d.Part0.Name` and `Part1Name.Value` to `motor6d.Part1.Name`.
6. (optional) Configure your [`AnimationIds`](/api/AnimationIds) module to enable auto attaching and auto detaching.

#### "motor6d only" finished product:

![tutorial-2](/images/tutorial-2.png)
![tutorial-3](/images/tutorial-3.png)

#### "motor6d only" code example:
```lua
-- In a ServerScript
Animations:AttachAnimatedObject(game.Players.YourName, "Sword")

-- or in the AnimationIds module
local AnimationIds = {
    Player = {
        -- The sword motor6d will be auto attached to the equipped sword tool when the "SwordWalk" animation plays
        SwordWalk = HasAnimatedObject(0000000, "Sword", { RunContext = "Server", AutoAttach = true })
    }
}
```

### `basepart`, `model`, `tool`

Useful if you want to attach a clone of an object to the rig for an animation. [(jump to "basepart, model, tool" finished product)](#basepart-model-tool-finished-product)

---

1. Copy the old `basepart`, `model`, `tool` that was used as the `animatedObject` in the rig during animating.
    - Paste the new `animatedObject` into `Animations.Deps.AnimatedObjects`.

2. Copy the old `motor6d` that was used for attaching the `animatedObject` to the rig during animating.
    - Paste the new `motor6d` into the new `animatedObject`.

3. Rename the new `motor6d` to `"AnimatedObjectMotor6D"`.
4. Create two `StringValues` inside of the new `motor6d` and name them `"Part0Name"` and `"Part1Name"`.
5. Set `Part0Name.Value` to `motor6d.Part0.Name` and `Part1Name.Value` to `motor6d.Part1.Name`.
6. (optional) Configure your [`AnimationIds`](/api/AnimationIds) module to enable auto attaching and auto detaching.

#### "basepart, model, tool" finished product:

![tutorial-4](/images/tutorial-4.png)
![tutorial-5](/images/tutorial-5.png)

#### "basepart, model, tool" code example:
```lua
-- In a ServerScript
Animations:AttachAnimatedObject(game.Players.YourName, "Sword")

-- or in the AnimationIds module
local AnimationIds = {
    Player = {
        -- The sword tool will be auto attached when the "SwordWalk" animation plays
        SwordWalk = HasAnimatedObject(0000000, "Sword", { RunContext = "Server", AutoAttach = true })
    }
}
```

### `folder`

Useful if you want to attach a clone of multiple objects to the rig for an animation. [(jump to "folder" finished product)](#folder-finished-product)

---

1. Create a folder inside of `Animations.Deps.AnimatedObjects` named whatever you would like.
2. Repeat the ["basepart, model, tool"](#basepart-model-tool) process for all the `animatedObjects` that you want to be attached at the same time.
3. (optional) Configure your [`AnimationIds`](/api/AnimationIds) module to enable auto attaching and auto detaching.

#### "folder" finished product:

![tutorial-6](/images/tutorial-6.png)

#### "folder" code example:
```lua
-- In a ServerScript
Animations:AttachAnimatedObject(game.Players.YourName, "MyAnimatedObjectsGroup")

-- or in the AnimationIds module
local AnimationIds = {
    Player = {
        -- The children of "MyAnimatedObjectsGroup" will be auto attached when "Walk" animation is played and auto detached when it stops
        Walk = HasAnimatedObject(0000000, "MyAnimatedObjectsGroup", { RunContext = "Server", AutoAttach = true, AutoDetach = true })
    }
}
```