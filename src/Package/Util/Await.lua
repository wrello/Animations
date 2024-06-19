-- made by wrello
-- v1.1.1

type EventWithSettingsType = {} -- {RBXScriptSignal, WinnerKey?, ...any?}
type TimeoutType = (number | RBXScriptSignal)?

local WINNER_KEY_FLAG = "winner key"

local function argsMatchParams(params, ...)
	local args = {...}
	
	for i, param in ipairs(params) do
		if type(param) == "function" then
			if not param(args[i]) then -- Typechecking
				return false
			end
		elseif param ~= args[i] then
			return false
		end
	end

	return true
end

local function isWinnerKey(t)
	if type(t) == "table" then
		return t[1] == WINNER_KEY_FLAG
	end
end

local Await = {}

-- The typechecker is not required, but it adds more functionality
if script:FindFirstChild("t") then
	Await.t = require(script.t)
end

-- Creates a winner key which can be used to determine the winner in an event race
-- @return {<string> WINNER_KEY_FLAG, <string> token}
-- Example:
--[[

	(see Await.First() example)
	
]]
function Await.WinnerKey(token)
	return {WINNER_KEY_FLAG, token}
end

-- Waits for the event with specific args to fire
-- @return (<boolean> timedOut, <...any?> ...passed args)
-- Example:
--[[
	
	local Players = game:GetService("Players")
	
	local timeoutDuration = nil -- The timeout duration is optional
	
	Await.Args(timeoutDuration, Players.PlayerRemoving, function(player)
		return player.Name == "wrello"
	end)
	
	print("wrello left!")
	
]]
function Await.Args(timeout: TimeoutType, event: RBXScriptSignal, ...: any)
	local thread = coroutine.running()
	local params = {...}
	
	local conn
	
	local function done(...)
		task.spawn(thread, ...)
		conn:Disconnect()
	end
	
	conn = event:Connect(function(...)
		if conn.Connected then 
			if argsMatchParams(params, ...) then
				done(false, ...)
			end
		end
	end)

	if timeout then
		if type(timeout) == "number" then
			task.delay(timeout, function()
				if conn.Connected then
					done(true)
				end
			end)
		else
			timeout:Once(function()
				if conn.Connected then
					done(true)
				end
			end)
		end
	end

	return coroutine.yield()
end

-- Waits for the event to fire
-- @return (<boolean> timedOut, <...any?> ...passed args)
-- Example:
--[[
	
	local part = Instance.new("Part")
	part.Parent = workspace
	
	local timeoutDuration = 5 -- The timeout duration is optional
	
	local timedOut, hitPart = Await.Event(timeoutDuration, part.Touched)
	
	if not timedOut then
		print("touched", hitPart)
	else
		print("did not touch anything after", timeoutDuration, "seconds")
	end
	
]]
function Await.Event(timeout: TimeoutType, event: RBXScriptSignal)
	local thread = coroutine.running()
	
	local conn
	
	local function done(...)
		conn:Disconnect()
		task.spawn(thread, ...)
	end
	
	conn = event:Connect(function(...)
		if conn.Connected then 
			done(false, ...)
		end
	end)

	if timeout then
		if type(timeout) == "number" then
			task.delay(timeout, function()
				if conn.Connected then
					done(true)
				end
			end)
		else
			timeout:Once(function()
				if conn.Connected then
					done(true)
				end
			end)
		end
	end

	return coroutine.yield()
end

-- Waits for the first event of multiple to fire
-- @return (<boolean> timedOut, <string | number> winnerKey, <{...any?}> winnerArgs)
-- Example:
--[[
	
	local part = Instance.new("Part")
	part.Parent = workspace

	local eventRaceArgs = {
	
		{part.Destroying, Await.WinnerKey("part destroyed")},
		
		{part.Touched, Await.WinnerKey("touched by hrp"), function(hitPart)
			return hitPart.Name == "HumanoidRootPart"
		end},
		
		part:GetPropertyChangedSignal("Name") -- The winner key would default to 2 in this case (that's this event's position in the 'eventRaceArgs' table)
	
	}

	local timeoutDuration = nil -- The timeout duration is optional

	-- Wait for the first one to fire
	local timedOut, winnerKey, winnerArgs = Await.First(timeoutDuration, unpack(eventRaceArgs))
	
	
	-- Use this if you set the timeoutDuration to not nil
	
	--if not timedOut then
	--	print(winnerKey, "was the first event to fire! Passed args:", winnerArgs)
	--else
	--  print("no events fired after", timeoutDuration, "seconds")
	--end
	
	
	print(winnerKey, "was the first event to fire! Passed args:", ...)
	
]]
function Await.First(timeout: TimeoutType, ...: RBXScriptSignal | EventWithSettingsType)
	local thread = coroutine.running()
	
	local conns = {}
	
	local function done(...)
		for _, conn in ipairs(conns) do
			conn:Disconnect()
		end
		
		task.spawn(thread, ...)
	end
	
	for i, event in ipairs({...}) do
		local conn

		if event.Connect then
			conn = event:Connect(function(...)
				if conn.Connected then
					done(false, i, {...})
				end
			end)
		else
			local winnerKey = nil
			
			local params = {} do
				local len = #event
				for i = 2, len do
					if isWinnerKey(event[i]) then
						winnerKey = event[i][2]
					else
						table.insert(params, event[i])
					end
				end
			end
			
			conn = event[1]:Connect(function(...)
				if conn.Connected then
					if argsMatchParams(params, ...) then
						done(false, winnerKey or i, {...})
					end
				end
			end)
		end

		table.insert(conns, conn)
	end

	if timeout then
		if type(timeout) == "number" then
			task.delay(timeout, function()
				if conns[1].Connected then
					done(true)
				end
			end)
		else
			timeout:Once(function()
				if conns[1].Connected then
					done(true)
				end
			end)
		end
	end

	return coroutine.yield()
end

return Await