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

local BUTTON_WIDTH = 200
local BUTTON_HEIGHT = 80

local VT_UNIT_NAME               = grp.VT_UNIT_NAME
local VT_UNIT_ID                 = grp.VT_UNIT_ID   
local VT_PET_OWNER               = grp.VT_PET_OWNER 
local VT_MOB_ID                  = grp.VT_MOB_ID                  
local VT_THREAT_VALUE            = grp.VT_THREAT_VALUE             
local VT_THREAT_VALUE_RATIO      = grp.VT_THREAT_VALUE_RATIO
local VT_DAMAGE_TAKEN            = grp.VT_DAMAGE_TAKEN
local VT_HEALING_RECEIVED        = grp.VT_HEALING_RECEIVED

-- Accumulators
local VT_ACCUM_THREAT_VALUE      = grp.VT_ACCUM_THREAT_VALUE
local VT_ACCUM_DAMAGE_TAKEN      = grp.VT_ACCUM_DAMAGE_TAKEN
local VT_ACCUM_HEALING_RECEIVED     = grp.VT_ACCUM_HEALING_RECEIVED
local VT_BUTTON                  = grp.VT_BUTTON
local VT_NUM_ELEMENTS            = grp.VT_BUTTON

local red = "\124cFFFF0000"
btn.threatIconStack = nil

local function highToLow( entry1, entry2)
  return entry1[grp.VT_THREAT_VALUE_RATIO ] > entry2[grp.VT_THREAT_VALUE_RATIO]
end

-- called  by createIconStack()
local function createEmptyButton(parent)

  local buttonFrame = CreateFrame("Button",nil,parent,"TooltipBackdropTemplate")
  buttonFrame:SetBackdropBorderColor(0.5,0.5,0.5)

  -- set size and position of portrait.
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
    local unitId          = entry[VT_UNIT_ID]
    local unitName        = entry[VT_UNIT_NAME]
    local membersThreat, threatRatio = grp:getThreatStats( unitName )
    local damageTaken, damageDone = grp:getDamageStats( unitName )
    local HealingReceived   = grp:getHealingStats( unitName)
    local button          = entry[VT_BUTTON]

    SetPortraitTexture( button.Portrait, unitId )
    button.Name:SetText( unitName )
    
    local dmgStr = sprintf("Damage taken %d", damageTaken)
    button.Damage:SetText("")
    button.Damage:SetText( dmgStr )

    -- local threatStr = sprintf( "Threat: "..red.." %d%%", threatRatio)
    local threatStr = sprintf( "Threat:  %0.1f%%", threatRatio * 100)

    button.Threat:SetText( "" )
    button.Threat:SetText( threatStr )
end
function btn:createIconStack()

    -- PARTY STUFF
    if #grp.addonParty == 0 then
      return
    end

    local groupCount = grp:getPlayerCount() + grp:getPetCount()

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
    table.sort( grp.addonParty, highToLow )

    f.portraitButtons = {} 
    for i, entry in ipairs( grp.addonParty ) do
      -- msg:postMsg( sprintf("Creating portrait button for %s...", entry[VT_UNIT_NAME]))
      f.portraitButtons[i] = createEmptyButton(f)
      f.portraitButtons[i]:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
      f.portraitButtons[i]:SetPoint("TOPLEFT",5,-((i-1)*BUTTON_HEIGHT)-24)
      entry[VT_BUTTON] = f.portraitButtons[i]
      updateButton( entry )
      -- msg:postMsg( sprintf("done.\n"))
    end
    return f
end
-- called from ThreatEventHandler
function btn:updatePortraitButtons()

  -- if #grp.addonParty == 0 then
  --   return
  -- end

  -- table.sort( grp.addonParty, highToLow )
  -- for _, entry in ipairs( grp.addonParty ) do        
  --   updateButton( entry )
  -- end
end

-- function btn:sortThreatStack()

--     -- sort the grp.addonParty and then copy the sorted
--     -- table into the f.portraitButtons table.
--   table.sort( grp.addonParty, highToLow )

--   for i, entry in ipairs( grp.addonParty ) do
--     local button = entry[VT_BUTTON]
--     if button ~= nil then
--       button:SetPoint("TOPLEFT",5,-((i-1)*BUTTON_HEIGHT)-24)
--     end
--   end
--   return f
-- end


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

	-- 	OnTooltipShow = function( tooltip )
	-- 		tooltip:AddLine(L["ADDON_NAME_AND_VERSION"])
	-- 		tooltip:AddLine(L["LEFT_CLICK_FOR_OPTIONS_MENU"])
	-- 		tooltip:AddLine(L["RIGHT_CLICK_SHOW_EXCLUSION_TABLE"])
	-- 		tooltip:AddLine(L["SHIFT_RIGHT_CLICK_DELETE_EXCLUSION_TABLE"])		
	-- 	end,
	-- 	OnClick = function(self, button ) 
	-- 		-- LEFT CLICK - Displays the options menu
	-- 		if button == "LeftButton" and not IsShiftKeyDown() then
	-- 			si:showOptionsMenu()
	-- 		end
	-- 		-- RIGHT CLICK - Displays the exclusion table
	-- 		if button == "RightButton" and not IsShiftKeyDown() then
	-- 			si:showExclusionTable()
	-- 		end
	-- 		-- SHIFT RIGHT CLICK - Deletes the exclusion table
	-- 		if button == "RightButton" and IsShiftKeyDown() then
	-- 			si:clearExclusionTable()
	-- 		end
	-- 	end,
	-- })

