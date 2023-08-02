-- made by wrello
-- v1.0.0

local function ChildFromPath(parent, path, index)
	if typeof(path) == "string" then -- A path string. Ex. "MyChild.MyDescendant" or "MyChild"
		local childKey, period = path:match("^([^%.]+)(%.?)")

		if childKey  then
			path = path:gsub(childKey .. period, "")

			if typeof(parent) == "Instance" then
				return ChildFromPath(parent:FindFirstChild(childKey), path)
			else
				return ChildFromPath(parent[childKey], path)
			end
		else
			return parent
		end
	elseif typeof(path) == "table" then -- A path table. Ex. { Vector3.new(), "MyDescendant", "MyDescendant2" }
		index = index or 1

		local childKey = path[index]

		if childKey ~= nil then
			index += 1

			if typeof(parent) == "Instance" then
				return ChildFromPath(parent:FindFirstChild(childKey), path, index)
			else
				return ChildFromPath(parent[childKey], path, index)
			end
		else
			return parent
		end
	else -- An immediate non-string child key. Ex. Vector3.yAxis or 43
		if typeof(parent) == "Instance" then
			return parent:FindFirstChild(path)
		else
			return parent[path]
		end
	end
end

return ChildFromPath