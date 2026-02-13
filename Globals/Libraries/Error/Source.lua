local function CaptureStructuredStack(StartLevel: number): {string}
	local Stack = {}
	local Level = StartLevel

	while true do
		local Source, Line, Name = debug.info(Level, `sln`)
		if not Source then break end
		Level += 1
		if Source == `[C]` then continue end
		Stack[#Stack + 1] = `>>> [{Source}] >>> [Line: {Line}] `..(Name ~= `` and `>>> [Function: {Name}]` or ``)
	end
	
	return Stack
end

---------------------------------------------------------------------------------------------------------------------
local function Log(Template: string, ...: any)
	local Lines = {string.format(Template, ...)}
	local Stack = CaptureStructuredStack(3)

	for _, Entry in Stack do Lines[#Lines + 1] = Entry end
	warn(table.concat(Lines, `\n`))
end

---------------------------------------------------------------------------------------------------------------------
return Log
