----------------------------------------------------------------------------------------
-- enUS.lua
-- AUTHOR: mtpeterson1948 at gmail dot com
-- ORIGINAL DATE: 28 December, 2018
----------------------------------------------------------------------------------------

local _, VisualThreat = ...
VisualThreat.enUS = {}
-- en = VisualThreat.enUS

local L = setmetatable({}, { __index = function(t, k)
	local v = tostring(k)
	rawset(t, k, v)
	return v
end })

VisualThreat.L = L
local sprintf = _G.string.format

-- English translations
local LOCALE = GetLocale()      -- BLIZZ
if LOCALE == "enUS" then

	L["ADDON_NAME"]							= "VisualThreat - A Graphical Threat Display"
	L["VERSION"]							= ", V0.1 (ShadowLands)"
	L["LOADED"]								= "loaded"
	L["ADDON_AND_VERSION"] 					= sprintf("%s %s", L["ADDON_NAME"], L["VERSION"] )
	L["ADDON_LOADED_MESSAGE"] 				= sprintf("%s %s %s", L["ADDON_NAME"], L["LOADED"], L["VERSION"] )

	L["ERROR_MSG_FRAME_TITLE"]			= "ERROR"
	L["USER_MSG_FRAME"]					= sprintf("%s %s", L["ADDON_AND_VERSION"], "User Messages")
	L["HELP_FRAME_TITLE"]				= sprintf("HELP - %s", L["ADDON_AND_VERSION"])
	L["ADDON_LOADED_MSG"]				= sprintf("%s loaded (Use /VT for help).", L["ADDON_AND_VERSION"])

	-- Generic Error Message
    L["ERROR_MSG"]            	= "[ERROR] %s"	

	L["ARG_NIL"]				= "INVALID: Parameter Was nil."
	L["ARG_INVALID_VALUE"]		= "INVALID: Parameter Not In Range."
	L["ARG_INVALID_TYPE"]		= "INVALID: Parameter Was Wrong Type."
	return 
end
