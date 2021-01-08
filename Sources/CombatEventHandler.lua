--------------------------------------------------------------------------------------
-- combatEventHandler.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 October, 2019
--------------------------------------------------------------------------------------
local _, VisualThreat = ...
VisualThreat.combatEventHandler = {}
ceh = VisualThreat.combatEventHandler

local L = VisualThreat.L
local E = errors
local sprintf = _G.string.format

-- return true if the source or target is a pet
local function unitIsPet( flags )
	return bit.band( flags, COMBATLOG_OBJECT_TYPE_MASK ) == bit.band( flags, COMBATLOG_OBJECT_TYPE_PET )
end
local function getPartyIdByName( sourceName )
    if UnitName("player") == sourceName then
        return "player"
    end

    local partyNames = GetHomePartyInfo()
    if partyNames == nil then
        return nil
    end

    local n = #partyNames
    for i = 1, n do
        if partyNames[i] == sourceName then
            partyId = "party"..tostring(i)
            return partyId
        end
    end
    return nil
end

-- entry = {unitId, damage}
local damageTable = {}

-- e.g., Usage
--          local unitId = "pet"
--          local entry = { unitId, 465 }
--          insertDamage( entry )
local function insertDamage( entry )
    if #damageTable == 0 then
        table.insert( damageTable, entry )
        return
    end

    for _, v in ipairs( damageTable ) do
        if v[1] == entry[1] then
            v[2] = v[2] + entry[2]
            return
        end
    end
    table.insert( damageTable, entry )
end
function ceh:getDamageByUnitId(unitId )
    local damage = 0
    for _, v in ipairs( damageTable ) do
        if v[1] == unitId then
            damage = v[2]
        end
    end
    return damage
end
function ceh:getDamageByPlayerName( playerName )
    local damage = 0
    for _, v in ipairs( damageTable ) do
        local name = UnitName( v[1] )
        if name == playerName then
            damage = v[2]
        end
    end
    return damage
end
function ceh:removePlayerByUnitId( unitId )
    local tmpTable = {}
    for _, v in ipairs( damageTable ) do
        if v[1] ~= unitId then
            table.insert(tmpTable, v )
        end
    end
    damageTable = {}
    for _, v in ipairs( tmpTable ) do
        table.insert( damageTable, v )
    end
end
function ceh:removePlayerByName( playerName )
    local tmpTable = {}
    for _, v in ipairs( damageTable ) do
        local name = UnitName( v[1])
        if playerName ~= name then
            table.insert(tmpTable, v )
        end
    end
    damageTable = {}
    for _, v in ipairs( tmpTable ) do
        table.insert( damageTable, v )
    end
end

local function OnEvent( self, event, ...)

    if event ~= "COMBAT_LOG_EVENT_UNFILTERED" then
        return
    end

    stats = {CombatLogGetCurrentEventInfo() }
    local sourceName = stats[5]
    
    -- if the sourceName is NOT a member of the party, then unitId will be nil.
    local unitId = getPartyIdByName( sourceName )
    if unitId == nil then
        return
    end
    local inMyParty = UnitPlayerOrPetInParty( unitId )
    if inMyParty == nil then
        return
    end

    local subEvent = stats[2]
    if subEvent == "SPELL_SUMMON" then
        return
    end

    if subEvent ~= "SWING_DAMAGE" and
        subEvent ~= "SPELL_DAMAGE" and
        subEvent ~= "SPELL_PERIODIC_DAMAGE" and
        subEvent ~= "RANGE_DAMAGE" then
        return
    end
    local damage = stats[15]

    if subEvent == "SWING_DAMAGE" then
        damage = stats[12]
    end

    local entry = {unitId, damage}
    insertDamage( entry )
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

eventFrame:SetScript("OnEvent", OnEvent )

SLASH_COMBAT_TEST1 = "/combat"
SlashCmdList["COMBAT_TEST"] = function( num )
end
