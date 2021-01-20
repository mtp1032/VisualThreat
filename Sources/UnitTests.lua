--------------------------------------------------------------------------------------
-- UnitTests.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 11 December, 2021
local _, VisualThreat = ...
VisualThreat.UnitTests = {}
tests = VisualThreat.UnitTests

local L = VisualThreat.L
local E = errors
local sprintf = _G.string.format

local STATUS_SUCCESS    = E.STATUS_SUCCESS
local STATUS_FAILURE    = E.STATUS_FAILURE
local SUCCESS           = E.SUCCESS

local VT_UNIT_NAME               = grp.VT_UNIT_NAME
local VT_UNIT_ID                 = grp.VT_UNIT_ID   
local VT_PET_OWNER               = grp.VT_PET_OWNER 
local VT_MOB_ID                  = grp.VT_MOB_ID                  
local VT_AGGRO_STATUS            = grp.VT_AGGRO_STATUS              
local VT_THREAT_VALUE            = grp.VT_THREAT_VALUE             
local VT_THREAT_VALUE_RATIO      = grp.VT_THREAT_VALUE_RATIO
local VT_DAMAGE_TAKEN            = grp.VT_DAMAGE_TAKEN
local VT_HEALING_RECEIVED           = grp.VT_HEALING_RECEIVED
local VT_BUTTON                  = grp.VT_BUTTON
local VT_NUM_ELEMENTS            = grp.VT_BUTTON

local playersParty = grp.playersParty
local initPlayersParty = grp.initPlayersParty

local function testOne( s )
    local result = {STATUS_SUCCESS, nil, nil }
    if s == nil then
        result = E:setResult(L["ARG_NIL"], debugstack() )
    end
    return result
end 
 ------------ GROUP EVENT HANDLER TESTS -----------------
local function printEntryName( nvp )
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

SLASH_GROUP_TESTS1 = "/grp"
SlashCmdList["GROUP_TESTS"] = function( num )
    ------ TEST INITIALIZATION -----------
    playersParty, r = initPlayersParty()
    if playersParty == nil or r[1] == STATUS_FAILURE then
        local s = sprintf("[FAILED: initPlayerParty()] %s\n%s\n\n",r[2], r[3])
        msg:post(s)
        return
    end
    for _, v in ipairs( playersParty ) do
        printEntryName(v)
    end

    msg:post( sprintf("\n\n"))

    ------- TEST UNITID FROM NAME ---------
    playersParty = {}
    playersParty, r = initPlayersParty()
    if playersParty == nil or r[1] == STATUS_FAILURE then
        local s = sprintf("[FAILED: initPlayerParty()] %s\n%s\n\n",r[2], r[3])
        msg:post(s)
        return
    end

    for _, v in ipairs( playersParty ) do
        local partyName = v[VT_UNIT_NAME]
        local unitId = grp:getUnitIdByName( partyName )
        local s = sprintf("%s : %s\n", partyName, unitId )
        msg:post(s)
    end
    -----TEST GET OWNER ---------
    return
end

 --------------------- CORE TESTS -----------------
 SLASH_CORE_TESTS1 = "/core1"
 SlashCmdList["CORE_TESTS"] = function( num )
    local addonName = core:getAddonName()               -- string
    core:printMsg( L["ADDON_AND_VERSION"] )

    local releaseVersion = core:getReleaseVersion()     -- string
    local buildNumber = core:getBuildNumber()           -- string
    local buildDate = core:getBuildDate()               -- string
    local tocVersion = core:getTocVersion()             -- number
    local s = sprintf("\n")
    s = s..sprintf("Release Version: %s\n", releaseVersion )
    s = s..sprintf("Build Number: %s\n", buildNumber )
    s = s..sprintf("Build Date: %s\n", buildDate)
    s = s..sprintf("TOC Version: %d\n", tocVersion )
    core:printMsg( s )
    return
end
-------------- ERROR HANDLING TESTS ----------------------
SLASH_ERROR_TESTS1 = "/test1"
SlashCmdList["ERROR_TESTS"] = function( num )
    local s = nil
    local r = testOne (s)
    if r[1] ~= STATUS_SUCCESS then
        E:postResult( r )
    end

    s = "Hello"
    r = testOne (s)
    if r[1] ~= STATUS_SUCCESS then
        E:postResult( r )
    else
        core:printMsg( "testOne successful" )
    end
end

-------------- COMBAT EVENT HANDLER TESTS -----------------
local VT_UNIT_NAME               = grp.VT_UNIT_NAME
local VT_UNIT_ID                 = grp.VT_UNIT_ID   
local VT_PET_OWNER               = grp.VT_PET_OWNER 
local VT_MOB_ID                  = grp.VT_MOB_ID                  
local VT_AGGRO_STATUS            = grp.VT_AGGRO_STATUS              
local VT_THREAT_VALUE            = grp.VT_THREAT_VALUE             
local VT_THREAT_VALUE_RATIO      = grp.VT_THREAT_VALUE_RATIO
local VT_DAMAGE_TAKEN            = grp.VT_DAMAGE_TAKEN
local VT_HEALING_RECEIVED           = grp.VT_HEALING_RECEIVED
local VT_BUTTON                  = grp.VT_BUTTON
local VT_NUM_ELEMENTS            = grp.VT_BUTTON 

local entries = {}
entries[1] = {"MIKE",         "player", nil, 4 }
entries[2] = {"BOB",          "party1", nil, 4 }
entries[3] = {"STEVE",        "party2", nil, 4 }
entries[4] = {"ANN",          "party3", nil, 4 }
entries[5] = {"JILL",         "party4", nil, 4 }
entries[6] = {"PET OF MIKE",   "partypet1", "MIKE", 4 }
entries[7] = {"PET OF JILL",   "partypet2", "JILL", 4 }

SLASH_COMBAT_TESTS1 = "/ch1"
SlashCmdList["COMBAT_TESTS"] = function( num )

end
---------------------- BUTTON TESTS -----------------------

 SLASH_BUTTON_TESTS1 = "/btn"
 SlashCmdList["BUTTON_TESTS"] = function( num )

    local playersParty, r = grp:initPlayersParty()
    if playersParty == nil or r[1] == STATUS_FAILURE then
        local s = sprintf("[FAILED: initPlayerParty()] %s\n%s\n\n",r[2], r[3])
        msg:post(s)
        return
    end
    btn.threatIconFrame = btn:createIconFrame()
    btn:updatePortraitButtons( btn.threatIconFrame )

return
 end
--[[  /run print("this is \124cFFFF0000red and \124cFF00FF00this is green\124r back to white")
 > this is red and this is green back to white
 ]] 

 local red = "\124cFFFF0000"
 local green = "\124cFF00FF00"
 SLASH_COLOR_TESTS1 = "/color"
 SlashCmdList["COLOR_TESTS"] = function( arg )
    print( red.."red"..", "..green.."green")

 end
