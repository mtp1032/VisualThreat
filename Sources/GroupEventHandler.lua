--------------------------------------------------------------------------------------
-- GroupEventHandler.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 October, 2019
--
-- UnitId Reference: https://wow.gamepedia.com/UnitId
-- https://wow.gamepedia.com/API_UnitIsGroupLeader
-- see https://wow.gamepedia.com/GROUP_ROSTER_UPDATE
--------------------------------------------------------------------------------------
local _, VisualThreat = ...
VisualThreat.GroupEventHandler = {}
grp = VisualThreat.GroupEventHandler

local sprintf   = _G.string.format
local L         = VisualThreat.L

local E                 = errors
local STATUS_SUCCESS 	= E.STATUS_SUCCESS
local STATUS_FAILURE 	= E.STATUS_FAILURE
local RESULT 			= E.SUCCESS -- = { STATUS_SUCCESS, nil, nil }

grp.VT_UNIT_NAME           = 1
grp.VT_UNIT_ID             = 2 
grp.VT_PET_OWNER           = 3
grp.VT_MOB_ID              = 4  
grp.VT_AGGRO_STATUS        = 5      
grp.VT_THREAT_VALUE        = 6     
grp.VT_THREAT_VALUE_RATIO  = 7
grp.VT_DAMAGE_TAKEN        = 8
grp.VT_HEALING_RECEIVED    = 9
grp.VT_PLAYER_FRAME        = 10
grp.VT_BUTTON              = 11
grp.VT_NUM_ELEMENTS     = grp.VT_BUTTON

-- See https://wow.gamepedia.com/API_Region_GetPoint
local VT_UNIT_NAME               = grp.VT_UNIT_NAME
local VT_UNIT_ID                 = grp.VT_UNIT_ID   
local VT_PET_OWNER               = grp.VT_PET_OWNER 
local VT_MOB_ID                  = grp.VT_MOB_ID                  
local VT_AGGRO_STATUS            = grp.VT_AGGRO_STATUS              
local VT_THREAT_VALUE            = grp.VT_THREAT_VALUE             
local VT_THREAT_VALUE_RATIO      = grp.VT_THREAT_VALUE_RATIO
local VT_DAMAGE_TAKEN            = grp.VT_DAMAGE_TAKEN
local VT_HEALING_RECEIVED        = grp.VT_HEALING_RECEIVED
local VT_PLAYER_FRAME            = grp.VT_PLAYER_FRAME
local VT_BUTTON                  = grp.VT_BUTTON
local VT_NUM_ELEMENTS            = grp.VT_BUTTON

local partypet  = {"partypet1", "partypet2", "partypet3", "partypet4"}
local party     = {"party1",    "party2",    "party3",    "party4" }

grp.playersParty = nil

function grp:printPartyEntry( nvp )
    if nvp[VT_PET_OWNER] ~= nil then
        msg:post( sprintf("Unit Name = %s, UnitId = %s, Owner's Name = %s\n", 
                                        nvp[VT_UNIT_NAME], 
                                        nvp[VT_UNIT_ID], 
                                        nvp[VT_PET_OWNER]))
    else
        msg:post( sprintf("Unit Name = %s, unitId = %s\n",  
                                        nvp[VT_UNIT_NAME], 
                                        nvp[VT_UNIT_ID] ))
    end
end
local function createNewEntry( unitName, unitId, ownerName, mobId )
    local r = {STATUS_SUCCESS, nil, nil}

    if unitName == nil then
        local st = debugstack(2)
        local str = sprintf("%s: %s", L["ARG_NIL"], "unitName" )
        return nil, E:setResult( str, st )
    end
    if unitId == nil then
        local st = debugstack(2)
        local str = sprintf("%s: %s", "unitId", L["ARG_NIL"] )
        return nil, E:setResult( str, st )
    end

    local newEntry = {nil, nil, nil, nil, 0, 0, 0, 0, 0, nil, ""}
    
    newEntry[VT_UNIT_NAME] = unitName
    newEntry[VT_UNIT_ID] = unitId
    if ownerName ~= nil then
        newEntry[VT_PET_OWNER] = ownerName
	end
	if mobId ~= nil then
        newEntry[VT_MOB_ID] = mobId
    end
	return newEntry, r
end 
function grp:inPlayersParty( memberName )
    local isMember = false
    if grp.playersParty == nil or #grp.playersParty == 0 then
        return isMember
    end
    for _, v in ipairs( grp.playersParty) do
        if v[1] == memberName then
            isMember = true
        end
    end
    return isMember
end
function grp:inBlizzParty( memberName )
    local isBlizzMember = false
    
    local blizzNames = GetHomePartyInfo()
    if blizzNames == nil then return isBlizzMember end

    local count = #blizzNames
    for i = 1, count do
        for _, v in ipairs( grp.playersParty) do
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
-- includes the "player".
function grp:getBlizzPartyCount()
    local blizzMemberCount = 0
    local blizzNames = GetHomePartyInfo()
    if blizzNames == nil then 
        return blizzMemberCount
    end
    -- the playerCount includes the "player". Therefore, the player count can
    -- be a maximum of 5 players, "player", "party1", ..., "party4"
    local blizzMemberCount = #blizzNames + 1
    return blizzMemberCount 
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
function grp:getBlizzPartyNames()
    local blizzNames = GetHomePartyInfo()
    if blizzNames == nil then return nil end
    local t = {}
    t[1] = UnitName("player")
    local count = #blizzNames + 1
    for i = 2, count do
        t[i] = blizzNames[i-1]
    end

    for i = 1, #t do
    end
    return t
end
function grp:getPartyNames()
    local partyNames = {}
    local i = 1
    for _, v in ipairs( grp.playersParty ) do
        if v[VT_PET_OWNER] == nil then 
            partyNames[i] = v[VT_UNIT_NAME]
            i = i + 1
        end
    end
    return partyNames
end
-- returns a count of the number of playerParty members. Does not
-- include pets (use getPetCount())
function grp:getPartyCount()
    local partyCount = 0
    if grp.playersParty == nil or #grp.playersParty == 0 then
        return partyCount
    end

    for i, v in ipairs( grp.playersParty ) do
        -- If the VT_PET_OWNER field contains a name
        -- this entry is a pet, not a player.
        if v[VT_PET_OWNER] == nil then 
            partyCount = partyCount + 1
        end
    end
    return partyCount
end
function grp:getPetCount()
    local petCount = 0
    if grp.playersParty == nil or #grp.playersParty == 0 then
        return petCount
    end

    for i, v in ipairs( grp.playersParty ) do
        -- If the VT_PET_OWNER field contains a name
        -- i.e., is non-nil, then this entry is a pet, 
        -- not a player.
        if v[VT_PET_OWNER] ~= nil then 
            petCount = petCount + 1
        end
    end
    return petCount

end
function grp:insertPartyMember( unitName, unitId, OwnerName )    
    local r = {STATUS_SUCCESS, nil, nil }

    local newEntry, r = createNewEntry( unitName, unitId, OwnerName, nil )
    if newEntry == nil then
        return nil, r 
    end
    if grp.playersParty == nil then grp.playersParty = {} end
    table.insert( grp.playersParty, newEntry )
    return newEntry, r
end
function grp:removePlayer( memberName )

    if grp.playersTable == nil or #grp.playersTable == 0 then
        return
    end

    for i, v in (grp.playersParty) do
        if v[1] == memberName then
            -- v[VT_PLAYER_FRAME]:Hide()
            table.remove( grp.playersParty, i )
        end
    end
end
function grp:getUnitIdByName( memberName )
    for _, nvp in ipairs( grp.playersParty ) do
        if nvp[1] == memberName then
            return nvp[2]
        end
    end
    return nil
end
function grp:getEntryByName( partyName )
    for _, nvp in ipairs( grp.playersParty ) do
        if nvp[1] == partyName then
            return nvp
        end
    end
    return nil
end
function grp:getOwnerByPetName( petName )
    local petOwner = nil 
    for _, v in ipairs( grp.playersParty ) do
        if v[VT_UNIT_NAME] == petName then
            petOwner = v[VT_PET_OWNER]
            break
        end
    end
    return petOwner
end
function grp:updateDamageTaken( memberName, damage )
    local r = {STATUS_SUCCESS, nil, nil}
    local damageTaken = 0

    for _, v in ipairs( grp.playersParty ) do
        if v[VT_UNIT_NAME] == memberName then -- accumulate the damage
            v[VT_DAMAGE_TAKEN] = v[VT_DAMAGE_TAKEN] + damage
            damageTaken = v[VT_DAMAGE_TAKEN]
        end
    end
    return damageTaken
end
function grp:getDamageTaken( memberName )
    local damageTaken = 0
    for _, v in ipairs( grp.playersParty ) do
        if v[VT_UNIT_NAME] == memberName then
            damageTaken = v[VT_DAMAGE_TAKEN]
            break
        end
    end
    return damageTaken
end
function grp:updateHealingReceived( memberName, healing )
    for _, v in ipairs( grp.playersParty ) do
        -- if the entry has already been inserted then just return
        if v[VT_UNIT_NAME] == memberName then
            v[VT_HEALING_RECEIVED] = v[VT_HEALING_RECEIVED] + healing
        end
    end
end
function grp:getHealingReceived( memberName )
    local HealingReceived = 0
    for _, v in ipairs( grp.playersParty ) do
        if v[VT_UNIT_NAME] == memberName then
            HealingReceived = v[VT_HEALING_RECEIVED]
            break
        end
    end
    return HealingReceived
end
function grp:hidePlayerFrame()
    -- btn.threatIconStack:Hide()
end
function grp:showPlayerFrame()
    -- btn.threatIconStack:Show()
end
function grp:setThreatValue( memberName, threatValue)
    for _, v in ipairs( grp.playersParty ) do
        if v[VT_UNIT_NAME] == memberName then
            v[VT_THREAT_VALUE] = 0
            v[VT_THREAT_VALUE] = threatValue
        end
    end

end
function grp:setThreatValueRatio( memberName, threatValueRatio )
    for _, v in ipairs( grp.playersParty ) do
        if v[VT_UNIT_NAME] == memberName then
            v[VT_THREAT_VALUE_RATIO] = threatValueRatio
        end
    end
end
function grp:getThreatValueRatio( memberName )
    local threatValueRatio = 0
    for _, v in ipairs( grp.playersParty ) do
        if v[VT_UNIT_NAME] == memberName then
            threatValueRatio = v[VT_THREAT_VALUE_RATIO]
            break
        end
    end
    return threatValueRation
end
function grp:getPlayersParty()
    return grp.playersParty
end
-- called when PLAYER_ENTERING_WORLD fires
-- The playersParty is a party that mirrors the blizz
-- party or group. The partyPlayer members have the same
-- names and unitIds as do the blizzParty members.
function grp:initPlayersParty()
    local r = {STATUS_SUCCESS, nil, nil}

    local blizzPartyCount = grp:getBlizzPartyCount()
    if blizzPartyCount == 0 then
        return
    end
    -- nullify the players party. We start from scratch each time
    -- this function is called.
    grp.playersParty = {}

    local blizzPartyNames = GetHomePartyInfo()

    -- The calling player is special and not included among the
    -- names returned by GetHomePartyInfo(). We need to explicitly
    -- add it.
    local memberName = UnitName("player")
    local playerId = "player"
    r = grp:insertPartyMember(memberName, playerId, nil)
    if r[1] == STATUS_FAILURE then
        return r
    end
    local petName = UnitName("pet")
    if petName ~= nil then
        r = grp:insertPartyMember(petName, "pet", memberName )
        if r[1] == STATUS_FAILURE then
            return r
        end
    end
    -- NOTE: the table of names returned by GetHomePartyInfo() does
    --          not include pets or the player.
    local count = #blizzPartyNames
    for i = 1, count do
        -- get a blizz party member's entry
        local blizzMemberId = party[i]
        local blizzMemberName = UnitName( blizzMemberId )
        if not grp:inPlayersParty(blizzMemberName ) then
            r = grp:insertPartyMember( blizzMemberName, blizzMemberId, nil )
            if r[1] == STATUS_FAILURE then
                return r
            end
        end
        local petName = UnitName( partypet[i])
        if petName ~= nil then
            local entry, r = grp:insertPartyMember( "Zilgup", "partypet1", "babethree" )
            if r[1] == STATUS_FAILURE then
                return r
            end
            local nvp = grp:getEntryByName( petName )
        end
    end        
    return r
end
function grp:congruencyCheck()
    local blizzPartyCount = grp:getBlizzPartyCount()
    local blizzPetCount = grp:getBlizzPetCount()
    local partyCount = grp:getPartyCount()
    local petCount = grp:getPetCount()

    -- TEST 1: numbers match
    if blizzPartyCount  ~= partyCount then 
        local st = debugstack(2)
        local str = sprintf("%s", L["ARG_UNEQUAL_VALUES"])
        return false, E:setResult( str, st )
    end
    if blizzPetCount ~= petCount then 
        local st = debugstack(2)
        local str = sprintf("%s", L["ARG_UNEQUAL_VALUES"])
        return false, E:setResult( str, st )
    end

    -- TEST 2: names match
    local partyNames = grp:getPartyNames()
    local blizzNames = grp:getBlizzPartyNames()
    for i = 1, blizzPartyCount do
        if partyNames[i] ~= blizzNames[i] then
            local st = debugstack(2)
            local str = sprintf("%s", L["ARG_UNEQUAL_VALUES"])
            return false, E:setResult( str, st )
        end
    end
    return true
end
