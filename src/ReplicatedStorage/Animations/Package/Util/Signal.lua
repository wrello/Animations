-- made by wrello
-- v1.0.1

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, handler, isOnce)
	return setmetatable({ 
		_signal = signal, 
		_isOnce = isOnce,
		Handler = handler, 
		Connected = true, 
	}, Connection)
end

function Connection:Disconnect()
	self.Connected = false
	table.remove(self._signal._connections, table.find(self._signal._connections, self))
end

local Signal = {}
Signal.__index = Signal

function Signal.new(): RBXScriptSignal
	return setmetatable({ _connections = {}, _waitingThreads = {} }, Signal)
end

function Signal:Wait()
	table.insert(self._waitingThreads, coroutine.running())

	return coroutine.yield()
end

function Signal:Connect(handler)
	local conn = Connection.new(self, handler)

	table.insert(self._connections, conn)

	return conn
end

function Signal:Once(handler)
	local conn = Connection.new(self, handler, true)

	table.insert(self._connections, conn)

	return conn
end

function Signal:Fire(...)
	for _, waitingThread in ipairs(self._waitingThreads) do
		task.spawn(waitingThread, ...)
	end
	
	local clonedConnections = table.clone(self._connections) -- This is to prevent `Connection:Disconnect()` calls during the for loop modifing the table we're looping through
	
	for _, conn in ipairs(clonedConnections) do
		if conn._isOnce then
			conn:Disconnect()
		end
		
		task.spawn(conn.Handler, ...)
	end

	table.clear(self._waitingThreads)
end

return Signal