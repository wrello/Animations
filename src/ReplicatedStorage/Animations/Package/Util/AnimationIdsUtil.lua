local AnimationIdsUtil = {}

function AnimationIdsUtil.HasProperties(
    animationId: number | {},
	propertiesSettings: {
        Priority: Enum.AnimationPriority?,
        Looped: boolean?,
        StartSpeed: number?,
        MarkerTimes: boolean?,
		DoUnpack: boolean?
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
		DoUnpack: boolean?
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