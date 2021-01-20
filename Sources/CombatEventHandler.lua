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

function ceh:handleEvent( stats )
    local targetName = stats[TARGETNAME]
    local subEvent = stats[SUBEVENT]

    if  subEvent ~= "SPELL_HEAL" and
        subEvent ~= "SPELL_PERIODIC_HEAL" and 
        subEvent ~= "SPELL_SUMMON" and
        subEvent ~= "SWING_DAMAGE" and
        subEvent ~= "SPELL_DAMAGE" and
        subEvent ~= "SPELL_PERIODIC_DAMAGE" and 
        subEvent ~= "RANGE_DAMAGE" then
            return
    end
    -------------- DAMAGE TAKEN ---------------
    if  subEvent == "SWING_DAMAGE" or
        subEvent == "SPELL_DAMAGE" or
        subEvent == "SPELL_PERIODIC_DAMAGE" or
        subEvent == "RANGE_DAMAGE" then
        
        local amountDamaged = 0
        if subEvent == "SWING_DAMAGE" then
            amountDamaged = stats[12]
        else
            amountDamaged = stats[15]
        end
        -- E:where( targetName..", damageTaken: "..amountDamaged )
        grp:updateDamageTaken( targetName, amountDamaged )
    end
    ------------- HEALING RECEIVED --------------------
    if  subEvent == "SPELL_HEAL" or subEvent == "SPELL_PERIODIC_HEAL" then
        grp:updateHealingReceived( targetName, stats[15] )
    end
    ------------- PET SUMMONED --------------------
    if  subEvent == "SPELL_SUMMON" then
        -- not implemented yet
    end   
end