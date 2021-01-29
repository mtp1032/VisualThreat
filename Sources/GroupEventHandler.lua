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

grp.VT_UNIT_NAME            = 1
grp.VT_UNIT_ID              = 2 
grp.VT_PET_OWNER            = 3
grp.VT_MOB_ID               = 4  
grp.VT_THREAT_VALUE         = 5     
grp.VT_ACCUM_THREAT_VALUE   = 6
grp.VT_THREAT_VALUE_RATIO   = 7

grp.VT_DAMAGE_TAKEN         = 8
grp.VT_ACCUM_DAMAGE_TAKEN   = 9

grp.VT_HEALING_RECEIVED     = 10
grp.VT_ACCUM_HEALING_RECEIVED  = 11

grp.VT_BUTTON               = 12
grp.VT_NUM_ELEMENTS         = grp.VT_BUTTON

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
local VT_ACCUM_HEALING_RECEIVED     = grp.VT_ACCUM_HEALING_RECEIVED
local VT_BUTTON                  = grp.VT_BUTTON
local VT_NUM_ELEMENTS            = grp.VT_BUTTON

local partypet  = {"partypet1", "partypet2", "partypet3", "partypet4"}
local party     = {"party1",    "party2",    "party3",    "party4" }

grp.playersParty = {}

---------------------------------------------+
function grp:getAddonPartyNames()
    if #grp.playersParty == 0 then return nil end

    local partyNames = {}
    local i = 1
    for _, v in ipairs( grp.playersParty ) do
        if v[VT_UNIT_NAME] ~= UnitName("player") then
            if v[VT_PET_OWNER] == nil then 
                partyNames[i] = v[VT_UNIT_NAME]
                i = i + 1
            end
        end
    end
    return partyNames
end
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
        local st = debugstack()
        local str = sprintf("%s: %s", L["ARG_NIL"], "unitName" )
        return nil, E:setResult( str, st )
    end
    if unitId == nil then
        local st = debugstack()
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
    if #grp.playersParty == 0 then
        return isMember
    end
    for _, v in ipairs( grp.playersParty ) do
        if v[1] == memberName then
            isMember = true
        end
    end
    return isMember
end
function grp:getPlayerNames()
    local playerNames = {}
    for i, v in ipairs( grp.playersParty ) do
        playerNames[i] = v[VT_UNIT_NAME]
    end
    return playerNames
end
function grp:inBlizzParty( memberName )
    local isBlizzMember = false
    
    local blizzNames = grp:getBlizzPartyNames()
    if blizzNames == nil then return isBlizzMember end

    local count = #blizzNames
    for i = 1, count do
        for _, v in ipairs( grp.playersParty ) do
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
    local blizzNames = grp:getBlizzPartyNames()
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
    local blizzNames = grp:getBlizzPartyNames()
    if blizzNames == nil then 
        return blizzMemberCount
    end
    return #blizzNames 
end
function grp:getBlizzPetCount()
    local blizzPetCount = 0
    local blizzNames = grp:getBlizzPartyNames()
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
function grp:getPartyCount()
    local partyCount = 0
    local name = nil
    if #grp.playersParty == 0 then
        return partyCount
    end

    for i, v in ipairs( grp.playersParty ) do
        -- If the VT_PET_OWNER field contains a name
        -- this entry is a pet, not a player.
        if v[VT_PET_OWNER] == nil then 
            name = v[1]
            partyCount = partyCount + 1
        end
    end
    return partyCount
end
function grp:getPetCount()
    local petCount = 0
    if #grp.playersParty == 0 then
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

    if grp:inPlayersParty( unitName ) then 
        return r 
    end

    local newEntry, r = createNewEntry( unitName, unitId, OwnerName, nil )
    if newEntry == nil then
        return r 
    end

    table.insert( grp.playersParty, newEntry )
    return r
end
function grp:removePlayer( memberName )

    if #grp.playersParty == 0 then
        return
    end

    for i, v in ( grp.playersParty ) do
        if v[1] == memberName then
            table.remove( grp.playersParty, i )
        end
    end
end
function grp:getUnitIdByName( memberName )
    if #grp.playersParty == 0 then return nil end
  
    for _, nvp in ipairs( grp.playersParty ) do
        if nvp[1] == memberName then
            return nvp[2]
        end
    end
    return nil
end
function grp:getEntryByName( partyName )
    if #grp.playersParty == 0 then return nil end

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
--- DAMAGE TAKEN METRICS
function grp:setDamageTaken( memberName, damageTaken )

    for _, v in ipairs( grp.playersParty ) do
        if v[VT_UNIT_NAME] == memberName then
            v[VT_DAMAGE_TAKEN] = damageTaken
            v[VT_ACCUM_DAMAGE_TAKEN] = v[VT_ACCUM_DAMAGE_TAKEN] + damageTaken
        end
    end
end
function grp:getDamageTaken( memberName )
    local damageTaken = 0
    local accumDamageTaken = 0

    for _, v in ipairs( grp.playersParty ) do
        if v[VT_UNIT_NAME] == memberName then
            damageTaken = v[VT_DAMAGE_TAKEN]
            accumDamageTaken = v[VT_ACCUM_DAMAGE_TAKEN]
            E:where( sprintf("%s: accum %d\n", memberName, accumDamageTaken ))
            return damageTaken, accumDamageTaken
        end
    end
    return damageTaken, accumDamageTaken
end
function grp:resetCombatData()
    local accumDamageTaken = 0
    local accumHealingReceived = 0
    local accumThreatValue = 0    

    for _, v in ipairs( grp.playersParty ) do
        
        accumThreatValue        = accumThreatValue + v[VT_ACCUM_THREAT_VALUE]
        accumDamageTaken        = accumDamageTaken + v[VT_ACCUM_DAMAGE_TAKEN]
        accumHealingReceived    = accumHealingReceived + v[VT_ACCUM_HEALING_RECEIVED]

        v[VT_THREAT_VALUE]           = 0
        v[VT_ACCUM_THREAT_VALUE]     = 0
        v[VT_THREAT_VALUE_RATIO]     = 0
        v[VT_DAMAGE_TAKEN]           = 0
        v[VT_ACCUM_DAMAGE_TAKEN]     = 0
        v[VT_HEALING_RECEIVED]       = 0
        v[VT_ACCUM_HEALING_RECEIVED] = 0        
    end
    msg:postMsg( sprintf("Party Summary: Total Threat %d, Total Damage Taken %d\n", accumThreatValue, accumDamageTaken ))
    return accumThreatValue, accumDamageTaken, accumHealingReceived 
end
--- HEALING RECEIVED METRICS
function grp:setHealingReceived( memberName, healingReceived )
    for _, v in ipairs( grp.playersParty ) do
        if v[VT_UNIT_NAME] == memberName then
            v[VT_HEALING_RECEIVED] = healingReceived
            v[VT_ACCUM_HEALING_RECEIVED] = v[VT_ACCUM_HEALING_RECEIVED] + healingReceived
        end
    end
end
function grp:getHealingReceived( memberName )
    local healingReceived = 0
    local accumHealingReceived = 0

    for _, v in ipairs( grp.playersParty ) do
        if v[VT_UNIT_NAME] == memberName then
            healingReceived = v[VT_HEALING_RECEIVED]
            accumHealingReceived = v[VT_ACCUM_HEALING_RECEIVED]
            break
        end
    end
    return healingReceived, accumHealingReceived
end
--- THREAT METRICS
function grp:setThreatValue( memberName, threatValue)
    for _, v in ipairs( grp.playersParty ) do
        if v[VT_UNIT_NAME] == memberName then
            v[VT_THREAT_VALUE] = threatValue
            v[VT_ACCUM_THREAT_VALUE] = v[VT_ACCUM_THREAT_VALUE] + threatValue
        end
    end
end
function grp:getThreatValue( memberName )    
    local threatValue = 0
    local accumThreatValue = 0

    for _, v in ipairs( grp.playersParty ) do
        if v[VT_UNIT_NAME] == memberName then
            threatValue = v[VT_THREAT_VALUE]
            accumThreatValue = v[VT_ACCUM_THREAT_VALUE]
            break
        end
    end
    return threatValue, accumThreatValue

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
function grp:getBlizzPartyNames()
    return GetHomePartyInfo()
end
local function congruencyCheck()
    local r = {STATUS_SUCCESS, nil, nil}

    local blizzPartyCount = grp:getBlizzPartyCount()
    local blizzPetCount = grp:getBlizzPetCount()
    local partyCount = grp:getPartyCount()
    local petCount = grp:getPetCount()

    if blizzPartyCount < 2 then
        return true, r
    end

    -- TEST 1:  names in the partyPlayers and blizzParty groups
    --          match.
    local partyNames = grp:getAddonPartyNames()
    local blizzNames = grp:getBlizzPartyNames()
    for i = 1, blizzPartyCount do
        if partyNames[i] ~= blizzNames[i] then
            local st = debugstack()
            local str = sprintf("%s: %s ~= %s", L["ARG_UNEQUAL_VALUES"], partyNames[i], blizzNames[i])
            return false, E:setResult( str, st )
        end
    end

    -- TEST 2a: Are the pet counts equal
    if blizzPetCount ~= petCount then 
        local st = debugstack()
        local str = sprintf("%s", L["ARG_UNEQUAL_VALUES"])
        return false, E:setResult( str, st )
    end
    
    -- TEST 2a: Are player counts equal
    if #partyNames ~= #blizzNames then 
        local st = debugstack()
        local str = sprintf("%s: party %d, blizz %d", L["ARG_UNEQUAL_VALUES"], playersAndPets, blizzAndPets )
        return false, E:setResult( str, st )
    end

    return true, r
end

-- called when PLAYER_ENTERING_WORLD fires
-- The playersParty is a party that mirrors the blizz
-- party or group. The partyPlayer members have the same
-- names and unitIds as do the blizzParty members.
function grp:initPlayersParty()
    local r = {STATUS_SUCCESS, nil, nil}

    grp.playersParty = {}

    -- This is always the player doing the inviting, i.e., the party leader. S/He
    -- will not show up in blizzParty table.
    local memberName = UnitName("player")
    local playerId = "player"
    r = grp:insertPartyMember(memberName, playerId, nil)
    if r[1] ~= STATUS_SUCCESS then
        return r
    end

    local petName = UnitName("pet")
    if petName ~= nil then
        r = grp:insertPartyMember(petName, "pet", memberName )
    end
    -- NOTE: the table of names returned by grp:getBlizzPartyNames() does
    --          not include pets or the player whose name is given by 
    --          UnitName( "player").
    -- local count = grp:getBlizzPartyCount()
    -- local partyCount = grp:getPartyCount()
    -- if count ~= partyCount then
    --     local st = debugstack()
    --     local s = sprintf("party counts unequal: blizz is %d, player is %d", count, partyCount )
    --     return E:setResult(s, st)
    -- end
    local count = grp:getBlizzPartyCount()
    for i = 1, count do      
        -- get the blizz party member's name.
        local blizzMemberName = UnitName( party[i] )
        if not grp:inPlayersParty( blizzMemberName ) then
            r = grp:insertPartyMember( blizzMemberName, party[i], nil )
            if r[1] ~= STATUS_SUCCESS then
                return r
            end
        end
        local petName = UnitName( partypet[i])
        if petName ~= nil then
            r = grp:insertPartyMember( petName, partypet[i], blizzMemberName  )
            if r[1] ~= STATUS_SUCCESS then
                return r
            end
        end
    end  
    local successFull, r = congruencyCheck()
    if not successFull then
        return r
    end
    return r
end
