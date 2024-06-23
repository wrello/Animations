local function HasAnimatedObject(
	animationId: number | {},
	animatedObjectPath: {any} | string,
	animatedObjectSettings: {
		AutoAttach: boolean?,
		AutoDetach: boolean?,
		DoUnpack: boolean?, -- Sets the key value pairs for everything up one level instead of in the passed animation ids able
	}
): {}
	local animatedObjectInfo = {
		AnimatedObjectPath = animatedObjectPath,
		AnimatedObjectSettings = animatedObjectSettings
	}

	if type(animationId) == "table" then
		animationId._animatedObjectInfo = animatedObjectInfo

		return animationId
	else
		return {
			_animatedObjectInfo = animatedObjectInfo,
			_singleAnimationId = animationId
		}
	end
end

return HasAnimatedObject