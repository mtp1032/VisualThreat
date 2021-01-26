----------------------------------------------------------------------------------------
-- enUS.lua
-- AUTHOR: mtpeterson1948 at gmail dot com
-- ORIGINAL DATE: 28 December, 2018
----------------------------------------------------------------------------------------

local _, VisualThreat = ...
VisualThreat.enUS = {}

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
	L["ADDON_LOADED_MESSAGE"] 				= sprintf("%s %s %s", L["ADDON_NAME"], L["LOADED"], L["VERSION"] )
	L["USER_MSG_FRAME"]					= sprintf("%s %s", L["ADDON_AND_VERSION"], "User Messages")

	-- Generic Error Message

	L["ARG_NIL"]				= "Value Was nil"
	L["ARG_MISSING"]			= "Parameter missing"
	L["ARG_INVALID_VALUE"]		= "Value Not In Range"
	L["ARG_UNEXPECTED_VALUE"]	= "Value Unexpected or Not In Range"
	L["ARG_UNEQUAL_VALUES"]		= "Unequal Values"
	L["ARG_INVALID_TYPE"]		= "Variable was type %s, expected %s"
	return 
end
