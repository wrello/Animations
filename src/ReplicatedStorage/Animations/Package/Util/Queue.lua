local Queue = {}
Queue.__index = Queue

function Queue.new()
	return setmetatable({ _array = {} }, Queue)
end

function Queue:Enqueue(v: any)
	table.insert(self._array, v)
end

function Queue:Dequeue(): any
	local first = self._array[1]

	table.remove(self._array, 1)

	return first
end

function Queue:DequeueIter()
	return function()
		return self:Dequeue()
	end
end

return Queue