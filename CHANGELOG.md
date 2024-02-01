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
    - Put both client and server animation modules in `--!strict` mode. This allowed for a lot of typing fixes.
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
    - Added assertions to check `AnimationsClient` and `AnimationsServer` are being required on the client and server respectively. [Issue #4](https://github.com/wrello/Animations/issues/4)

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