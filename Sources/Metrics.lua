--------------------------------------------------------------------------------------
-- Metrics.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 11 December, 2021
local _, VisualThreat = ...
VisualThreat.Metrics = {}
mt = VisualThreat.Metrics

local L = VisualThreat.L
local E = errors
local sprintf = _G.string.format

local STATUS_SUCCESS 	= errors.STATUS_SUCCESS
local STATUS_FAILURE 	= errors.STATUS_FAILURE

local VT_UNIT_NAME               = grp.VT_UNIT_NAME

local SUM_THREAT_VALUE      = grp.SUM_THREAT_VALUE
local SUM_DAMAGE_TAKEN      = grp.SUM_DAMAGE_TAKEN
local SUM_HEALS_RECEIVED    = grp.SUM_HEALS_RECEIVED
local SUM_DAMAGE_DONE       = grp.SUM_DAMAGE_DONE

-- SORTING FUNCTIONS: All functions sort high to low
local function sortByThreatValue(entry1, entry2)
    return entry1[SUM_THREAT_VALUE] > entry2[SUM_THREAT_VALUE]
end
local function sortByDamageTaken(entry1, entry2)
    return entry1[SUM_DAMAGE_TAKEN] > entry2[SUM_DAMAGE_TAKEN]
end
local function sortByHealsReceived(entry1, entry2)
    return entry1[SUM_HEALS_RECD] > entry2[SUM_HEALS_RECD]
end

local MEMBER_NAME 			= 1
local SUM_MEMBER_THREAT 	= 2
local RELATIVE_THREAT		= 3
local SUM_DMG_TAKEN 		= 4
local SUM_HEALS_RECD 		= 5

local memberStats = {}

local function initMemberStats()
	local addonParty = grp:getAddonPartyTable()
	
	for _, entry in ipairs( addonParty ) do
		local memberName = entry[VT_UNIT_NAME]
		local relativeThreat = 0
		local totalMemberThreat, totalGroupThreat = grp:getThreatStats( memberName )
		if totalGroupThreat ~= 0 then 
			relativeThreat = totalMemberThreat/totalGroupThreat
			msg:postMsg( sprintf("\n  %s's Threat: %d, Total Threat: %d, Percent of Total: %0.2f%%\n", memberName, totalMemberThreat, totalGroupThreat, relativeThreat ))
		end

		local sumDmgTaken, sumDmgDone = grp:getDamageStats( memberName )
		local sumHealsRecd = grp:getHealingStats( memberName )

		local entry = {memberName, totalMemberThreat, relativeThreat, sumDmgTaken, sumHealsRecd }
		table.insert( memberStats, entry )
	end
end
function mt:memberStats( memberName)
	if #memberStats == 0 then
		initMemberStats()
	end

	local s = nil
	for _, entry in ipairs( memberStats ) do
		if entry[MEMBER_NAME] == memberName then
			s = sprintf("  %s's threat: %d, Percent of Total Threat: %0.2f%%, Damage Taken %d,  Healing Received %d\n", 
								entry[MEMBER_NAME], 
								entry[SUM_MEMBER_THREAT],
								entry[RELATIVE_THREAT] * 100, 
								entry[SUM_DMG_TAKEN], 
								entry[SUM_HEALS_RECD] )
		end
	end
	print( s )
    return s
end

SLASH_METRIC_TESTS1 = "/metrics"
SlashCmdList["METRIC_TESTS"] = function( num )
end
