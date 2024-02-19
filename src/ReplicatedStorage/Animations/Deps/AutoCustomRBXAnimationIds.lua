local Types = require(script.Parent.Parent.Package.Util.Types)

--[=[
	@interface customRBXAnimationIds
	@within AutoCustomRBXAnimationIds
	.run number?
	.walk number?
	.jump number?
	.idle {Animation1: number?, Animation2: number?}?
	.fall number?
	.swim number?
	.swimIdle number?
	.climb number?
	
	A table of animation ids to replace the default roblox animation ids.
	
	:::info
	Roblox applies the `"walk"` animation id for `R6` characters and the `"run"` animation id for `R15` characters (instead of both).
	:::
]=]

--[=[
	@interface humanoidRigTypeToCustomRBXAnimationIds
	@within AutoCustomRBXAnimationIds
	.[Enum.HumanoidRigType.R6] customRBXAnimationIds?
	.[Enum.HumanoidRigType.R15] customRBXAnimationIds?
	
	A table mapping a humanoid rig type to its supported animation ids that will replace the default roblox animation ids.
]=]

--[=[
	@tag Read Only
	@server
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
	
	:::info
	Roblox applies the `"walk"` animation id for `R6` characters and the `"run"` animation id for `R15` characters (instead of both).
	:::

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

return AutoCustomRBXAnimationIds :: Types.HumanoidRigTypeToCustomRBXAnimationIdsType