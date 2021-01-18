--------------------------------------------------------------------------------------
-- combatEventHandler.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 October, 2020
--------------------------------------------------------------------------------------
local _, VisualThreat = ...
VisualThreat.combatEventHandler = {}
ch = VisualThreat.combatEventHandler

local L = VisualThreat.L
local E = errors
local sprintf = _G.string.format

local STATUS_SUCCESS    = E.STATUS_SUCCESS
local STATUS_FAILURE    = E.STATUS_FAILURE
local SUCCESS           = E.SUCCESS

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

local SPELLID         	= 12 	-- amountDmg
local SPELLNAME       	= 13  	-- overKill
local SCHOOL		    = 14 	-- schoolIndex
local AMOUNT_DAMAGED	= 15
local AMOUNT_HEALED		= 15
local MISSTYPE			= 15    
local OVERKILL        	= 16	-- absorbed  (integer)
local OVERHEALED		= 16
local SCHOOL_INDEX    	= 17	-- critical  (boolean)
local RESISTED        	= 18 	-- glancing  (boolean)
local BLOCKED         	= 19 	-- crushing  (boolean)
local ABSORBED        	= 20 	-- isOffHand (boolean)
local CRITICAL        	= 21	-- <unused>
local GLANCING        	= 22	-- <unused>
local CRUSHING        	= 23	-- <unused>
local OFFHAND			= 24

-- indices into the partyMembersTable entry

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

------------- FUNCTIONS LOCAL TO THIS FILE ----------------------------
local function handleEvent( stats )
    local sourceName = stats[SOURCENAME]
    local targetName = stats[TARGETNAME]
 
    -- we're only interested in damage taken by a member
    -- of our party.
    local unitId = grp:getUnitIdByName( targetName )
    local inMyParty = UnitPlayerOrPetInParty( unitId )
    if not inMyParty then
        return
    end

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
        grp:updateMemberEntry( targetName, true, amountDamaged )
    end
    ------------- HEALING TAKEN --------------------
    if  subEvent == "SPELL_HEAL" or subEvent == "SPELL_PERIODIC_HEAL" then
        local amountHealed = stats[AMOUNT_HEALED]
        grp:updateMemberEntry( targetName, false, amountHealed )
    end
    ------------- PET SUMMONED --------------------
    if  subEvent == "SPELL_SUMMON" then
        -- not implemented yet
    end   
end

local function OnEvent( self, event, ...)
    local stats = {CombatLogGetCurrentEventInfo() }
    handleEvent( stats )
end
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:SetScript("OnEvent", OnEvent )
