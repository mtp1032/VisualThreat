--------------------------------------------------------------------------------------
-- ThreatEventHandler.lua
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

local VT_UNIT_NAME      = grp.VT_UNIT_NAME
local VT_UNIT_ID        = grp.VT_UNIT_ID   

-- When the UNIT_THREAT_LIST_UPDATE fires, the handler calls updateThreatStatus
-- to update all the threat metrics.
function tev:updateThreatStatus( mobId )
    if mobId == "player" then
        return
    end
    -- Sum the threat values as we loop through and update each party member's entry
    local addonParty = grp:getAddonPartyTable()
    for _, entry in ipairs( addonParty ) do
        local unitId = entry[VT_UNIT_ID]

        local isTanking, status, _, _, threatValue = UnitDetailedThreatSituation( unitId, mobId )

        if threatValue == nil then return end 
        grp:setThreatValues( entry[VT_UNIT_NAME], threatValue )
    end
end
