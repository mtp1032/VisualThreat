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

-- Returns a simple table of party names (including pets)
--      local nameTable = grp.getNameTableMembersAndPets

--      local threat, accumThreat = grp.getThreatValues()
--      local damage, accumDamage = grp:getDamageValues( memberName )
--      local heals, accumHeals = grp:getHealValues( memberName )

local MEMBER_NAME       = 1
local THREAT            = 2
local THREAT_RATIO      = 3
local DAMAGE_TAKEN      = 4
local DAMAGE_DONE 		= 5
local HEALING_RECEIVED  = 6

-- returns an array of values for the specified spell
local function getStatsDataSet( spellName )
	local spellFound = false
	local result = {STATUS_SUCCESS, nil, nil }

	local dataSet = {}
	for _, v in ipairs( tableOfSpells ) do
		if v[1] == spellName then
			table.insert( dataSet, v )
			spellFound = true
		end
	end

	if not spellFound then
		result = {STATUS_FAILURE, sprintf("Spell, %s, not found.\n", debugstack() )}
		dataSet = nil
	end

	return dataSet, result
end
-- a dataset is an array of spell damages, i.e., t = {N1, N2,..,Nn}
local function calculateStats( dataSet )

	local sum = 0
	local mean = 0
	local variance = 0
	local stdDev = 0
	local n = 0

	if dataSet == nil then
		return mean, stdDev
	end
	if #dataSet == 0 then
		return mean, stdDev
	end

	-- calculate the mean
	for _, v in ipairs( dataSet ) do
		n = n + 1
		sum = sum + v[2]
	end
	mean = sum/n

	-- calculate the variance
	local residual = 9
	for _, v in ipairs(dataSet) do
		local residual =  (v[2] - mean)^2
		variance = variance + residual
	end

	if n == 1 then
		stdDev = 0.0
	else
		variance = variance/(n-1)
		stdDev = math.sqrt( variance )/n
	end

	return mean, stdDev
end
-- For correlation coefficient see https://www.youtube.com/watch?v=lVOzlHx_15s
-- A dataset is given by a set of x values and a set of y values.
local function getCorrelation( dataSet )
	local n = #dataset
	if n == 0 then return end

	local r = 0
	sumX = 0
	sumY = 0
	local dsX = 0
	local dsY = 0

	for _, xyPair in ipairs(dataSet) do
		sumX = sumX + xyPair[1]
		sumY = sumY + xyPair[2]
	end
	local xavg = sumX/n
	local yavg = sumY/n
	local ssX = 0
	local ssY = 0
	local sp = 0

	for _, xyPair in ipairs(dataSet) do
		ssX = ssX + (xyPair[1] - xavg)^2		-- sum of the squares for the x elements
		ssY = ssY + (xyPair[2] - yavg)^2		-- sum of the squares for the y elements
		sp = sp + (ssX * ssY)
	end

	r = sp /(sqrt(ssX) * sqrt(ssY))
	return r
end

-- SORTING FUNCTIONS: All functions sort high to low
local function sortByThreat(entry1, entry2)
    return entry1[THREAT] > entry2[THREAT]
end
local function sortByThreatRatio( entry1, entry2 )
    return entry1[THREAT_RATIO] > entry2[THREAT_RATIO]
end
local function sortByDamageTaken( entry1, entry2 )
    return entry1[DAMAGE_TAKEN] > entry2[DAMAGE_TAKEN]
end
local function sortByDamageDone( entry1, entry2 )
    return entry1[DAMAGE_DONE] > entry2[DAMAGE_DONE]
end
local function sortByHealing( entry1, entry2 )
    return entry1[HEALING_RECEIVED] > entry2[HEALING_RECEIVED]
end
local function getMetrics()
    local metrics = {}
    local nameTable = grp.getNameTableMembersAndPets
    for i = 1, #nameTable do
        local name = nameTable[i]
        local _, accumThreat = grp:getThreatValues( name )
        local threatRatio = grp:getThreatValueRatio( name )
        local _, accumDmgTaken, accumDmgDone = grp:getDamageStats( name )
        local _, accumHeals = grp:getHealingValues( name )
        local entry = {name, accumThreat, threatRatio, accumDmg, accumHeals }
        table.insert( metrics, entry )
    end
    return metrics
end
local function printMetricsTable( t )
    for _, v in ipairs( t ) do
        local s = sprintf("  %s: %d, %d, %d, %d\n", v[MEMBER_NAME], v[THREAT], v[THREAT_RATIO], v[DAMAGE_TAKEN], v[HEALING_RECEIVED ])
        postMsg( s )
    end
    postMsg("\n")
end
local function printHealingMetrics()
    local metrics = getMetrics()
    table.sort( metrics, sortByHealing )
    postMsg("HEALING RECEIVED:\n")
    printMetricsTable( metrics )
end
local function printDamageMetrics()
    local metrics = getMetrics()
    table.sort( metrics, sortByDamageTaken )
    postMsg("DAMAGE TAKEN:")
    printMetricsTable( metrics )
end
local function printThreatMetrics()
    local metrics = getMetrics()
    table.sort( metrics, sortByThreat )
    postMsg("THREAT GENERATED:")
    printMetricsTable( metrics )
end

SLASH_METRIC_TESTS1 = "/metrics"
SlashCmdList["METRIC_TESTS"] = function( num )
end
