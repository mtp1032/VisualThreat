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
grp.VT_HEALING_RECEIVED       = 9
grp.VT_BUTTON              = 10
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
local VT_BUTTON                  = grp.VT_BUTTON
local VT_NUM_ELEMENTS            = grp.VT_BUTTON

grp.playersParty = {}

local partypet  = {"partypet1", "partypet2", "partypet3", "partypet4"}
local party     = {"party1",    "party2",    "party3",    "party4" }

local function printPartyEntry( nvp )
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
local function copyEntries( v, e)   -- *** Copies e into v ***
    v[VT_AGGRO_STATUS]          = e[VT_AGGRO_STATUS]
    v[VT_THREAT_VALUE]          = e[VT_THREAT_VALUE]
    v[VT_THREAT_VALUE_RATIO]    = e[VT_THREAT_VALUE_RATIO]
    v[VT_HEALING_RECEIVED]      = e[VT_HEALING_RECEIVED]
    v[VT_BUTTON]                = e[VT_BUTTON]
end
local function createNewEntry( unitName, unitId, ownerName, mobId )
    local r = RESULT -- {STATUS_SUCCESS, nil, nil}

    if unitName == nil then
        local st = debugstack()
        local str = sprintf("INVALID_ARG: unitName not specified.\n%s\n", st )
        r = E:setResult( str )
        return nil, r
    end
    if unitId == nil then
        local st = debugstack()
        local str = sprintf("INVALID_ARG: unitId not specified.\n%s\n", st )
        r = E:setResult( str )
        return nil, r
    end

    local newEntry = {nil, nil, nil, nil, 0, 0, 0, 0, 0, ""}
    
    newEntry[VT_UNIT_NAME] = unitName
    newEntry[VT_UNIT_ID] = unitId

    if ownerName ~= nil then
        newEntry[VT_PET_OWNER] = ownerName
	end
	if mobId ~= nil then
        newEntry[VT_MOB_ID] = mobId
    end
    -- printPartyEntry( newEntry )
	return newEntry, r
end 
function grp:isPartyMember( memberName )
    local isAMember = false
    for _, v in ipairs( grp.playersParty) do
        if v[1] == memberName then
            isAMember = true
        end
    end
    return isAMember
end
function grp:getUnitIdByName( memberName )
    for _, npv in ipairs( playersParty ) do
        if npv[1] == memberName then
            return npv[2]
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
    local r = RESULT -- {STATUS_SUCCESS, nil, nil}
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
function grp:initPlayersParty()
    local r = {STATUS_SUCCESS, nil, nil}
    
    local blizzPartyNames = GetHomePartyInfo()
    if blizzPartyNames == nil then
        return "", r
    end

    -- The calling player is special and not included among the
    -- names returned by GetHomePartyInfo(). We need to explicitly
    -- add it.
    local player = UnitName("player")
    local newEntry, r = createNewEntry( player, "player" )
    if r[1] ~= STATUS_SUCCESS then
        local stackFrame = debugstack()
        local playerName = UnitName("player")
        local s = sprintf("Entry not created for %s.\n", player )
        return E:setResult( s, stackFrame )   
    end
    table.insert( grp.playersParty, newEntry )

    -- if this player has a pet
    local pet = UnitName("pet")
    if pet ~= nil then
        local petEntry, r = createNewEntry( pet, "pet", player )
        table.insert( grp.playersParty, petEntry )
    end

    local count = #blizzPartyNames
    for i = 1, count do
        -- get a blizz party member's entry
        local playerId = party[i]
        local playerName = UnitName( playerId )
        if not grp:isPartyMember(playerName ) then
            ------ CONGRUENCY CHECK REMOVE WHEN THOROUGHLY TESTED ------------
            if playerName ~= blizzPartyNames[i] then
                local stackFrame = debugstack()
                local errStr = sprintf("Party and Bizzard Names Incongruent.\n")
                return E:setResult( errStr, stackFrame )
            end

            local newEntry, r = createNewEntry( playerName, playerId )
            table.insert( grp.playersParty, newEntry )

            -- if this player owns a pet, enter it also.
            local petName = UnitName( partypet[i] )
            if petName ~= nil then 
                local petEntry, r = createNewEntry( petName, partypet[i], playerName )
                table.insert( grp.playersParty, petEntry )
            end
        end
    end
    return grp.playersParty, r
end
function grp:eventHandler( event )
end