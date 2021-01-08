--------------------------------------------------------------------------------------
-- Buttons.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 15 December, 2020
-- REMARKS: This derived directly from the original code that appeared in the WoW UI 
--          forums written Gello
--------------------------------------------------------------------------------------
local _, VisualThreat = ...
VisualThreat.Buttons = {}
btn = VisualThreat.Buttons
local L = VisualThreat.L
local E = errors
local sprintf = _G.string.format 

local BUTTON_WIDTH = 150
local BUTTON_HEIGHT = 40

-- element indices into the playerMembersTable (see GroupEventHandler.lua )
btn.ENTRY_UNIT_NAME               = 1   -- playerName or petName
btn.ENTRY_UNIT_ID                 = 2   -- UUID of player or pet
btn.ENTRY_PET_OWNER               = 3   --  petOwner, nil if not a pet
btn.ENTRY_MOB_ID                  = 4                  
btn.ENTRY_AGGRO_STATUS            = 5              
btn.ENTRY_THREAT_VALUE            = 6             
btn.ENTRY_THREAT_VALUE_RATIO      = 7   
btn.ENTRY_BUTTON                  = 8 
btn.ENTRY_NUM_ELEMENTS            = btn.ENTRY_BUTTON

local ENTRY_UNIT_NAME               = btn.ENTRY_UNIT_NAME -- playerName or petName             
local ENTRY_UNIT_ID 		            = btn.ENTRY_UNIT_ID	  -- corresponding playerName or petName
local ENTRY_PET_OWNER               = btn.ENTRY_PET_OWNER -- petOwnerName (nil if ENTRY_UNIT_ID not a petId )
local ENTRY_MOB_ID			            = btn.ENTRY_MOB_ID    -- UUID of mob targeting player                    
local ENTRY_AGGRO_STATUS 		        = btn.ENTRY_AGGRO_STATUS  -- 1, 2, 3, 4 (see https://wow.gamepedia.com/API_UnitDetailedThreatSituation )             
local ENTRY_THREAT_VALUE 		        = btn.ENTRY_THREAT_VALUE  --  see https://wow.gamepedia.com/API_UnitDetailedThreatSituation               
local ENTRY_THREAT_VALUE_RATIO      = btn.ENTRY_THREAT_VALUE_RATIO  -- calculated: (playerThreatValue/totalThreatValue)
local ENTRY_BUTTON                  = btn.ENTRY_BUTTON
local ENTRY_NUM_ELEMENTS            = btn.ENTRY_BUTTON


-- https://wow.gamepedia.com/API_Region_GetPoint
-- point, relativeTo, relativePoint, xOfs, yOfs = MyRegion:GetPoint(n)

-- https://wow.gamepedia.com/API_Region_SetPoint 

-- Utility function to order by threatValue (from highest to lowest)
local function highToLow( entry1, entry2)
  return entry1[ENTRY_THREAT_VALUE_RATIO ] > entry2[ENTRY_THREAT_VALUE_RATIO]
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

function btn:updateButton( entry, button )
    local unitId  = entry[ENTRY_UNIT_ID]
    local name    = entry[ENTRY_UNIT_NAME]
    local threat  = entry[ENTRY_THREAT_VALUE_RATIO]*100

    SetPortraitTexture( button.Portrait, unitId )
    button.Name:SetText( name )
    local str = sprintf( "%d%%", threat )
    button.Threat:SetText( str )
end
-- create a vertical display (stack) of icons each of which represents
-- a party member (including pets). The icons will show 0% threat.
function btn:createIconFrame( partyMembersTable )

  local partyCount = #partyMembersTable
    local f = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplate")
    f:SetSize(BUTTON_WIDTH+10,BUTTON_HEIGHT*partyCount+28)
    f:SetPoint( "RIGHT")
    f.TitleText:SetText("Threat Stack")

    -- make frame movable
    f:SetMovable(true)
    f:SetScript("OnMouseDown",f.StartMoving)
    f:SetScript("OnMouseUp",f.StopMovingOrSizing)

    -- create and position icon buttons (portraits) anchored to the parent.
    -- create one button for each party member.
    f.unitButtons = {}

    local i = 1
    for _, entry in ipairs( partyMembersTable ) do
      f.unitButtons[i] = createEmptyButton(f)
      f.unitButtons[i]:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
      f.unitButtons[i]:SetPoint("TOPLEFT",5,-((i-1)*BUTTON_HEIGHT)-24)
      -- local alphaFactor = 0.2
      -- local alpha = i - (i - 1)*(alphaFactor)
      -- f.unitButtons[i]:SetAlpha( alpha )
      entry[ENTRY_BUTTON] = f.unitButtons[i]
      btn:updateButton( entry, f.unitButtons[i] )
      i = i + 1
    end
    return f
end

function btn:updatePortraitButtons(iconFrame, partyMembersTable )
    for _, entry in ipairs( partyMembersTable) do
      local button = entry[ENTRY_BUTTON]
      if button ~= nil then
          btn:updateButton( entry, button )
      end
    end

    -- sort the partyMembersTable and then copy the sorted
    -- table into the f.unitButtons table.
    table.sort( partyMembersTable, highToLow )

    local i = 1
    for _, entry in ipairs( partyMembersTable ) do
        local button = entry[ENTRY_BUTTON]
        if button ~= nil then
          button:SetPoint("TOPLEFT",5,-((i-1)*BUTTON_HEIGHT)-24)
        end
        i = i + 1
    end

    return f
end

-------------------  TEST 1 ----------------------------------
local testFrame = nil
SLASH_BUTTON_TEST1 = "/btn"
SlashCmdList["BUTTON_TEST"] = function( num )
  return
end

