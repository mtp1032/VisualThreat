--------------------------------------------------------------------------------------
-- CombatStats.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 October, 2020
--------------------------------------------------------------------------------------
local _, VisualThreat = ...
VisualThreat.CombatStats = {}
combatStats = VisualThreat.CombatStats

local L = VisualThreat.L
local E = errors
local sprintf = _G.string.format

-- CELU base parameters
combatStats.TIMESTAMP			  = 1
combatStats.SUBEVENT    		  = 2	
combatStats.HIDECASTER      	  = 3		
combatStats.SOURCEGUID      	  = 4 	
combatStats.SOURCENAME      	  = 5 	
combatStats.SOURCEFLAGS     	  = 6 	
combatStats.SOURCERAIDFLAGS 	  = 7 	
combatStats.TARGETGUID      	  = 8 	
combatStats.TARGETNAME      	  = 9 	
combatStats.TARGETFLAGS     	  = 10 	
combatStats.TARGETRAIDFLAGS 	  = 11	
combatStats.AMOUNT_SWING_DAMAGED = 12
combatStats.SPELL_NAME          = 13
combatStats.SPELL_SCHOOL        = 14
combatStats.AMOUNT_SPELL_DAMAGED      = 15
combatStats.AMOUNT_HEALED       = 15
combatStats.IS_CRIT_HEAL        = 18
combatStats.IS_CRIT_RANGE       = 18
combatStats.IS_CRIT_DAMAGE      = 21

local TIMESTAMP				= combatStats.TIMESTAMP
local SUBEVENT    			= combatStats.SUBEVENT
local HIDECASTER      		= combatStats.HIDECASTER
local SOURCEGUID      		= combatStats.SOURCEGUID
local SOURCENAME      		= combatStats.SOURCENAME
local SOURCEFLAGS     		= combatStats.SOURCEFLAGS
local SOURCERAIDFLAGS 		= combatStats.SOURCERAIDFLAGS
local TARGETGUID      		= combatStats.TARGETGUID
local TARGETNAME      		= combatStats.TARGETNAME
local TARGETFLAGS     		= combatStats.TARGETFLAGS
local TARGETRAIDFLAGS 		= combatStats.TARGETRAIDFLAGS
local AMOUNT_SWING_DAMAGED   = combatStats.AMOUNT_SWING_DAMAGED

local SPELL_NAME            = combatStats.SPELL_NAME
local SPELL_SCHOOL          = combatStats.SPELL_SCHOOL
local AMOUNT_SPELL_DAMAGED        = combatStats.AMOUNT_SPELL_DAMAGED
local AMOUNT_HEALED         = combatStats.AMOUNT_HEALED
local IS_CRIT_HEAL          = combatStats.IS_CRIT_HEAL
local IS_CRIT_RANGE         = combatStats.IS_CRIT_RANGE
local IS_CRIT_DAMAGE        = combatStats.IS_CRIT_DAMAGE

local spellSchoolNames = {
	{1, "Physical"},
	{2, "Holy"},
	{3, "Holystrike"},
	{4, "Fire"},
	{5, "Flamestrike"},
	{6, "Holyfire (Radiant"},
	{8, "Nature"},
	{9, "Stormstrike"},
	{10, "Holystorm"},
	{12, "Firestorm"},
	{16, "Frost"},
	{17, "Froststrike"},
	{18, "Holyfrost"},
	{20, "Frostfire"},
	{24, "Froststorm"},
	{28, "Elemental"},
	{32, "Shadow"},
	{33, "Shadowstrike"},
	{34, "Shadowlight"},
	{36, "Shadowflame"},
	{40, "Shadowstorm(Plague)"},
	{48, "Shadowfrost"},
	{64, "Arcane"},
	{65, "Spellstrike"},
	{66, "Divine"},
	{68, "Spellfire"},
	{72, "Spellstorm"},
	{80, "Spellfrost"},
	{96, "Spellshadow"},
	{124, "Chromatic(Chaos)"},
	{126, "Magic"},
	{127, "Chaos"}
}
local function dbgDumpSubevent( subEvent )
    for _, subEvent in ipairs( subEvents) do
        if subEvent[SUBEVENT] == subEvent then
            for i = 1, NUM_COMBAT_ENTRIES do
		        if subEvent[i] ~= nil then
			        local value = nil
			        local dataType = type(subEvent[i])

			        if dataType ~= "string" then
				        value = tostring( subEvent[i] )
			        else
				        value = subEvent[i]
			        end
			        msg:postMsg( sprintf("subEvent[%d] = %s (%s)\n", i, value, dataType))
		        else
			        msg:postMsg( sprintf("subEvent[%d] = nil\n", i ))
		        end
            end
            msg:postMsg( sprintf("\n"))
        end
	end
end	

local VT_UNIT_NAME               = grp.VT_UNIT_NAME
local VT_UNIT_ID                 = grp.VT_UNIT_ID   
local VT_PET_OWNER               = grp.VT_PET_OWNER 
local VT_MOB_ID                  = grp.VT_MOB_ID                  

-- Accumulators
local VT_ACCUM_THREAT_VALUE      = grp.VT_ACCUM_THREAT_VALUE
local VT_ACCUM_DAMAGE_TAKEN      = grp.VT_ACCUM_DAMAGE_TAKEN
local VT_ACCUM_HEALING_RECEIVED  = grp.VT_ACCUM_HEALING_RECEIVED
local VT_UNIT_FRAME              = grp.VT_UNIT_FRAME

-- indices into the globalStats Array
local TOTAL_DMG       = 1
local TOTAL_HEALING      = 2
local TOTAL_CRIT_DMG   = 3
local TOTAL_CRITHEALS    = 4
local TOTAL_DMG_CASTS     = 5
local TOTAL_HEALCASTS    = 6

local globalStats = {
            0,      -- TOTAL_DMG
            0,      -- TOTAL_HEALING
            0,      -- TOTAL_CRIT_DMG
            0,      -- TOTAL_CRITHEALS
            0,      -- TOTAL_DMG_CASTS
            0       -- TOTAL_HEALCASTS
        }
function combatStats:resetStats()
	grp:resetStats()
	globalStats = {0,0,0,0,0,0}
	damageSpellsDB = {}
	healingSpellsDB = {}
end
		
-----------------------------------------------------------------------------------------

----------------------------------------------------------===-------------------------------
-- The combat stats DB is derived from CLEU subEvents and is maintained by these two tables.
-- The table layouts for both tables (damageSpellsDB{} and healingSpellsDB{}) is identical.
--
--      layout  { memberName, 
--                      {spellName1, castCount, totalAmount, totalCritAmount, spellSchool },
--                      {spellName2, castCount, totalAmount, totalCritAmount, spellSchool },
--                      {spellName3, castCount, totalAmount, totalCritAmount, spellSchool },
--                      {spellName4, castCount, totalAmount, totalCritAmount, spellSchool }
--              }
-----------------------------------------------------------------------------------------
local damageSpellsDB     = {}
local healingSpellsDB    = {}
local ENABLE_PARTY_COMBAT_STATS = false
local ENABLE_DETAILED_COMBAT_STATS = false

function combatStats:getNumDamageRecords()
	return #damageSpellsDB
end
function combatStats:getNumHealingRecords()
	return #healingSpellsDB
end
local function getDamageRecords( memberName )
	local status = "success"
    if #damageSpellsDB == 0 then 
		return nil, "Damage Data Base has no entries."
	end

    local spellRecordTable = {}
    local foundMemberTable = false

    for _, entry in ipairs( damageSpellsDB ) do
        if entry[1] == memberName then
            for _, spellRecord in ipairs( entry[2] ) do
                table.insert( spellRecordTable, spellRecord )
                foundMemberTable = true
            end
        end            
    end
    if foundMemberTable == false then 
        return nil, "Record for "..memberName.." not found."
	end
    return spellRecordTable, status
end
local function getHealingRecords( memberName )
    local foundTable = false
	local status = "Success"
	local healingSpells = {}

	if #healingSpellsDB == 0 then
		return nil, "Healing Data Base has no entries."
	end

    for _, entry in ipairs( healingSpellsDB ) do
        if entry[1] == memberName then
            healingSpells = entry[2]
            foundTable = true
        end            
    end
    if foundTable == false then
        return nil, "Record for "..memberName.." not found."
    end
    return healingSpells, status
end
local function spellSchoolName( spellSchoolIndex )
	local spellSchool = nil
	for _, v in ipairs(spellSchoolNames) do
		if v[1] == spellSchoolIndex then
			spellSchool = v[2]
		end
	end
	return spellSchool
end
------------------------------------------------------------------------------------------
--								PUBLIC FUNCTIONS
------------------------------------------------------------------------------------------
function combatStats:enableDetailedCombatStats()
	ENABLE_DETAILED_COMBAT_STATS = true
	E:where( "Detailed Combat Stats Report Enabled.")
end
function combatStats:disableDetailedCombatStats()
	ENABLE_DETAILED_COMBAT_STATS = false
	E:where( "Detailed Combat Stats Report Disabled.")
end
function combatStats:enablePartyCombatStats()
	ENABLE_PARTY_COMBAT_STATS = true
	E:where( "Party Combat Stats Report Enabled.")
end
function combatStats:disablePartyCombatStats()
	ENABLE_PARTY_COMBAT_STATS = false
	E:where( "Party Combat Stats Report Disabled.")
end

----------------- RECORDS FROM CLEU SUBEVENTS --------------------------------
function combatStats:insertDamageRecord( memberName, spellName, amountDamaged, isCrit, schoolIndex )

    globalStats[TOTAL_DMG]          = globalStats[TOTAL_DMG] + amountDamaged
    globalStats[TOTAL_DMG_CASTS]    = globalStats[TOTAL_DMG_CASTS] + 1
    if isCrit then
        globalStats[TOTAL_CRIT_DMG] = globalStats[TOTAL_CRIT_DMG] + amountDamaged
    end

    local spellRecord = {}
    if isCrit then 
        spellRecord = {spellName, 1, amountDamaged, amountDamaged, schoolIndex }
    else
        spellRecord = {spellName, 1, amountDamaged, 0, schoolIndex }
    end

    local updatedExistingRecord = false
    local foundMemberEntry = false
    local recordExists = false
    local spellRecordTable = {}

    ------------------------------------------------------------------------------
    --  THE DAMAGE RECORDS TABLE DOES NOT YET EXIST
    ------------------------------------------------------------------------------
    if #damageSpellsDB == 0 then
        table.insert( spellRecordTable, spellRecord )
        local damageRecordEntry = { memberName, spellRecordTable }
        table.insert( damageSpellsDB, damageRecordEntry )
        return
    end
    ------------------------------------------------------------------------------
    --  THE DAMAGE RECORDS TABLE DOES NOT CONTAIN AN ENTRY FOR THIS MEMBER'S NAME
    -------------------------------------------------------------------------------
    for _, damageRecord in ipairs( damageSpellsDB ) do
        if damageRecord[1] == memberName then
            foundMemberEntry = true
        end
    end
    if foundMemberEntry == false then
        spellRecordTable = {}
        table.insert( spellRecordTable, spellRecord )
        damageRecordEntry = { memberName, spellRecordTable }
        table.insert( damageSpellsDB, damageRecordEntry )
        return
    end
    --------------------------------------------------------------------------------
    --  THE DAMAGE RECORDS TABLE CONTAINS AN ENTRY FOR THIS MEMBER'S NAME AND SPELL
    --------------------------------------------------------------------------------
    for _, dmgEntry in ipairs( damageSpellsDB ) do
        if dmgEntry[1] == memberName then
            spellRecordTable = dmgEntry[2]
            for _, entry in ipairs( spellRecordTable ) do
                if entry[1] == spellRecord[1] then
                    entry[2] = entry[2] + 1
                    entry[3] = entry[3] + spellRecord[3]
                    entry[4] = entry[4] + spellRecord[4]
                    entry[5] = spellRecord[5]                   
                    updatedExistingRecord = true
                end
            end
        end
    end
    if updatedExistingRecord == true then
        return
    end
    -------------------------------------------------------------------------------------------------------
    -- THIS OCCURS WHEN A MEMBER, ALREADY IN THE DAMAGE RECORDS TABLE, CASTS A SPELL NOT IN THE SPELL TABLE
    -------------------------------------------------------------------------------------------------------
    if updatedExistingRecord == false then
        for _, dmgEntry in ipairs( damageSpellsDB ) do
            if dmgEntry[1] == memberName then
                table.insert( dmgEntry[2], spellRecord ) 
            end 
        end
    end
end
function combatStats:insertHealingRecord( memberName, spellName, amountHealed, isCrit, schoolIndex )

    globalStats[TOTAL_HEALING]       = globalStats[TOTAL_HEALING] + amountHealed
    globalStats[TOTAL_HEALCASTS]     = globalStats[TOTAL_HEALCASTS] + 1
    if isCrit then
        globalStats[TOTAL_CRITHEALS] = globalStats[TOTAL_CRITHEALS] + amountHealed
    end

    local spellRecord = {}
    if isCrit then 
        spellRecord = {spellName, 1, amountHealed, amountHealed, schoolIndex }
    else
        spellRecord = {spellName, 1, amountHealed, 0, schoolIndex }
    end

    local updatedExistingRecord = false
    local foundMemberEntry = false
    local recordExists = false
    local spellRecordTable = {}

    ------------------------------------------------------------------------------
    --  THE HEALING RECORDS TABLE DOES NOT YET EXIST
    ------------------------------------------------------------------------------
    if #healingSpellsDB == 0 then
        table.insert( spellRecordTable, spellRecord )
        local entry = { memberName, spellRecordTable }
        table.insert( healingSpellsDB, entry )
        return
    end
    ------------------------------------------------------------------------------
    --  THE HEALING RECORDS TABLE DOES NOT CONTAIN AN ENTRY FOR THIS MEMBER'S NAME
    -------------------------------------------------------------------------------
    for _, healingRecord in ipairs( healingSpellsDB ) do
        if healingRecord[1] == memberName then
            foundMemberEntry = true
        end
    end
    if foundMemberEntry == false then
        spellRecordTable = {}
        table.insert( spellRecordTable, spellRecord )
        local entry = { memberName, spellRecordTable }
        table.insert( healingSpellsDB, entry )
		return
    end
    --------------------------------------------------------------------------------
    --  THE HEALING RECORDS TABLE CONTAINS AN ENTRY FOR THIS MEMBER'S NAME AND SPELL
    --------------------------------------------------------------------------------
    for _, healingRecord in ipairs( healingSpellsDB ) do
        if healingRecord[1] == memberName then
            for _, entry in ipairs( healingRecord[2] ) do
                if entry[1] == spellRecord[1] then
                    entry[2] = entry[2] + 1
                    entry[3] = entry[3] + spellRecord[3]
                    entry[4] = entry[4] + spellRecord[4]
                    entry[5] = spellRecord[5]                   
                    updatedExistingRecord = true
                end
            end
        end
    end
    if updatedExistingRecord == true then
        return
    end
    -------------------------------------------------------------------------------------------------------
    -- THIS OCCURS WHEN A MEMBER, ALREADY IN THE HEALING RECORDS TABLE, CASTS A SPELL NOT IN THE SPELL TABLE
    -------------------------------------------------------------------------------------------------------
    if updatedExistingRecord == false then
        for _, healingRecord in ipairs( healingSpellsDB ) do
            if healingRecord[1] == memberName then
                table.insert( healingRecord[2], spellRecord ) 
            end 
        end
    end
end
function combatStats:getDamageRecord( memberName )
	local damageRecords, status = getDamageRecords( memberName )
	if damageRecords == nil then
		return 0,0,0
	end
	return damageRecords, status
end
function combatStats:getDamageStats( memberName )
	local memberDamage = 0
	local memberCrit = 0
	local memberCasts = 0

	local damageRecords, status = getDamageRecords( memberName )
	if damageRecords == nil then
		return 0, 0, 0
	end

	for _, entry in ipairs( damageRecords ) do
		memberCasts = memberCasts + entry[2]
		memberDamage = memberDamage + entry[3]
		memberCrit = memberCrit + entry[4] 
	end
	return memberDamage, memberCrit, memberCasts
end
function combatStats:getHealingRecord( memberName )
	local healingRecord, status = getHealingRecords( memberName )
	return healingRecord, status
end
function combatStats:getDamageBySpell( memberName, spellName )
	local spellDamage = 0
	local spellCrit = 0
	local spellCasts = 0

	local spellTable = getDamageSpellRecordsTable( memberName )
	for _, entry in ipairs( spellTable ) do
		if entry[1] == spellName then
			spellCasts 	= entry[2]
			spellDamage = entry[3]
			spellCrit	= entry[4]
		end
	end
	return spellDamage, spellCrit, spellCasts
end
function combatStats:getHealingBySpell( memberName, spellName )
	local spellHealing = 0
	local spellCrit = 0
	local spellCasts = 0

	local spellTable = getHealsSpellRecordsTable( memberName )
	for _, entry in ipairs( spellTable ) do
		if entry[1] == spellName then
			spellCasts 	= entry[2]
			spellHealing = entry[3]
			spellCrit	= entry[4]
		end
	end
	return spellHealing, spellCrit, spellCasts

end
function combatStats:getGroupDamageStats()
    return globalStats[TOTAL_DMG], globalStats[TOTAL_CRIT_DMG], globalStats[TOTAL_DMG_CASTS]
end
function combatStats:getGroupHealingStats()
	return globalStats[TOTAL_HEALING], globalStats[TOTAL_CRITHEALS],globalStats[TOTAL_HEALCASTS]
end
function combatStats:getMemberDamageBySchool( memberName, schoolIndex )
    local schoolDamage = 0
    local numSchoolCasts = 0

    return schoolDamage, numSchoolCasts
end
function combatStats:getSpellSchoolName( index )
	return spellSchoolName( index )
end


