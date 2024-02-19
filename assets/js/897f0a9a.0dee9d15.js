"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[147],{5214:t=>{t.exports=JSON.parse('{"functions":[],"properties":[],"types":[{"name":"rigType","desc":"The first key in the `AnimationIds` module that indicates the type of rig the paired animation id table belongs to.\\n\\n```lua\\nlocal AnimationIds = {\\n\\tPlayer = { -- `rigType` of \\"Player\\"\\n\\t\\tDodge = {\\n\\t\\t\\t[Enum.KeyCode.W] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.S] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.A] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.D] = 0000000,\\n\\t\\t},\\n\\t\\tRun = 0000000,\\n\\t\\tWalk = 0000000,\\n\\t\\tIdle = 0000000\\n\\t}\\n}\\n```\\n\\n:::info\\nThe only preset `rigType` is that of **\\"Player\\"** for all player/client animation ids.\\n:::","lua_type":"string","source":{"line":30,"path":"src/ReplicatedStorage/Animations/Deps/AnimationIds.lua"}},{"name":"animationId","desc":"","lua_type":"number","source":{"line":35,"path":"src/ReplicatedStorage/Animations/Deps/AnimationIds.lua"}},{"name":"idTable","desc":"","fields":[{"name":"[any]","lua_type":"idTable | animationId","desc":""}],"source":{"line":41,"path":"src/ReplicatedStorage/Animations/Deps/AnimationIds.lua"}},{"name":"HasAnimatedObject","desc":"```lua\\nlocal AnimationIds = {\\n\\tPlayer = { -- `rigType` of \\"Player\\"\\n\\t\\tDodge = {\\n\\t\\t\\t[Enum.KeyCode.W] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.S] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.A] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.D] = 0000000,\\n\\t\\t},\\n\\t\\tRun = 0000000,\\n\\t\\tWalk = 0000000,\\n\\t\\tIdle = 0000000,\\n\\t\\tSword = {\\n\\t\\t\\tWalk = HasAnimatedObject(0000000, \\"Sword\\", { RunContext = \\"Client\\", AutoAttach = true }) -- Now when the \\"Sword.Walk\\" animation plays on the client \\"Sword\\" will auto attach to the player and get animated\\n\\t\\t\\tIdle = 0000000,\\n\\t\\t\\tRun = 0000000,\\n\\t\\t\\tAttackCombo = HasAnimatedObject({\\n\\t\\t\\t\\t[1] = 0000000,\\n\\t\\t\\t\\t[2] = 0000000,\\n\\t\\t\\t\\t[3] = 0000000\\n\\t\\t\\t}, \\"Sword\\", { RunContext = \\"Client\\", AutoAttach = true }) -- Now when {\\"Sword\\", \\"AttackCombo\\", 1 or 2 or 3} animation plays \\"Sword\\" will auto attach to the player and get animated\\n\\t\\t}\\n\\t},\\n}\\n```\\n\\n:::info\\nFor more information on setting up animated objects check out [animated objects tutorial](/docs/animated-objects).\\n:::","lua_type":"(animationId: number | {}, animatedObjectPath: {any} | string, autoAttachDetachSettings: {RunContext: \\"Client\\" | \\"Server\\", AutoAttach: boolean?, AutoDetach: boolean?}?): {}","tags":["Beta"],"source":{"line":77,"path":"src/ReplicatedStorage/Animations/Deps/AnimationIds.lua"}},{"name":"AnimationIds","desc":"```lua\\nlocal AnimationIds = {\\n\\tPlayer = { -- `rigType` of \\"Player\\"\\n\\t\\tDodge = {\\n\\t\\t\\t[Enum.KeyCode.W] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.S] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.A] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.D] = 0000000,\\n\\t\\t},\\n\\t\\tRun = 0000000,\\n\\t\\tWalk = 0000000,\\n\\t\\tIdle = 0000000\\n\\t},\\n\\t\\n\\tBigMonster = { -- `rigType` of \\"BigMonster\\"\\n\\t\\tHardMode = {\\n\\t\\t\\tAttack1 = 0000000,\\n\\t\\t\\tAttack2 = 0000000\\n\\t\\t},\\n\\t\\tEasyMode = {\\n\\t\\t\\tAttack1 = 0000000,\\n\\t\\t\\tAttack2 = 0000000\\n\\t\\t}\\n\\t},\\n\\t\\n\\tSmallMonster = { -- `rigType` of \\"SmallMonster\\"\\n\\t\\tHardMode = {\\n\\t\\t\\tAttack1 = 0000000,\\n\\t\\t\\tAttack2 = 0000000\\n\\t\\t},\\n\\t\\tEasyMode = {\\n\\t\\t\\tAttack1 = 0000000,\\n\\t\\t\\tAttack2 = 0000000\\n\\t\\t}\\n\\t}\\n}\\n```","fields":[{"name":"[rigType]","lua_type":"idTable","desc":""}],"source":{"line":121,"path":"src/ReplicatedStorage/Animations/Deps/AnimationIds.lua"}}],"name":"AnimationIds","desc":":::note\\nRoblox model path: `Animations.Deps.AnimationIds`\\n:::","tags":["Read Only"],"source":{"line":130,"path":"src/ReplicatedStorage/Animations/Deps/AnimationIds.lua"}}')}}]);