--------------------------------------------------------------------------------------
-- EventHandler.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 October, 2019
--------------------------------------------------------------------------------------
local _, VisualThreat = ...
VisualThreat.ThreatEventHandler = {}
tev = VisualThreat.ThreatEventHandler

local L = VisualThreat.L
local E = errors
local sprintf = _G.string.format


-- https://wow.gamepedia.com/API_UnitThreatPercentageOfLead
-- https://wow.gamepedia.com/API_UnitThreatSituation			Has example code
-- https://wow.gamepedia.com/API_GetThreatStatusColor			Has example code


local ENTRY_UNIT_NAME           = btn.ENTRY_UNIT_NAME           -- playerName or petName             
local ENTRY_UNIT_ID 		    = btn.ENTRY_UNIT_ID	            -- corresponding playerName or petName
local ENTRY_PET_OWNER           = btn.ENTRY_PET_OWNER           -- petOwnerName (nil if ENTRY_UNIT_ID not a petId )
local ENTRY_MOB_ID			    = btn.ENTRY_MOB_ID              -- UUID of mob targeting player                    
local ENTRY_AGGRO_STATUS 		= btn.ENTRY_AGGRO_STATUS        -- 1, 2, 3, 4 (see https://wow.gamepedia.com/API_UnitDetailedThreatSituation )             
local ENTRY_THREAT_VALUE 		= btn.ENTRY_THREAT_VALUE        --  see https://wow.gamepedia.com/API_UnitDetailedThreatSituation               
local ENTRY_THREAT_VALUE_RATIO  = btn.ENTRY_THREAT_VALUE_RATIO  -- calculated: (playerThreatValue/totalThreatValue)
local ENTRY_BUTTON              = btn.ENTRY_BUTTON
local ENTRY_NUM_ELEMENTS        = btn.ENTRY_BUTTON


-- entry: {Name, unitId, petOwner, mobId, aggroStatus, threatValue, threatValueRatio, button }
-- default entry: {name, unitId, nil, nil, 0, 0, 0, nil }

-- When the UNIT_THREAT_LIST_UPDATE fires, the handler calls updateThreatStatus 
-- which creates/update an entry into the partyMembersTable (see GroupEventHandler.lua).
local function updateThreatStatus( partyMembersTable, mobId )

    -- Sum the threat values as we loop through and update each party member's entry
    local sumThreatValue = 0
    for _, entry in ipairs( partyMembersTable ) do
        local _, aggroStatus, scaledThreatPercent, rawThreatPercent, threatValue = UnitDetailedThreatSituation(entry[ENTRY_UNIT_ID], mobId )

        if aggroStatus == nil then aggroStatus = 0 end
        if threatValue == nil then threatValue = 0 end

        sumThreatValue = sumThreatValue + threatValue

        entry[ENTRY_AGGRO_STATUS]   = aggroStatus
        entry[ENTRY_THREAT_VALUE]   = threatValue
        entry[ENTRY_THREAT_VALUE_RATIO] = 0

        grp:insertEntryInPartyMembersTable( entry )
    end

    if sumThreatValue > 0 then
        for _, entry in ipairs( partyMembersTable ) do
            entry[ENTRY_THREAT_VALUE_RATIO] = entry[ENTRY_THREAT_VALUE]/sumThreatValue
            grp:insertEntryInPartyMembersTable( entry )
        end
    end
end

local threatFrame = nil

local eventFrame = CreateFrame("Frame") 
eventFrame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE") 		-- unitTarget
eventFrame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")				-- unitTarget
eventFrame:SetScript("OnEvent", 
function( self, event, ... )
	local arg1, arg2, arg3, arg4 = ...

    -- Fired when a player on the mob's threat list moves past another unit
    -- on that list
    if event == "UNIT_THREAT_SITUATION_UPDATE" then
        local partyMembersTable = grp:getPartyMembersTable()
        if partyMembersTable == nil then
            return
        end
        btn:updatePortraitButtons( threatFrame, partyMembersTable )
    end
    if event == "UNIT_THREAT_LIST_UPDATE" then
        local partyMembersTable = grp:getPartyMembersTable()
        if partyMembersTable == nil then
            return
        end
        updateThreatStatus( partyMembersTable, arg1 )
        if threatFrame == nil then
            threatFrame = btn:createIconFrame( partyMembersTable )
        end
        btn:updatePortraitButtons( threatFrame, partyMembersTable )
	end
end)

