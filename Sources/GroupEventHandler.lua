--------------------------------------------------------------------------------------
-- GroupEventHandler.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 October, 2019
--------------------------------------------------------------------------------------
local _, VisualThreat = ...
VisualThreat.GroupEventHandler = {}
grp = VisualThreat.GroupEventHandler

local L = VisualThreat.L
local E = errors
local sprintf = _G.string.format

-- UnitId Reference: https://wow.gamepedia.com/UnitId
-- https://wow.gamepedia.com/API_UnitIsGroupLeader
-- see https://wow.gamepedia.com/GROUP_ROSTER_UPDATE
-- 

local ENTRY_UNIT_NAME           = btn.ENTRY_UNIT_NAME -- playerName or petName             
local ENTRY_UNIT_ID 		    = btn.ENTRY_UNIT_ID	  -- UnitId of player or pet
local ENTRY_PET_OWNER           = btn.ENTRY_PET_OWNER -- if this is a pet entry, ENTRY_PET_OWNER is the owner of the pet. Nil otherwise
local ENTRY_MOB_ID			    = btn.ENTRY_MOB_ID    -- UUID of mob targeting player                    
local ENTRY_AGGRO_STATUS 		= btn.ENTRY_AGGRO_STATUS        -- 1, 2, 3, 4 (see https://wow.gamepedia.com/API_UnitDetailedThreatSituation )             
local ENTRY_THREAT_VALUE 		= btn.ENTRY_THREAT_VALUE        --  see https://wow.gamepedia.com/API_UnitDetailedThreatSituation               
local ENTRY_THREAT_VALUE_RATIO  = btn.ENTRY_THREAT_VALUE_RATIO  -- calculated: (playerThreatValue/totalThreatValue)
local ENTRY_BUTTON              = btn.ENTRY_BUTTON
local ENTRY_NUM_ELEMENTS        = btn.ENTRY_BUTTON

-- entry: {Name, unitId, petOwner, mobId, aggroStatus, threatValue, threatValueRatio, button }
-- default entry: {name, unitId, nil, nil, 0,0,0, nil }
local partyMembersTable = {}

local function memberTableToArray()
    if #partyMembersTable == 0 then return nil end
    local memberEntries = {}
    for i, v in ipairs( partyMembersTable ) do
        memberEntries[i] = v
        i = i + 1
    end
    return memberEntries
end
local function getNumPetEntries()
    if #partyMembersTable == 0 then return nil end

    local petCount = 0
    for _, v in ipairs( partyMembersTable ) do
        if v[ENTRY_PET_OWNER] then 
            petCount = petCount + 1 
        end
    end
    return petCount
end
local function getAllPetEntries()
    local petEntries = {}
    local i = 1
    for i, v in ipairs( partyMembersTable ) do
        if v[ENTRY_PET_OWNER] ~= nil then
            petEntries[i] = v
            i = i+1
            E:where( tostring(i))
        else
            E:where( v[ENTRY_UNIT_NAME ])
        end
    end

    if #petEntries == 0 then return nil end
    return petEntries
end
local function getPetEntryByOwner( ownerName )
    if #partyMembersTable == 0 then return nil end

    for _, v in ipairs( partyMembersTable ) do
        if v[ENTRY_PET_OWNER] == ownerName then
            return v
        end
    end
    return nil
end
local function getMemberEntryByName( memberName )
    if #partyMembersTable == 0 then return nil end

    for _, v in ipairs( partyMembersTable ) do
        if v[ENTRY_UNIT_NAME] == memberName then
            return entry
        end
    end
    return nil 
end
local function isMemberAnOrphan( memberName )
    if #partyMembersTable == 0 then return nil end

    local partyNames = GetHomePartyInfo()
    if partyNames == nil then
        return nil
    end

    local partyCount = #partyNames
    local memberEntries = memberTableToArray()
    local memberCount = #memberEntries
    local isOrphan = true

    for i = 1, memberCount do
        local entry = memberEntries[i]
        local memberName = entry[ENTRY_UNIT_NAME]
        for n = 1, partyCount do
            if memberName == partyNames[n] then
                return false
            end
        end
    end
    return isOrphan
end
local function removeOrphanMembers()

    local memberEntries = memberTableToArray()
    local memberCount = #memberEntries
    E:where( tostring(memberCount))
    for i = 1, memberCount do
        local memberEntry = memberEntries[i]
        if isMemberAnOrphan( memberEntry[ENTRY_UNIT_NAME] ) then

            -- if this orphaned member has a pet remove its entry
            local petName = getPetEntryByOwner( memberName )
            if petName ~= nil then
                grp:removeEntryFromPartyMembersTable( petName )
            end

            -- now remove the orphaned member
            grp:removeEntryFromPartyMembersTable( memberEntry )
        end
    end
end
local function dbgDumpPartyMembersTable()
    if #partyMembersTable == 0 then msg:post(sprintf("partyMembersTable uninitialized.\n")) end

    local dbgStr = nil
    for i, v in ipairs( partyMembersTable ) do
        dbgStr = sprintf("Name: %s UnitId: %s ", v[ENTRY_UNIT_NAME], v[ENTRY_UNIT_ID])
        local ownerName = v[ENTRY_PET_OWNER]
        if ownerName ~= nil then
            dbgStr = dbgStr..sprintf("Owner Name %s", ownerName )
        end
        dbgStr = dbgStr..sprintf("\n")
        msg:post( dbgStr )        
    end
end
local function dbgValidateHomePartyInfo()
    if #partyMembersTable == 0 then msg:post(sprintf("partyMembersTable uninitialized.\n")) end
    
    if not UnitInParty("player") then
        return
    end

    local partyNames = GetHomePartyInfo()
    if partyNames == nil then
        return
    end
    for i = 1, #partyNames do
        local playerName = partyNames[i]
    end
end
local function getUnitIdByName( memberName )
    local partyNames = GetHomePartyInfo()
    local count = #partyNames

    for i = 1, count do
        local memberId = "party"..tostring(i)
        local partyName = UnitName( memberId )
        if partyName == memberName then
            return memberId
        end
    end
    return nil
end
function grp:insertEntryInPartyMembersTable( entry )
    
    -- always overwrites an existing entry
    local isPresent = false
    for _, v in ipairs( partyMembersTable ) do
        if  v[ENTRY_UNIT_NAME] == entry[ENTRY_UNIT_NAME] then

            -- update the entry values
            v[ENTRY_UNIT_ID]            = entry[ENTRY_UNIT_ID]
            v[ENTRY_PET_OWNER]          = entry[ENTRY_PET_OWNER]
            v[ENTRY_MOB_ID]             = entry[ENTRY_MOB_ID]
            v[ENTRY_AGGRO_STATUS]       = entry[ENTRY_AGGRO_STATUS]
            v[ENTRY_THREAT_VALUE]       = entry[ENTRY_THREAT_VALUE]
            v[ENTRY_THREAT_VALUE_RATIO] = entry[ENTRY_THREAT_VALUE_RATIO]
            v[ENTRY_BUTTON]             = entry[ENTRY_BUTTON]
            isPresent = true
        end
    end

    if isPresent == false then
        table.insert( partyMembersTable, entry )
    end
    return
end
function grp:removeEntryFromPartyMembersTable( memberName )
    if #partyMembersTable == 0 then return nil end

    local tmp = {}
    -- copy all entries except the one to be deleted into
    -- the tmp table
    for _, v in ipairs( partyMembersTable ) do
        if v[1] ~= memberName then
            table.insert( tmp, v )
        end
    end

    -- zero out the partyMembersTable and copy the entries
    -- in the tmp table back into the partyMembersTable
    partyMembersTable = {}
    for _, v in ipairs( tmp ) do
        if #partyMembersTable == 0 then 
            partyMembersTable = { v }
        else
            table.insert( partyMembersTable, v )
        end
    end
end
function grp:getPartyMembersTable()
    if #partyMembersTable == 0 then return nil end
    return partyMembersTable
end
local function handleEvent( event )

    if not UnitInParty("player") then
        return
    end

    partyMembersTable = {}

    -- at this point, the player is in the game's party but the player's copy of the 
    -- partyMembersTable does not exist so we must create it.

    -- Step 1: create the member's entry and a pet entry if pet exists.
    local playerName = UnitName( "player")
    local petName = UnitName("pet")
    local playerEntry = nil
    playerEntry = {playerName, "player", nil, nil, 0,0,0,nil}
    grp:insertEntryInPartyMembersTable( playerEntry)
    local petEntry = nil
    if petName ~= nil then
        petEntry = {petName, "pet", playerName, nil, 0,0,0,nil}
        grp:insertEntryInPartyMembersTable( petEntry )
        local logStr = sprintf("%s %s inserted in member's table.\n", event, petName )
    end

    -- NOW DO THE SAME FOR THE REST OF THE PARTY
    local partyNames = GetHomePartyInfo()
    if partyNames == nil then
        return
    end
    local count = #partyNames

    for i = 1, count do
        local partyMemberName = UnitName( partyNames[i])
        local playerId = getUnitIdByName( partyMemberName )
        if playerId ~= nil then
            playerEntry = { partyMemberName, playerId, nil, nil, 0,0,0, nil}
            grp:insertEntryInPartyMembersTable( playerEntry)
        
            -- If this player has a pet, build and insert its entry. NOTE: the player's pet id 
            -- has the same suffix as the player id, e.g.,
            --          partyN == partpetN
            local petId = "partypet"..tostring(i)
            if UnitName( petId ) ~= nil then
                local ownerName = partyMemberName
                petName = UnitName( petId )
                petEntry = { petName, petId, ownerName, nil, 0,0,0, nil}
                grp:insertEntryInPartyMembersTable( petEntry )
            end
        end
    end
    return
end
local function OnEvent( self, event, ...)
    local arg1, arg2, arg3, arg4 = ...
------------------------------ PLAYER ENTERING WORLD -----------------
    if event == "PLAYER_ENTERING_WORLD" then
        handleEvent( event )
        return
    end
--------------------------- GROUP ROSTER UPDATE ---------------------
    if event == "GROUP_ROSTER_UPDATE" then
        handleEvent( event )
        return
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")			-- arg1: boolean isInitialLogin, arg2: boolean isReloadingUI
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:SetScript("OnEvent", OnEvent )

-- Player Icon
 
-- party1 Icon
-- party2 Icon
-- party3 Icon
-- party4 Icon
local CR = sprintf("\n")
SLASH_GROUP_TEST1 = "/grp"
SlashCmdList["GROUP_TEST"] = function( num )
    dbgDumpPartyMembersTable()
    dbgValidateHomePartyInfo()
    msg:post( CR )
end
SLASH_PET_TEST1 = "/pet"
SlashCmdList["PET_TEST"] = function( num )

    local petEntries = getAllPetEntries()
    if petEntries == nil then
        msg:post(sprintf("PET TEST: %s shows no pet entries.\n", UnitName("player")))
    else
        msg:post(sprintf("PET TEST: %s shows %d pet entries.\n", UnitName("player"), #petEntries ))
    end

end

