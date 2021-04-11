--------------------------------------------------------------------------------------
-- Metrics.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 11 December, 2021
local _, VisualThreat = ...
VisualThreat.Metrics = {}
metrics = VisualThreat.Metrics

local L = VisualThreat.L
local E = errors
local sprintf = _G.string.format

local STATUS_SUCCESS 	= errors.STATUS_SUCCESS
local STATUS_FAILURE 	= errors.STATUS_FAILURE

------------ THE MEMBER RECORD INDICES ------------------
local VT_UNIT_NAME               = grp.VT_UNIT_NAME
local VT_UNIT_ID                 = grp.VT_UNIT_ID   
local VT_PET_OWNER               = grp.VT_PET_OWNER 
local VT_MOB_ID                  = grp.VT_MOB_ID                  
local VT_ACCUM_THREAT_VALUE      = grp.VT_ACCUM_THREAT_VALUE
local VT_ACCUM_DAMAGE_TAKEN      = grp.VT_ACCUM_DAMAGE_TAKEN
local VT_ACCUM_HEALING_RECEIVED  = grp.VT_ACCUM_HEALING_RECEIVED

-------------- THREAT STATS RECORD INDICES ---------------
local SUM_THREAT_VALUE      = grp.SUM_THREAT_VALUE
local SUM_DAMAGE_TAKEN      = grp.SUM_DAMAGE_TAKEN
local SUM_HEALS_RECEIVED    = grp.SUM_HEALS_RECEIVED


local MEMBER_NAME 			= 1
local SUM_MEMBER_THREAT 	= 2
local RELATIVE_THREAT		= 3
local SUM_DMG_TAKEN 		= 4
local SUM_HEALS_RECD 		= 5

local function highToLow( entry1, entry2 )
	return entry1[2] > entry2[2]
end
function metrics:getThreatStats()
	local memberName = grp:getAddonPartyNames()
	local numMembers = #memberName
	
	local threat	= {}
	local damage	= {}
	local heals 	= {}

	for i = 1, numMembers do
		local entry = {}
		local memberStats, groupStatsStats = grp:getThreatStats( memberName[i])
        if memberStats > 0 then
		    entry = {memberName[i], memberStats, groupStatsStats }
		    table.insert( threat, entry )
        end

		local memberStats, groupStats	= grp:getHealingStats( memberName[i])
        if memberStats > 0 then
		    entry = {memberName[i], memberStats, groupStats }
		    table.insert( heals, entry )
        end

		local memberStats, groupStats	= grp:getDamageTakenStats( memberName[i])
        if memberStats > 0 then
		    entry = {memberName[i], memberStats, groupStats }
		    table.insert( damage, entry )
        end
	end
	table.sort( threat, highToLow )
	table.sort( damage, highToLow)
	table.sort( heals, highToLow )

	local threatStr = {}
	for i = 1, numMembers do
		for _, entry in ipairs( threat ) do
            local s = nil
            local percentTotal = 0.0
            if entry[3] > 0 then
                local percent = (entry[2]/entry[3]) * 100
                s = sprintf("%s: %d threat generated (%0.1f%% of %d)\n", entry[1], entry[2], percent, entry[3] )
            else
                s = sprintf("%s: %d threat generated\n", entry[1], entry[2] )
            end
            local v = {entry[1], s }
            table.insert( threatStr, v )
		end
	end

	local healsStr = {}
	for i = 1, numMembers do
		for _, entry in ipairs( heals ) do
            local percentTotal = 0.0
            if entry[3] > 0 then
                s = sprintf("%s: %d heals received (%0.1f%% of %d)\n", entry[1], entry[2], entry[2]/entry[3], entry[3] )
            else
                s = sprintf("%s: %d heals received.\n", entry[1], entry[2] )
            end
            local v = {entry[1], s }
			table.insert( healsStr, v )
		end
	end

	local dmgTakenStr = {}
	for i = 1, numMembers do
		for _, entry in ipairs( damage ) do
            local s = nil
            local percentTotal = 0.0
            if entry[3] > 0 then
                s = sprintf("%s: %d damage taken (%0.1f%% of %d)\n", entry[1], entry[2], entry[2]/entry[3], entry[3] )
            else
                s = sprintf("%s: %d damage taken.\n", entry[1], entry[2] )
            end
            local v = {entry[1], s }
		    table.insert( dmgTakenStr, v)
		end
	end
	return threatStr, healsStr, dmgTakenStr
end

if E:isDebug() then
    local fileName = "Metrics.lua"
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
