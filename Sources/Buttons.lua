--------------------------------------------------------------------------------------
-- Buttons.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 15 December, 2020
-- REMARKS: This derived directly from the original code that appeared in the WoW UI 
--          forums written Gello
-- https://wow.gamepedia.com/API_Region_GetPoint
-- https://wow.gamepedia.com/API_Region_SetPoint 
--[[ 
PROBLEM:
1) Warwraith's portrait is blank sometimes
2) AddOn must be reloaded (i.e., PLAYER_ENTERING_WORLD fired) in order for
   group leader's icon to show.

 ]]--------------------------------------------------------------------------------------
local _, VisualThreat = ...
VisualThreat.Buttons = {}
btn = VisualThreat.Buttons

local L = VisualThreat.L
local E = errors 
local sprintf = _G.string.format 

local BUTTON_WIDTH = 230
local BUTTON_HEIGHT = 80

local VT_UNIT_NAME               = grp.VT_UNIT_NAME
local VT_UNIT_ID                 = grp.VT_UNIT_ID   
local VT_BUTTON                  = grp.VT_BUTTON

local red = "\124cFFFF0000"
btn.threatIconStack = nil

-- called  by createIconStack()
local function createEmptyButton(parent)

  local buttonFrame = CreateFrame("Button",nil,parent,"TooltipBackdropTemplate")
  buttonFrame:SetBackdropBorderColor(0.5,0.5,0.5)

  buttonFrame.Portrait = buttonFrame:CreateTexture(nil,"ARTWORK")
  buttonFrame.Portrait:SetSize(BUTTON_HEIGHT-8,BUTTON_HEIGHT-8)
  buttonFrame.Portrait:SetPoint("LEFT",4,0)

  buttonFrame.Name = buttonFrame:CreateFontString(nil,"ARTWORK", "GameFontNormal")
  buttonFrame.Name:SetPoint("TOPLEFT",buttonFrame.Portrait,"TOPRIGHT",4,-4)
  buttonFrame.Name:SetPoint("BOTTOMRIGHT",buttonFrame,"RIGHT",-4,0)
  buttonFrame.Name:SetJustifyH("LEFT")

  buttonFrame.Threat = buttonFrame:CreateFontString(nil,"ARTWORK","GameFontHighlight")
  buttonFrame.Threat:SetPoint("TOPLEFT",buttonFrame.Portrait,"RIGHT",4,0)
  buttonFrame.Threat:SetPoint("BOTTOMRIGHT",-4,4)
  buttonFrame.Threat:SetJustifyH("LEFT")

  buttonFrame.Damage = buttonFrame:CreateFontString(nil,"ARTWORK","GameFontHighlight")
  buttonFrame.Damage:SetPoint("TOPLEFT",buttonFrame.Portrait,"RIGHT",4,35)
  buttonFrame.Damage:SetPoint("BOTTOMRIGHT",-4,4)
  buttonFrame.Damage:SetJustifyH("LEFT")

  return buttonFrame 
end
local function updateButton( entry )
    local button          = entry[VT_BUTTON]
    local unitId          = entry[VT_UNIT_ID]
    local unitName        = entry[VT_UNIT_NAME]
    local membersThreat, totalThreat  = grp:getThreatStats( unitName )
    local damageTaken, damageDone     = grp:getDamageStats( unitName )
    local HealingReceived             = grp:getHealingStats( unitName)

    SetPortraitTexture( button.Portrait, unitId )
    button.Name:SetText( unitName )
    
    local dmgStr = sprintf("Damage taken %d", damageTaken)
    button.Damage:SetText("")
    button.Damage:SetText( dmgStr )

    -- local threatStr = sprintf( "Threat: "..red.." %d%%", threatRatio)
    local relativeThreat = 0
    if totalThreat ~= 0 then
      relativeThreat = membersThreat/totalThreat
    end
    local threatStr = sprintf( "Threat:  %0.2f%%", relativeThreat * 100)

    button.Threat:SetText( "" )
    button.Threat:SetText( threatStr )
end
function btn:createIconStack()

    local groupCount = grp:getTotalMemberCount()
    if groupCount == 0 then return end

    ------- CREATE THE FRAME FOR THE PORTRAIT ICONS ---------------
    local f = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplate")
    f:SetSize(BUTTON_WIDTH+10,BUTTON_HEIGHT*groupCount+28)
    f.TitleText:SetText("Threat Stack")
  ------------ SET, SAVE, and GET FRAME POSITION ---------------------
    f:SetPoint( framePosition[1], 
                framePosition[2], 
                framePosition[3], 
                framePosition[4], 
                framePosition[5] )
    f:SetMovable(true)
    f:SetScript("OnMouseDown",f.StartMoving)
    f:SetScript("OnMouseUp", function(self)
      f:StopMovingOrSizing()
      framePosition = {f:GetPoint()}
    end)

    ---- CREATE A PORTRAIT BUTTON FOR EACH PARTY MEMBER -------
    f.portraitButtons = {} 
    local addonParty = grp:getAddonPartyTable()

    for i, entry in ipairs( addonParty ) do
      f.portraitButtons[i] = createEmptyButton(f)
      f.portraitButtons[i]:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
      f.portraitButtons[i]:SetPoint("TOPLEFT",5,-((i-1)*BUTTON_HEIGHT)-24)

      entry[VT_BUTTON] = f.portraitButtons[i]
      updateButton( entry )
    end
    return f
end
