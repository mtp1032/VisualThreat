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
local VT_AGGRO_STATUS            = grp.VT_AGGRO_STATUS              
local VT_THREAT_VALUE            = grp.VT_THREAT_VALUE             
local VT_THREAT_VALUE_RATIO      = grp.VT_THREAT_VALUE_RATIO
local VT_DAMAGE_TAKEN            = grp.VT_DAMAGE_TAKEN
local VT_HEALING_RECEIVED        = grp.VT_HEALING_RECEIVED
local VT_PLAYER_FRAME            = grp.VT_PLAYER_FRAME
local VT_BUTTON                  = grp.VT_BUTTON 
local VT_NUM_ELEMENTS            = grp.VT_BUTTON

local function blizzPartyExists()
    local partyExists = false
    local count = 0

    -- if no party exists then return false
    local blizzNames = GetHomePartyInfo()
    if blizzNames ~= nil then
        partyExists = true
        count = #blizzNames
    end
    return partyExists, count
end

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
eventFrame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
eventFrame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
eventFrame:RegisterEvent("PET_DISMISS_START")
-- eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local function OnEvent( self, event, ...)

	local arg1, arg2, arg3, arg4 = ...
    local r = {STATUS_SUCCESS, nil, nil}

    -------------------------- ADDON_LOADED ----------------
    if event == "ADDON_LOADED" and arg1 == "VisualThreat" then        -- The framePosition array has been loaded by this point
        if framePositionSaved == false  then
            framePosition = { "CENTER", nil, "CENTER", 0, 0 }
            framePositionSaved = true
        end
        return        
    end   
    ------------------------------ COMBAT LOG EVENT UNFILTERED -----------
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local stats = {CombatLogGetCurrentEventInfo()}

        ceh:handleEvent( stats )
        return
    end
    ------------------------------ PLAYER ENTERING WORLD -----------------
    if event == "PLAYER_ENTERING_WORLD" then
        -- E:where("DEBUG:"..UnitName("player").."-"..event )

        -- discontinue processing if no blizz party exists.
        -- NOTE: if a party does exist the player's name is not
        -- returned in the table of names.
        -- local partyNames = GetHomePartyInfo()
        -- partyNames{} will not contain UnitName("player")
        local exists, partyCount = blizzPartyExists()
        if blizzPartyExists() == false then
            -- E:where("DEBUG LOG: No Home Party exists. Returning.")
            return 
        end

        r = grp:initPlayersParty()
        if r[1] == STATUS_FAILURE then
            E:where( r[2])
            msg:post( sprintf("%s\n%s\n", r[2], r[3]))
            return
        end
        local success, r = grp:congruencyCheck()
        if not success then
            msg:post( sprintf("%s\n%s\n", r[2], r[3]))
            return
        end
        
        if btn.threatIconStack == nil then
            btn.threatIconStack = btn:createIconStack()
        end
        return
    end
    --------------------------- GROUP LEFT ---------------------
    if event == "GROUP_LEFT" then
        msg:post( "DEBUG: "..UnitName("player").."-"..event )
        if not blizzPartyExists() then
            grp:hidePlayerFrame()
            return
        end

        r = grp:initPlayersParty()
        if r[1] ~= STATUS_SUCCESS then
            msg:post( sprintf("%s\n\n%s\n", r[2], r[3]))
            return
        end
        local success, r = grp:congruencyCheck()
        if not success then
            msg:post( sprintf("%s\n%s\n", r[2], r[3]))
            return
        end
    end
    --------------------------- GROUP JOINED ---------------------
    if event == "GROUP_JOINED" then

        local r = {STATUS_SUCCESS, nil, nil }
        r = grp:initPlayersParty()
        if r[1] ~= STATUS_SUCCESS then
            msg:post( sprintf("%s\n\n%s\n", r[2], r[3]))
            return
        end

        local success, r = grp:congruencyCheck()
        if not success then
            msg:post( sprintf("%s\n%s\n", r[2], r[3]))
            return
        end

        if btn.threatIconStack == nil then
            btn.threatIconStack = btn:createIconStack()
        end
    end
    --------------------------- GROUP ROSTER UPDATE ---------------------
    if event == "GROUP_ROSTER_UPDATE" then
        -- E:where( "DEBUG: "..UnitName("player").."-"..event )
        -- At this point the players have just processed GROUP_JOINED or
        -- GROUP_LEFT. They are already members of both player and Blizz
        -- parties.
        --
        -- The code in this handler makes sure everything is put together
        -- properly. Especially that the playersParty and the blizzParty 
        -- members are exactly the same.

        r = grp:initPlayersParty()
        if r[1] ~= STATUS_SUCCESS then
            msg:post( sprintf("%s\n\n%s\n", r[2], r[3]))
            return
        end
        local success, r = grp:congruencyCheck()
        if not success then
            msg:post( sprintf("%s\n%s\n", r[2], r[3]))
            return
        end
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
    --------------------------- PET DISMISS START ---------------------
    if event == "PET_DISMISS_START" then
      return
    end
    ---------------------- UNIT THREAT SITUATION UPDATE ---------------
    if event == "UNIT_THREAT_SITUATION_UPDATE" then
        -- tev:updateThreatStatus( arg1 )
    end
    ---------------------- UNIT THREAT LIST UPDATE ---------------
    if event == "UNIT_THREAT_LIST_UPDATE" then
        if not blizzPartyExists() then return end
        tev:updateThreatStatus( arg1 )
    end
end


eventFrame:SetScript("OnEvent", OnEvent ) 