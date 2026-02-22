local function HasProperties(
	animationId: number | {},
	propertiesSettings: {
		Priority: Enum.AnimationPriority?,
		Looped: boolean?,
		StartSpeed: number?,
		MarkerTimes: boolean?,
		DoUnpack: boolean?
	}
): {}
	local doUnpack = propertiesSettings.DoUnpack
	propertiesSettings.DoUnpack = nil

	if type(animationId) == "table" then
		animationId._doUnpack = doUnpack
		animationId._runtimeProps = propertiesSettings

		return animationId
	else
		return {
			_runtimeProps = propertiesSettings,
			_singleAnimationId = animationId
		}
	end
end

--[=[
	@type rigType string
	@within AnimationIds

	The first key in the `AnimationIds` module that indicates the type of rig the paired animation id table belongs to.

	```lua
	local AnimationIds = {
		Player = { -- rigType of "Player"
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
	The only preset `rigType` is that of `"Player"` for all player animation ids.
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
	@interface propertiesSettings
	@within AnimationIds
	.Priority Enum.AnimationPriority?
	.Looped boolean?
	.StartSpeed number? -- Auto set animation speed through [`Animations:PlayTrack()`](/api/AnimationsServer#PlayTrack) related methods
	.DoUnpack boolean? -- Set the key-value pairs of [`animationId`](#HasProperties) (if it's a table) *in the parent table*
	.MarkerTimes boolean? -- Support [`Animations:GetTimeOfMarker()`](/api/AnimationsServer#GetTimeOfMarker)
]=]

--[=[
	@type HasProperties (animationId: idTable, propertiesSettings: propertiesSettings): {}
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
	Roblox model path: `Animations\Deps\AnimationIds`
	:::
]=]
local AnimationIds = {
	Player = {
		
	}
}

return AnimationIds