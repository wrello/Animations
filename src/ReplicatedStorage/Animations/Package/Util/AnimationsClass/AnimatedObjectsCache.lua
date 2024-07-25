local function pathToString(path)
	if type(path) == "table" then
		local concatStr = ""
		for _, v in ipairs(path) do
			concatStr ..= tostring(v)
		end
		return concatStr
	end
	
	return path
end

local AnimatedObjectsCache = {}
AnimatedObjectsCache.__index = AnimatedObjectsCache

function AnimatedObjectsCache.new()
	local self = setmetatable({}, AnimatedObjectsCache)
	
	self.Cache = {}
	
	return self
end

function AnimatedObjectsCache:Get(animatedObjectPath)
	local pathStr = pathToString(animatedObjectPath)

	return self.Cache[pathStr]
end

function AnimatedObjectsCache:Map(animatedObjectPath, animatedObjectTable)
	local pathStr = pathToString(animatedObjectPath)
	
	if self.Cache[pathStr] then
		return
	end
	
	self.Cache[pathStr] = animatedObjectTable
end

function AnimatedObjectsCache:Remove(animatedObjectPath)
	local pathStr = pathToString(animatedObjectPath)
	
	if not self.Cache[pathStr] then
		return
	end
	
	self.Cache[pathStr] = nil
end

return AnimatedObjectsCache