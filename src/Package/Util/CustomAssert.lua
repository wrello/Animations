local function CustomAssert(check, ...)
	if not check then
		print("ERROR:", ...)
		error("read above message for information")
	end
end

return CustomAssert