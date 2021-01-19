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

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")			-- arg1: boolean isInitialLogin, arg2: boolean isReloadingUI
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("GROUP_JOINED")
eventFrame:RegisterEvent("GROUP_LEFT")
eventFrame:RegisterEvent("PET_DISMISS_START")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE") 		-- unitTarget
eventFrame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")				-- unitTarget

eventFrame:SetScript("OnEvent", 
function( self, event, ... )
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

        if not grp:isPartyMember( stats[9] ) then
            return
        end
        -- is the unit in the blizzard party? 
        -- OK, dispatch the event to its handler
        ceh:handleEvent( stats )
        return
    end
    ------------------------------ PLAYER ENTERING WORLD -----------------
    if event == "PLAYER_ENTERING_WORLD" then

        grp.playersParty, r = grp:initPlayersParty()
        if grp.playersParty == "" then
            grp.playersParty = nil
            return
        end

        if btn.threatIconFrame == nil then
            btn.threatIconFrame = btn:createIconFrame()
        end
        btn:updatePortraitButtons()
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
    --------------------------- GROUP ROSTER UPDATE ---------------------
    if event == "GROUP_ROSTER_UPDATE" then

        grp.playersParty, r = grp:initPlayersParty()
        if grp.playersParty == "" then
            grp.playersParty = nil
            return
        end
        btn.threatIconFrame = btn:createIconFrame()
        btn:updatePortraitButtons()
        return
    end
    --------------------------- GROUP JOINED ---------------------
    if event == "GROUP_JOINED" then
        grp.playersParty, r = grp:initPlayersParty()
        if grp.playersParty == "" then
            grp.playersParty = nil
            return
        end
      btn:updatePortraitButtons( btn.threatIconFrame )
      return
    end
    --------------------------- GROUP LEFT ---------------------
    if event == "GROUP_LEFT" then
        grp.playersParty, r = grp:initPlayersParty()
        if grp.playersParty == "" then
            grp.playersParty = nil
            return
        end
      if btn.threatIconFrame == nil then
        btn.threatIconFrame = btn:createIconFrame()
      end
      btn:updatePortraitButtons()
    return
    end
    --------------------------- PET DISMISS START ---------------------
    if event == "PET_DISMISS_START" then
        grp.playersParty, r = grp:initPlayersParty()
        if grp.playersParty == "" then
            grp.playersParty = nil
            return
        end
      if btn.threatIconFrame == nil then
        btn.threatIconFrame = btn:createIconFrame()
      end
      btn:updatePortraitButtons()
      return
    end
    ---------------------- UNIT THREAT SITUATION UPDATE ---------------
    if event == "UNIT_THREAT_SITUATION_UPDATE" then
        tev:updateThreatStatus( arg1 )
        btn:updatePortraitButtons()
    end
    ---------------------- UNIT THREAT LIST UPDATE ---------------
    if event == "UNIT_THREAT_LIST_UPDATE" then
        tev:updateThreatStatus( arg1 )
        btn:updatePortraitButtons()
	end
end)


