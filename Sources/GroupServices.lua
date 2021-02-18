--------------------------------------------------------------------------------------
-- GroupServices.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 October, 2019
--
-- UnitId Reference: https://wow.gamepedia.com/UnitId
-- https://wow.gamepedia.com/API_UnitIsGroupLeader
-- see https://wow.gamepedia.com/GROUP_ROSTER_UPDATE
--------------------------------------------------------------------------------------
local _, VisualThreat = ...
VisualThreat.GroupServices = {}
grp = VisualThreat.GroupServices

local sprintf   = _G.string.format
local L         = VisualThreat.L

local E                 = errors
local STATUS_SUCCESS 	= E.STATUS_SUCCESS
local STATUS_FAILURE 	= E.STATUS_FAILURE

grp.VT_UNIT_NAME                = 1
grp.VT_UNIT_ID                  = 2 
grp.VT_PET_OWNER                = 3
grp.VT_MOB_ID                   = 4  
grp.VT_ACCUM_THREAT_VALUE       = 5
grp.VT_THREAT_VALUE_RATIO       = 6

grp.VT_ACCUM_DAMAGE_TAKEN       = 7
grp.VT_ACCUM_DAMAGE_DONE        = 8
grp.VT_ACCUM_HEALING_RECEIVED   = 9
grp.VT_UNIT_FRAME               = 10

local VT_UNIT_NAME               = grp.VT_UNIT_NAME
local VT_UNIT_ID                 = grp.VT_UNIT_ID   
local VT_PET_OWNER               = grp.VT_PET_OWNER 
local VT_MOB_ID                  = grp.VT_MOB_ID                  
local VT_THREAT_VALUE_RATIO      = grp.VT_THREAT_VALUE_RATIO

-- Accumulators
local VT_ACCUM_THREAT_VALUE      = grp.VT_ACCUM_THREAT_VALUE
local VT_ACCUM_DAMAGE_TAKEN      = grp.VT_ACCUM_DAMAGE_TAKEN
local VT_ACCUM_DAMAGE_DONE       = grp.VT_ACCUM_DAMAGE_DONE
local VT_ACCUM_HEALING_RECEIVED  = grp.VT_ACCUM_HEALING_RECEIVED
local VT_UNIT_FRAME              = grp.VT_UNIT_FRAME

-- Indices into the stats table
grp.SUM_THREAT_VALUE    = 1
grp.SUM_DAMAGE_TAKEN    = 2
grp.SUM_HEALS_RECEIVED  = 3
grp.SUM_DAMAGE_DONE     = 4

local SUM_THREAT_VALUE      = grp.SUM_THREAT_VALUE
local SUM_DAMAGE_TAKEN      = grp.SUM_DAMAGE_TAKEN
local SUM_HEALS_RECEIVED    = grp.SUM_HEALS_RECEIVED
local SUM_DAMAGE_DONE       = grp.SUM_DAMAGE_DONE

local statsTable = { 0,    -- SUM_THREAT_VALUE
                     0,    -- SUM_DAMAGE_TAKEN
                     0,    -- SUM_HEALS_RECEIVED
                     0}    -- SUM_DAMAGE_DONE

grp._EMPTY = ""
local _EMPTY = grp._EMPTY

local _defaultEntry = { _EMPTY, _EMPTY, nil, nil, 0, 0, 0, 0, 0, _EMPTY }

local partypet  = {"partypet1", "partypet2", "partypet3", "partypet4"}
local party     = {"party1",    "party2",    "party3",    "party4" }

-- NOTE: The differences between the addonParty and the blizzard party
-- are: (1) the addonParty contains an entry for the player whose unitId
-- is "player"; (2) the addonParty contains an entry for each pet. The
-- blizzard party contains no entry for the pet. Thus, the addonParty can
-- contain up to 10 members if each of the [maximum of] 5 members has a pet.
local addonParty = {}

---------------------------------------------+
local function copyAddonTable()
    local tableCopy = {}
    for i, entry in ipairs( addonParty ) do
        tableCopy[i] = entry
    end
    return tableCopy
end
local function sortByThreatValue( entry1, entry2 )
    return entry1[VT_ACCUM_THREAT_VALUE] > entry2[VT_ACCUM_THREAT_VALUE]
end
local function sortByDamageTaken(entry1, entry2)
    return entry1[VT_ACCUM_DAMAGE_TAKEN ] > entry2[VT_ACCUM_DAMAGE_TAKEN]
end
local function sortByHealsReceived(entry1, entry2)
    return entry1[VT_ACCUM_HEALING_RECEIVED ] > entry2[VT_ACCUM_HEALING_RECEIVED]
end
function grp:sortAddonTable( index )

    local sortedTable = copyAddonTable()

    if index == nil then
    end
    if index == VT_ACCUM_THREAT_VALUE then
        table.sort( sortedTable, sortByThreatValue )
    elseif index == VT_ACCUM_DAMAGE_TAKEN then
        table.sort( sortedTable, sortByDamageTaken )
    elseif index == VT_ACCUM_HEALING_RECEIVED then
        table.sort( sortedTable, sortByHealsReceived )
    end
    return sortedTable
end     
function grp:getAddonPartyTable()
    return addonParty
end
local function initializePartyEntry( unitName, unitId, petOwner, mobId )
    local r = {STATUS_SUCCESS, nil, nil}

    -- if unitId == "" then 
    --     return nil, E:setResult(sprintf("%s's unitId is nil!\n", unitName), debugstack() ) 
    -- end

    local newEntry = { unitName, unitId, petOwner, mobId, 0, 0, 0, 0, 0, _EMPTY }
    return newEntry, r
end
function grp:insertPartyEntry( unitName, unitId, OwnerName, mobId )    
    local r = {STATUS_SUCCESS, nil, nil }

    if grp:inPlayersParty( unitName ) then 
        return r 
    end

    local newEntry, r = initializePartyEntry( unitName, unitId, OwnerName, mobId )
    if newEntry == nil then
        return r 
    end

    table.insert( addonParty, newEntry )
    return r
end
function grp:printPartyEntry( entry )
    if entry[VT_PET_OWNER] ~= nil then
        msg:postMsg( sprintf("Unit Name = %s, UnitId = %s, Owner's Name = %s\n", 
                                        entry[VT_UNIT_NAME], 
                                        entry[VT_UNIT_ID], 
                                        entry[VT_PET_OWNER]))
    else
        msg:postMsg( sprintf("Unit Name = %s, unitId = %s\n",  
                                        entry[VT_UNIT_NAME], 
                                        entry[VT_UNIT_ID] ))
    end
end
-- returns a table identical to that of the blizz party, i.e.,
-- NO PET nor the "player"
function grp:getAddonPartyNames()
    if #addonParty == 0 then return nil end

    local partyNames = {}
    for i, v in ipairs( addonParty ) do
        partyNames[i] = v[VT_UNIT_NAME]
    end
    return partyNames
end
function grp:getPartyEntries()
    local nameTable = {}
    for i, v in ipairs( addonParty ) do
        nameTable[i] = v
    end
    return nameTable
end
function grp:inPlayersParty( memberName )
    local isMember = false
    if #addonParty == 0 then
        return isMember
    end
    for _, v in ipairs( addonParty ) do
        if v[VT_UNIT_NAME] == memberName then
            isMember = true
        end
    end
    return isMember
end
-- function GetHomePartyInfo()
--     return GetHomePartyInfo()
-- end
function grp:inBlizzParty( memberName )
    local isBlizzMember = false
    
    local blizzNames = GetHomePartyInfo()
    if blizzNames == nil then return isBlizzMember end

    local count = #blizzNames
    for i = 1, count do
        for _, v in ipairs( addonParty ) do
            if blizzNames[i] == v[VT_UNIT_NAME] then
                isBlizzMember = true
            end
        end
    end
    return isBlizzMember
end
function grp:blizzPartyExists()
    local partyExists = false
    local count = 0

    -- if no party exists then return false
    local blizzNames = GetHomePartyInfo()
    if blizzNames ~= nil then
        partyExists = true
        count = #blizzNames
    end
    return partyExists, count
end
-- returns the count of the number of members in the blizz party
-- Does not count the party leader or any pets.
function grp:getBlizzPartyCount()
    local blizzMemberCount = 0
    local blizzNames = GetHomePartyInfo()
    if blizzNames == nil then 
        return blizzMemberCount
    end
    return #blizzNames 
end
function grp:getBlizzPetCount()
    local blizzPetCount = 0
    local blizzNames = GetHomePartyInfo()
    if blizzNames == nil then 
        return blizzPetCount
    end

    for i = 1, #blizzNames do
        local petName = UnitName( partypet[i] )
        if petName ~= nil then
            blizzPetCount = blizzPetCount + 1
        end
    end
    if UnitName("pet") ~= nil then
        blizzPetCount = blizzPetCount + 1
    end
    return blizzPetCount 
end
-- returns a count of the number of playerParty members. Does not
-- include pets (use getPetCount())
function grp:getPlayerCount()
    local playerCount = 0
    local name = nil
    if #addonParty == 0 then
        return playerCount
    end

    for i, v in ipairs( addonParty ) do
        -- If the VT_PET_OWNER field contains a name
        -- this entry is a pet, not a player.
        if v[VT_PET_OWNER] == nil then 
            playerCount = playerCount + 1
        end
    end
    return playerCount
end
function grp:getPetCount()
    local petCount = 0
    if #addonParty == 0 then
        return petCount
    end

    for i, v in ipairs( addonParty ) do
        -- If the VT_PET_OWNER field contains a name
        -- i.e., is non-nil, then this entry is a pet, 
        -- not a player.
        if v[VT_PET_OWNER] ~= nil then 
            petCount = petCount + 1
        end
    end
    return petCount
end
function grp:getTotalMemberCount()
    return #addonParty
end
function grp:removeMember( memberName )

    if #addonParty == 0 then
        return
    end

    for i, v in ipairs( addonParty ) do
        if v[VT_UNIT_NAME] == memberName then
            table.remove( addonParty, i )
        end
    end
end
function grp:getUnitIdByName( memberName )
    if #addonParty == 0 then return nil end
  
    for _, entry in ipairs( addonParty ) do
        if entry[VT_UNIT_NAME] == memberName then
            return entry[VT_UNIT_ID]
        end
    end
    return nil
end
function grp:getEntryByName( memberName )
    if #addonParty == 0 then return nil end

    for _, entry in ipairs( addonParty ) do
        if entry[VT_UNIT_NAME] == memberName then
            return entry
        end
    end
    return nil
end
function grp:getOwnerByPetName( petName )
    for _, v in ipairs( addonParty ) do
        if v[VT_UNIT_NAME] == petName then
            return v[VT_PET_OWNER]
        end
    end
    return nil
end
function grp:getPetByOwnerName( memberName )
    local petName = nil
    for _, v in ipairs( addonParty ) do
        if v[VT_PET_OWNER] == memberName then
            return v[VT_UNIT_NAME]
        end
    end
    return petName
end
function grp:getMemberNameById( unitId )
    if #addonParty == 0 then return nil end

    for _, entry in ipairs( addonParty ) do
        if entry[VT_UNIT_ID] == unitId then
            return entry[VT_UNIT_NAME]
        end
    end
    return nil
end
function grp:getMemberNameFromFrameName( frameName )
    local playerId = nil

    if frameName == "PlayerFrame" then
        playerId = "player"
    elseif frameName == "PartyMemberFrame1" then
        playerId = "party1" 
    elseif frameName == "PartyMemberFrame2" then
        playerId = "party2"
    elseif frameName == "PartyMemberFrame3" then
        playerId = "party3"
    elseif frameName == "PartyMemberFrame4" then
        playerId = "party4"
    else
        E:where("frameName = "..frameName )
        return nil
    end
    E:where( frameName .. ", "..UnitName( playerId ))
    return UnitName( playerId )
end
------------- DAMAGE METRICS ---------------------------
function grp:setDamageTaken( memberName, damageTaken )

    statsTable[SUM_DAMAGE_TAKEN] = statsTable[SUM_DAMAGE_TAKEN] + damageTaken

    for _, v in ipairs( addonParty ) do
        if v[VT_UNIT_NAME] == memberName then
            v[VT_ACCUM_DAMAGE_TAKEN] = v[VT_ACCUM_DAMAGE_TAKEN] + damageTaken
        end
    end
end
function grp:getDamageTakenStats( memberName )
    local accumMemberDmgTaken = 0

    for _, v in ipairs( addonParty ) do
        if v[VT_UNIT_NAME] == memberName then
            accumMemberDmgTaken = v[VT_ACCUM_DAMAGE_TAKEN]
        end
    end
    return accumMemberDmgTaken, statsTable[SUM_DAMAGE_TAKEN]
end
function grp:setDamageDone( memberName, damageDone )

    statsTable[SUM_DAMAGE_DONE] = statsTable[SUM_DAMAGE_DONE] + damageDone

    for _, v in ipairs( addonParty ) do

        if v[VT_UNIT_NAME] == memberName then
            v[VT_ACCUM_DAMAGE_DONE] = v[VT_ACCUM_DAMAGE_DONE] + damageDone
        end
    end
end
function grp:getDamageDoneStats( memberName )
    local accumMemberDmgDone = 0
    for _, v in ipairs( addonParty ) do
        if v[VT_UNIT_NAME] == memberName then
            accumMemberDmgDone = v[VT_ACCUM_DAMAGE_DONE]
        end
    end
    return accumMemberDmgDone, statsTable[SUM_DAMAGE_DONE]
end
------------- HEALING RECEIVED METRICS ---------------------
function grp:setHealingReceived( memberName, healingReceived )
    local accumHealing = 0
    
    statsTable[SUM_HEALS_RECEIVED] = statsTable[SUM_HEALS_RECEIVED] + healingReceived

    for _, v in ipairs( addonParty ) do
        if v[VT_UNIT_NAME] == memberName then
            v[VT_ACCUM_HEALING_RECEIVED] = v[VT_ACCUM_HEALING_RECEIVED] + healingReceived
        end
    end
end
function grp:getHealingStats( memberName )
    local membersHealingReceived = 0

    for _, v in ipairs( addonParty ) do
        if v[VT_UNIT_NAME] == memberName then
            membersHealingReceived = v[VT_ACCUM_HEALING_RECEIVED]
            break
        end
    end
    return membersHealingReceived, statsTable[SUM_HEALS_RECEIVED]
end
---------------- THREAT METRICS -----------------------------
function grp:setThreatValues( memberName, threatValue)

    statsTable[SUM_THREAT_VALUE] = statsTable[SUM_THREAT_VALUE] + threatValue

    for _, v in ipairs( addonParty ) do
        if v[VT_UNIT_NAME] == memberName then
            v[VT_ACCUM_THREAT_VALUE] = v[VT_ACCUM_THREAT_VALUE] + threatValue
        end
    end
end
function grp:getThreatStats( memberName )    
    local membersThreatValue = 0

    for _, v in ipairs( addonParty ) do
        if v[VT_UNIT_NAME] == memberName then
            membersThreatValue = v[VT_ACCUM_THREAT_VALUE]
        end
    end

    return membersThreatValue, statsTable[SUM_THREAT_VALUE]
end
function grp:getStatsTable()
    return statsTable[SUM_THREAT_VALUE], statsTable[SUM_DAMAGE_TAKEN], statsTable[SUM_HEALS_RECEIVED], statsTable[SUM_DAMAGE_DONE]
end
function grp:resetCombatStats()
    statsTable = {0,0,0,0}
    for _, v in ipairs( addonParty ) do
        v[VT_THREAT_VALUE_RATIO]      = 0
        
        -- Accumulators
        v[VT_ACCUM_THREAT_VALUE]      = 0
        v[VT_ACCUM_DAMAGE_TAKEN]      = 0
        v[VT_ACCUM_DAMAGE_DONE]       = 0
        v[VT_ACCUM_HEALING_RECEIVED]  = 0
    end
end

-- called when PLAYER_ENTERING_WORLD fires
-- The addonParty is a party that mirrors the blizz
-- party or group. The partyPlayer members have the same
-- names and unitIds as do the blizzParty members.
function grp:initAddonParty()
    local r = {STATUS_SUCCESS, nil, nil }

    if not grp:blizzPartyExists() then
        local strace = debugstack()
        r = {STATUS_SUCCESS, "Blizzard Party Does Not Yet Exist", strace }
    end

    addonParty = {}

    local blizzNames = GetHomePartyInfo()
    ------------------------------------------------------------------------------
    -- CREATE THE PLAYER ENTRY AND, IF A PET IS PRESENT, THE PET'S ENTRY AS WELL.
    ------------------------------------------------------------------------------
    local memberName = UnitName("player")
    local playerId = "player"
    r = grp:insertPartyEntry(memberName, playerId, nil)
    if r[1] ~= STATUS_SUCCESS then return r end

    -- Does the player have a pet? If so, insert its entry into
    -- addon's table.
    local petId = "pet"
    local petName = UnitName("pet")
    if petName ~= nil then
        r = grp:insertPartyEntry(petName, petId, memberName )
        if r[1] ~= STATUS_SUCCESS then   return r end
        -- msg:postMsg(sprintf("%s Pet Name %s, Owner %s\n", E:fileLocation(debugstack()), petName, memberName ))
    end

    -----------------------------------------------------------------------------
    --  CREATE AN ENTRY FOR EACH MEMBER (AND PET) OF THE BLIZZARD PARTY
    -----------------------------------------------------------------------------
    local count = grp:getBlizzPartyCount()
    for i = 1, count do
        local blizzMemberName = UnitName( party[i] )
        if not grp:inPlayersParty( blizzMemberName ) then
            r = grp:insertPartyEntry( blizzMemberName, party[i], nil )
            if r[1] ~= STATUS_SUCCESS then return r end
        end
        -- Now, enter the pet if present
        local petName = UnitName( partypet[i])
        if petName ~= nil then
            r = grp:insertPartyEntry( petName, partypet[i], blizzMemberName  )
            if r[1] ~= STATUS_SUCCESS then return r end
            -- msg:postMsg(sprintf("%s Pet Name %s, Owner %s\n", E:fileLocation(debugstack()), petName, blizzMemberName ))
        end
    end  
    return r
end

E:where("GroupServices.lua loaded")