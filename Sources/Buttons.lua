--------------------------------------------------------------------------------------
-- Buttons.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 15 December, 2020
-- REMARKS: This derived directly from the original code that appeared in the WoW UI 
--          forums written Gello
-- https://wow.gamepedia.com/API_Region_GetPoint
-- https://wow.gamepedia.com/API_Region_SetPoint 

--------------------------------------------------------------------------------------
local _, VisualThreat = ...
VisualThreat.Buttons = {}
btn = VisualThreat.Buttons
local L = VisualThreat.L
local E = errors 
local sprintf = _G.string.format 

local BUTTON_WIDTH = 150
local BUTTON_HEIGHT = 40

local VT_UNIT_NAME               = grp.VT_UNIT_NAME
local VT_UNIT_ID                 = grp.VT_UNIT_ID   
local VT_PET_OWNER               = grp.VT_PET_OWNER 
local VT_MOB_ID                  = grp.VT_MOB_ID                  
local VT_AGGRO_STATUS            = grp.VT_AGGRO_STATUS              
local VT_THREAT_VALUE            = grp.VT_THREAT_VALUE             
local VT_THREAT_VALUE_RATIO      = grp.VT_THREAT_VALUE_RATIO
local VT_DAMAGE_TAKEN            = grp.VT_DAMAGE_TAKEN
local VT_HEALING_TAKEN           = grp.VT_HEALING_TAKEN
local VT_BUTTON                  = grp.VT_BUTTON
local VT_NUM_ELEMENTS            = grp.VT_BUTTON

local function highToLow( entry1, entry2)
  return entry1[VT_THREAT_VALUE_RATIO ] > entry2[VT_THREAT_VALUE_RATIO]
end

-- called  by createIconFrame()
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

  return buttonFrame 
end
local function updateButton( entry, button )
    local unitId        = entry[VT_UNIT_ID]
    local name          = entry[VT_UNIT_NAME]
    local threat        = entry[VT_THREAT_VALUE_RATIO]*100
    local damageTaken   = entry[VT_DAMAGE_TAKEN]
    local healingTaken  = entry[VT_HEALING_TAKEN]

    SetPortraitTexture( button.Portrait, unitId )
    button.Name:SetText( name )
    local str = sprintf( "%d%%", threat )
    button.Threat:SetText( str )
    msg:post( sprintf("%s hit for %d damage. Has %d%% threat\n", name, damageTaken, threat ))
end

function btn:createIconFrame()
  local playersParty = grp:getPlayersParty()
  if playersParty == nil then
    print("this is a problem")
  end
  local partyCount = #playersParty
  local f = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplate")

  f:SetSize(BUTTON_WIDTH+10,BUTTON_HEIGHT*partyCount+28)

  ------------------- SET POINT ---------------------
  f:SetPoint( framePosition[1], 
                framePosition[2], 
                framePosition[3], 
                framePosition[4], 
                framePosition[5] )
  f.TitleText:SetText("Threat Stack")
  ------------------- SET POINT ---------------------


  ------------------- GET POINT ----------------------
  f:SetMovable(true)
  f:SetScript("OnMouseDown",f.StartMoving)
  f:SetScript("OnMouseUp", function(self)
    f:StopMovingOrSizing()
    framePosition = {f:GetPoint()}
  ------------------ GET POINT ----------------------
  end)

    -- create and position icon buttons (portraits) anchored to the parent.
    -- create one button for each party member.
    f.unitButtons = {}

    local i = 1
    for _, entry in ipairs( playersParty ) do
      f.unitButtons[i] = createEmptyButton(f)
      f.unitButtons[i]:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
      f.unitButtons[i]:SetPoint("TOPLEFT",5,-((i-1)*BUTTON_HEIGHT)-24)
      f.unitButtons[i]:SetScript("OnClick", function(self)
        iconName = self.Name:GetText()
        if iconName ~= nil then
          local dmg = ch:getDamageByName( iconName )
          msg:post( sprintf("OnClick: %s damage: %d\n", iconName, dmg ))
          local attackerId = sprintf("%s-target", iconName)
          enemyTargetingPlayer = UnitName( attackerId )
          if enemyTargetingPlayer ~= nil then
            msg:post(sprintf("Target of %s - %s\n", iconName, enemyTargetingPlayer ))
          end
        end
      end)
      -- local alphaFactor = 0.2
      -- local alpha = i - (i - 1)*(alphaFactor)
      -- f.unitButtons[i]:SetAlpha( alpha )
      entry[VT_BUTTON] = f.unitButtons[i]
      updateButton( entry, f.unitButtons[i] )
      i = i + 1
    end
    return f
end
-- called from ThreatEventHandler
function btn:updatePortraitButtons( iconFrame )
  local playersParty = grp:getPlayersParty()
    for _, entry in ipairs( playersParty) do        
      local button = entry[VT_BUTTON]
      if button ~= nil then
          updateButton( entry, button )
      end
    end

    -- sort the playersParty and then copy the sorted
    -- table into the f.unitButtons table.
    table.sort( playersParty, highToLow )

    local i = 1
    for _, entry in ipairs( playersParty ) do
        local button = entry[VT_BUTTON]
        if button ~= nil then
          button:SetPoint("TOPLEFT",5,-((i-1)*BUTTON_HEIGHT)-24)
        end
        i = i + 1
    end

    return f
end

btn.threatIconFrame = nil 
local threatIconFrame = btn.threatIconFrame

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")			-- arg1: boolean isInitialLogin, arg2: boolean isReloadingUI
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("GROUP_JOINED")
eventFrame:RegisterEvent("GROUP_LEFT")
eventFrame:RegisterEvent("PET_DISMISS_START")
eventFrame:SetScript("OnEvent", 
function( self, event, ... )
	local arg1, arg2, arg3, arg4 = ...
    local r = {STATUS_SUCCESS, nil, nil}

    ------------------------------ PLAYER ENTERING WORLD -----------------
    if event == "PLAYER_ENTERING_WORLD" then

        local playersParty, r = grp:initPlayersParty()
        if playersParty == nil or r[1] == STATUS_FAILURE then
            local s = sprintf("[FAILED: initPlayerParty()] %s\n%s\n\n",r[2], r[3])
            msg:post(s)
            return
        end     
        threatIconFrame = btn:createIconFrame()
        btn:updatePortraitButtons( threatIconFrame )
        return
    end
--------------------------- GROUP ROSTER UPDATE ---------------------
    if event == "GROUP_ROSTER_UPDATE" then
        local playersParty, r = grp:initPlayersParty()
        if playersParty == nil or r[1] == STATUS_FAILURE then
            local s = sprintf("[FAILED: initPlayerParty()] %s\n%s\n\n",r[2], r[3])
            msg:post(s)
            return
        end
        threatIconFrame = btn:createIconFrame()
        btn:updatePortraitButtons( threatIconFrame )
        return
    end
    if event == "GROUP_JOINED" then
      local playersParty, r = grp:initPlayersParty()
      if playersParty == nil or r[1] == STATUS_FAILURE then
          local s = sprintf("[FAILED: initPlayerParty()] %s\n%s\n\n",r[2], r[3])
          msg:post(s)
          return
      end
      threatIconFrame = btn:createIconFrame()
      btn:updatePortraitButtons( threatIconFrame )
    return
    end

    if event == "GROUP_LEFT" then
      local playersParty, r = grp:initPlayersParty()
      if playersParty == nil or r[1] == STATUS_FAILURE then
          local s = sprintf("[FAILED: initPlayerParty()] %s\n%s\n\n",r[2], r[3])
          msg:post(s)
          return
      end
      threatIconFrame = btn:createIconFrame()
      btn:updatePortraitButtons( threatIconFrame )
    return
    end

    if event == "PET_DISMISS_START" then
      local playersParty, r = grp:initPlayersParty()
      if playersParty == nil or r[1] == STATUS_FAILURE then
          local s = sprintf("[FAILED: initPlayerParty()] %s\n%s\n\n",r[2], r[3])
          msg:post(s)
          return
      end
      threatIconFrame = btn:createIconFrame()
      btn:updatePortraitButtons( threatIconFrame )
    return
    end
end)

