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

local BUTTON_WIDTH = 230
local BUTTON_HEIGHT = 80

local VT_UNIT_NAME               = grp.VT_UNIT_NAME
local VT_UNIT_ID                 = grp.VT_UNIT_ID   
local VT_PET_OWNER               = grp.VT_PET_OWNER 
local VT_MOB_ID                  = grp.VT_MOB_ID                  
local VT_AGGRO_STATUS            = grp.VT_AGGRO_STATUS              
local VT_THREAT_VALUE            = grp.VT_THREAT_VALUE             
local VT_THREAT_VALUE_RATIO      = grp.VT_THREAT_VALUE_RATIO
local VT_DAMAGE_TAKEN            = grp.VT_DAMAGE_TAKEN
local VT_HEALING_RECEIVED        = grp.VT_HEALING_RECEIVED
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

  buttonFrame.Damage = buttonFrame:CreateFontString(nil,"ARTWORK","GameFontHighlight")
  buttonFrame.Damage:SetPoint("TOPLEFT",buttonFrame.Portrait,"RIGHT",4,35)
  buttonFrame.Damage:SetPoint("BOTTOMRIGHT",-4,4)
  buttonFrame.Damage:SetJustifyH("LEFT")

  return buttonFrame 
end

local red = "\124cFFFF0000"

local function updateButton( entry, button )
    local unitId        = entry[VT_UNIT_ID]
    local playerName    = entry[VT_UNIT_NAME]
    local threatRatio   = entry[VT_THREAT_VALUE_RATIO]*100
    local damageTaken   = entry[VT_DAMAGE_TAKEN]
    local HealingReceived  = entry[VT_HEALING_RECEIVED]

    SetPortraitTexture( button.Portrait, unitId )
    button.Name:SetText( playerName )
    
    local damageTaken = grp:getDamageTaken( playerName )
    -- E:where( damageTaken )
    local dmgStr = sprintf("Damage taken %d", damageTaken)
    button.Damage:SetText( dmgStr )

    local str = sprintf( "Threat: "..red.." %d%%", threatRatio)
    button.Threat:SetText( str )
end

function btn:createIconFrame()

  -- PARTY STUFF
  if grp.playersParty == nil then
    print("this is a problem")
    return
  end
  local partyCount = #grp.playersParty

  ------- CREATE THE FRAME FOR THE PORTRAIT ICONS ---------------
  local f = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplate")
  f:SetSize(BUTTON_WIDTH+10,BUTTON_HEIGHT*partyCount+28)
  f.TitleText:SetText("Threat Stack")
  ------------ SET AND GET FRAME POSITION ---------------------
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

    local i = 1
    for _, entry in ipairs( grp.playersParty ) do
      f.portraitButtons[i] = createEmptyButton(f)

      f.portraitButtons[i]:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
      f.portraitButtons[i]:SetPoint("TOPLEFT",5,-((i-1)*BUTTON_HEIGHT)-24)

      ----- SET WHAT HAPPENS WHEN A PORTRAIT IS CLICKED -----------
      f.portraitButtons[i]:SetScript("OnClick", function(self)
        local playerName = self.Name:GetText()

        local dmg = grp:getDamageTaken( playerName )
        local status = UnitThreatSituation( entry[VT_UNIT_ID], targetId )
        local r = 0 g = 0 b = 0
        if status > 0 then
          if status == 1 then
            -- r = 255 g = 255 b = 255
            r = 1.0 g = 1.0 b = 1.0 
         elseif status == 2 then
            --r = 0 g = 255 b = 0
            r = 0.0 g = 1.0 b = 0.0
          elseif status == 3 then
            -- r = 255 g = 255 b = 0
            r = 1.0 g = 1.0 b = 0.0
          elseif status == 4 then
            -- r = 255 g = 0 b = 0
            r = 1.0 g = 0.0 b = 0.0
          end

          -- local r, g, b = GetThreatStatusColor(status)
          local dmgTxt = sprintf("Cumulative damage taken by %s: %d", playerName, dmg)
          DEFAULT_CHAT_FRAME:AddMessage( dmgTxt, r, g, b )
        end
      end)
      entry[VT_BUTTON] = f.portraitButtons[i]
      updateButton( entry, f.portraitButtons[i] )
      i = i + 1
    end
    return f
end
-- called from ThreatEventHandler
function btn:updatePortraitButtons()
    for _, entry in ipairs( grp.playersParty ) do        
      local button = entry[VT_BUTTON]
      if button ~= nil then
          updateButton( entry, button )
      else
        -- E:where( "button = nil")
      end
    end

    -- sort the grp.playersParty and then copy the sorted
    -- table into the f.portraitButtons table.
    table.sort( grp.playersParty, highToLow )

    local i = 1
    for _, entry in ipairs( grp.playersParty ) do
        local button = entry[VT_BUTTON]
        if button ~= nil then
          button:SetPoint("TOPLEFT",5,-((i-1)*BUTTON_HEIGHT)-24)
        end
        i = i + 1
    end
    return f
end

btn.threatIconFrame = nil 

    -- local status = UnitThreatSituation( entry[VT_UNIT_ID], targetId )
    -- if status > 0 then
    --   if status == 1 then
    --     -- r = 255 g = 255 b = 255
    --     r = 1.0 g = 1.0 b = 1.0 
    --  elseif status == 2 then
    --     --r = 0 g = 255 b = 0
    --     r = 0.0 g = 1.0 b = 0.0
    --   elseif status == 3 then
    --     -- r = 255 g = 255 b = 0
    --     r = 1.0 g = 1.0 b = 0.0
    --   elseif status == 4 then
    --     -- r = 255 g = 0 b = 0
    --     r = 1.0 g = 0.0 b = 0.0
    --   end
    -- end
