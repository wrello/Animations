local RunService = game:GetService("RunService")

local CustomAssert = require(script.Parent.Parent.CustomAssert)

local ANIMATED_OBJECT_MOTOR6D_NAME = "AnimatedObjectMotor6D"
local SERVER_ANIM_OBJ_AUTO_ATTACH_STR = "server_auto_attach_animated_object_path_type"

local rigToRightGripDisabledCount = {}

function rigToRightGripDisabledCount.track(rig)
	if not rigToRightGripDisabledCount[rig] then
		rigToRightGripDisabledCount[rig] = 0

		local conn; conn = rig.AncestryChanged:Connect(function(_, newParent)
			if newParent == nil then
				conn:Disconnect()
				rigToRightGripDisabledCount[rig] = nil
			end
		end)
	end
end

local function setupMotor6d(motor6d, rig, animatedObject)
	-- Setting the motor6d's Part0 to the correct body part
	-- so it will work with the animation
	local part0NameStrVal = motor6d:FindFirstChild("Part0Name")
	CustomAssert(part0NameStrVal, `No "Part0Name" string value found under animated object motor6d for animated object [ {animatedObject:GetFullName()} ]`)
	motor6d.Part0 = rig:FindFirstChild(part0NameStrVal.Value, true)

	-- Setting the motor6d's Part1 to the correct animated
	-- object part so it will work with the animation
	if animatedObject:IsA("BasePart") then 
		motor6d.Part1 = animatedObject
	else
		local part1NameStrVal = motor6d:FindFirstChild("Part1Name")
		CustomAssert(part1NameStrVal, `No "Part1Name" string value found under animated object motor6d for animated object [ {animatedObject:GetFullName()} ]`)
		motor6d.Part1 = animatedObject:FindFirstChild(part1NameStrVal.Value, true)
	end
end

local AnimatedObject = {}
AnimatedObject.__index = AnimatedObject

AnimatedObject.SERVER_ANIM_OBJ_AUTO_ATTACH_STR = SERVER_ANIM_OBJ_AUTO_ATTACH_STR

function AnimatedObject.new(rig, animatedObjectSrc, animatedObjectInfo, debugPrints)
	local self = setmetatable({}, AnimatedObject)
	
	self._debugPrints = debugPrints
	self._animatedObjectSrc = animatedObjectSrc
	self._animatedObjectInfo = animatedObjectInfo
	self._listenToDetachHandlers = {}
	self._rightGripWeldEnabled = true
	self._rig = rig

	rigToRightGripDisabledCount.track(rig)

	return self
end

function AnimatedObject:_setRightGripWeldEnabled(enabled)
	if enabled == self._rightGripWeldEnabled then
		return
	end
	
	self._rightGripWeldEnabled = enabled
	
	if not enabled then
		rigToRightGripDisabledCount[self._rig] += 1
	else
		rigToRightGripDisabledCount[self._rig] -= 1
	end
	
	if self._debugPrints then
		print(`[ANIM_OBJ_DEBUG] Trying set right grip weld enabled [ {enabled} ]. New right grip weld disabled count [ {rigToRightGripDisabledCount[self._rig]} ]`)
	end
	
	local rightGripWeld = (self._rig:FindFirstChild("Right Arm") or self._rig:FindFirstChild("RightHand")):FindFirstChild("RightGrip")
	
	if not rightGripWeld or rightGripWeld.Enabled == enabled then
		if self._debugPrints then
			print("[ANIM_OBJ_DEBUG] <previous action fail>")
		end
		return
	end
	
	if enabled
		
		-- Re-enable right grip weld if the count is back
		-- down to only one animated object that has it
		-- disabled
		and rigToRightGripDisabledCount[self._rig] ~= 0
		
	then
		if self._debugPrints then
			print("[ANIM_OBJ_DEBUG] <previous action fail>")
		end
		return
	end
	
	if self._debugPrints then
		print("[ANIM_OBJ_DEBUG] <previous action success>")
	end
	
	rightGripWeld.Enabled = enabled
end

function AnimatedObject:_createAnimatedObjectClone()
	if self._animatedObjectSrc.ClassName == "Motor6D" then -- motor6d only
		self._animatedObjectClone = self._animatedObjectSrc:Clone()
	elseif self._animatedObjectSrc.ClassName == "Tool" -- tool, model, basepart
		or self._animatedObjectSrc.ClassName == "Model"
		or self._animatedObjectSrc:IsA("BasePart")
	then
		self._animatedObjectClone = self._animatedObjectSrc:Clone()
	elseif self._animatedObjectSrc.ClassName == "Folder" then
		self._animatedObjectClone = self._animatedObjectSrc:Clone()
	else
		CustomAssert(false, `Animated object [ {self._animatedObjectSrc:GetFullName()} ] of class [ {self._animatedObjectSrc.ClassName} ] is not a supported animated object type`)
	end
	
	if self._animatedObjectInfo
		and RunService:IsServer() 
	then
		if self._animatedObjectInfo.AnimatedObjectSettings.AutoAttach then
			self._animatedObjectClone:SetAttribute(SERVER_ANIM_OBJ_AUTO_ATTACH_STR, type(self._animatedObjectInfo.AnimatedObjectPath))
		end
	end

	return self._animatedObjectClone
end

function AnimatedObject:_setLifelineAnimatedObject(lifelineAnimatedObject)
	if self._lifelineConn then
		self._lifelineConn:Disconnect()
	end
	
	-- When our lifeline is detached (unparented from the
	-- rig) we will detach as well.
	self._lifelineConn = lifelineAnimatedObject.AncestryChanged:Connect(function(_, newParent)
		if newParent ~= self._rig then
			self._lifelineConn:Disconnect()
			self:Detach()
		end
	end)
end

function AnimatedObject:Attach()
	local lifelineAnimatedObject = nil
	
	if self._animatedObjectSrc.ClassName == "Motor6D" then -- motor6d only
		-- WARNING: If the tool does not have a "Handle" and
		-- therefore does not automatically create a
		-- "RightGrip" weld (i.e. doesn't attach it to the
		-- character's hand before it's parented to the
		-- character) this motor6d will not save it from
		-- appearing floating in space for a split second
		-- before it attaches to the correct animated
		-- position.
		
		if self._debugPrints then
			print("[ANIM_OBJ_DEBUG] Attaching animated object motor6d only [", self._animatedObjectSrc:GetFullName(), "]")
		end
		
		local preEquippedAnimatedObject = self._rig:FindFirstChild(self._animatedObjectSrc.Name)

		if not preEquippedAnimatedObject then
			if self._debugPrints then
				print(`[ANIM_OBJ_DEBUG] Unable to attach animated object - no pre-equipped animated object found with same name of animated object motor6d [ {self._animatedObjectSrc.Name} ]`)
			end
			return	
		end
		
		self:_createAnimatedObjectClone()
		
		setupMotor6d(self._animatedObjectClone, self._rig, preEquippedAnimatedObject)
		
		if preEquippedAnimatedObject.ClassName == "Tool" then
			self:_setRightGripWeldEnabled(false)
		end
		
		lifelineAnimatedObject = preEquippedAnimatedObject
	elseif self._animatedObjectSrc.ClassName == "Tool" -- tool, model, basepart
		or self._animatedObjectSrc.ClassName == "Model"
		or self._animatedObjectSrc:IsA("BasePart")
	then
		if self._debugPrints then
			print("[ANIM_OBJ_DEBUG] Attaching animated object tool, model, basepart [", self._animatedObjectSrc:GetFullName(), "]")
		end
		
		local animatedObjectMotor6d = self._animatedObjectSrc:FindFirstChild(ANIMATED_OBJECT_MOTOR6D_NAME, true)
		
		if not animatedObjectMotor6d then
			if self._debugPrints then
				print(`[ANIM_OBJ_DEBUG] Unable to attach animated object - no animated object motor6d \"{ANIMATED_OBJECT_MOTOR6D_NAME}\" found in animated object [ {self._animatedObjectSrc:GetFullName()} ]`)
			end
			return
		end
	
		self:_createAnimatedObjectClone()
	
		setupMotor6d(self._animatedObjectClone:FindFirstChild(ANIMATED_OBJECT_MOTOR6D_NAME, true), self._rig, self._animatedObjectClone)
	
		if self._animatedObjectSrc.ClassName == "Tool" then
			self:_setRightGripWeldEnabled(false)
		end
		
		lifelineAnimatedObject = self._animatedObjectClone
	elseif self._animatedObjectSrc.ClassName == "Folder" then
		if self._debugPrints then
			print("[ANIM_OBJ_DEBUG] Attaching animated object folder [", self._animatedObjectSrc:GetFullName(), "]")
		end

		for _, animatedObject in ipairs(self._animatedObjectSrc:GetChildren()) do
			local animatedObjectMotor6d = animatedObject:FindFirstChild(ANIMATED_OBJECT_MOTOR6D_NAME, true)
			
			if not animatedObjectMotor6d then
				if self._debugPrints then
					print(`[ANIM_OBJ_DEBUG] Unable to attach animated object - no animated object motor6d \"{ANIMATED_OBJECT_MOTOR6D_NAME}\" found in animated object [ {animatedObject:GetFullName()} ]`)
				end
				return
			end
		end
		
		self:_createAnimatedObjectClone()
		
		for _, animatedObject in ipairs(self._animatedObjectClone:GetChildren()) do
			local animatedObjectMotor6d = animatedObject:FindFirstChild(ANIMATED_OBJECT_MOTOR6D_NAME, true)

			setupMotor6d(animatedObjectMotor6d, self._rig, animatedObject)

			if animatedObject.ClassName == "Tool" then
				self:_setRightGripWeldEnabled(false)
			end
		end
		
		lifelineAnimatedObject = self._animatedObjectClone
	else
		CustomAssert(false, `Animated object [ {self._animatedObjectSrc:GetFullName()} ] of class [ {self._animatedObjectSrc.ClassName} ] is not a supported animated object type`)
	end
	
	self:_setLifelineAnimatedObject(lifelineAnimatedObject)
	
	self._animatedObjectClone.Parent = self._rig
	
	return true
end

function AnimatedObject:Detach()
	if self._detached then
		return
	end

	self._detached = true

	if self._debugPrints then
		print("[ANIM_OBJ_DEBUG] Detaching animated object [", self._animatedObjectSrc:GetFullName(), "]")
	end

	-- Try to decrease the right grip weld disabled counter
	-- if we had increased it at the start
	self:_setRightGripWeldEnabled(true)

	-- Destroy the animated object clone
	if self._animatedObjectClone.Parent == self._rig then
		self._animatedObjectClone:Destroy()
	end

	-- Invoke ":ListenToDetach()" callbacks
	for _, fn in ipairs(self._listenToDetachHandlers) do
		task.spawn(fn)
	end

	table.clear(self._listenToDetachHandlers)
end

function AnimatedObject:ListenToDetach(fn)
	table.insert(self._listenToDetachHandlers, fn)
end

-- Client only
function AnimatedObject:TransferToServerAnimatedObject(serverAnimatedObject)
	self:_setLifelineAnimatedObject(serverAnimatedObject) -- If the server animated object gets removed for some reason we detach now
	self._animatedObjectClone:Destroy() -- We destroy the client animated object immediately 
	self._animatedObjectClone = serverAnimatedObject -- We destroy the server animated object when we detach now
end

return AnimatedObject