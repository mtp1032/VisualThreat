--------------------------------------------------------------------------------------
-- MsgFrames.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 27 August, 2020
--------------------------------------------------------------------------------------
local _, VisualThreat = ...
VisualThreat.MsgFrames = {}
msg = VisualThreat.MsgFrames
local sprintf = _G.string.format
local L = VisualThreat.L
local E = errors

-- https://us.forums.blizzard.com/en/wow/t/addons-now-usable-in-shadowlands-beta/586355/16
-- https://wow.gamepedia.com/API_Frame_SetBackdrop
-- https://wow.gamepedia.com/EdgeFiles
-- https://wow.gamepedia.com/API_FontInstance_SetFontObject


local DEFAULT_FRAME_WIDTH = 800
local DEFAULT_FRAME_HEIGHT = 400

--------------------------------------------------------------------------
--                         CREATE THE VARIOUS BUTTONS
--------------------------------------------------------------------------
local function createResizeButton( f )
    f:SetResizable( true )
	local resizeButton = CreateFrame("Button", nil, f)
	resizeButton:SetSize(16, 16)
	resizeButton:SetPoint("BOTTOMRIGHT")
	resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	resizeButton:SetScript("OnMouseDown", function(self, button)
    	f:StartSizing("BOTTOMRIGHT")
    	f:SetUserPlaced(true)
	end)
 
	resizeButton:SetScript("OnMouseUp", function(self, button)
		f:StopMovingOrSizing()
        frameWidth, frameHeight= f:GetSize()
	end)
end
-- THIS CLEARS TEXT BUT DOES NOT DELETE ANY STATE
local function createClearButton( f, placement, offX, offY )
    local clearButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearButton:SetPoint(placement, f, offX, offY)
    clearButton:SetHeight(25)
    clearButton:SetWidth(70)
    clearButton:SetText("Clear")
    clearButton:SetScript("OnClick", 
        function(self)
            self:GetParent().Text:EnableMouse( false )    
            self:GetParent().Text:EnableKeyboard( false )   
            self:GetParent().Text:SetText("") 
            self:GetParent().Text:ClearFocus()
        end)
    f.clearButton = clearButton
end
-- THIS RESETS THE STATE AND CLEARS THE TEXT - A STARTOVER
local function createResetButton( f, placement, offX, offY )
    local resetButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    resetButton:SetPoint(placement, f, offX, offY)
    resetButton:SetHeight(25)
    resetButton:SetWidth(70)
    resetButton:SetText("Reset")
    resetButton:SetScript("OnClick", 
        function(self)
            self:GetParent().Text:EnableMouse( false )    
            self:GetParent().Text:EnableKeyboard( false )   
            self:GetParent().Text:SetText("") 
            self:GetParent().Text:ClearFocus()
            evh:resetGlobals()
            local msg = sprintf("\n\n*** All tables have been reset to initial conditions. ***\n\n")
            self:GetParent().Text:Insert( msg )
        end)
    f.resetButton = resetButton
end
-- PRINTS A SUMMARY OF THE ENCOUNTER
local function createSummaryButton( f, placement, offX, offY )
    local summaryButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    summaryButton:SetPoint(placement, f, offX, offY)
    summaryButton:SetHeight(25)
    summaryButton:SetWidth(70)
    summaryButton:SetText("Summary")
    summaryButton:SetScript("OnClick", 
        function(self)
            evh:summarizeEncounter()
            evh:dumpTables()
           end)
    f.summaryButton = summaryButton
end
-- DUMPS ALL THE DAMAGE AND HEALING TABLES
local function createPrintButton( f, placement, offX, offY )
    local printButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    printButton:SetPoint(placement, f, offX, offY)
    printButton:SetHeight(25)
    printButton:SetWidth(70)
    printButton:SetText("Details")
    printButton:SetScript("OnClick", 
        function(self)
            evh:dumpTables()
           end)
    f.printButton = printButton
end
local function createReloadButton( f, placement, offX, offY )
    local reloadButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    reloadButton:SetPoint(placement, f, offX, offY)
    reloadButton:SetHeight(25)
    reloadButton:SetWidth(70)
    reloadButton:SetText(L["Reload"])
    reloadButton:SetScript("OnClick", 
        function(self)
            ReloadUI()
        end)
    f.reloadButton = reloadButton
end
-- SELECTS ALL TEXT FOR COPYING
local function createSelectButton( f, placement, offX, offY )
    local selectButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    selectButton:SetPoint(placement, f, offX, offY) -- xPos < 0 moves button to the left

    selectButton:SetHeight(25)
    selectButton:SetWidth(70)
    selectButton:SetText("Select")
    selectButton:SetScript("OnClick", 
        function(self)
            self:GetParent().Text:EnableMouse( true )    
            self:GetParent().Text:EnableKeyboard( true )   
            self:GetParent().Text:HighlightText()
            self:GetParent().Text:SetFocus()
        end)
    f.selectButton = selectButton
end
--------------------------------------------------------------------------
--                         CREATE THE FRAMES
--------------------------------------------------------------------------
local function createTopFrame( frameName, width, height, red, blue, green )
	local f = CreateFrame( "Frame", frameName, UIParent, "BasicFrameTemplateWithInset" )
	if width == nil then
		width = DEFAULT_FRAME_WIDTH
	end
	if height == nil then
		height = DEFAULT_FRAME_HEIGHT
	end
    f:SetSize( width, height )
	return f
end
local function createTextDisplay(f)
    f.SF = CreateFrame("ScrollFrame", "$parent_DF", f, "UIPanelScrollFrameTemplate")
    f.SF:SetPoint("TOPLEFT", f, 12, -30)
    f.SF:SetPoint("BOTTOMRIGHT", f, -30, 40)

    --                  Now create the EditBox
    f.Text = CreateFrame("EditBox", nil, f)
    f.Text:SetMultiLine(true)
    f.Text:SetSize(DEFAULT_FRAME_WIDTH - 20, DEFAULT_FRAME_HEIGHT )
    f.Text:SetPoint("TOPLEFT", f.SF)    -- ORIGINALLY TOPLEFT
    f.Text:SetPoint("BOTTOMRIGHT", f.SF) -- ORIGINALLY BOTTOMRIGHT
    f.Text:SetMaxLetters(99999)
    f.Text:SetFontObject(CombatLogFont) -- Color this R 99, G 14, B 55
    f.Text:SetHyperlinksEnabled( true )
    f.Text:SetTextInsets(5, 5, 5, 5, 5)
    f.Text:SetAutoFocus(false)
    f.Text:EnableMouse( false )
    f.Text:EnableKeyboard( false )
    f.Text:SetScript("OnEscapePressed", 
        function(self) 
            self:ClearFocus() 
        end) 
    f.SF:SetScrollChild(f.Text)
end
function msg:createHelpFrame( title )
	local f = createTopFrame("HelpFrame", 700, 225, 0, 0, 0 )
	f:SetPoint("CENTER", 0, 200)
    f:SetFrameStrata("BACKGROUND")
    f:EnableMouse(true)
    f:EnableMouseWheel(true)
    f:SetMovable(true)
    f:Hide()
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing) 

    f.title = f:CreateFontString(nil, "OVERLAY")
	f.title:SetFontObject("GameFontHighlight")
    f.title:SetPoint("CENTER", f.TitleBg, "CENTER", 5, 0)
	f.title:SetText( title)
	
	createTextDisplay(f)
	createSelectButton(f, "BOTTOMRIGHT", -10, 5)
	createClearButton(f,"BOTTOMLEFT", 5,5 )
    return f
end
--------------------------------------------------------------------------
--                   THESE ARE THE APPLICATION FRAMES
--------------------------------------------------------------------------
-- --  Create the frame where error messages are posted
local errorFrameWidth = 600
local errorFrameHight = 200

function msg:createErrorMsgFrame(title)
    local f = createTopFrame( "ErrorMsgFrame",errorFrameWidth, errorFrameHight, 0, 0 )
    f:SetPoint("CENTER", 0, 200)
    f:SetFrameStrata("BACKGROUND")
    f:EnableMouse(true)
    f:EnableMouseWheel(true)
    f:SetMovable(true)
    f:Hide()
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f.title = f:CreateFontString(nil, "OVERLAY")
    f.title:SetFontObject("GameFontHighlightLarge")
    f.title:SetPoint("CENTER", f.TitleBg, "CENTER", 5, 0)
    f.title:SetText( title)
    
    createResizeButton(f)
    createTextDisplay(f)
    createReloadButton(f, "BOTTOMLEFT",f, 5, 5)
    createSelectButton(f, "BOTTOMRIGHT",f, 5, -10)
    createClearButton(f, "BOTTOM",f, 5, 5)
    return f
end
function msg:printErrorMsg( msg )
        UIErrorsFrame:AddMessage( msg, 1.0, 1.0, 0.0, nil, true ) 
end
function msg:printInfoMsg( msg )
    UIErrorsFrame:AddMessage( msg, 1.0, 1.0, 0.0, nil, 10 ) 
end
--  Create the frame where info messages are posted
function msg:createMsgFrame( title )
    local f = createTopFrame("MsgFrame", 800, 600, 0, 0, 0 )
    f:SetResizable( true )
    f:SetPoint("TOPRIGHT", -100, -200)
    f:SetFrameStrata("BACKGROUND")
    f:EnableMouse(true)
    f:EnableMouseWheel(true)
    f:SetMovable(true)
    f:Hide()
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    f.title = f:CreateFontString(nil, "OVERLAY");
	f.title:SetFontObject("GameFontHighlight")
    f.title:SetPoint("CENTER", f.TitleBg, "CENTER", 5, 0);
    f.title:SetText(title);

	createResizeButton(f)
	createTextDisplay(f)
	createSelectButton(f,"BOTTOMRIGHT", -10,5 )
    createClearButton(f, "BOTTOMLEFT", 5, 5)
    return f
end
function msg:hideFrame( f )
	if f == nil then
		return
	end
	if f:IsVisible() == true then
		f:Hide()
	end
end
function msg:showFrame(f)
    if f == nil then
        return
	end
	f:Show()
end
function msg:clearFrameText(f)
	if f == nil then
		return
	end
	f.Text:EnableMouse( false )    
	f.Text:EnableKeyboard( false )   
	f.Text:SetText("") 
	f.Text:ClearFocus()
end

local errorFrame = nil
function msg:postResult( result )
    if errorFrame == nil then
        errorFrame = msg:createErrorMsgFrame("Errors: Visual Threat")
    end
    errorFrame:Show()
    errorFrame.Text:Insert( result[2] )
end

-- local frameTitle = L["USER_MSG_FRAME"]
-- local msgFrame = msg:createMsgFrame( frameTitle)

-- function msg:postMsg( message )
--     msg:showFrame( msgFrame )
--     msgFrame.Text:Insert( message )
-- end
