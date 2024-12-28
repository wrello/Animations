local Types = require(script.Parent.Parent.Package.Util.Types)
local AnimationIdsUtil = require(script.Parent.Parent.Package.Util.AnimationIdsUtil)

local HasAnimatedObject = AnimationIdsUtil.HasAnimatedObject
local HasProperties = AnimationIdsUtil.HasProperties

--[=[
	@type rigType string
	@within AnimationIds

	The first key in the `AnimationIds` module that indicates the type of rig the paired animation id table belongs to.

	```lua
	local AnimationIds = {
		Player = { -- `rigType` of "Player"
			Dodge = {
				[Enum.KeyCode.W] = 0000000,
				[Enum.KeyCode.S] = 0000000,
				[Enum.KeyCode.A] = 0000000,
				[Enum.KeyCode.D] = 0000000,
			},
			Run = 0000000,
			Walk = 0000000,
			Idle = 0000000
		}
	}
	```

	:::info
	The only preset `rigType` is that of **"Player"** for all player/client animation ids.
	:::
]=]

--[=[
	@type animationId number
	@within AnimationIds
]=]

--[=[
	@interface idTable
	@within AnimationIds
	.[any] idTable | animationId
]=]

--[=[
	@type HasProperties (animationId: idTable, propertiesSettings: {Priority: Enum.AnimationPriority?, Looped: boolean?, DoUnpack: boolean?, MarkerTimes: boolean?}): {}
	@within AnimationIds

	:::tip *added in version 2.0.0*
	:::

	```lua
	local AnimationIds = {
		Player = { -- `rigType` of "Player"
			Dodge = {
				[Enum.KeyCode.W] = 0000000,
				[Enum.KeyCode.S] = 0000000,
				[Enum.KeyCode.A] = 0000000,
				[Enum.KeyCode.D] = 0000000,
			},
			Run = 0000000,
			Walk = 0000000,
			Idle = 0000000,
			Sword = {
				-- Now when the "Sword.Walk" animation plays it will
				-- automatically have `Enum.AnimationPriority.Action` priority
				Walk = HasProperties(0000000, { Priority = Enum.AnimationPriority.Action })

				Idle = 0000000,
				Run = 0000000,

	            -- Now when {"Sword", "AttackCombo", 1 or 2 or 3} animation
	            -- plays it will automatically have `Enum.AnimationPriority.Action` priority and
				-- will support `Animations:GetTimeOfMarker()`
				AttackCombo = HasProperties({
					[1] = 0000000,
					[2] = 0000000,
					[3] = 0000000
				}, { Priority = Enum.AnimationPriority.Action, MarkerTimes = true })
			}
		},
	}
	```
]=]

--[=[
	@tag Beta
	@type HasAnimatedObject (animationId: idTable, animatedObjectPath: path, animatedObjectSettings: {AutoAttach: boolean?, AutoDetach: boolean?, DoUnpack: boolean?}): {}
	@within AnimationIds

	```lua
	local AnimationIds = {
		Player = { -- `rigType` of "Player"
			Dodge = {
				[Enum.KeyCode.W] = 0000000,
				[Enum.KeyCode.S] = 0000000,
				[Enum.KeyCode.A] = 0000000,
				[Enum.KeyCode.D] = 0000000,
			},
			Run = 0000000,
			Walk = 0000000,
			Idle = 0000000,
			Sword = {
				-- Now when the "Sword.Walk" animation plays "Sword" will
				-- auto attach to the player and get animated
				Walk = HasAnimatedObject(0000000, "Sword", { AutoAttach = true })

				Idle = 0000000,
				Run = 0000000,

				-- Now when {"Sword", "AttackCombo", 1 or 2 or 3} animation
				-- plays "Sword" will auto attach to the player and get
				-- animated
				AttackCombo = HasAnimatedObject({
					[1] = 0000000,
					[2] = 0000000,
					[3] = 0000000
				}, "Sword", { AutoAttach = true })
			}
		},
	}
	```

	:::info
	For more information on setting up animated objects check out [animated objects tutorial](/docs/animated-objects).
	:::
]=]

--[=[
	@interface AnimationIds
	@within AnimationIds
	.[rigType] idTable

	```lua
	local AnimationIds = {
		Player = { -- `rigType` of "Player"
			Dodge = {
				[Enum.KeyCode.W] = 0000000,
				[Enum.KeyCode.S] = 0000000,
				[Enum.KeyCode.A] = 0000000,
				[Enum.KeyCode.D] = 0000000,
			},
			Run = 0000000,
			Walk = 0000000,
			Idle = 0000000
		},

		BigMonster = { -- `rigType` of "BigMonster"
			HardMode = {
				Attack1 = 0000000,
				Attack2 = 0000000
			},
			EasyMode = {
				Attack1 = 0000000,
				Attack2 = 0000000
			}
		},

		SmallMonster = { -- `rigType` of "SmallMonster"
			HardMode = {
				Attack1 = 0000000,
				Attack2 = 0000000
			},
			EasyMode = {
				Attack1 = 0000000,
				Attack2 = 0000000
			}
		}
	}
	```
]=]

--[=[
	@tag Read Only
	@class AnimationIds

	:::note
	Roblox model path: `Animations.Deps.AnimationIds`
	:::
]=]
local AnimationIds = {

}

return AnimationIds :: Types.AnimationIdsType