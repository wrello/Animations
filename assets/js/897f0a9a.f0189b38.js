"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[147],{5214:t=>{t.exports=JSON.parse('{"functions":[],"properties":[],"types":[{"name":"rigType","desc":"The first key in the `AnimationIds` module that indicates the type of rig the paired animation id table belongs to.\\n\\n```lua\\nlocal AnimationIds = {\\n\\tPlayer = { -- `rigType` of \\"Player\\"\\n\\t\\tDodge = {\\n\\t\\t\\t[Enum.KeyCode.W] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.S] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.A] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.D] = 0000000,\\n\\t\\t},\\n\\t\\tRun = 0000000,\\n\\t\\tWalk = 0000000,\\n\\t\\tIdle = 0000000\\n\\t}\\n}\\n```\\n\\n:::info\\nThe only preset `rigType` is that of **\\"Player\\"** for all player/client animation ids.\\n:::","lua_type":"string","source":{"line":33,"path":"src/ReplicatedStorage/Animations/Deps/AnimationIds.lua"}},{"name":"animationId","desc":"","lua_type":"number","source":{"line":38,"path":"src/ReplicatedStorage/Animations/Deps/AnimationIds.lua"}},{"name":"idTable","desc":"","fields":[{"name":"[any]","lua_type":"idTable | animationId","desc":""}],"source":{"line":44,"path":"src/ReplicatedStorage/Animations/Deps/AnimationIds.lua"}},{"name":"HasProperties","desc":":::tip *added in version 2.0.0*\\n:::\\n\\n:::caution *changed in version 2.1.0*\\nAdded `MarkerTimes` property.\\n\\nLook at [`Animations:GetTimeOfMarker()`](/api/AnimationsServer#GetTimeOfMarker) for more information.\\n:::\\n\\n```lua\\nlocal AnimationIds = {\\n\\tPlayer = { -- `rigType` of \\"Player\\"\\n\\t\\tDodge = {\\n\\t\\t\\t[Enum.KeyCode.W] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.S] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.A] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.D] = 0000000,\\n\\t\\t},\\n\\t\\tRun = 0000000,\\n\\t\\tWalk = 0000000,\\n\\t\\tIdle = 0000000,\\n\\t\\tSword = {\\n\\t\\t\\t-- Now when the \\"Sword.Walk\\" animation plays it will\\n\\t\\t\\t-- automatically have `Enum.AnimationPriority.Action` priority\\n\\t\\t\\tWalk = HasProperties(0000000, { Priority = Enum.AnimationPriority.Action })\\n\\n\\t\\t\\tIdle = 0000000,\\n\\t\\t\\tRun = 0000000,\\n\\n            -- Now when {\\"Sword\\", \\"AttackCombo\\", 1 or 2 or 3} animation\\n            -- plays it will automatically have `Enum.AnimationPriority.Action` priority and\\n\\t\\t\\t-- will support `Animations:GetTimeOfMarker()`\\n\\t\\t\\tAttackCombo = HasProperties({\\n\\t\\t\\t\\t[1] = 0000000,\\n\\t\\t\\t\\t[2] = 0000000,\\n\\t\\t\\t\\t[3] = 0000000\\n\\t\\t\\t}, { Priority = Enum.AnimationPriority.Action, MarkerTimes = true })\\n\\t\\t}\\n\\t},\\n}\\n```","lua_type":"(animationId: idTable, propertiesSettings: {Priority: Enum.AnimationPriority?, Looped: boolean?, DoUnpack: boolean?, MarkerTimes: boolean?}): {}","source":{"line":91,"path":"src/ReplicatedStorage/Animations/Deps/AnimationIds.lua"}},{"name":"HasAnimatedObject","desc":"```lua\\nlocal AnimationIds = {\\n\\tPlayer = { -- `rigType` of \\"Player\\"\\n\\t\\tDodge = {\\n\\t\\t\\t[Enum.KeyCode.W] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.S] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.A] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.D] = 0000000,\\n\\t\\t},\\n\\t\\tRun = 0000000,\\n\\t\\tWalk = 0000000,\\n\\t\\tIdle = 0000000,\\n\\t\\tSword = {\\n\\t\\t\\t-- Now when the \\"Sword.Walk\\" animation plays \\"Sword\\" will\\n\\t\\t\\t-- auto attach to the player and get animated\\n\\t\\t\\tWalk = HasAnimatedObject(0000000, \\"Sword\\", { AutoAttach = true })\\n\\n\\t\\t\\tIdle = 0000000,\\n\\t\\t\\tRun = 0000000,\\n\\n\\t\\t\\t-- Now when {\\"Sword\\", \\"AttackCombo\\", 1 or 2 or 3} animation\\n\\t\\t\\t-- plays \\"Sword\\" will auto attach to the player and get\\n\\t\\t\\t-- animated\\n\\t\\t\\tAttackCombo = HasAnimatedObject({\\n\\t\\t\\t\\t[1] = 0000000,\\n\\t\\t\\t\\t[2] = 0000000,\\n\\t\\t\\t\\t[3] = 0000000\\n\\t\\t\\t}, \\"Sword\\", { AutoAttach = true })\\n\\t\\t}\\n\\t},\\n}\\n```\\n\\n:::info\\nFor more information on setting up animated objects check out [animated objects tutorial](/docs/animated-objects).\\n:::","lua_type":"(animationId: idTable, animatedObjectPath: path, animatedObjectSettings: {AutoAttach: boolean?, AutoDetach: boolean?, DoUnpack: boolean?}): {}","tags":["Beta"],"source":{"line":134,"path":"src/ReplicatedStorage/Animations/Deps/AnimationIds.lua"}},{"name":"AnimationIds","desc":"```lua\\nlocal AnimationIds = {\\n\\tPlayer = { -- `rigType` of \\"Player\\"\\n\\t\\tDodge = {\\n\\t\\t\\t[Enum.KeyCode.W] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.S] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.A] = 0000000,\\n\\t\\t\\t[Enum.KeyCode.D] = 0000000,\\n\\t\\t},\\n\\t\\tRun = 0000000,\\n\\t\\tWalk = 0000000,\\n\\t\\tIdle = 0000000\\n\\t},\\n\\n\\tBigMonster = { -- `rigType` of \\"BigMonster\\"\\n\\t\\tHardMode = {\\n\\t\\t\\tAttack1 = 0000000,\\n\\t\\t\\tAttack2 = 0000000\\n\\t\\t},\\n\\t\\tEasyMode = {\\n\\t\\t\\tAttack1 = 0000000,\\n\\t\\t\\tAttack2 = 0000000\\n\\t\\t}\\n\\t},\\n\\n\\tSmallMonster = { -- `rigType` of \\"SmallMonster\\"\\n\\t\\tHardMode = {\\n\\t\\t\\tAttack1 = 0000000,\\n\\t\\t\\tAttack2 = 0000000\\n\\t\\t},\\n\\t\\tEasyMode = {\\n\\t\\t\\tAttack1 = 0000000,\\n\\t\\t\\tAttack2 = 0000000\\n\\t\\t}\\n\\t}\\n}\\n```","fields":[{"name":"[rigType]","lua_type":"idTable","desc":""}],"source":{"line":178,"path":"src/ReplicatedStorage/Animations/Deps/AnimationIds.lua"}}],"name":"AnimationIds","desc":":::note\\nRoblox model path: `Animations.Deps.AnimationIds`\\n:::","tags":["Read Only"],"source":{"line":187,"path":"src/ReplicatedStorage/Animations/Deps/AnimationIds.lua"}}')}}]);