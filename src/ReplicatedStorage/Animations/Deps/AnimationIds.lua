local Types = require(script.Parent.Parent.Package.Util.Types)

--[=[
	@type rigType string
	@within AnimationIds
	
	This is the first step to accessing or loading animation tracks from the client or server.
	
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
	@interface AnimationIds
	@within AnimationIds
	.[rigType] idTable

	```lua
	local AnimationIds = {
		Player = {
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
		
		Monster = {
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
type AnimationIdsType = Types.AnimationIdsType

--[=[
	@tag Read Only
	@class AnimationIds
]=]
local AnimationIds = {}

return AnimationIds :: AnimationIdsType