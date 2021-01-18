--------------------------------------------------------------------------------------
-- EventHandler.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 October, 2019
-- https://wow.gamepedia.com/API_UnitThreatPercentageOfLead
-- https://wow.gamepedia.com/API_UnitThreatSituation			Has example code
-- https://wow.gamepedia.com/API_GetThreatStatusColor			Has example code
--------------------------------------------------------------------------------------
local _, VisualThreat = ...
VisualThreat.ThreatEventHandler = {}
tev = VisualThreat.ThreatEventHandler

local L = VisualThreat.L
local E = errors
local sprintf = _G.string.format

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

-- When the UNIT_THREAT_LIST_UPDATE fires, the handler calls updateThreatStatus 
local function updateThreatStatus( mobId )

    -- Sum the threat values as we loop through and update each party member's entry
    local sumThreatValue = 0
    for _, entry in ipairs( grp.playersParty ) do
        local unitId = entry[VT_UNIT_ID]
        local _, _, _, _, threatValue = UnitDetailedThreatSituation( unitId, mobId )
        grp:setThreatValue( entry[VT_UNIT_NAME], threatValue )
        sumThreatValue = sumThreatValue + threatValue
    end

    if sumThreatValue > 0 then
        for _, entry in ipairs( grp.playersParty ) do
            local threatValueRatio = entry[VT_THREAT_VALUE]/sumThreatValue
            grp:setThreatValueRatio( entry[VT_UNIT_NAME], threatValueRatio )
        end
    end
end

local eventFrame = CreateFrame("Frame") 
eventFrame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE") 		-- unitTarget
eventFrame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")				-- unitTarget
eventFrame:SetScript("OnEvent", 
function( self, event, ... )
	local arg1, arg2, arg3, arg4 = ...
    -- Fired when a player on the mob's threat list moves past another unit
    -- on that list
    if event == "UNIT_THREAT_SITUATION_UPDATE" then
        btn:updatePortraitButtons()
    end
    if event == "UNIT_THREAT_LIST_UPDATE" then
        if grp.playersParty == nil then
            return
        end
        updateThreatStatus( arg1 )
        btn:updatePortraitButtons()
	end
end)

