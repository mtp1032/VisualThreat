--------------------------------------------------------------------------------------
-- Core.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 9 October, 2019
local _, VisualThreat = ...
VisualThreat.Core = {}
core = VisualThreat.Core

local E = errors
local L = VisualThreat.L
local sprintf = _G.string.format

-----------------------------------------------------------------------------------------------------------
--                      The infoTable
-----------------------------------------------------------------------------------------------------------

--                      Indices into the infoTable table
local INTERFACE_VERSION = 1	-- string
local BUILD_NUMBER 		= 2		-- string
local BUILD_DATE 		= 3		-- string
local TOC_VERSION		= 4		-- number
local ADDON_NAME 		= 5		-- string

local infoTable = {}

--****************************************************************************************
--                      Game/Build/AddOn Info (from Blizzard's GetBuildInfo())
--****************************************************************************************
local infoTable = { GetBuildInfo() }

function core:getAddonName()
	return infoTable[ADDON_NAME]
end
function core:getReleaseVersion()
    return infoTable[INTERFACE_VERSION]
end
function core:getBuildNumber()
    return infoTable[BUILD_NUMBER]
end
function core:getBuildDate()
    return infoTable[BUILD_DATE]
end
function core:getTocVersion()
    return infoTable[TOC_VERSION]	-- e.g., 90002
end
function core:printMsg( msg )
	DEFAULT_CHAT_FRAME:AddMessage( msg, 1.0, 1.0, 0.0 )
end

framePositionSaved = false
