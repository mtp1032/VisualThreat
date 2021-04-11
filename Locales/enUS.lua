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

local fileName = "enUS.lua"

VisualThreat.L = L
local sprintf = _G.string.format

-- English translations
local LOCALE = GetLocale()      -- BLIZZ
if LOCALE == "enUS" then

	L["ADDON_NAME"]					= "VisualThreat"
	L["VERSION"]					= "V0.1 (ShadowLands)"
	L["ADDON_AND_VERSION"] 			= sprintf("%s - %s", L["ADDON_NAME"], L["VERSION"] )
	L["LOADED"]						= "loaded"
	L["ADDON_LOADED_MESSAGE"] 		= sprintf("%s %s - %s", L["ADDON_NAME"], L["LOADED"], L["VERSION"] )
	L["USER_MSG_FRAME"]				= sprintf("%s %s", L["ADDON_AND_VERSION"], "User Messages")
	L["THREAT_LOGGING_ENABLED"]		= sprintf("%s", "Advanced Combat Logging Enabled")
	L["THREAT_LOGGING_DISABLED"]	= sprintf("%s", "Advanced Combat Logging Disabled")

	L["LEFTCLICK_FOR_OPTIONS_MENU"]			= sprintf( "Left click to display the %s Options Menu.", L["ADDON_NAME"] )
	L["RIGHTCLICK_SHOW_METRICS"]			= "Right click."
	L["SHIFT_LEFTCLICK_DISMISS_COMBATLOG"]	= "Shift-Left click."
	L["SHIFT_RIGHTCLICK_ERASE_TEXT"]		= "Shift-Right click."
	L["PROMPT_ENABLE_ADDON"] 				= sprintf("Disable %s", L["ADDON_NAME"])
	L["ENABLE_ADDON_TOOLTIP"] 				= sprintf("Checking this box disables %s.", L["ADDON_NAME"])

	L["DESCR_SUBHEADER"] = "A Real Time Threat Display for Party Groups Only"

	L["LINE1"]			= sprintf("For each member of the party, %s may be configure to display", L["ADDON_NAME"] )
	L["LINE2"]			= sprintf("one, two, or three real-time status windows. The windows are:\n")
	L["LINE3"]			= sprintf("  (1) A 'Threat Generated' status bar, ")
	L["LINE4"]			= sprintf("  (2) A 'Damage Taken' status bar, and ") 
	L["LINE5"]			= sprintf("  (3) A 'Heals Received' status bar.\n")
	L["LINE6"]			= sprintf("Each of which is optional.\n")

	L["TOOLTIP_COMBAT_METRICS"]	= sprintf("If checked, an extensive set of encounter combat metrics for each group member will be published in a separate window.")

	-- Generic Error Message

	L["ARG_NIL"]				= "Value Was nil"
	L["ARG_MISSING"]			= "Parameter missing"
	L["ARG_INVALID_VALUE"]		= "Value Not In Range"
	L["ARG_UNEXPECTED_VALUE"]	= "Value Unexpected or Not In Range"
	L["ARG_UNEQUAL_VALUES"]		= "Unequal Values"
	L["ARG_INVALID_TYPE"]		= "Variable was type %s, expected %s"
	return 
end
