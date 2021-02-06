--------------------------------------------------------------------------------------
-- EventDispatcher.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 15 December, 2020
-- REMARKS: This derived directly from the original code that appeared in the WoW UI 
--          forums written Gello
-- https://wow.gamepedia.com/API_Region_GetPoint
-- https://wow.gamepedia.com/API_Region_SetPoint 

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
local VT_THREAT_VALUE_RATIO      = grp.VT_THREAT_VALUE_RATIO

-- Accumulators
local VT_ACCUM_THREAT_VALUE      = grp.VT_ACCUM_THREAT_VALUE
local VT_ACCUM_DAMAGE_TAKEN      = grp.VT_ACCUM_DAMAGE_TAKEN
local VT_ACCUM_DAMAGE_DONE       = grp.VT_ACCUM_DAMAGE_DONE
local VT_ACCUM_HEALING_RECEIVED  = grp.VT_ACCUM_HEALING_RECEIVED
local VT_BUTTON                  = grp.VT_BUTTON

local eventFrame = CreateFrame("Frame")
-- We never Unregister these events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")			-- arg1: boolean isInitialLogin, arg2: boolean isReloadingUI
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
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
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local function OnEvent( self, event, ...)

	local arg1, arg2, arg3, arg4 = ...
    local r = {STATUS_SUCCESS, nil, nil}

    -------------------- PLAYER_REGEN_ENABLED ----------------
    if event == "PLAYER_REGEN_ENABLED" then
        ceh.IN_COMBAT = false
        msg:postMsg(sprintf("\n*** Combat Ended ***\n"))

        -- msg:postMsg(sprintf("\nENCOUNTER SUMMARY\n"))
        -- local addonParty = grp:getAddonPartyTable()
        -- for _, v in ipairs( addonParty ) do
        --     local str = mt:memberStats( v[VT_UNIT_NAME])
        --     msg:postMsg( str )
        -- end
        -- msg:postMsg("\n\n")
    end
    -------------------- PLAYER_REGENN_DISABLED ---------------
    if event == "PLAYER_REGEN_DISABLED" then
        ceh.IN_COMBAT = true
        grp:resetCombatStats()
    end
    -------------------------- ADDON_LOADED ----------------
    if event == "ADDON_LOADED" and arg1 == "VisualThreat" then        -- The framePosition array has been loaded by this point

        if framePositionSaved == false  then
            framePosition = { "CENTER", nil, "CENTER", 0, 0 }
            framePositionSaved = true
        end
        DEFAULT_CHAT_FRAME:AddMessage( L["ADDON_LOADED_MESSAGE"], 1.0, 1.0, 0.0 )
        return        
    end   
    ------------------------------ COMBAT LOG EVENT UNFILTERED -----------
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if IN_COMBAT == false then
            return
        end
        local stats = {CombatLogGetCurrentEventInfo()}

        ceh:handleEvent( stats )
        return
    end
    ------------------------------ PLAYER ENTERING WORLD -----------------
    if event == "PLAYER_ENTERING_WORLD" then
        -- discontinue processing if no blizz party exists.
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
            E:where()
            btn.threatIconStack:Hide()
        end
        btn.threatIconStack = btn:createIconStack()
        -- btn.updatePortraitButtons()

        return
    end
    --------------------------- GROUP LEFT ---------------------
    if event == "GROUP_LEFT" then
        btn.threatIconStack:Hide()
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
        btn.threatIconStack = btn:createIconStack()
        -- btn.updatePortraitButtons()
        btn.threatIconStack:Show()
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
        btn.threatIconStack = btn:createIconStack()
        btn.threatIconStack:Show()
        return
    end
    -------------------- PET DISMISS START -------------------
    if event == "PET_DISMISS_START" then
        local petName = UnitName("pet")
        local petOwner = grp:getOwnerByPetName( petName )
        grp:removeMember( petName )
        -- msg:postMsg( sprintf("%s %s's pet %s removed from party.\n", E:fileLocation( debugstack()), petOwner, petName ))

        btn.threatIconStack:Hide()
        btn.threatIconStack = btn:createIconStack()
        -- btn.updatePortraitButtons()
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
        local targetId = "target"

        local groupCount = grp:getTotalMemberCount()
        if groupCount == 0 then return end

        local isTanking, status, _, _, threatValue = UnitDetailedThreatSituation( arg1, targetId )
    
        if btn.threatIconStack == nil then
            btn.threatIconStack = btn:createIconStack()
        end
        btn.threatIconStack:Hide()
        btn.threatIconStack = btn:createIconStack()
        btn.threatIconStack:Show()
    end
    ---------------------- UNIT THREAT LIST UPDATE ---------------
    if event == "UNIT_THREAT_LIST_UPDATE" then
        local exists, count = grp:blizzPartyExists()
        if not exists then return end
        
        tev:updateThreatStatus( arg1 )

        return
    end
end

eventFrame:SetScript("OnEvent", OnEvent ) 