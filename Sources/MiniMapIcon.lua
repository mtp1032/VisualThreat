--------------------------------------------------------------------------------------
-- MiniMapIcon.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 November, 2019
local _, VisualThreat = ...
VisualThreat.MiniMapIcon = {}
icon = VisualThreat.MiniMapIcon

local L = VisualThreat.L
local E = errors

local sprintf = _G.string.format

local REDX = 136813	-- this is the icon's texture

-- register the addon with ACE
local addon = LibStub("AceAddon-3.0"):NewAddon("VisualThreat", "AceConsole-3.0")

local shiftLeftClick = (button == "LeftButton") and IsShiftKeyDown()
local shiftRightClick = (button == "RightButton") and IsShiftKeyDown()
local altLeftClick = (button == "LeftButton") and IsAltKeyDown()
local altRightClick = (button == "RightButton") and IsAltKeyDown()
local rightButtonClick = (button == "RightButton")

-- The addon's icon state (e.g., position, etc.,) is kept in the AAReportDB. Therefore
--  this is set as the ##SavedVariable in the .toc file
local AAReportDB = LibStub("LibDataBroker-1.1"):NewDataObject("VisualThreat", 
	{
		type = "data source",
		text = "VisualThreat",
		icon = REDX,
		OnTooltipShow = function( tooltip )
			tooltip:AddLine(L["ADDON_NAME"])
			tooltip:AddLine(L["LEFTCLICK_FOR_OPTIONS_MENU"])
			tooltip:AddLine(L["RIGHTCLICK_SHOW_COMBATLOG"])
			tooltip:AddLine(L["SHIFT_LEFTCLICK_DISMISS_COMBATLOG"])
			tooltip:AddLine(L["SHIFT_RIGHTCLICK_ERASE_TEXT"])
		end,
		OnClick = function(self, button )
			-- LEFT CLICK - Display the options menu
			if button == "LeftButton" and not IsShiftKeyDown() then 
				InterfaceOptionsFrame_OpenToCategory("Visual Threat Status")
				InterfaceOptionsFrame_OpenToCategory("Visual Threat Status")
			end
			-- RIGHT CLICK - Show the Combat Log Display
			if button == "RightButton" and not IsShiftKeyDown() then
				-- Show Damage Taken Stack
			end
			-- SHIFT-LEFT BUTTON - Dismiss the Combat Log window
			if button == "LeftButton" and IsShiftKeyDown() then
				-- Show Threat Stack
			end
			-- SHIFT-RIGHT BUTTON -- Erase the text
			if button == "RightButton" and IsShiftKeyDown() then
				-- Show Heals Received Stack
			end
	end,
	})

-- so far so good. Now, create the actual icon	
local icon = LibStub("LibDBIcon-1.0")

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("AAReportDB", 
					{ profile = { minimap = { hide = false, }, }, }) 
	icon:Register("VisualThreat", AAReportDB, self.db.profile.minimap) 
end

-- What to do when the player clicks the minimap icon
-- local eventFrame = CreateFrame("Frame" )
-- eventFrame:RegisterEvent( "ADDON_LOADED")
-- eventFrame:SetScript("OnEvent", 
-- function( self, event, ... )
-- 	local arg1, arg2, arg3 = ...

-- 	if event == "ADDON_lOADED" and arg1 == L["ADDON_NAME"] then
-- 		addon:OnInitialize()
-- 	end
-- end)
