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
grp.VT_HEALING_TAKEN       = 9
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
local VT_HEALING_TAKEN           = grp.VT_HEALING_TAKEN
local VT_BUTTON                  = grp.VT_BUTTON
local VT_NUM_ELEMENTS            = grp.VT_BUTTON

playersParty = nil

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
local function copyEntries( v, e)
    v[VT_AGGRO_STATUS]          = e[VT_AGGRO_STATUS]
    v[VT_THREAT_VALUE]          = e[VT_THREAT_VALUE]
    v[VT_THREAT_VALUE_RATIO]    = e[VT_THREAT_VALUE_RATIO]
    v[VT_HEALING_TAKEN]         = e[VT_HEALING_TAKEN]
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
function grp:getUnitIdByName( memberName )
    for _, npv in ipairs( playersParty ) do
        if npv[1] == memberName then
            return npv[2]
        end
    end
    return nil
end
function grp:updateDamageTaken( memberName, damage )
    local r = RESULT -- {STATUS_SUCCESS, nil, nil}

    for _, v in ipairs( playersParty ) do
        -- if the entry has already been inserted then just return
        if v[VT_UNIT_NAME] == memberName then
            v[VT_DAMAGE_TAKEN] = v[VT_DAMAGE_TAKEN] + damage
            return r
        end
    end
end
function grp:updateHealingTaken( memberName, healing )
    for _, v in ipairs( playersParty ) do
        -- if the entry has already been inserted then just return
        if v[VT_UNIT_NAME] == memberName then
            v[VT_HEALING_TAKEN] = V[VT_HEALING_TAKEN] + healing
        end
    end
end
function grp:setThreatValue( memberName, threatValue)
    for _, v in ipairs( playersParty ) do
        if v[VT_UNIT_NAME] == memberName then
            v[VT_THREAT_VALUE] = 0
            v[VT_THREAT_VALUE] = threatValue
        end
    end

end
function grp:setThreatValueRatio( memberName, threatValueRatio )
    for _, v in ipairs( playersParty) do
        if v[VT_UNIT_NAME] == memberName then
            v[VT_THREAT_VALUE_RATIO] = 0
            v[VT_THREAT_VALUE_RATIO] = threatValueRatio
        end
    end
end
function grp:insertEntryInPlayersParty( entry )
    local r = RESULT -- {STATUS_SUCCESS, nil, nil}

    for _, v in ipairs( playersParty ) do
        -- if the entry has already been inserted then just return
        if  v[VT_UNIT_NAME] == entry[VT_UNIT_NAME] then
            copyEntries( v, entry)
            return r
        end
    end
    return r
end
function grp:initPlayersParty()
    local r = RESULT -- {STATUS_SUCCESS, nil, nil}

    local blizzPartyNames = GetHomePartyInfo()
    if blizzPartyNames == nil then
        return r
    end

    local playersParty = {}
    -- The calling player is special and not included among the
    -- names returned by GetHomePartyInfo()
    local player = UnitName("player")
    local newEntry, r = createNewEntry( player, "player" )
    table.insert( playersParty, newEntry )
    -- printPartyEntry( newEntry )

    -- if this player has a pet
    local pet = UnitName("pet")
    if pet ~= nil then
        local petEntry, r = createNewEntry( pet, "pet", player )
        table.insert( playersParty, petEntry )
        -- printPartyEntry( petEntry )
    end

    local count = #blizzPartyNames
    for i = 1, count do
        
        -- get a blizz party member's entry
        local playerId = partyId[i]
        local playerName = UnitName( playerId )
        local blizzPartyMember = blizzPartyNames[i]

        -- congruency check
        if playerName ~= blizzPartyMember then
            E:where( "party names are incongruent.")
            return
        end

        local newEntry, r = createNewEntry( playerName, playerId )
        table.insert( playersParty, newEntry )
        -- printPartyEntry( newEntry )

        -- if this player owns a pet, enter it also.
        local petName = UnitName( petId[i] )
        if petName ~= nil then 
            local petEntry, r = createNewEntry( petName, petId[i], playerName )
            table.insert( playersParty, petEntry )
            -- printPartyEntry( petEntry )
        end
    end
    return playersParty, r
end
