local function GetAttributeAsync(obj: Instance, attrName: string)
	local v = obj:GetAttribute(attrName)

	if v == nil then
        task.delay(3, function()
            if v == nil then
                warn(`Infinite yield possible on '{obj.Name}:GetAttributeChangedSignal("{attrName}"):Wait()'`)
            end
        end)

		obj:GetAttributeChangedSignal(attrName):Wait()

		v = obj:GetAttribute(attrName)
	end

	return v
end

return GetAttributeAsync