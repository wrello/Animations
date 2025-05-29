-- made by wrello

local AsyncInfoCache = {}

local cache = {}

local function retryPcall(count, obj, methodName, ...)
	local ok, result = nil, nil
	local i = 0

	repeat
		i += 1
		ok, result = pcall(obj[methodName], obj, ...)
	until ok or i == 3 or not task.wait(1)
	
	return ok, result
end

function AsyncInfoCache.asyncCall(retryCount, service, methodName, args, processResultFn)
	local idx = args[1]
	
	local _cache = cache[methodName]
	if not _cache then
		_cache = {}
		cache[methodName] = _cache
	end

	if not _cache[idx] then
		local ok, result = retryPcall(retryCount or 3, service, methodName, idx)

		if ok then
			_cache[idx] = if processResultFn then processResultFn(result) else result
		else
			warn(`[AsyncInfoCache] Error when calling {service.Name}:{methodName}({unpack(args) .. (#args > 2 and ("... and " .. #args-1 .. " more") or "")}): {result}`)
		end
	end

	return _cache[idx]
end

return AsyncInfoCache