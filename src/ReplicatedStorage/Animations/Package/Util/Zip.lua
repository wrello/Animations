-- made by wrello
-- v1.2.0

local Zip = {}

function Zip.children(container, initFunction)
	local zipped = {}

	for _, moduleScript in ipairs(container:GetChildren()) do
		if moduleScript.ClassName == "ModuleScript" then
			local required = require(moduleScript)

			if initFunction then
				required = initFunction(moduleScript, required)
			end

			zipped[type(required) == "table" and required.Name or moduleScript.Name] = required
		end
	end

	return zipped
end

function Zip.descendants(container, initFunction)
	local zipped = {}

	for _, moduleScript in ipairs(container:GetDescendants()) do
		if moduleScript.ClassName == "ModuleScript" then
			local required = require(moduleScript)

			if initFunction then
				required = initFunction(moduleScript, required)
			end

			zipped[type(required) == "table" and required.Name or moduleScript.Name] = required
		end
	end

	return zipped
end

return Zip