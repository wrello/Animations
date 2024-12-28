local AnimationIdsUtil = {}

function AnimationIdsUtil.HasProperties(
    animationId: number | {},
	propertiesSettings: {
        Priority: Enum.AnimationPriority?,
        Looped: boolean?,
        MarkerTimes: boolean?, -- Set this to true for animations that should have accessible animation marker times
		DoUnpack: boolean?, -- Sets the key value pairs for everything up one level instead of in the passed animation ids able
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

function AnimationIdsUtil.HasAnimatedObject(
	animationId: number | {},
	animatedObjectPath: {any} | string,
	animatedObjectSettings: {
		AutoAttach: boolean?,
		AutoDetach: boolean?,
		DoUnpack: boolean?, -- Sets the key value pairs for everything up one level instead of in the passed animation ids able
	}
): {}
    local doUnpack = animatedObjectSettings.DoUnpack
    animatedObjectSettings.DoUnpack = nil

    local animatedObjectInfo = {
        AnimatedObjectPath = animatedObjectPath,
        AnimatedObjectSettings = animatedObjectSettings
    }

    if type(animationId) == "table" then
        animationId._doUnpack = doUnpack
        animationId._animatedObjectInfo = animatedObjectInfo

        return animationId
    else
        return {
            _animatedObjectInfo = animatedObjectInfo,
            _singleAnimationId = animationId
        }
    end
end

return AnimationIdsUtil