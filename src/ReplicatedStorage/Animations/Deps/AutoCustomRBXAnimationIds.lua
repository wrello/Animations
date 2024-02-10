local Types = require(script.Parent.Parent.Package.Util.Types)

--[=[
	@tag Read Only
	@tag Server Only
	@class AutoCustomRBXAnimationIds

	:::note
	Roblox model path: `Animations.Deps.AutoCustomRBXAnimationIds`
	:::

	A table of animation ids to apply to player character's animate script, replacing default roblox animation ids on spawn if [`EnableAutoCustomRBXAnimationIds`](/api/AnimationsServer#EnableAutoCustomRBXAnimationIds) is enabled.

	```lua
	-- All optional number values
	local AutoCustomRBXAnimationIds = {
		[Enum.HumanoidRigType.R6] = { -- [string]: number? | { [string]: number? }
			run = nil,
			walk = nil,
			jump = nil,
			idle = {
				Animation1 = nil,
				Animation2 = nil
			},
			fall = nil,
			swim = nil,
			swimIdle = nil,
			climb = nil
		},
		[Enum.HumanoidRigType.R15] = { -- [string]: number? | { [string]: number? }
			run = nil,
			walk = nil,
			jump = nil,
			idle = {
				Animation1 = nil,
				Animation2 = nil
			},
			fall = nil,
			swim = nil,
			swimIdle = nil,
			climb = nil
		}
	}
	```

	:::caution
	You should not delete the `key = nil` key-value pairs. They are meant to stay for ease of modification.
	:::
]=]
local AutoCustomRBXAnimationIds = {
	[Enum.HumanoidRigType.R6] = {
		run = nil,
		walk = nil,
		jump = nil,
		idle = {
			Animation1 = nil,
			Animation2 = nil
		},
		fall = nil,
		swim = nil,
		swimIdle = nil,
		climb = nil
	},
	[Enum.HumanoidRigType.R15] = {
		run = nil,
		walk = nil,
		jump = nil,
		idle = {
			Animation1 = nil,
			Animation2 = nil
		},
		fall = nil,
		swim = nil,
		swimIdle = nil,
		climb = nil
	}
}

return AutoCustomRBXAnimationIds :: Types.CustomRBXAnimationIdsType