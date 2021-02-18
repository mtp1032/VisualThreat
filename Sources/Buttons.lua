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

local BUTTON_WIDTH = 260  -- was 250
local BUTTON_HEIGHT = 35 -- was 50

local VT_UNIT_NAME               = grp.VT_UNIT_NAME
local VT_UNIT_ID                 = grp.VT_UNIT_ID   
local VT_UNIT_FRAME           = grp.VT_UNIT_FRAME
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

-- frameName = GetMouseFocus():GetName())


local stackNames = { "Threat Status (% Total)", "Heals Received (% Total)", "Damage Taken (% Total)" }


--[[ 

How to get the popup to popup when the mouse is over one of the
Blizzard party frames:

Note party frame names are named "PartyMemberFrameN" where N - 1, 2, 3, or 4

Steps:
1)  Use GetMouseFocus():GetName() to obtain the name of the unitframe over which the
    mouse is hovering.
2)  Parse the frame name for the member id. For example, PartyMemberFrame3 
    has a unitId of party3. 
3)  Get the UserName using grp:getMemberNameById( unitId
4)  Pass the user name to the PopUp window.
 ]]
 local function drawLine(yPos, f)
	local lineFrame = CreateFrame("FRAME", nil, f )
	lineFrame:SetPoint("CENTER", -10, yPos )
	lineFrame:SetSize( BUTTON_WIDTH - 10, BUTTON_WIDTH - 10 )
	
	local line = lineFrame:CreateLine()
	line:SetColorTexture(.5, .5, .5, 1) -- Grey per https://wow.gamepedia.com/Power_colors
	line:SetThickness(1)
	line:SetStartPoint("TOPLEFT",10, -10)
	line:SetEndPoint("TOPRIGHT", 10, -10 )
	lineFrame:Show() 
 end

local function popUpStats( unitName )

  local f = CreateFrame("Button", "Current Stats", nil, "TooltipBackdropTemplate" )
  f:SetBackdropBorderColor(0.5,0.5,0.5)
  f:SetPoint("RIGHT", -100, -100)
  f:SetSize(BUTTON_WIDTH, 120)

  -- f.Name = f:CreateFontString(nil,"ARTWORK", "GameFontHighlightLarge")
  f.Name = f:CreateFontString(nil,"ARTWORK", "GameFontNormal")
  f.Name:SetPoint("TOPLEFT",10,-8)
  f.Name:SetJustifyH("LEFT")
  f.Name:SetText( unitName )
  local partyTable = grp:getAddonPartyTable()
  for _, entry in ipairs( partyTable ) do
    if entry[VT_UNIT_NAME] == unitName then
      local unitGuid = UnitGUID( entry[VT_UNIT_ID])
      local class, _, race, gender, name, realm = GetPlayerInfoByGUID( unitGuid )
      local level = UnitEffectiveLevel( entry[VT_UNIT_ID] )
      local ownerName = grp:getOwnerByPetName( unitName )
      local _, faction = UnitFactionGroup( entry[VT_UNIT_ID])
      if ownerName then
        f.Name:SetFormattedText( "%s - %s's Pet", unitName, ownerName, level )
      else
        f.Name:SetFormattedText( "%s - level %d %s (%s)", unitName, level, class, faction )
      end
    end
  end

  drawLine( -80, f )
  
  local str = nil
  local taken, total = grp:getThreatStats(unitName)
  if total > 0 then
    local relative= (taken/total)*100
    str = sprintf("Threat Generated: %d (%1.f%%)", taken, relative )
    f.Threat = f:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
    f.Threat:SetPoint("TOPLEFT", 10 ,-40 )
    f.Threat:SetJustifyH("LEFT")
    f.Threat:SetText(str)
  end
  local taken, total = grp:getDamageTakenStats(unitName)
  if total > 0 then
    local relative= (taken/total)*100
    str = sprintf("Damage Taken: %d (%1.f%%)", taken, relative )
    f.Damage = f:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
    f.Damage:SetPoint("TOPLEFT", 10, -60)
    f.Damage:SetJustifyH("LEFT")
    f.Damage:SetText( str )
  end
  local taken, total = grp:getHealingStats(unitName)
  if total > 0 then
    local relative= (taken/total)*100
    str = sprintf("Healing Received: %d (%1.f%%)", taken, relative )
    f.Heals = f:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
    f.Heals:SetPoint("TOPLEFT", 10, -80)
    f.Heals:SetJustifyH("LEFT")
    f.Heals:SetText(str)
  end
  local taken, total = grp:getDamageDoneStats(unitName)
  if total > 0 then
    local relative= (taken/total)*100
    str = sprintf("DamageDone: %d (%1.f%%", taken, relative )
    f.DamageDone = f:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
    f.DamageDone:SetPoint("TOPLEFT", 10, -100)
    f.DamageDone:SetJustifyH("LEFT")
    f.DamageDone:SetText(str )
  end
  return f
end

-- PartyMemberFrame1:SetScript("OnEnter", function( self, ... )
--   popUpStats( Predator)
-- end)

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
--     f.statusBar:SetSmoothedValue( val ) 
-- end)

local function createEmptyButton(parent, frameName )

  local buttonFrame = CreateFrame("Button", frameName, parent,"TooltipBackdropTemplate")
  buttonFrame:SetBackdropBorderColor(0.5,0.5,0.5)
  -- buttonFrame:SetAlpha( 0.5 )

  buttonFrame.Portrait = buttonFrame:CreateTexture(nil,"ARTWORK")
  buttonFrame.Portrait:SetSize(BUTTON_HEIGHT-8,BUTTON_HEIGHT-8)
  buttonFrame.Portrait:SetPoint("LEFT",4,0)

  buttonFrame.Name = buttonFrame:CreateFontString(nil,"ARTWORK", "GameFontNormalSmall")
  buttonFrame.Name:SetPoint("TOPLEFT", buttonFrame.Portrait, "TOPRIGHT",6,-4)
  buttonFrame.Name:SetPoint("BOTTOMRIGHT",buttonFrame, "RIGHT",-4, 0 )
  buttonFrame.Name:SetJustifyH("LEFT")

  -- creates a status bar of the player's class color.
  buttonFrame.StatusBar = createStatusBar(buttonFrame)
  buttonFrame.StatusBar:SetPoint("TOPLEFT", buttonFrame.Portrait, "RIGHT",4,-4) -- original
  buttonFrame.StatusBar:SetPoint("BOTTOMRIGHT",buttonFrame, "RIGHT",-4, -10 )
  -- buttonFrame.StatusBar:SetPoint("BOTTOMRIGHT",buttonFrame, "RIGHT",-4, -20 ) -- original

  Mixin(buttonFrame.StatusBar, SmoothStatusBarMixin)
  buttonFrame.StatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

  return buttonFrame 
end
    ------- CREATES THE FRAME FOR THE PORTRAIT ICONS ---------------
function btn:createIconStack( stackType )

  --------- DEBUG -------
  if stackType == HEALS_RECEIVED then return end
  ------- END DEBUG -----

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
    local popUpFrame = {}
    
    if stackType == DAMAGE_TAKEN then
      frameName = "DAMAGE TAKEN"
    end
    if stackType == HEALS_RECEIVED then
      frameName = "HEALS RECEIVED"
    end
    if stackType == THREAT_GENERATED then
      frameName = "THREAT GENERATED"
    end

    entry[VT_UNIT_FRAME] = createEmptyButton(f, frameName )
    entry[VT_UNIT_FRAME]:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    entry[VT_UNIT_FRAME]:SetPoint("TOPLEFT",5,-((i-1)*BUTTON_HEIGHT)-24)
    -- if i > 1 then
    --   entry[VT_UNIT_FRAME]:SetAlpha( 0.2)
    -- end
    entry[VT_UNIT_FRAME]:SetScript("OnEnter", function( self, ... )
        local frame = GetMouseFocus()
        local frameName = frame:GetName()
        popUpFrame = popUpStats( entry[VT_UNIT_NAME] )
    end)
    entry[VT_UNIT_FRAME]:SetScript("OnLeave", function( self, ... )
      popUpFrame:Hide()
    end)
    entry[VT_UNIT_FRAME]:SetScript("OnClick", function( self, button )
      popUpFrame:Hide()
    end)

    SetPortraitTexture( entry[VT_UNIT_FRAME].Portrait, unitId )
    local r, g, b = getClassColor( unitId )
    entry[VT_UNIT_FRAME].StatusBar:SetStatusBarColor(r, g, b )
        
        ---------------------- THREAT GENERATE ----------------------------
    if stackType == THREAT_GENERATED then
      local relativeThreat = 0
      local memberTotalThreat, groupTotalThreat  = grp:getThreatStats( unitName )
      if groupTotalThreat ~= 0 then
        relativeThreat = memberTotalThreat/groupTotalThreat  
      end

      if relativeThreat == 0 then
        entry[VT_UNIT_FRAME].Name:SetFormattedText( "%s", unitName )
      else
        entry[VT_UNIT_FRAME].Name:SetFormattedText( "%s: %0.1f%%", unitName, relativeThreat * 100 )
      end

      entry[VT_UNIT_FRAME].StatusBar:SetSmoothedValue( relativeThreat )
    end  
    ------------------------  HEALING RECEIVED ---------------------
    if stackType == HEALS_RECEIVED then
      local relativeHealing = 0
      local memberTotalHealing, groupTotalHealing  = grp:getHealingStats( unitName )
      if groupTotalHealing ~= 0 then
        relativeHealing = memberTotalHealing/groupTotalHealing 
      end

      if relativeHealing == 0 then
        entry[VT_UNIT_FRAME].Name:SetFormattedText( "%s", unitName )
      else
        entry[VT_UNIT_FRAME].Name:SetFormattedText( "%s: %0.1f%%", unitName, relativeHealing * 100 )
      end

      entry[VT_UNIT_FRAME].StatusBar:SetSmoothedValue( relativeHealing )
    end
    ---------------------- DAMAGE TAKEN ----------------------------
    if stackType == DAMAGE_TAKEN then
      local relativeDamage = 0
      local memberTotalDamage, groupTotalDamage  = grp:getDamageTakenStats( unitName )
      if groupTotalDamage ~= 0 then
        relativeDamage = memberTotalDamage/groupTotalDamage  
      end

      if relativeDamage == 0 then
        entry[VT_UNIT_FRAME].Name:SetFormattedText( "%s", unitName )
      else
        entry[VT_UNIT_FRAME].Name:SetFormattedText( "%s: %0.1f%%", unitName, relativeDamage * 100 )
      end

      entry[VT_UNIT_FRAME].StatusBar:SetSmoothedValue( relativeDamage )
    end  
  end
  return f
end  
