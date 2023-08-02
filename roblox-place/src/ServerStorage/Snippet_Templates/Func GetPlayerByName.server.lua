local function GetPlayerByName(TargetName)
	assert(typeof(TargetName) == "string", "Need string value for player name.")
	assert(#TargetName < 3, "Need 3 or more characters for the name.")
	
	for _, Player in pairs(game:GetService("Players"):GetPlayers()) do
		if Player.Name:lower():sub(1, #TargetName) == TargetName:lower() then
			return Player
		end
	end
end