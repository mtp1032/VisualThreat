--------------------------------------------------------------------------------------
-- OptionsMenua.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 11 Nov, 2019
--------------------------------------------------------------------------------------

local _, VisualThreat = ...
VisualThreat.OptionsManu = {}
opt = VisualThreat.OptionsMenu

local L = VisualThreat.L
local E = errors

local sprintf = _G.string.format

local function drawLine( f, yPos )

	local lineFrame = CreateFrame("FRAME", nil, f )
	lineFrame:SetPoint("CENTER", -10, yPos )
	lineFrame:SetSize( 610, 200)
	
	local line = lineFrame:CreateLine()
	line:SetColorTexture(1.0, 1.0, 0.0 ) -- Grey per https://wow.gamepedia.com/Power_colors
	line:SetThickness(1)
	line:SetStartPoint("TOPLEFT",10, -10)
	line:SetEndPoint("TOPRIGHT", 10, -10 )
	lineFrame:Show() 
 end

local function checkBox_disableAddon(f, xPos, yPos )

	disableAddonBtn = CreateFrame("CheckButton", 
									"OPTIONS_disableAddonBtn", 
									f, 
									"ChatConfigCheckButtonTemplate" )

	disableAddonBtn:SetPoint("TOPLEFT", xPos, yPos )
	disableAddonBtn.Text:SetFontObject( GameFontNormal )
	disableAddonBtn.tooltip = "Check box to disable Visual Threat. Uncheck to [re]enable the addon."
	_G[disableAddonBtn:GetName().."Text"]:SetText("Disable Addon?")
	local disableAddon = false
	disableAddonBtn:SetChecked( disableAddon )
	disableAddonBtn:SetScript("OnClick", 
	function(self)
		disableAddon = self:GetChecked() and true or false
		if disableAddon then
			evd:disableAddon()
		else
			evd:enableAddon()
		end
	end)
end
local function checkBox_trackHealingReceived( f, xPos, yPos )
	
	local trackHealingRecdBtn = CreateFrame("CheckButton", 
									  "OPTIONS_trackHealingRecdBtn", 
									  f, 
									  "ChatConfigCheckButtonTemplate")

	trackHealingRecdBtn:SetPoint("TOPLEFT", xPos, yPos)
	trackHealingRecdBtn.Text:SetFontObject( GameFontNormal )
	trackHealingRecdBtn.tooltip = "Track the amount of healing the player receives."
	_G[trackHealingRecdBtn:GetName().."Text"]:SetText("Track Healing Received?")
	local healTrackingEnabled = false
	trackHealingRecdBtn:SetChecked( healTrackingEnabled )
	trackHealingRecdBtn:SetScript("OnClick", 
	function(self)
		healTrackingEnabled = self:GetChecked() and true or false
		if healTrackingEnabled then
			btn:enableHealsRecdTracking()
		else
			btn:disableHealsRecdTracking()
		end
	end)
end
local function checkBox_trackDamageTaken( f, xPos, yPos )
	local trackDamageTakenBtn = CreateFrame("CheckButton", 
												  "OPTIONS_trackDamageTakenBtn", 
												  f, 
												  "ChatConfigCheckButtonTemplate")

	trackDamageTakenBtn:SetPoint("TOPLEFT", xPos, yPos)
	trackDamageTakenBtn.Text:SetFontObject( GameFontNormal )
	trackDamageTakenBtn.tooltip = L["Tracks the damage taken by the player."]
	_G[trackDamageTakenBtn:GetName().."Text"]:SetText("Track Damage Taken?")
	local damageTakenEnabled = false
	trackDamageTakenBtn:SetChecked( damageTakenEnabled )
	trackDamageTakenBtn:SetScript("OnClick", 
	function(self)
	damageTakenEnabled = self:GetChecked() and true or false
	if damageTakenEnabled then
		btn:enableDmgTakenTracking()
	else
		btn:disableDmgTakenTracking()
	end
	end)
end
local function checkBox_trackThreat(  f, xPos, yPos )
	local trackThreatBtn = CreateFrame("CheckButton", 
									"OPTIONS_trackThreatBtn", 
									f, 
									"ChatConfigCheckButtonTemplate")

	trackThreatBtn:SetPoint("TOPLEFT", xPos, yPos)
	trackThreatBtn.Text:SetFontObject( GameFontNormal )
	trackThreatBtn.tooltip = L["Tracks amount of threat generated by the player."]
	_G[trackThreatBtn:GetName().."Text"]:SetText("Track Threat Generation?")
	local trackThreatEnabled = false
	trackThreatBtn:SetChecked( trackThreatEnabled )
	trackThreatBtn:SetScript("OnClick", 
	function(self)
		trackThreatEnabled = self:GetChecked() and true or false
		if trackThreatEnabled then
			btn:enableThreatTracking()
		else
			btn:disableThreatTracking()
		end
	end)
end
local function checkBox_reportPartyDamage(f, xPos, yPos )
	local partyDamageBtn = CreateFrame("CheckButton", 
										"OPTIONS_partyDamageBtn", 
										f, 
										"ChatConfigCheckButtonTemplate")

	partyDamageBtn:SetPoint("TOPLEFT", xPos, yPos )
	partyDamageBtn.Text:SetFontObject( GameFontNormal )
	partyDamageBtn.tooltip = "Generates a report of damage and healing by the party."
	_G[partyDamageBtn:GetName().."Text"]:SetText("Combat metrics by party?")
	local reportPartyDamage = false
	partyDamageBtn:SetChecked( reportPartyDamage )
	partyDamageBtn:SetScript("OnClick", 
	function(self)
		reportPartyDamage = self:GetChecked() and true or false
		if reportPartyDamage then
			combatStats:enablePartyCombatStats()
		else
			combatStats:disablePartyCombatStats()
		end
	end)
end
local function checkBox_reportDamageDetails(f, xPos, yPos )
	local detailsDamageBtn = CreateFrame("CheckButton", 
										"OPTIONS_detailsDamageBtn", 
										f, 
										"ChatConfigCheckButtonTemplate")
	detailsDamageBtn:SetPoint("TOPLEFT", xPos, yPos )
	detailsDamageBtn.Text:SetFontObject( GameFontNormal )

	local toolTipText = "Report damage and healing done by each party member."
	local promptText  = "Combat metrics by party member?"
	detailsDamageBtn.tooltip = toolTipText
	detailsDamageBtn.Text:SetText( promptText )	

	local reportDamageDetails = false
	detailsDamageBtn:SetChecked( reportDamageDetails )
	detailsDamageBtn:SetScript("OnClick", 

	function(self)
		reportDamageDetails = self:GetChecked() and true or false
		if reportDamageDetails then
			combatStats:enableDetailedCombatStats()
		else
			combatStats:disableDetailedCombatStats()
		end
	end)
end

local function optionsMenu_Initialize()
 
	local optionsMenuFrame = CreateFrame("FRAME","OPTIONS_MENU_MainFrame")
	optionsMenuFrame.name = "Visual Threat Status"
	
	InterfaceOptions_AddCategory(optionsMenuFrame)    -- Register the Configuration panel with LibUIDropDownMenu
	
    -- Print a header at the top of the panel
    local IntroMessageHeader = optionsMenuFrame:CreateFontString(nil, "ARTWORK","GameFontNormalLarge")
    IntroMessageHeader:SetPoint("TOPLEFT", 10, -10)
    IntroMessageHeader:SetText(L["ADDON_AND_VERSION"])

    local DescrSubHeader = optionsMenuFrame:CreateFontString(nil, "ARTWORK","GameFontNormalLarge")
    DescrSubHeader:SetPoint("TOPLEFT", 20, -50)
	DescrSubHeader:SetText(L["DESCR_SUBHEADER"])

	local str = sprintf("%s\n%s\n%s\n%s\n%s\n%s\n", L["LINE1"], L["LINE2"], L["LINE3"], L["LINE4"], L["LINE5"], L["LINE6"])
	local messageText = optionsMenuFrame:CreateFontString(nil, "ARTWORK","GameFontNormal")
	messageText:SetJustifyH("LEFT")
	messageText:SetPoint("TOPLEFT", 10, -80)
	messageText:SetText(sprintf(str))

	drawLine(optionsMenuFrame, -30 )

	-- To move down, increase the negative Y position
	-- To move Left, decrease the X position, to move right, increase the X position

	checkBox_disableAddon( optionsMenuFrame, 20, -240 )

	checkBox_trackThreat( optionsMenuFrame, 20, -280 )
	checkBox_trackDamageTaken( optionsMenuFrame, 20, -300 )
	checkBox_trackHealingReceived( optionsMenuFrame, 20, -320 )

	checkBox_reportPartyDamage(optionsMenuFrame, 350, -280)
	checkBox_reportDamageDetails( optionsMenuFrame, 350, -300 )
end
optionsMenu_Initialize()