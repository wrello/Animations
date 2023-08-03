local Types = require(script.Parent.Parent.Package.Util.Types)

--[=[
	@interface AutoCustomRBXAnimationIds
	@within AutoCustomRBXAnimationIds
	.run number?
	.walk number?
	.jump number?
	.idle {Animation1: number?, Animation2: number?}?
	.fall number?
	.swim number?
	.swimIdle number?
	.climb number?
	
	A table of animation ids to apply to player character's animate script, replacing default roblox animation ids.
]=]
type AutoCustomRBXAnimationIdsType = Types.AutoCustomRBXAnimationIdsType

--[=[
	@tag Read Only
	@class AutoCustomRBXAnimationIds

	A table of animation ids to apply to player character's animate script, replacing default roblox animation ids.
]=]
local AutoCustomRBXAnimationIds = {
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

return AutoCustomRBXAnimationIds :: AutoCustomRBXAnimationIdsType