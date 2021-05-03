--------------------------------------------------------------------------------------
-- FloatingText.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 11 December, 2021
local _, VisualThreat = ...
VisualThreat.FloatingText = {}
ftext = VisualThreat.FloatingText

local L = VisualThreat.L
local E = errors
local sprintf = _G.string.format

local SUCCESS 	= errors.STATUS_SUCCESS
local FAILURE 	= errors.STATUS_FAILURE
------------- FLOATING TEXT METHODS ----------------------

local SIG_NONE      = timer.SIG_NONE    -- default value. Means no signal is pending
local SIG_RETURN    = timer.SIG_RETURN  -- cleanup state and return from the action routine
local SIG_DIE       = timer.SIG_DIE     -- call threadDestroy()
local SIG_WAKEUP    = timer.SIG_WAKEUP  -- You've returned prematurely from a yield. Do what's appropriate.
local SIG_LAST      = timer.SIG_WAKEUP
local SIG_FIRST     = timer.SIG_FIRST

local IN_COMBAT = false

local NUM_FRAMES_IN_POOL = 10

local logEntryBuffer = {}
function ftext:setInCombat( isInCombat )
  IN_COMBAT = isInCombat
  if IN_COMBAT == false then
    mf:postMsg(sprintf("Clearing logEntryBuffer.\n"))
    logEntryBuffer = {}
  end
end

local writer_h = nil
function ftext:getWriterThread()
    return writer_h
end
function ftext:insertLogEntry( logEntry )
    table.insert( logEntryBuffer, logEntry )
    if writer_h == nil then
      return
    end
end
local function removeLogEntry()
  local logEntry = table.remove( logEntryBuffer, 1 )
  -- E:where("Log entries = " .. tostring( #logEntryBuffer ))
  return logEntry
end

local framePool = {}
local function createNewFrame()
  local f = CreateFrame( "Frame", nil, UIParent, "BackdropTemplate")
  f.Text1 = f:CreateFontString()
  -- f.Text1:SetFontObject( GameFontNormal)
  -- f.Text1:SetFontObject( GameFontNormalSmall )
  f.Text1:SetFontObject( GameFontNormalLarge )
  f.Text1:SetWidth( 600 )
  f.Text1:SetJustifyH("LEFT")
  f.Text1:SetJustifyV("TOP")
  f.Done = false
  f.TotalTicks = 0
  f.UpdateTicks = 2 -- Move the frame once every 2 ticks
  f.UpdateTickCount = f.UpdateTicks
  return f
end
local function initFramePool( numEntries )
    for i = 1, numEntries do
        local f = createNewFrame()
        table.insert( framePool, f )
    end
end
local function releaseFrame( f )
  table.insert( framePool, f )
end
local function acquireFrame()
    local f = table.remove( framePool )
    if f == nil then 
      f = createNewFrame() 
    end
    return f
end

initFramePool( NUM_FRAMES_IN_POOL )

local function writeLogEntry( logEntry )
    local ymove = 1.5 -- move this much each update
    local xmove = 0
    local xos = 400
    local yos = -200

    local f = acquireFrame()

    f:ClearAllPoints()
    f.Text1:SetPoint("CENTER", UIParent, xos, yos )
    f.Text1:SetText( logEntry )
    f:Show()
    f:SetScript("OnUpdate", 
  
          function(self, elapsed)
              self.UpdateTickCount = self.UpdateTickCount - 1
              if self.UpdateTickCount > 0 then
                return
              end
              self.UpdateTickCount = self.UpdateTicks
              self.TotalTicks = self.TotalTicks + 1
              
              if self.TotalTicks == 40 then f:SetAlpha( 0.8 ) end
              if self.TotalTicks == 50 then f:SetAlpha( 0.6 ) end
              if self.TotalTicks == 60 then f:SetAlpha( 0.4 ) end
              if self.TotalTicks == 70 then f:SetAlpha( 0.2 ) end
              if self.TotalTicks == 90 then f:SetAlpha( 0.1 ) end
              if self.TotalTicks >= 100 then 
                f:Hide()
                f.Done = true
              else
                yos = yos + ymove
                xos = xos + xmove
                f:ClearAllPoints()
                f.Text1:SetPoint("CENTER", UIParent, xos, yos ) -- reposition the text to its new location
              end

          end)
    if f.Done == true then
      releaseFrame(f)
    end
end
function ftext:publishLogEntry()
    local done = false
    
    while not done do
        if IN_COMBAT == true then
          local logEntry = removeLogEntry()
          if logEntry ~= nil then
            writeLogEntry( logEntry )
          end
        end
        thread:yield()
        signal = thread:getSignal()
        if signal == SIG_RETURN then
          done = true
        end
    end
    mf:postMsg( sprintf("writer_h received %s and terminated.\n", thread:getSignalName( signal )))
end

local function main()
    local result = {SUCCESS, nil, nil }

    -- create the writer_h thread
    local fps = (1/GetFramerate())
    -- mf:postMsg( sprintf("%0.3f frames/second. x300 = %0.3f seconds.\n ", fps, 300*fps ))
    local yieldInterval = (1/GetFramerate()) * 25 -- about 0.5 seconds
    writer_h, result = thread:create( yieldInterval, function() ftext:publishLogEntry() end )
    if result[1] ~= SUCCESS then
        mf:postResult( result )
        return
    end

    -- Now, we wait
    local done = false
    local signal = SIG_NONE
    while signal ~= SIG_RETURN do
        thread:yield()
        signal = thread:getSignal()
    end
    mf:postMsg( sprintf("main_h received %s and terminated.\n", thread:getSignalName( signal )))
end

local result = {SUCCESS, nil, nil}
local main_h, result = thread:create( 0.5, main )
if main_h == nil then
  mf:postResult( result )
  return
end

  
if E:isDebug() then
    local fileName = "FloatingText.lua"
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
