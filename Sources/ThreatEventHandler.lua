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

        local isTanking, _, _, _, threatValue = UnitDetailedThreatSituation( unitId, mobId )

        if threatValue ~= nil then 
            if threatValue > 0 then 
                grp:setThreatValues( entry[VT_UNIT_NAME], threatValue )
                E:where()
                local totalThreat, groupThreat = grp:getThreatStats( entry[VT_UNIT_NAME])
                local percent = (totalThreat/groupThreat) * 100
                local threatStr = sprintf("%s has %d threat (%0.1f%% of total) from %s.", entry[VT_UNIT_NAME], totalThreat, percent, UnitName( mobId ) )
                E:where( threatStr )
            end
        end
    end
end
if E:isDebug() then
    local fileName = "ThreatEventHandler.lua"
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
