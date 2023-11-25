"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[292],{44097:a=>{a.exports=JSON.parse('{"functions":[{"name":"Init","desc":"Initializes `AnimationsClient`. Yields if [`AnimationsClient.AutoLoadTracks`](#AutoLoadTracks) is set to true and the player\'s character already exists.\\n\\n:::info\\nShould be called once before any other method.\\n:::","params":[{"name":"initOptions","desc":"","lua_type":"initOptions?"}],"returns":[],"function_type":"method","yields":true,"source":{"line":93,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"AwaitLoaded","desc":"Yields until the client animation tracks have loaded.","params":[],"returns":[],"function_type":"method","yields":true,"source":{"line":158,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"AwaitRigLoaded","desc":"Yields until the rig animation tracks have loaded.","params":[{"name":"rig","desc":"","lua_type":"Model"}],"returns":[],"function_type":"method","yields":true,"source":{"line":166,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"AreTracksLoaded","desc":"Returns if the client has had its animation tracks loaded.","params":[],"returns":[{"desc":"","lua_type":"boolean"}],"function_type":"method","source":{"line":174,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"AreRigTracksLoaded","desc":"Returns if the rig has had its animation tracks loaded.","params":[{"name":"rig","desc":"","lua_type":"Model"}],"returns":[{"desc":"","lua_type":"boolean"}],"function_type":"method","source":{"line":182,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"LoadTracks","desc":"Yields while client animation tracks load.\\n\\n:::tip\\nAutomatically gives the rig (the player\'s character) an attribute `AnimationsRigType` set to the given [`rigType`](/api/AnimationIds#rigType) (which is \\"Player\\" in this case).\\n:::","params":[],"returns":[],"function_type":"method","yields":true,"source":{"line":194,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"LoadRigTracks","desc":"Yields while the rig animation tracks load.\\n\\n:::tip\\nAutomatically gives the rig an attribute `AnimationsRigType` set to the given [`rigType`](/api/AnimationIds#rigType).\\n:::","params":[{"name":"rig","desc":"","lua_type":"Model"},{"name":"rigType","desc":"","lua_type":"string"}],"returns":[],"function_type":"method","yields":true,"source":{"line":207,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"GetTrack","desc":"Returns a client animation track or nil.","params":[{"name":"path","desc":"","lua_type":"path"}],"returns":[{"desc":"","lua_type":"AnimationTrack?"}],"function_type":"method","source":{"line":216,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"GetRigTrack","desc":"Returns a rig animation track or nil.","params":[{"name":"rig","desc":"","lua_type":"Model"},{"name":"path","desc":"","lua_type":"path"}],"returns":[{"desc":"","lua_type":"AnimationTrack?"}],"function_type":"method","source":{"line":225,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"PlayTrack","desc":"Returns a playing client animation track.","params":[{"name":"path","desc":"","lua_type":"path"},{"name":"fadeTime","desc":"","lua_type":"number?"},{"name":"weight","desc":"","lua_type":"number?"},{"name":"speed","desc":"","lua_type":"number?"}],"returns":[{"desc":"","lua_type":"AnimationTrack"}],"function_type":"method","source":{"line":237,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"PlayRigTrack","desc":"Returns a playing rig animation track.","params":[{"name":"rig","desc":"","lua_type":"Model"},{"name":"path","desc":"","lua_type":"path"},{"name":"fadeTime","desc":"","lua_type":"number?"},{"name":"weight","desc":"","lua_type":"number?"},{"name":"speed","desc":"","lua_type":"number?"}],"returns":[{"desc":"","lua_type":"AnimationTrack"}],"function_type":"method","source":{"line":249,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"StopTrack","desc":"Returns a stopped client animation track.","params":[{"name":"path","desc":"","lua_type":"path"},{"name":"fadeTime","desc":"","lua_type":"number?"}],"returns":[{"desc":"","lua_type":"AnimationTrack"}],"function_type":"method","source":{"line":259,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"StopRigTrack","desc":"Returns a stopped rig animation track.","params":[{"name":"rig","desc":"","lua_type":"Model"},{"name":"path","desc":"","lua_type":"path"},{"name":"fadeTime","desc":"","lua_type":"number?"}],"returns":[{"desc":"","lua_type":"AnimationTrack"}],"function_type":"method","source":{"line":269,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"GetTrackFromAlias","desc":"Returns a client animation track or nil.","params":[{"name":"alias","desc":"","lua_type":"any"}],"returns":[{"desc":"","lua_type":"AnimationTrack?"}],"function_type":"method","source":{"line":278,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"GetRigTrackFromAlias","desc":"Returns a rig animation track or nil.","params":[{"name":"rig","desc":"","lua_type":"Model"},{"name":"alias","desc":"","lua_type":"any"}],"returns":[{"desc":"","lua_type":"AnimationTrack?"}],"function_type":"method","source":{"line":287,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"PlayTrackFromAlias","desc":"Returns a playing client animation track.","params":[{"name":"alias","desc":"","lua_type":"any"},{"name":"fadeTime","desc":"","lua_type":"number?"},{"name":"weight","desc":"","lua_type":"number?"},{"name":"speed","desc":"","lua_type":"number?"}],"returns":[{"desc":"","lua_type":"AnimationTrack"}],"function_type":"method","source":{"line":299,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"PlayRigTrackFromAlias","desc":"Returns a playing rig animation track.","params":[{"name":"rig","desc":"","lua_type":"Model"},{"name":"alias","desc":"","lua_type":"any"},{"name":"fadeTime","desc":"","lua_type":"number?"},{"name":"weight","desc":"","lua_type":"number?"},{"name":"speed","desc":"","lua_type":"number?"}],"returns":[{"desc":"","lua_type":"AnimationTrack"}],"function_type":"method","source":{"line":311,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"StopTrackFromAlias","desc":"Returns a stopped client animation track.","params":[{"name":"alias","desc":"","lua_type":"any"},{"name":"fadeTime","desc":"","lua_type":"number?"}],"returns":[{"desc":"","lua_type":"AnimationTrack"}],"function_type":"method","source":{"line":321,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"StopRigTrackFromAlias","desc":"Returns a stopped rig animation track.","params":[{"name":"rig","desc":"","lua_type":"Model"},{"name":"alias","desc":"","lua_type":"any"},{"name":"fadeTime","desc":"","lua_type":"number?"}],"returns":[{"desc":"","lua_type":"AnimationTrack"}],"function_type":"method","source":{"line":331,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"SetTrackAlias","desc":"Sets an alias to be the equivalent of the given path for a client animation track.\\n\\n:::tip\\nYou can use the alias as the last key in the path. Useful for a table of animations. Example:\\n\\n```lua\\n-- In ReplicatedStorage.Animations.Deps.AnimationIds\\nlocal animationIds = {\\n\\tPlayer = {\\n\\t\\tFistsCombat = {\\n\\t\\t\\t-- Fists 3 hit combo\\n\\t\\t\\tCombo = {\\n\\t\\t\\t\\t[1] = 1234567,\\n\\t\\t\\t\\t[2] = 1234567,\\n\\t\\t\\t\\t[3] = 1234567\\n\\t\\t\\t},\\n\\n\\t\\t\\t-- Fists heavy attack\\n\\t\\t\\tHeavyAttack = 1234567\\n\\t\\t},\\n\\n\\t\\tSwordCombat = {\\n\\t\\t\\t-- Sword 3 hit combo\\n\\t\\t\\tCombo = {\\n\\t\\t\\t\\t[1] = 1234567,\\n\\t\\t\\t\\t[2] = 1234567,\\n\\t\\t\\t\\t[3] = 1234567\\n\\t\\t\\t},\\n\\n\\t\\t\\t-- Sword heavy attack\\n\\t\\t\\tHeavyAttack = 1234567\\n\\t\\t}\\n\\t}\\n}\\n```\\n\\n```lua\\n-- In a LocalScript\\n\\n-- After the client\'s animation tracks are loaded...\\n\\nlocal heavyAttackAlias = \\"HeavyAttack\\" -- We want this alias in order to call Animations:PlayTrackFromAlias(heavyAttackAlias) regardless what weapon is equipped\\n\\nlocal currentEquippedWeapon\\n\\nlocal function updateHeavyAttackAliasPath()\\n\\tlocal alias = heavyAttackAlias\\n\\tlocal path = currentEquippedWeapon .. \\"Combat\\"\\n\\n\\tAnimations:SetTrackAlias(alias, path) -- Running this will search first \\"path.alias\\" and then search \\"path\\" if it didn\'t find \\"path.alias\\"\\nend\\n\\nlocal function equipNewWeapon(weaponName)\\n\\tcurrentEquippedWeapon = weaponName\\n\\n\\tupdateHeavyAttackAliasPath()\\nend\\n\\nequipNewWeapon(\\"Fists\\")\\n\\nAnimations:PlayTrackFromAlias(heavyAttackAlias) -- Plays \\"FistsCombat.HeavyAttack\\" on the client\'s character\\n\\nequipNewWeapon(\\"Sword\\")\\n\\nAnimations:PlayTrackFromAlias(heavyAttackAlias) -- Plays \\"SwordCombat.HeavyAttack\\" on the client\'s character\\n```\\n:::","params":[{"name":"alias","desc":"","lua_type":"any"},{"name":"path","desc":"","lua_type":"path"}],"returns":[],"function_type":"method","source":{"line":406,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"SetRigTrackAlias","desc":"Sets an alias to be the equivalent of the given path for a rig animation track.\\n\\n:::tip\\nSame tip for [`Animations:SetTrackAlias()`](#SetTrackAlias) applies here.\\n:::","params":[{"name":"rig","desc":"","lua_type":"Model"},{"name":"alias","desc":"","lua_type":"any"},{"name":"path","desc":"","lua_type":"path"}],"returns":[],"function_type":"method","source":{"line":419,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"RemoveTrackAlias","desc":"Removes the alias for a client animation track.","params":[{"name":"alias","desc":"","lua_type":"any"}],"returns":[],"function_type":"method","source":{"line":427,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"RemoveRigTrackAlias","desc":"Removes the alias for a rig animation track.","params":[{"name":"rig","desc":"","lua_type":"Model"},{"name":"alias","desc":"","lua_type":"any"}],"returns":[],"function_type":"method","source":{"line":435,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}}],"properties":[{"name":"AutoLoadPlayerTracks","desc":"If set to true, client animation tracks will be loaded each time the client spawns.\\n\\n:::warning\\nMust have animation ids under [`rigType`](/api/AnimationIds#rigType) of **\\"Player\\"** in the [`AnimationIds`](/api/AnimationIds) module.\\n:::","lua_type":"false","source":{"line":69,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"TimeToLoadPrints","desc":"If set to true, prints will be made on each call to [`AnimationsClient:LoadTracks()`](#LoadTracks) to indicate the start, stop and elapsed time of pre-loading the client animation tracks.\\n\\n:::caution\\nIt is suggested to keep this as true because a lot of client animation tracks results in a significant yield time which is difficult to debug if forgotten.\\n:::","lua_type":"true","source":{"line":81,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}}],"types":[{"name":"initOptions","desc":"Gets applied to [`Properties`](#properties).","fields":[{"name":"AutoLoadPlayerTracks","lua_type":"boolean","desc":"Defaults to false"},{"name":"TimeToLoadPrints","lua_type":"boolean","desc":"Defaults to true (on the client)"}],"source":{"line":21,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}},{"name":"path","desc":"```lua\\nlocal Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsClient)\\n\\n\\n-- These are all valid options for retrieving an animation track\\nlocal animationPath = \\"Jump\\" -- A single key (any type)\\n\\nlocal animationPath = {\\"Dodge\\", Vector3.xAxis} -- An array path (values of any type)\\n\\nlocal animationPath = \\"Climb.Right\\" -- A path seperated by \\".\\" (string)\\n\\n\\nlocal animationTrack = Animations:GetTrack(animationPath)\\n```","lua_type":"any","source":{"line":42,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}}],"name":"AnimationsClient","desc":":::note\\nRoblox model path: `Animations.Package.AnimationsClient`\\n:::\\n\\n:::info\\nAny reference to \\"client animation tracks\\" is referring to animation ids found under [`rigType`](/api/AnimationIds#rigType) of **\\"Player\\"** in the [`AnimationIds`](/api/AnimationIds) module\\n:::","realm":["Client"],"source":{"line":57,"path":"src/ReplicatedStorage/Animations/Package/AnimationsClient.lua"}}')}}]);