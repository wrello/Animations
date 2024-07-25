-- made by wrello
-- v2.0.0

local function ChildFromPath(parent, path)
	local child = parent

	if type(path) == "string" then
		local function forEachMatch(m)
			child = child[m] or child[tonumber(m)]
		end

		string.gsub(path, "[^.]+", forEachMatch)
	else
		for _, token in ipairs(path) do
			child = child[token]
		end
	end

	return child
end

return ChildFromPath