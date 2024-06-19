local function HasAnimatedObject(
	animationId: number | {}, 
	animatedObjectPath: {any} | string, 
	autoAttachDetachSettings: {
		RunContext: "Client" | "Server",
		AutoAttach: boolean?,
		AutoDetach: boolean?
	}?
): {}
	local animatedObjectInfo = {
		AnimatedObjectPath = animatedObjectPath,
		AutoAttachDetachSettings = autoAttachDetachSettings
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