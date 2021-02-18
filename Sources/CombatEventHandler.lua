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
local SPELL_NAME        = 13

ceh.IN_COMBAT = true

local THREAT_GENERATED    = btn.THREAT_GENERATED
local HEALS_RECEIVED  = btn.HEALS_RECEIVED
local DAMAGE_TAKEN    = btn.DAMAGE_TAKEN

function ceh:handleEvent( stats )

    if not ceh.IN_COMBAT then
        return
    end
    
    local targetName = stats[TARGETNAME]
    local sourceName = stats[SOURCENAME]
    local subEvent = stats[SUBEVENT]
    local r = {STATUS_SUCCESS, nil, nil }

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
        subEvent ~= "SPELL_CAST_START" and
        subEvent ~= "SPELL_CAST_SUCCESS" and
        subEvent ~= "SPELL_INTERRUPT" and
        subEvent ~= "RANGE_DAMAGE" then
            return
    end

    if subEvent == "SPELL_CAST_START" then
        -- if the target is a group member, then s/he's been targeted
        -- by the caster.
        -- E:where( sourceName.." casting "..tostring(stats[13]))
        -- if grp:inPlayersParty( targetName ) then
        --     local targetUnitId = grp:getUnitIdByName( targetName )

        --     local spell, _, _, _, _, _, _, notInterruptible = UnitCastingInfo( targetUnitId )

        --     if notInterruptible == false then
        --         local s = sprintf("%s cast by %s is interruptible. Interrupt Now!", stats[13], sourceName )
        --         msg:postMsg( s )
        --     end
        -- end
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
            grp:setDamageTaken( targetName, damage )
        end
        if grp:inPlayersParty( sourceName ) then
            grp:setDamageDone( sourceName, damage )
        end
    end
    ------------- HEALING RECEIVED --------------------
    if  subEvent == "SPELL_HEAL" or subEvent == "SPELL_PERIODIC_HEAL" then
        -- msg:postMsg( sprintf("%s: %s (%s) healed %s for %d.\n", subEvent, stats[SPELL_NAME], stats[SOURCENAME], stats[TARGETNAME], stats[HEALS_RECEIVED]))
        grp:setHealingReceived( targetName, stats[15] )
    end
    ------------- PETS SUMMONED AND DISMISSED --------------------
    local spell = string.upper( stats[SPELL_NAME] )
    
    -- Hunter calls/summons a pet
    if subEvent == "SPELL_SUMMON" then
        local hunterSpell = string.sub(spell,1, 8)
        if hunterSpell == "CALL PET" then
            local huntersName = stats[SOURCENAME]
            local petName = stats[TARGETNAME]
            local petId = "pet"
            grp:insertPartyEntry( petName, petId, huntersName)
            -- msg:postMsg( sprintf("%s %s's pet %s added to party.\n", E:fileLocation( debugstack()),huntersName, petName ))
        end
    end
    -- Warlock summons a pet
    if subEvent == "SPELL_SUMMON" then
        local lockSpell = string.sub(spell,1, 6)
        if spell == "SUMMON" then
            local locksName = stats[SOURCENAME]
            local petName = stats[TARGETNAME]
            local petId = "pet"
            grp:insertPartyEntry( petName, petId, locksName)
            -- msg:postMsg( sprintf("%s %s's pet %s added to party.\n", E:fileLocation( debugstack()), locksName, petName ))
        end
    end
    -- Hunter dismisses a pet
    if  subEvent == "SPELL_CAST_SUCCESS" then
        local hunterSpell = string.sub(spell,1, 7)
        if hunterSpell == "DISMISS" then
            -- GET THE NAME OF THE HUNTER'S PET, THEN
            -- REMOVE IT.
            local huntersName = stats[SOURCENAME]
            local petName = grp:getPetByOwnerName( huntersName )
            grp:removeMember( petName )
            -- msg:postMsg( sprintf("%s %s's pet %s removed from party.\n", E:fileLocation( debugstack()), huntersName, petName ))
        end
    end

    if btn.threatIconStack then
        btn.threatIconStack:Hide()
    end
    btn.threatIconStack = btn:createIconStack(THREAT_GENERATED)
    btn.threatIconStack:Show()

    if btn.healsIconStack then
        btn.healsIconStack:Hide()
    end
    -- btn.healsIconStack = btn:createIconStack(HEALS_RECEIVED)
    -- btn.healsIconStack:Show()
    
    if btn.damageIconStack then
        btn.damageIconStack:Hide()
    end
    btn.damageIconStack = btn:createIconStack( DAMAGE_TAKEN )
    btn.damageIconStack:Show()

return
end
