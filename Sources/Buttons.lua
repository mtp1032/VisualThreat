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

local BUTTON_WIDTH = 250
local BUTTON_HEIGHT = 50

local VT_UNIT_NAME               = grp.VT_UNIT_NAME
local VT_UNIT_ID                 = grp.VT_UNIT_ID   
local VT_UNIT_PORTRAIT           = grp.VT_UNIT_PORTRAIT
local VT_ACCUM_THREAT_VALUE      = grp.VT_ACCUM_THREAT_VALUE
local VT_ACCUM_DAMAGE_TAKEN      = grp.VT_ACCUM_DAMAGE_TAKEN
local VT_ACCUM_DAMAGE_DONE       = grp.VT_ACCUM_DAMAGE_DONE
local VT_ACCUM_HEALING_RECEIVED  = grp.VT_ACCUM_HEALING_RECEIVED

local _EMPTY                     = grp._EMPTY

local red = "\124cFFFF0000"
btn.threatIconStack = nil
btn.healsIconStack = nil
btn.damageIconStack = nil

local BAR_WIDTH       = 200
local BAR_HEIGHT      = 20

btn.THREAT_GENERATED  = 1
btn.HEALS_RECEIVED    = 2
btn.DAMAGE_TAKEN      = 3

local THREAT_GENERATED    = btn.THREAT_GENERATED
local HEALS_RECEIVED      = btn.HEALS_RECEIVED
local DAMAGE_TAKEN        = btn.DAMAGE_TAKEN

local stackNames = { "Threat Status", "Heals Received", "Damage Taken" }

local function popUpStats( unitName )

  local f = CreateFrame("Button", "Current Stats", UIParent, "TooltipBackdropTemplate" )
  f:SetBackdropBorderColor(0.5,0.5,0.5)
  f:SetPoint("CENTER", 0, 0)
  f:SetSize(BUTTON_WIDTH, 120)

  f.Name = f:CreateFontString(nil,"ARTWORK", "GameFontNormalLarge")
  f.Name:SetPoint("TOP",0,-10)
  f.Name:SetJustifyH("LEFT")
  f.Name:SetText( unitName )

  local str = nil
  local taken, total = grp:getThreatStats(unitName)
  if total > 0 then
    local relative= (taken/total)*100
    str = sprintf("Threat Generated: %d (%1.f%%)", taken, relative )
    f.Threat = f:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    f.Threat:SetPoint("TOPLEFT", 30 ,-30 )
    f.Threat:SetJustifyH("LEFT")
    f.Threat:SetText(str)
  end

  local taken, total = grp:getDamageStats(unitName)
  if total > 0 then
    local relative= (taken/total)*100
    str = sprintf("Damage Taken: %d (%1.f%%)", taken, relative )
    f.Damage = f:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    f.Damage:SetPoint("TOPLEFT", 30, -50)
    f.Damage:SetJustifyH("LEFT")
    f.Damage:SetText( str )
  end

  local taken, total = grp:getHealingStats(unitName)
  if total > 0 then
    local relative= (taken/total)*100
    str = sprintf("Healing Received: %d (%1.f%%)", taken, relative )
    f.Heals = f:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    f.Heals:SetPoint("TOPLEFT", 30, -70)
    f.Heals:SetJustifyH("LEFT")
    f.Heals:SetText(str)
  end

  local taken, total = grp:getDamageDoneStats(unitName)
  if total > 0 then
    local relative= (taken/total)*100
    str = sprintf("DamageDone: %d (%1.f%%", taken, relative )
    f.DamageDone = f:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    f.DamageDone:SetPoint("TOPLEFT", 30, -90)
    f.DamageDone:SetJustifyH("LEFT")
    f.DamageDone:SetText(str )
  end
  return f
end

local function getClassColor( unitId )
  local guid = UnitGUID( unitId )
  local _, localizedClassName = GetPlayerInfoByGUID( guid )
  return GetClassColor( localizedClassName )
end

local function createStatusBar( parent )

  -- this frame creates a background for the status bar
  local f = CreateFrame("Frame", nil, parent, "TooltipBackdropTemplate")
  f:SetBackdropBorderColor(0.5,0.5,0.5)
  f:SetSize(BAR_WIDTH, BAR_HEIGHT)

  f.statusBar = CreateFrame("StatusBar", nil, f )
  Mixin(f.statusBar, SmoothStatusBarMixin)
  f.statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  f.statusBar:SetMinMaxSmoothedValue(0,1)

  return f.statusBar
end
-- ******************* UNIT TESTING ******************************
-- C_Timer.NewTicker(0.5, function()
--     local val = random(100)/100
--     E:where( tostring( val ))
--     f.statusBar:SetSmoothedValue( val ) 
-- end)

local function createEmptyButton(parent, frameName )

  local buttonFrame = CreateFrame("Button", frameName, parent,"TooltipBackdropTemplate")
  buttonFrame:SetBackdropBorderColor(0.5,0.5,0.5)
  -- buttonFrame:SetAlpha( 0.5 )

  buttonFrame.Portrait = buttonFrame:CreateTexture(nil,"ARTWORK")
  buttonFrame.Portrait:SetSize(BUTTON_HEIGHT-8,BUTTON_HEIGHT-8)
  buttonFrame.Portrait:SetPoint("LEFT",4,0)

  buttonFrame.Name = buttonFrame:CreateFontString(nil,"ARTWORK", "GameFontNormal")
  buttonFrame.Name:SetPoint("TOPLEFT", buttonFrame.Portrait, "TOPRIGHT",6,-4)
  buttonFrame.Name:SetPoint("BOTTOMRIGHT",buttonFrame, "RIGHT",-4, 0 )
  buttonFrame.Name:SetJustifyH("LEFT")

  -- creates a status bar of the player's class color.
  buttonFrame.StatusBar = createStatusBar(buttonFrame)
  buttonFrame.StatusBar:SetPoint("TOPLEFT", buttonFrame.Portrait, "RIGHT",4,-4)
  --buttonFrame.StatusBar:SetPoint("BOTTOMRIGHT",buttonFrame, "RIGHT",-4, 0 )
  buttonFrame.StatusBar:SetPoint("BOTTOMRIGHT",buttonFrame, "RIGHT",-4, -20 )

  Mixin(buttonFrame.StatusBar, SmoothStatusBarMixin)
  buttonFrame.StatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

  return buttonFrame 
end

    ------- CREATES THE FRAME FOR THE PORTRAIT ICONS ---------------
function btn:createIconStack( stackType )

  local groupCount = grp:getTotalMemberCount()

  local f = CreateFrame("Frame", "IconStack", UIParent, "BasicFrameTemplate")
   
    f:SetSize( BUTTON_WIDTH+10, BUTTON_HEIGHT*groupCount+28)
    f.TitleText:SetText( stackNames[stackType])
    f:SetMovable(true)

    ------------ SET, SAVE, and GET FRAME POSITION ---------------------
  local sortedTable = {}
  if stackType == THREAT_GENERATED then
    sortedTable = grp:sortAddonTable( VT_ACCUM_THREAT_VALUE )

    f:SetPoint( framePosition[1], 
                framePosition[2], 
                framePosition[3], 
                framePosition[4], 
                framePosition[5] )
    f:SetScript("OnMouseDown",f.StartMoving)
    f:SetScript("OnMouseUp", function(self)
      f:StopMovingOrSizing()
      framePosition = {f:GetPoint()}
    end)
  end
  if stackType == HEALS_RECEIVED then
    sortedTable = grp:sortAddonTable( VT_ACCUM_HEALING_RECEIVED )
    f:SetPoint( healsFramePosition[1], 
                healsFramePosition[2], 
                healsFramePosition[3], 
                healsFramePosition[4], 
                healsFramePosition[5] )
    f:SetScript("OnMouseDown",f.StartMoving)
    f:SetScript("OnMouseUp", function(self)
      f:StopMovingOrSizing()
      healsFramePosition = {f:GetPoint()}
    end)
  end
  if stackType == DAMAGE_TAKEN then
    sortedTable = grp:sortAddonTable( VT_ACCUM_DAMAGE_TAKEN )

    f:SetPoint( damageFramePosition[1], 
                damageFramePosition[2], 
                damageFramePosition[3], 
                damageFramePosition[4], 
                damageFramePosition[5] )
    f:SetScript("OnMouseDown",f.StartMoving)
    f:SetScript("OnMouseUp", function(self)
      f:StopMovingOrSizing()
      damageFramePosition = {f:GetPoint()}
    end)
  end

  for i, entry in ipairs( sortedTable ) do

    local unitName = entry[VT_UNIT_NAME]
    local unitId   = entry[VT_UNIT_ID]
    local displayFrame = {}
    
    local frameName = nil
    if stackType == DAMAGE_TAKEN then
      frameName = "DAMAGE TAKEN"
    end
    if stackType == HEALS_RECEIVED then
      frameName = "HEALS RECEIVED"
    end
    if stackType == THREAT_GENERATED then
      frameName = "THREAT GENERATED"
    end

    entry[VT_UNIT_PORTRAIT] = createEmptyButton(f, frameName )
    entry[VT_UNIT_PORTRAIT]:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    entry[VT_UNIT_PORTRAIT]:SetPoint("TOPLEFT",5,-((i-1)*BUTTON_HEIGHT)-24)
    if i > 1 then
      entry[VT_UNIT_PORTRAIT]:SetAlpha( 0.2)
    end

    entry[VT_UNIT_PORTRAIT]:SetScript("OnEnter", function( self, ... )
        local frameName = GetMouseFocus():GetName()
        local statType = 0
        if frameName == "DAMAGE TAKEN" then
          statType = DAMAGE_TAKEN
        elseif frameName == "HEALS RECEIVED" then
          statType = HEALS_RECEIVED
        else
          statType = THREAT_GENERATED
        end
        displayFrame = popUpStats( entry, statType )
    end)
    entry[VT_UNIT_PORTRAIT]:SetScript("OnLeave", function( self, ... )
      displayFrame:Hide()
    end)
    entry[VT_UNIT_PORTRAIT]:SetScript("OnClick", function( self, button )
      displayFrame:Hide()
    end)

    SetPortraitTexture( entry[VT_UNIT_PORTRAIT].Portrait, unitId )
    entry[VT_UNIT_PORTRAIT].Name:SetText( unitName )

    local r, g, b = getClassColor( unitId )
    entry[VT_UNIT_PORTRAIT].StatusBar:SetStatusBarColor(r, g, b )
        
    local relativeValue = 0
    if stackType == THREAT_GENERATED then
      local memberTotalThreat, groupTotalThreat  = grp:getThreatStats( unitName )
      if totalTotalThreat ~= 0 then
        relativeValue = memberTotalThreat/groupTotalThreat  
      end 
    end       
    if stackType == HEALS_RECEIVED then
        local membersHealing, totalHealing = grp:getHealingStats( unitName )
        if totalHealing ~= 0 then
          relativeValue = membersHealing / totalHealing
        end
    end
    if stackType == DAMAGE_TAKEN then
        local membersDamage, totalDamage = grp:getDamageTakenStats( unitName )
        if totalDamage ~= 0 then
          relativeValue = membersDamage / totalDamage
        end
    end
    entry[VT_UNIT_PORTRAIT].StatusBar:SetSmoothedValue( relativeValue )
  end
  return f
end  
