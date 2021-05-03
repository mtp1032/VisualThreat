--------------------------------------------------------------------------------------
-- EventDispatcher.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 15 December, 2020
-- REMARKS: This derived directly from the original code that appeared in the WoW UI 
--          forums written Gello
-- https://wow.gamepedia.com/API_Region_GetPoint
-- https://wow.gamepedia.com/API_Region_SetPoint 
-- Interruptable Spells:
--  https://us.forums.blizzard.com/en/wow/t/detect-interruptable-spells/866016

--------------------------------------------------------------------------------------
local _, VisualThreat = ...
VisualThreat.EventDispatcher = {}
evd = VisualThreat.EventDispatcher
local L = VisualThreat.L
local E = errors 
local sprintf = _G.string.format 

local STATUS_SUCCESS 	= errors.STATUS_SUCCESS
local STATUS_FAILURE 	= errors.STATUS_FAILURE

local VT_UNIT_NAME               = grp.VT_UNIT_NAME
local VT_UNIT_ID                 = grp.VT_UNIT_ID   
local VT_PET_OWNER               = grp.VT_PET_OWNER 
local VT_MOB_ID                  = grp.VT_MOB_ID                  
local VT_THREAT_VALUE            = grp.VT_THREAT_VALUE             

-- Accumulators
local VT_ACCUM_THREAT_VALUE      = grp.VT_ACCUM_THREAT_VALUE
local VT_ACCUM_DAMAGE_TAKEN      = grp.VT_ACCUM_DAMAGE_TAKEN
local VT_ACCUM_HEALING_RECEIVED  = grp.VT_ACCUM_HEALING_RECEIVED

local THREAT_GENERATED  = btn.THREAT_GENERATED
local HEALS_RECEIVED    = btn.HEALS_RECEIVED
local DAMAGE_TAKEN      = btn.DAMAGE_TAKEN

timer.SIG_LAST      = timer.SIG_WAKEUP
timer.SIG_FIRST     = timer.SIG_NONE

local SIG_NONE      = timer.SIG_NONE    -- default value. Means no signal is pending
local SIG_RETURN    = timer.SIG_RETURN  -- cleanup state and return from the action routine
local SIG_DIE       = timer.SIG_DIE     -- call threadDestroy()
local SIG_WAKEUP    = timer.SIG_WAKEUP  -- You've returned prematurely from a yield. Do what's appropriate.
local SIG_LAST      = timer.SIG_WAKEUP
local SIG_FIRST     = timer.SIG_FIRST

local ADDON_ENABLED = core.ADDON_ENABLED

-- local DEFAULT_STARTING_REGION   = ft.DEFAULT_STARTING_REGION
-- local DEFAULT_STARTING_XPOS     = ft.STARTING_XPOS
-- local DEFAULT_STARTING_YPOS     = ft.STARTING_YPOS

function evd:disableAddon()
    ADDON_ENABLED = false
    E:where( "Visual Threat is disabled")
end
function evd:enableAddon()
    ADDON_ENABLED = true
    E:where( "Visual Threat is enabled")
end
function evd:addonEnabled()
    return ADDON_ENABLED
end

local eventFrame = CreateFrame("Frame")
-- We never Unregister these events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")			-- arg1: boolean isInitialLogin, arg2: boolean isReloadingUI
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")


eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:RegisterEvent("GROUP_JOINED")
eventFrame:RegisterEvent("GROUP_LEFT")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
eventFrame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")

eventFrame:RegisterEvent("PET_DISMISS_START")

local function OnEvent( self, event, ...)

    if event ~= "COMBAT_LOG_EVENT_UNFILTERED" or
       event ~= "GROUP_JOINED" or
       event ~= "GROUP_LEFT" or
       event ~= "GROUP_ROSTER_UPDATE" or
       event ~= "UNIT_THREAT_SITUATION_UPDATE" or
       event ~= "UNIT_THREAT_LIST_UPDATE" or
       event ~= "UNIT_SPELLCAST_START" or
       event ~= "UNIT_SPELLCAST_INTERRUPTED" or
       event ~= "PET_DISMISS_START" then
        if not ADDON_ENABLED then
            return
        end
    end

	local arg1, arg2, arg3, arg4 = ...
    local r = {STATUS_SUCCESS, nil, nil}

    -------------------- UNIT_SPELLCAST_START ----------------
    if event == "UNIT_SPELLCAST_START" then
        local sourceId      = arg1          -- the Mob casting the spell

        local spellName, _, _, _, _, _, _, notInterruptible, spellId = UnitCastingInfo( sourceId )
        if notInterruptible == true then return end

        local sourceName = UnitName( sourceId )
        if grp:inPlayersParty( sourceName ) then return end

        local targetId = arg1.."target"
        local targetName = UnitName( targetId )

        local msg = nil
        if targetName == nil then
            msg = sprintf("%s preparing to cast %s.\n INTERRUPT NOW!\n", sourceName, spellName )
        else
            msg = sprintf("%s casting %s at %s.\n INTERRUPT NOW!\n", sourceName, spellName, targetName )
        end
        UIErrorsFrame:AddMessage(msg, 1.0, 0.25, 0.25, 1, 4 )
    end
    ---------------- UNIT_SPELLCAST_INTERRUPTED ----------
    if event == "UNIT_SPELLCAST_INTERRUPTED" then
        local unitTarget    = arg1
        local castGUID      = arg2
        local spellId       = tonumber( arg3 )
    end
    -------------------- PLAYER_REGEN_DISABLED ---------------
    if event == "PLAYER_REGEN_DISABLED" then
        ftext:setInCombat( true )
        mf:postMsg(sprintf("Entering Combat\n"))
    end    
    -------------------- PLAYER_REGEN_ENABLED ----------------
    if event == "PLAYER_REGEN_ENABLED" then
        mf:postMsg(sprintf("Leaving Combat\n"))
        ftext:setInCombat( false )
    end
    -------------------------- ADDON_LOADED ----------------
    if event == "ADDON_LOADED" and arg1 == "VisualThreat" then        -- The framePosition array has been loaded by this point

        if framePositionSaved == false  then
            framePosition = { "CENTER", nil, "CENTER", 0, 0 }
            framePositionSaved = true
        end

        if damageFramePositionSaved == false  then
            damageFramePosition = { "LEFT", nil, "LEFT", 300, 0 }
            damageFramePositionSaved = true
        end

        if healsFramePositionSaved == false  then
            healsFramePosition = { "RIGHT", nil, "RIGHT", -300, 0 }
            healsFramePositionSaved = true
        end

        DEFAULT_CHAT_FRAME:AddMessage( L["ADDON_LOADED_MESSAGE"], 1.0, 1.0, 0.0 )
        mgmt:initWoWThreads()
        return        
    end   
    ------------------------------ COMBAT LOG EVENT UNFILTERED -----------
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local stats = {CombatLogGetCurrentEventInfo()}
        ceh:handleEvent( stats )
        if btn.threatIconStack then
            btn.threatIconStack:Hide()
        end
        btn.threatIconStack =btn:createIconStack(THREAT_GENERATED)

        if btn.healsIconStack then
            btn.healsIconStack:Hide()
        end
        btn.healsIconStack = btn:createIconStack(HEALS_RECEIVED)
        
        if btn.damageIconStack then
            btn.damageIconStack:Hide()
        end
        btn.damageIconStack = btn:createIconStack( DAMAGE_TAKEN )

    end
    ------------------------------ PLAYER ENTERING WORLD -----------------
    if event == "PLAYER_ENTERING_WORLD" then
        -- return if blizz party does not yet exist
        local r = {STATUS_SUCCESS, nil, nil}
        local exists, partyCount = grp:blizzPartyExists()
        if not exists then
            return 
        end

        r = grp:initAddonParty()
        if r[1] == STATUS_FAILURE then
            msg:postResult( r )
            return
        end

        if btn.threatIconStack then
            btn.threatIconStack:Hide()
        end
        btn.threatIconStack =btn:createIconStack(THREAT_GENERATED)

        if btn.healsIconStack then
            btn.healsIconStack:Hide()
        end
        btn.healsIconStack = btn:createIconStack(HEALS_RECEIVED)
        
        if btn.damageIconStack then
            btn.damageIconStack:Hide()
        end
        btn.damageIconStack = btn:createIconStack( DAMAGE_TAKEN )
        return
    end
    --------------------------- GROUP LEFT ---------------------
    if event == "GROUP_LEFT" then
        btn.threatIconStack:Hide()
        btn.healsIconStack:Hide()
        btn.damageIconStack:Hide()
    end
    --------------------------- GROUP JOINED ---------------------
    if event == "GROUP_JOINED" then
        local r = {STATUS_SUCCESS, nil, nil}

        r = grp:initAddonParty()
        if r[1] ~= STATUS_SUCCESS then
            msg:postResult( r )
            return
        end
        if btn.threatIconStack then
            btn.threatIconStack:Hide()
        end
        btn.threatIconStack = btn:createIconStack(THREAT_GENERATED)
        btn.threatIconStack:Show()

        if btn.healsIconStack then
            btn.healsIconStack:Hide()
        end
        btn.healsIconStack = btn:createIconStack(HEALS_RECEIVED)
        btn.healsIconStack:Show()
        
        if btn.damageIconStack then
            btn.damageIconStack:Hide()
        end
        btn.damageIconStack = btn:createIconStack( DAMAGE_TAKEN )
        btn.damageIconStack:Show()
    end
    --------------------------- GROUP ROSTER UPDATE ---------------------
    if event == "GROUP_ROSTER_UPDATE" then
        local r = {STATUS_SUCCESS, nil, nil}

        local blizzPartyNames = GetHomePartyInfo()
        if blizzPartyNames == nil then
            return
        end
        r = grp:initAddonParty()
        if r[1] ~= STATUS_SUCCESS then
            msg:postResult( r )
            return
        end
        btn.threatIconStack:Hide()
        btn.threatIconStack = btn:createIconStack(THREAT_GENERATED)
        btn.threatIconStack:Show()

        btn.healsIconStack:Hide()
        btn.healsIconStack = btn:createIconStack( HEALS_RECEIVED )
        btn.healsIconStack:Show()

        btn.damageIconStack:Hide()
        btn.damageIconStack = btn:createIconStack( DAMAGE_TAKEN )
        btn.damageIconStack:Show()

        return
    end
    -------------------- PET DISMISS START -------------------
    if event == "PET_DISMISS_START" then
        local petName = UnitName("pet")
        local petOwner = grp:getOwnerByPetName( petName )
        grp:removeMember( petName )
        -- msg:postMsg( sprintf("%s %s's pet %s removed from party.\n", E:fileLocation( debugstack()), petOwner, petName ))

        btn.threatIconStack:Hide()
        btn.threatIconStack = btn:createIconStack(THREAT_GENERATED)
        btn.threatIconStack:Show()
        return
    end    
    ------------------------- PLAYER LOGIN -----------------
    if event == "PLAYER_LOGIN" and arg1 == "VisualThreat" then
        return
    end
    ------------------------- PLAYER LOGOUT -----------------
    if event == "PLAYER_LOGOUT" then
        return
    end    
    ---------------------- UNIT THREAT SITUATION UPDATE ---------------
    if event == "UNIT_THREAT_SITUATION_UPDATE" then

        if btn.threatIconStack == nil then
            btn.threatIconStack = btn:createIconStack(THREAT_GENERATED)
        end
        btn.threatIconStack:Hide()
        btn.threatIconStack = btn:createIconStack(THREAT_GENERATED)
        btn.threatIconStack:Show()
    end
    ---------------------- UNIT THREAT LIST UPDATE ---------------
    local writer_h = nil

    if event == "UNIT_THREAT_LIST_UPDATE" then
        -- arg1 can be "player", "target" or "namplateN"
        local exists, count = grp:blizzPartyExists()
        if not exists then 
            return 
        end
              
        local mobId = arg1

        -- arg1/mobId can be "player", "target" or "namplateN"
        if mobId == "player" then
            return
        end
        -- Sum the threat values as we loop through and update each party member's entry
        local partyMembers = grp:getAddonPartyTable()
        for _, entry in ipairs( partyMembers ) do
            local unitId = entry[VT_UNIT_ID]
            local memberName = UnitName( unitId )

            local isTanking, status, _, _, threatValue = UnitDetailedThreatSituation( unitId, mobId )
            if threatValue ~= nil then
                if threatValue > 0 then
                    grp:setThreatValues( memberName, threatValue )
                    local membersThreat, totalThreat = grp:getThreatStats(unitName)

                    if threatValue > 0 then
                        local logEntry = nil
                        local relative = (membersThreat/totalThreat)*100
                        if isTanking then
                            if relative > 0 then
                                logEntry = sprintf("%s (tanking) - %1.f%% of Total Threat: %d", memberName, relative, totalThreat )
                            else
                                logEntry = sprintf("%s (tanking) - Total Threat: %d", memberName, totalThreat )
                            end
                        else
                            if relative > 0 then
                                logEntry = sprintf("%s - %1.f%% of Total Threat: %d", memberName, relative, totalThreat )
                            else
                                logEntry = sprintf("%s - Total Threat: %d", memberName, totalThreat )
                            end
                        end
                        ftext:insertLogEntry( logEntry )
                    end
                end
            end
            if writer_h == nil then 
                writer_h = ftext:getWriterThread()
            end
            -- wow:threadSendSignal( writer_h, SIG_WAKEUP )
        end

        if btn.threatIconStack == nil then
            btn.threatIconStack = btn:createIconStack(THREAT_GENERATED)
        end
        btn.threatIconStack:Hide()
        btn.threatIconStack = btn:createIconStack(THREAT_GENERATED)
        btn.threatIconStack:Show()

        return
    end
end

eventFrame:SetScript("OnEvent", OnEvent ) 

if E:isDebug() then
    local fileName = "EventDispatcher.lua"
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
