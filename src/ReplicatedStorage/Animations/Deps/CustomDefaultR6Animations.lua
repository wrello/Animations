return function(char)
	local humanoid = char:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	for _, track in pairs(animator:GetPlayingAnimationTracks()) do
		track:Stop(0)
	end

	local animateScript = char:WaitForChild("Animate")
	
	-- TO SET A NEW CUSTOM DEFAULT R6 ANIMATION:
	
	-- "rbxassetid://insert custom default r6 animation id here" then uncomment the line
	
	
	--animateScript.run.RunAnim.AnimationId 		= "rbxassetid:// "
	--animateScript.walk.WalkAnim.AnimationId 		= "rbxassetid:// "
	--animateScript.jump.JumpAnim.AnimationId 		= "rbxassetid:// "
	--animateScript.idle.Animation1.AnimationId 	= "rbxassetid:// "
	--animateScript.idle.Animation2.AnimationId 	= "rbxassetid:// "
	--animateScript.fall.FallAnim.AnimationId 		= "rbxassetid:// "
	--animateScript.swim.Swim.AnimationId		 	= "rbxassetid:// "
	--animateScript.swimidle.SwimIdle.AnimationId 	= "rbxassetid:// "
	--animateScript.climb.ClimbAnim.AnimationId 	= "rbxassetid:// "
end