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
local VT_THREAT_VALUE            = grp.VT_THREAT_VALUE             
local VT_THREAT_VALUE_RATIO      = grp.VT_THREAT_VALUE_RATIO
local VT_DAMAGE_TAKEN            = grp.VT_DAMAGE_TAKEN
local VT_DAMAGE_DONE             = grp.VT_DAMAGE_DONE
local VT_HEALING_RECEIVED        = grp.VT_HEALING_RECEIVED

-- Accumulators
local VT_ACCUM_THREAT_VALUE      = grp.VT_ACCUM_THREAT_VALUE
local VT_ACCUM_DAMAGE_TAKEN      = grp.VT_ACCUM_DAMAGE_TAKEN
local VT_ACCUM_DAMAGE_DONE       = grp.VT_ACCUM_DAMAGE_DONE
local VT_ACCUM_HEALING_RECEIVED  = grp.VT_ACCUM_HEALING_RECEIVED
local VT_BUTTON                  = grp.VT_BUTTON
local VT_NUM_ELEMENTS            = grp.VT_BUTTON

-- When the UNIT_THREAT_LIST_UPDATE fires, the handler calls updateThreatStatus
-- to update all the threat metrics - Notably, VT_ACCUM_THREAT_VALUE, VT_DAMAGE_TAKEN, and 
-- VT_ACCUM_HEALING_RECEIVED.
function tev:updateThreatStatus( mobId )
    if mobId == "player" then
        return
    end
    -- Sum the threat values as we loop through and update each party member's entry
    local addonParty = grp:getAddonPartyTable()
    for _, entry in ipairs( addonParty ) do
        local isTanking, status, _, _, threatValue = UnitDetailedThreatSituation( entry[VT_UNIT_ID], mobId )
        if threatValue == nil then 
            threatValue = 0 
        end

        if threatValue > 0 then
            grp:setThreatValues( entry[VT_UNIT_NAME], threatValue )
        end

        btn:updateButton( entry )
    end
end
