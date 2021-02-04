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
local VT_ACCUM_HEALING_RECEIVED  = grp.VT_ACCUM_HEALING_RECEIVED
local VT_BUTTON                  = grp.VT_BUTTON
local VT_NUM_ELEMENTS            = grp.VT_BUTTON

local SUM_THREAT_VALUE      = grp.SUM_THREAT_VALUE
local SUM_DAMAGE_TAKEN      = grp.SUM_DAMAGE_TAKEN
local SUM_HEALS_RECEIVED    = grp.SUM_HEALS_RECEIVED
local SUM_DAMAGE_DONE       = grp.SUM_DAMAGE_DONE

-- SORTING FUNCTIONS: All functions sort high to low
local function sortByThreatValue(entry1, entry2)
    return entry1[SUM_THREAT_VALUE] > entry2[SUM_THREAT_VALUE]
end
local function sortByThreatRatio(entry1, entry2)
    return entry1[THREAT_VALUE_RATIO] > entry2[THREAT_VALUE_RATIO]
end
local function sortByDamageTaken(entry1, entry2)
    return entry1[SUM_DAMAGE_TAKEN] > entry2[SUM_DAMAGE_TAKEN]
end
local function sortByHealsReceived(entry1, entry2)
    return entry1[SUM_HEALS_RECD] > entry2[SUM_HEALS_RECD]
end

local MEMBER_NAME 			= 1
local SUM_MEMBER_THREAT 	= 2
local THREAT_VALUE_RATIO	= 3
local SUM_DMG_TAKEN 		= 4
local SUM_HEALS_RECD 		= 5

local memberStats = {}

local function initMemberStats()
	local stats = {grp:getStatsTable()}
	
	for i, entry in ipairs( grp.addonParty ) do
		memberName = entry[VT_UNIT_NAME]
		local sumMemberThreat, threatValueRatio = grp:getThreatStats( memberName )
		local sumDmgTaken, sumDmgDone = grp:getDamageStats( memberName )
		local threatValueRatio = (sumMemberThreat/stats[SUM_THREAT_VALUE])
		local sumHealsRecd = grp:getHealingStats( memberName )

		local entry = {memberName, sumMemberThreat, threatValueRatio, sumDmgTaken, sumHealsRecd }
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
			s = sprintf("  %s: Accum Threat %d, Threat Ratio %0.1f%%, Damage Taken %d,  Healing Received %d\n", entry[MEMBER_NAME], entry[SUM_MEMBER_THREAT], entry[THREAT_VALUE_RATIO], entry[SUM_DMG_TAKEN], entry[SUM_HEALS_RECD]*100 )
		end
	end
    return s
end

SLASH_METRIC_TESTS1 = "/metrics"
SlashCmdList["METRIC_TESTS"] = function( num )
end
