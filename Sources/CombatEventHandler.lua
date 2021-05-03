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
local TIMESTAMP			= combatStats.TIMESTAMP
local SUBEVENT    		= combatStats.SUBEVENT
local HIDECASTER      	= combatStats.HIDECASTER
local SOURCEGUID      	= combatStats.SOURCEGUID
local SOURCENAME      	= combatStats.SOURCENAME
local SOURCEFLAGS     	= combatStats.SOURCEFLAGS
local SOURCERAIDFLAGS 	= combatStats.SOURCERAIDFLAGS
local TARGETGUID      	= combatStats.TARGETGUID
local TARGETNAME      	= combatStats.TARGETNAME
local TARGETFLAGS     	= combatStats.TARGETFLAGS
local TARGETRAIDFLAGS 	= combatStats.TARGETRAIDFLAGS

local SPELL_NAME            = combatStats.SPELL_NAME
local SPELL_SCHOOL          = combatStats.SPELL_SCHOOL
local AMOUNT_SWING_DAMAGED   = combatStats.AMOUNT_SWING_DAMAGED
local AMOUNT_SPELL_DAMAGED   = combatStats.AMOUNT_SPELL_DAMAGED
local AMOUNT_HEALED         = combatStats.AMOUNT_HEALED
local IS_CRIT_HEAL          = combatStats.IS_CRIT_HEAL
local IS_CRIT_RANGE         = combatStats.IS_CRIT_RANGE
local IS_CRIT_DAMAGE        = combatStats.IS_CRIT_DAMAGE

ceh.IN_COMBAT = true

local THREAT_GENERATED      = btn.THREAT_GENERATED
local HEALS_RECEIVED        = btn.HEALS_RECEIVED
local DAMAGE_TAKEN          = btn.DAMAGE_TAKEN

function ceh:handleEvent( stats )
    
    local targetName = stats[TARGETNAME]
    local sourceName = stats[SOURCENAME]
    local subEvent = stats[SUBEVENT]
    local r = {STATUS_SUCCESS, nil, nil }

    -- this filters out all combat events EXCEPT those
    -- in which the target OR source is one of the party members.
    -- if grp:inPlayersParty( sourceName ) ~= true and
    --    grp:inPlayersParty( targetName ) ~= true then
    --     return
    -- end

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
    local spellName = stats[SPELL_NAME]
    if subEvent == "SPELL_CAST_START" then
        -- if the target is a group member, then s/he's been targeted
        -- by the caster.
        -- if grp:inPlayersParty( targetName ) then
        --     local targetUnitId = grp:getUnitIdByName( targetName )

        --     local spell, _, _, _, _, _, _, notInterruptible = UnitCastingInfo( targetUnitId )

        --     if notInterruptible == false then
        --         local s = sprintf("%s cast by %s is interruptible. Interrupt Now!", stats[13], sourceName )
        --         msg:postMsg( s )
        --     end
        -- end
    end
    ------------- HEALING RECEIVED --------------------
    if  subEvent == "SPELL_HEAL" or subEvent == "SPELL_PERIODIC_HEAL" then

        ------------- Healing Received ---------------
        if grp:inPlayersParty( targetName ) then
            local healingReceived = stats[AMOUNT_HEALED]
            if healingReceived > 0 then
                grp:setHealingReceived( targetName, healingReceived )
                local healingReceivedStr = sprintf("%s healed for %d.", targetName, healingReceived )
                ftext:insertLogEntry( healingReceivedStr )
            end
        end

        local healsString = nil
        if stats[IS_CRIT_DAMAGE] then
            healsString = sprintf("%s's %s CRITICALLY healed %s for %d.", sourceName, spellName, targetName, stats[15] )
        else
            healsString = sprintf("%s's %s healed %s for %d.", sourceName, spellName, targetName, stats[15] )
        end

        ------------- Healing Done ----------------
        if stats[AMOUNT_HEALED] == nil then
            stats[AMOUNT_HEALED] = 0
        end
        local spellSchool = stats[SPELL_SCHOOL]
        combatStats:insertHealingRecord( sourceName, stats[SPELL_NAME], stats[AMOUNT_SPELL_DAMAGED], stats[IS_CRIT_DAMAGE], spellSchool )
        return
    end

    -------------- DAMAGE TAKEN AND DAMAGE DONE ---------------
    if  subEvent ~= "SWING_DAMAGE" and
        subEvent ~= "SPELL_DAMAGE" and
        subEvent ~= "SPELL_PERIODIC_DAMAGE" and
        subEvent ~= "RANGE_DAMAGE" then
            return
    end
        
    local spellName     = stats[SPELL_NAME]
    local spellSchool   = stats[SPELL_SCHOOL]
        
    if subEvent == "SWING_DAMAGE" then
        damage      = stats[AMOUNT_SWING_DAMAGED]
        spellName   = "melee attack"
    end
    if damage == nil then damage = 0 end
    ---------- Damage Taken ----------------
    if damage > 0 then
        if grp:inPlayersParty( targetName ) then
            grp:setDamageTaken( targetName, damage )
            local dmgTakenStr = sprintf("%s hit %s for %d damage.", sourceName, targetName, damage )
            ftext:insertLogEntry( dmgTakenStr )
        end
        ----------- Damage Done -----------------
            
        local dmgStr = nil
        if stats[IS_CRIT_DAMAGE] then
            dmgString = sprintf("%s's %s(%s) CRITICALLY hit %s for %d damage.", "foobar", spellName, spellSchool,targetName, damage )
        else
            dmgString = sprintf("%s's %s(%s) hit %s for %d damage.", "foobar", spellName, spellSchool,targetName, damage )
        end
        combatStats:insertDamageRecord( sourceName, spellName, spellSchool, targetName, damage )
        return
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
    
    if btn.damageIconStack then
        btn.damageIconStack:Hide()
    end
    btn.damageIconStack = btn:createIconStack( DAMAGE_TAKEN )
    btn.damageIconStack:Show()

return
end
