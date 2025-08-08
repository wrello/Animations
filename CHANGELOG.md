## v2.5.1
> ###### 8/7/2025
----

- Fixes
    - Fixed animations freezing when [`Animations:ApplyAnimationProfile()`](/api/AnimationsServer#ApplyAnimationProfile) was called mid free fall.
    - Improved the animation stutter caused by [`Animations:ApplyAnimationProfile()`](/api/AnimationsServer#ApplyAnimationProfile) by removing an uncessary `RunService.Stepped:Wait()`.

## v2.5.0
> ###### 7/9/2025
----
- Enhancements
    - Improved preload async time by preloading animations concurrently.

## v2.4.0
> ###### 5/28/2025
----
- Enhancements
    - Added [basic usage monster/npc tutorial](/docs/basic-usage-monster-npc)
    - **[Beta]** Added [`AnimationsServer:EquipAnimatedTool()`](/api/AnimationsServer#EquipAnimatedTool). [Issue #73](https://github.com/wrello/Animations/issues/73)
    - **[Beta]** You can now set a custom tool name(s) for "motor6d only" animated objects. Learn about this in the [animated objects tutorial](/docs/animated-objects#motor6d-only-toolname-module). [Issue #73](https://github.com/wrello/Animations/issues/73)
    - Added an infinite yield warning if animator is not descendant of game for too long. [Issue #74](https://github.com/wrello/Animations/issues/74)
- Changes (breaking)
    - **[Beta]** You can no longer use [`Animations:AttachAnimatedObject()`](/api/AnimationsServer#AttachAnimatedObject) with a single motor6d. This is because after equipping a tool with `humanoid:EquipTool()`, the tool will most likely not immediately be parented to the character ([Roblox quirk that is discussed here](https://devforum.roblox.com/t/tools-new-parent-is-delayed-when-using-humanoidequiptool-potential-studio-bug/3667271)), so [`Animations:AttachAnimatedObject()`](/api/AnimationsServer#AttachAnimatedObject) will fail to attach the motor6d.
- Fixes
    - Fixed an issue where auto attaching of animated objects would fail due to mismatched animation ids.

## v2.3.0
> ###### 4/3/2025

----

- Enhancements
    - Added `StartSpeed` to [`HasProperties`](/api/AnimationIds#HasProperties) and corresponding [`Animations:GetTrackStartSpeed()`](/api/AnimationsServer#GetTrackStartSpeed) method. [Issue #70](https://github.com/wrello/Animations/issues/70)
    - Added better documentation for [`HasProperties`](/api/AnimationIds#propertiesSettings) and [`HasAnimatedObject`](/api/AnimationIds#animatedObjectSettings).
    - Added code example for [`AnimationsClient:PlayRigTrack()`](/api/AnimationsClient#PlayRigTrack).

## v2.2.0
> ###### 3/21/2025

----

- Enhancements
    - Added pesde support.
    - Added better Wally support. You can now require `Animations` like so (if installed as a Wally dependency): 
    ```lua
    local Animations = require(game.ReplicatedStorage.Packages.Animations)
    ```
    [Issue #67](https://github.com/wrello/Animations/issues/67)
    - Switched to using [`LemonSignal`](https://github.com/Data-Oriented-House/LemonSignal) for better stability and performance. [Issue #69](https://github.com/wrello/Animations/issues/69)


## v2.1.0
> ###### 12/27/2024

----

- Enhancements
    - Set animation track names to be the same as their source animation instance names for convenience.
    - Added [`Animations:WaitForRigPlayingTrack()`](/api/AnimationsServer/#WaitForRigPlayingTrack)/[`Animations:FindFirstRigPlayingTrack()`](/api/AnimationsServer/#FindFirstRigPlayingTrack). [Issue #62](https://github.com/wrello/Animations/issues/62)
    - **[Beta]** Added [`Animations:GetTimeOfMarker()`](/api/AnimationsServer/#GetTimeOfMarker). [Issue #64](https://github.com/wrello/Animations/issues/64)
    - Added [`Animations:GetAnimationIdString()`](/api/AnimationsServer/#GetAnimationIdString).


- Changes (non-breaking)
    - Removed `Animations.AutoRegisterPlayers` on client and server. Automatic registration will always happen through `player.CharacterAdded` events. This decision was made for convenience and to eliminate the redudancy with `Animations.AutoLoadAllPlayerTracks` which *also* automatically registers the players when their character gets added.


- Fixes
    - Utility module `ChildFromPath` bug. [Issue #59](https://github.com/wrello/Animations/issues/59)
    - Documentation fixes. [Issue #58](https://github.com/wrello/Animations/issues/58)


## v2.0.0
> ###### 8/24/2024

----

- Changes (breaking)
    - Changed method of requiring [`HasAnimatedObject()`](/api/AnimationIds/#HasAnimatedObject) function in [`AnimationIds`](/api/AnimationIds) module. After replacing the empty deps with your current ones, the directory structure should look like this:
```
Animations/ (new)
  Deps/ (mix)
    AnimationIds (new with copied table from old)
    AnimationProfiles (old)
    AnimatedObjects (old)
    AutoCustomRBXAnimationIds (old)
  Package/ (new)
    ...
```


- Ehancements
    - Added [`HasProperties()`](/api/AnimationIds/#HasProperties) function in [`AnimationIds`](/api/AnimationIds) module. [Issue #54](https://github.com/wrello/Animations/issues/54)
    - Added [`Animations:GetAppliedProfileName()`](/api/AnimationsServer/#GetAppliedProfileName). [Issue #53](https://github.com/wrello/Animations/issues/53)


- Fixes
    - Fixed [`AutoCustomRBXAnimationIds`](/api/AutoCustomRBXAnimationIds) not working. [Issue #55](https://github.com/wrello/Animations/issues/55)
    - Fixed waiting for `player.CharacterAdded` event that might never happen if `Players.CharacterAutoLoads` is disabled. [Issue #52](https://github.com/wrello/Animations/issues/52)
    - Fixed "Cannot load the AnimationClipProvider Service" error/bug. [Issue #51](https://github.com/wrello/Animations/issues/51)
    - Fixed documentation issues. [Issue #49](https://github.com/wrello/Animations/issues/49), [Issue #50](https://github.com/wrello/Animations/issues/50)


## v2.0.0-rc1
> ###### 7/25/2024

----

[Migrate to v2.0.0 guide](/docs/migrate-to-2.0.0)

- Changes (breaking)
    - Changed init option ~~`Animations.AutoLoadPlayerTracks`~~ -> to -> [`Animations.AutoLoadAllPlayerTracks`](/api/AnimationsServer/#AutoLoadAllPlayerTracks) in order to match the new [`Animations:LoadAllTracks()`](/api/AnimationsServer/#LoadAllTracks). [Issue #43](https://github.com/wrello/Animations/issues/43)
    - Changed ~~`Animations:LoadTracks`~~ -> to -> [`Animations:LoadAllTracks()`](/api/AnimationsServer/#LoadAllTracks). [Issue #43](https://github.com/wrello/Animations/issues/43)
    - Changed ~~`Animations:AwaitLoaded()`~~ -> to -> [`Animations:AwaitAllTracksLoaded()`](/api/AnimationsServer/#AwaitAllTracksLoaded). [Issue #43](https://github.com/wrello/Animations/issues/43)
    - Changed ~~`Animations:AreTracksLoaded()`~~ -> to -> [`Animations:AreAllTracksLoaded()`](/api/AnimationsServer/#AreAllTracksLoaded). [Issue #43](https://github.com/wrello/Animations/issues/43)
    - Changed ~~`Animations:StopAllTracks()`~~ -> to -> [`Animations:StopPlayingTracks()`](/api/AnimationsServer/#StopPlayingTracks) in order to match the new [`Animations:GetPlayingTracks()`](/api/AnimationsServer/#GetPlayingTracks). [Issue #42](https://github.com/wrello/Animations/issues/42)


- Enhancements
    - Wally support.
    - Added method [`Animations:AwaitPreloadAsyncFinished()`](/api/AnimationsServer/#AwaitPreloadAsyncFinished).
    - Added methods [`Animations:Register()`](/api/AnimationsServer/#Register)/[`Animations:AwaitRegistered()`](/api/AnimationsServer/#AwaitRegistered)/[`Animations:IsRegistered()`](/api/AnimationsServer/#IsRegistered). [Issue #43](https://github.com/wrello/Animations/issues/43)
    - Added methods [`Animations:LoadTracksAt()`](/api/AnimationsServer/#LoadTracksAt)/[`Animations:AwaitTracksLoadedAt()`](/api/AnimationsServer/#AwaitTracksLoadedAt)/[`Animations:AreTracksLoadedAt()`](/api/AnimationsServer/#AreTracksLoadedAt). [Issue #43](https://github.com/wrello/Animations/issues/43)
    - Added event [`Animations.PreloadAsyncProgressed`](/api/AnimationsServer/#PreloadAsyncProgressed).
    - Added init option [`Animations.DepsFolderPath`](/api/AnimationsServer/#DepsFolderPath). [Issue #46](https://github.com/wrello/Animations/issues/46)
    - Added [`Animations:GetPlayingTracks()`](/api/AnimationsServer/#GetPlayingTracks). [Issue #42](https://github.com/wrello/Animations/issues/42)
    - Added init option [`AnimationsClient.EnableAutoCustomRBXAnimationIds`](/api/AnimationsClient/#EnableAutoCustomRBXAnimationIds).
    - Added init option [`AnimationsClient.AutoRegisterPlayer`](/api/AnimationsClient/#AutoRegisterPlayer)/[`AnimationsServer.AutoRegisterPlayers`](/api/AnimationsServer/#AutoRegisterPlayers). [Issue #43](https://github.com/wrello/Animations/issues/43)
    

- Changes (non-breaking)
    - Changed init option [`AnimationsServer.TimeToLoadPrints`](/api/AnimationsServer/#TimeToLoadPrints) to default to `true` because it's important to realize that initialization can yield for quite some time during `ContentProvider:PreloadAsync()` on all animations in the [`AnimationIds`](/api/AnimationIds) module. [Issue #44](https://github.com/wrello/Animations/issues/44)


- Fixes
    - Fixed `ContentProvider:PreloadAsync()` being called every time tracks got loaded for a rig. [Issue #44](https://github.com/wrello/Animations/issues/44)
    - Fixed animations server editing players' animate scripts when it wasn't necessary. [Issue #45](https://github.com/wrello/Animations/issues/45)


- Notes
    - It was impossible to load tracks seperately with the `Animations:LoadTracks()` method. This is now possible and means that loading tracks could happen many times during one rig's lifetime forcing us to seperate registration into [`Animations:Register()`](/api/AnimationsServer/#Register) so that it only happens once before any track loading does.


## v2.0.0-alpha
> ###### 6/23/2024

----

- Changes (breaking)
    - **[Beta]** Changed the animated object specifier parameter of [`Animations:AttachAnimatedObject()`](/api/AnimationsServer/#AttachAnimatedObject) and [`Animations:DetachAnimatedObject()`](/api/AnimationsServer/#DetachAnimatedObject) to just a [`path`](/api/AnimationsServer/#path) type.
    - **[Beta]** Changed [`HasAnimatedObject()`](/api/AnimationIds/#HasAnimatedObject) *optional* parameter `autoAttachDetachSettings?` -> to -> *required* parameter `animatedObjectSettings`.


- Enhancements
    - Added [`Animations:StopAllTracks()`](/api/AnimationsServer/#StopAllTracks). [Issue #39](https://github.com/wrello/Animations/issues/39)
    - Added [`Animations:GetAnimationProfile()`](/api/AnimationsServer/#GetAnimationProfile). [Issue #29](https://github.com/wrello/Animations/issues/29)
    - Added information on the all too common [`"Animator.EvaluationThrottled"`](/docs/animator-error) error. [Issue #38](https://github.com/wrello/Animations/issues/38)
    - Added R6/R15 NPC support for [`Animations:ApplyCustomRBXAnimationIds()`](/api/AnimationsServer/#ApplyCustomRBXAnimationIds) and [`Animations:ApplyAnimationProfile()`](/api/AnimationsServer/#ApplyAnimationProfile) on client & server. There are caveats when using these, be sure to read documentation. [Issue #41](https://github.com/wrello/Animations/issues/41)
    - Added more clear usage description of [`animation profiles`](/docs/animation-profiles). [Issue #34](https://github.com/wrello/Animations/issues/34)
    - **[Beta]** Added optional parameter `DoUnpack?` for [`HasAnimatedObject()`](/api/AnimationIds/#HasAnimatedObject).
    - Added warning and yield until the server initializes in [`AnimationsClient:Init()`](/api/AnimationsClient/#Init). [Issue #37](https://github.com/wrello/Animations/issues/37)
    - [`AnimationsServer:LoadTracks()`](/api/AnimationsServer/#LoadTracks) now automatically applies `rigType` of `"Player"` if no `rigType` is specified and the `player_or_rig` is a player or player's character.
    - Rewrite of animated objects system (still in beta).


- Changes (non-breaking)
    - **[Beta]** Changed [`HasAnimatedObject()`](/api/AnimationIds/#HasAnimatedObject) to no longer require a `RunContext` in `autoAttachDetachSettings?` (which is now `animatedObjectSettings`). It will now automatically run on client & server. [Issue #31](https://github.com/wrello/Animations/issues/31)


- Fixes
    - Fixed memory leak associated with trusting that the `Player.Character.Destroying` event would fire when a character model got removed from the game.
    - Fixed [`"Animator.EvaluationThrottled"`](/docs/animator-error) error caused by [`Animations.TimeToLoadPrints`](/api/AnimationsServer/#initOptions).
    - Fixed problem with string paths involving utility function `GetChildFromPath()`. [Issue #40](https://github.com/wrello/Animations/issues/40) 
    - Fixed auto detach of animated objects being bugged. [Issue #36](https://github.com/wrello/Animations/issues/36)
    - Fixed right grip weld not getting disabled for multiple animated object equips. [Issue #30](https://github.com/wrello/Animations/issues/30)
    - Fixed animation ids not being able to attach to multiple animated objects. [Issue #32](https://github.com/wrello/Animations/issues/32)
    - Fixed incorrect type for [`AnimationsServer:StopTracksOfPriority()`](/api/AnimationsServer/#StopTracksOfPriority). [Issue #33](https://github.com/wrello/Animations/issues/33)
    - Fixed documentation mistakes. [Issue #35](https://github.com/wrello/Animations/issues/35)

## v1.3.0
> ###### 5/6/2024

----

- Enhancements
    - Added [`animation profiles`](docs/animation-profiles). [Issue #22](https://github.com/wrello/Animations/issues/22)
    - Added [`Animations:StopTracksOfPriority()`](/api/AnimationsServer/#StopTracksOfPriority). [Issue #26](https://github.com/wrello/Animations/issues/26)
    - Errors if no "animator parent" (`Humanoid` or `AnimationController`) exists in the rig. [Issue #27](https://github.com/wrello/Animations/issues/27)


- Fixes
    - Fixed calling `Humanoid:ChangeState()` when it shouldn't be called. [Issue #28](https://github.com/wrello/Animations/issues/28)
    - Fixed no documentation on [`AnimationsClient:DetachAnimatedObject()`](/api/AnimationsClient/#DetachAnimatedObject). [Issue #25](https://github.com/wrello/Animations/issues/25)
    - Fixed basic usage document mistakes. [Issue #24](https://github.com/wrello/Animations/issues/24), [Issue #23](https://github.com/wrello/Animations/issues/23)

## v1.2.0
> ###### 2/20/2024

----

- Enhancements
    - Added [`AnimationsClient:ApplyCustomRBXAnimationIds()`](/api/AnimationsClient/#ApplyCustomRBXAnimationIds). [Issue #21](https://github.com/wrello/Animations/issues/21)


- Fixes
    - Fixed [`AnimationsServer:ApplyCustomRBXAnimationIds()`](/api/AnimationsServer/#ApplyCustomRBXAnimationIds) not updating the animations until after the player moved.

## v1.1.0
> ###### 2/18/2024

----

- Enhancements
    - **[Beta]** Added [`Animations:AttachAnimatedObject()`](/api/AnimationsServer/#AttachAnimatedObject), [`Animations:DetachAnimatedObject()`](/api/AnimationsServer/#DetachAnimatedObject) methods, [`HasAnimatedObject`](/api/AnimationIds/#HasAnimatedObject) function in the [`AnimationIds`](/api/AnimationIds) module, and an [animated objects tutorial](/docs/animated-objects). [Issue #15](https://github.com/wrello/Animations/issues/15)
    - Added a tip that `"walk"` is the animation id that is applied for `R6` characters and `"run"` is the animation id that is applied for `R15` characters when using [`AnimationsServer:ApplyCustomRBXAnimationIds()`](/api/AnimationsServer#ApplyCustomRBXAnimationIds) and [`AutoCustomRBXAnimationIds`](/api/AutoCustomRBXAnimationIds). [Issue #20](https://github.com/wrello/Animations/issues/20)


- Changes (non-breaking)
    - Changed `ASSET_ID_STR` to format an integer instead of a float. [Issue #19](https://github.com/wrello/Animations/issues/19)


- Fixes
    - Fixed lots of documentation and typing errors, especially related to `CustomRBXAnimationIds` which is now [`humanoidRigTypeToCustomRBXAnimationIds`](/api/AnimationsServer/#humanoidRigTypeToCustomRBXAnimationIds).
    - Fixed [`AnimationsServer:ApplyCustomRBXAnimationIds()`](/api/AnimationsServer#ApplyCustomRBXAnimationIds) and [`AutoCustomRBXAnimationIds`](/api/AutoCustomRBXAnimationIds) not working. [Issue #18](https://github.com/wrello/Animations/issues/18)
    - Fixed bad type annotation for [`AutoCustomRBXAnimationIds`](/api/AutoCustomRBXAnimationIds). [Issue #16](https://github.com/wrello/Animations/issues/16)

## v1.0.5
> ###### 1/31/2024

----

- Fixes
    - Fixed all methods having no auto-complete (bad types). [Issue #12](https://github.com/wrello/Animations/issues/12)
    - Fixed missing weight and speed parameters for auto-complete in some methods (bad types). [Issue #13](https://github.com/wrello/Animations/issues/13)
    - Fixed an overcomplicated private method `:_getAnimatorOrAnimationController()` in the `AnimationsClass`. Its new name is `:_getAnimator()`. [Issue #14](https://github.com/wrello/Animations/issues/14)

## v1.0.4
> ###### 11/22/2023

----

- Enhancements
    - Put both client & server animation modules in `--!strict` mode. This allowed for a lot of typing fixes.
    - Added a warning `Infinite yield possible on 'player_or_rig.CharacterAdded():Wait()'` that occurs whenever the `getRig()` helper function is called if the player's character doesn't exist after 5 seconds. This is helpful if `Players.CharacterAutoLoads` is not enabled and `getRig()` gets called.


- Fixes
    - Fixed `initOptions.AutoCustomRBXAnimationIds` not working because it was named incorrectly. New name is `initOptions.EnableAutoCustomRBXAnimationIds`. [AnimationsServer initOptions](/api/AnimationsServer/#initOptions)
    - Fixed multiple references to the same animation id's table causing an error. [Issue #11](https://github.com/wrello/Animations/issues/11)
    - Fixed incorrect types.

## v1.0.3
> ###### 11/22/2023

----

- Enhancements
    - [`Animations:LoadTracks()`](/api/AnimationsClient#LoadTracks) now automatically gives the rig an attribute `AnimationsRigType` set to the given [`rigType`](/api/AnimationIds#rigType) (which is "Player" when the client calls it). [Issue #9](https://github.com/wrello/Animations/issues/9)
    - Explained a convenient feature when using [`Animations:SetTrackAlias()`](/api/AnimationsClient#SetTrackAlias) in the documentation of the function.


- Fixes
    - Fixed [`Animations:GetTrackFromAlias()`](/api/AnimationsClient#GetTrackFromAlias) not working. [Issue #10](https://github.com/wrello/Animations/issues/10)
    - Fixed `Util.ChildFromPath` bug that caused errors when the `parent` became nil during the recursion. [Issue #7](https://github.com/wrello/Animations/issues/7)

## v1.0.2
> ###### 8/31/2023

----

- Enhancements
    - Added assertions to check `AnimationsClient` and `AnimationsServer` are being required on the client & server respectively. [Issue #4](https://github.com/wrello/Animations/issues/4)


- Fixes
    - Fixed subsequent `Animations:AwaitLoaded()` calls getting discarded. [Issue #5](https://github.com/wrello/Animations/issues/5)
    - Fixed documentation. [Issue #3](https://github.com/wrello/Animations/issues/3)
    - Fixed documentation. [Issue #2](https://github.com/wrello/Animations/issues/2)
    - Removed an unecessary `:`. [Issue #1](https://github.com/wrello/Animations/issues/1)

## v1.0.1
> ###### 8/3/2023

----

- Fixes
    - Fixed Animation:Init() error when called without optional `initOptions`.

## v1.0.0
> ###### 8/3/2023

----

- Initial release