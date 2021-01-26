--------------------------------------------------------------------------------------
-- Errors.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 11 November, 2018	(Formerly DbgInfo.lua prior to this date)
--------------------------------------------------------------------------------------
local _, VisualThreat = ...
VisualThreat.Errors = {}	
errors = VisualThreat.Errors	
local sprintf = _G.string.format

local L = VisualThreat.L
local E = errors
--                      Error messages associated with function parameters

--                      The Result Table
local DISPLAY_TIME = 20

errors.mt 				= "Unused"		-- the empty string
local mt 				= errors.mt

errors.STATUS_SUCCESS = 1
errors.STATUS_FAILURE = 0
errors.SUCCESS = {errors.STATUS_SUCCESS, nil, nil }

local STATUS_SUCCESS 	= errors.STATUS_SUCCESS
local STATUS_FAILURE 	= errors.STATUS_FAILURE
local SUCCESS 			= errors.SUCCESS

---------------------------------------------------------------------------------------------------
--                      LOCAL FUNCTIONS
----------------------------------------------------------------------------------------------------
local function simplifyStackTrace( stackTrace )
	local startPos, endPos = string.find( stackTrace, '\'' )
	stackTrace = string.sub( stackTrace, 1, startPos )
	stackTrace = string.gsub( stackTrace, "Interface\\AddOns\\", "")
	
	stackTrace = string.gsub( stackTrace, "`", "<")
	stackTrace = string.gsub( stackTrace, "'", ">")
		
	stackTrace = string.gsub( stackTrace, ": in function ", "")        
	local stackFrames = { strsplit( "/\n", stackTrace )}
			
	local numFrames = #(stackFrames)
	for i = 1, numFrames do
		stackFrames[i] = strtrim( stackFrames[i] )
	end
	
	for i = 1, numFrames do
		startPos = strfind( stackFrames[i], "<")
		stackFrames[i] = string.sub( stackFrames[i], 1, startPos-1)
	end
	
	local simplifiedStackTrace = stackFrames[1]
	for i = 2, numFrames do
		simplifiedStackTrace = strjoin( "\n", simplifiedStackTrace, stackFrames[i])
		simplifiedStackTrace = strtrim( simplifiedStackTrace )
	end
	return simplifiedStackTrace
end	
local function fileAndLineNo( stackTrace )
	local pieces = {strsplit( ":", stackTrace, 5 )}
	local segment = {strsplit( "\\", pieces[1], 5 )}
	local i = 1
	local fileName = segment[i]
	while segment[i] ~= nil do
		index = tostring(i)
		fileName = segment[i]
		i = i+1 
	end

	-- [EventHandler.lua"]	-- need to remove the " character - the 18th character in the string"
	local strLen = string.len( fileName )
	local fileName = string.sub( fileName, 1, strLen - 2 )
	local lineNumber = tonumber(pieces[2])
	local fileAndLine = sprintf("[%s:%d]", fileName, lineNumber )

	return fileAndLine
end
---------------------------------------------------------------------------------------------------
--                      PUBLIC/EXPORTED FUNCTIONS
----------------------------------------------------------------------------------------------------
-- return an error message of the form [File.lua:66] FAILED: Invalid parameter
function errors:setResult( errMsg, stackTrace )
	local fn = fileAndLineNo( stackTrace )
	errMsg = sprintf("%s FAILED: %s\nSTACK TRACE:\n%s\n", fn, errMsg, stackTrace )
	local result = {STATUS_FAILURE, errMsg, stackTrace}
	return result
end
function errors:postResult( result )
	if result[1] == STATUS_SUCCESS then
		return
	end

	local reason = result[2]
	local stackTrace = result[3]
	local str = sprintf("%s\n\n%s\n", reason, stackTrace  )
	msg:post( str )
end
function errors:where( msg )
	local fn = fileAndLineNo( debugstack(2) )
	local str = nil
	if msg then
		str = sprintf("%s %s", fn, msg )
	else
		str = fn
	end
	DEFAULT_CHAT_FRAME:AddMessage( str, 1.0, 1.0, 0.0 )
end

