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
local VT_THREAT_VALUE            = grp.VT_THREAT_VALUE             
local VT_THREAT_VALUE_RATIO      = grp.VT_THREAT_VALUE_RATIO
local VT_DAMAGE_TAKEN            = grp.VT_DAMAGE_TAKEN
local VT_HEALING_RECEIVED        = grp.VT_HEALING_RECEIVED

-- Accumulators
local VT_ACCUM_THREAT_VALUE      = grp.VT_ACCUM_THREAT_VALUE
local VT_ACCUM_DAMAGE_TAKEN      = grp.VT_ACCUM_DAMAGE_TAKEN
local VT_ACCUM_HEALING_RECEIVED     = grp.VT_ACCUM_HEALING_RECEIVED
local VT_BUTTON                  = grp.VT_BUTTON
local VT_NUM_ELEMENTS            = grp.VT_BUTTON

grp.playersParty = {}
local function testOne( s )
    local result = {STATUS_SUCCESS, nil, nil }
    if s == nil then
        local st = debugstack()
        result = E:setResult(L["ARG_NIL"], st )
    end
    return result
end 
 ------------ GROUP EVENT HANDLER TESTS -----------------
local function printEntryName( nvp )
    if nvp[VT_PET_OWNER] ~= nil then
        msg:postMsg( sprintf("Unit Name = %s, UnitId = %s, Owner's Name = %s\n", 
                                        nvp[VT_UNIT_NAME], 
                                        nvp[VT_UNIT_ID], 
                                        nvp[VT_PET_OWNER]))
    else
        msg:postMsg( sprintf("Unit Name = %s, unitId = %s\n",  
                                        nvp[VT_UNIT_NAME], 
                                        nvp[VT_UNIT_ID] ))
    end
end

SLASH_GROUP_TESTS1 = "/grp"
SlashCmdList["GROUP_TESTS"] = function( num )
    ------ TEST INITIALIZATION -----------
    local r = {STATUS_SUCCESS, nil, nil}

    r = grp:initPlayersParty()
    if r[1] == STATUS_FAILURE then
        msg:postResult( r )
        return
    end 
    local s = sprintf("*** PASSED INITIALIZATION TESTS ***\n\n")
    msg:postMsg(s)

    --- TEST GROUP/PARTY FUNCTIONS

    -- TEST 1: Does GetHomePartyInfo() return all 
    --         members of the party (pets excepting)

    local blizzPartyNames = grp:getBlizzPartyNames()
    if blizzPartyNames == nil then
        local stackTrace = debugstack()
        r = E:setResult("Blizzard party does not yet exist.\n", stackTrace )
        msg:postResult( r )
        return
    end
    local name = sprintf("Blizz member Count %d: %s", #blizzPartyNames, blizzPartyNames[1])
    for i = 2, #blizzPartyNames do        
        name = name..sprintf(", %s", blizzPartyNames[i])        
    end
    name = name..sprintf("\n")
    msg:postMsg( name )

    local addonPartyNames = grp:getAddonPartyNames()
    -- + 1 added for "player"
    local name = sprintf("Addon Member Count %d: %s", #addonPartyNames + 1, addonPartyNames[1])
    for i = 2, #addonPartyNames do        
        name = name..sprintf(", %s", addonPartyNames[i])        
    end
    name = name..sprintf("\n")
    msg:postMsg( name )



    return
end
 --------------------- CORE TESTS -----------------
 SLASH_CORE_TESTS1 = "/core1"
 SlashCmdList["CORE_TESTS"] = function( num )
    local addonName = core:getAddonName()               -- string
    core:printMsg( L["ADDON_LOADED_MESSAGE"] )

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
        core:printChatMsg( "testOne successful" )
    end
end
---------------------- BUTTON AND FRAME TESTS -----------------------
local function bottom()
    local st = debugstack()
    local str = sprintf("%s: %s", L["ARG_NIL"], "unitName" )
    return E:setResult( str, st )
end
local function top()
    local result = bottom()
    return result
end
SLASH_BUTTON_TESTS1 = "/btn"
SlashCmdList["BUTTON_TESTS"] = function( num )
    btn:updatePortraitButtons( btn.threatIconStack )
    return
 end
-- CREATE A DRAGABLE FRAME
local function createFrame()
    local frame = CreateFrame("Frame", "DragFrame2", UIParent)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- The code below makes the frame visible, and is not necessary to enable dragging.
    frame:SetPoint("CENTER")
    frame:SetSize(64, 64)
    local tex = frame:CreateTexture("ARTWORK")
    tex:SetAllPoints()
    tex:SetColorTexture(1.0, 0.5, 0, 0.5)
    return frame
end

-- [[  /run print("this is \124cFFFF0000red and \124cFF00FF00this is green\124r back to white")
--  > this is red and this is green back to white
--  ]] 

--  local red = "\124cFFFF0000"
--  local green = "\124cFF00FF00"
--  SLASH_COLOR_TESTS1 = "/color"
--  SlashCmdList["COLOR_TESTS"] = function( arg )
--     print( red.."red"..", "..green.."green")

