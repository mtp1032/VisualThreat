--------------------------------------------------------------------------------------
-- combatEventHandler.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 October, 2020
--------------------------------------------------------------------------------------
local _, VisualThreat = ...
VisualThreat.combatEventHandler = {}
ceh = VisualThreat.combatEventHandler

local L = VisualThreat.L
local E = errors
local sprintf = _G.string.format

-- CELU base parameters
local TIMESTAMP			= 1		-- valid for all subEvents
local SUBEVENT    		= 2		-- valid for all subEvents
local HIDECASTER      	= 3		-- valid for all subEvents
local SOURCEGUID      	= 4 	-- valid for all subEvents
local SOURCENAME      	= 5 	-- valid for all subEvents
local SOURCEFLAGS     	= 6 	-- valid for all subEvents
local SOURCERAIDFLAGS 	= 7 	-- valid for all subEvents
local TARGETGUID      	= 8 	-- valid for all subEvents
local TARGETNAME      	= 9 	-- valid for all subEvents
local TARGETFLAGS     	= 10 	-- valid for all subEvents
local TARGETRAIDFLAGS 	= 11	-- valid for all subEvents

ceh.IN_COMBAT = true

function ceh:handleEvent( stats )
    local targetName = stats[TARGETNAME]
    local sourceName = stats[SOURCENAME]
    local subEvent = stats[SUBEVENT]

    -- this filters out all combat events EXCEPT those
    -- in which the target OR source is one of our members.
    if grp:inPlayersParty( sourceName ) ~= true and
       grp:inPlayersParty( targetName ) ~= true then
        return
    end

    if  subEvent ~= "SPELL_HEAL" and
        subEvent ~= "SPELL_PERIODIC_HEAL" and 
        subEvent ~= "SPELL_SUMMON" and
        subEvent ~= "SWING_DAMAGE" and
        subEvent ~= "SPELL_DAMAGE" and
        subEvent ~= "SPELL_PERIODIC_DAMAGE" and 
        subEvent ~= "RANGE_DAMAGE" then
            return
    end
    -------------- DAMAGE TAKEN AND DAMAGE DONE ---------------
    if  subEvent == "SWING_DAMAGE" or
        subEvent == "SPELL_DAMAGE" or
        subEvent == "SPELL_PERIODIC_DAMAGE" or
        subEvent == "RANGE_DAMAGE" then
        
        local damage = 0
        if subEvent == "SWING_DAMAGE" then
            damage = stats[12]
        else
            damage = stats[15]
        end
        if grp:inPlayersParty( targetName ) then
            -- E:where( sourceName.." hits "..targetName.." for "..tostring(damage ).." damage.")
            grp:setDamageTaken( targetName, damage )
        end
        if grp:inPlayersParty( sourceName ) then
            -- E:where( sourceName.." hits "..targetName.." for "..tostring(damage ).." damage.")
            grp:setDamageDone( sourceName, damage )
        end
    end
    ------------- HEALING RECEIVED --------------------
    if  subEvent == "SPELL_HEAL" or subEvent == "SPELL_PERIODIC_HEAL" then
        grp:setHealingReceived( targetName, stats[15] )
    end
    ------------- PET SUMMONED --------------------
    if  subEvent == "SPELL_SUMMON" then
        -- not implemented yet
    end   
end
