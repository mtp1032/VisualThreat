--------------------------------------------------------------------------------------
-- PrototypeTimers.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 11 December, 2021
local _, VisualThreat = ...
VisualThreat.PrototypeTimers = {}
timers = VisualThreat.PrototypeTimers

local L = VisualThreat.L
local E = errors
local sprintf = _G.string.format

local function round2Nearest( num )
    local lowerInt = math.floor( num )
    local diff = num - lowerInt
    if diff > 0.5 then
        return math.ceil( num )
    end
    return lowerInt
end
------------------------------ MANAGEMENT AND TESTING SERVICES -----------------------------
-- local function repeatingTimer()
--     if maxCount == 4 then
--         print("Done")
--         return
--     end
--     print( GetTime() )
--     C_Timer.After(1, repeatingTimer )
--     maxCount = maxCount + 1
-- end

local _DEFAULT_TICK_INTERVAL     = 0.2
local _TERMINATE_THREAD         = false
local tickCount                 = 0
local _SUSPEND                  = false
local timerThread               = nil

local function ticker( tickerInterval )

    if _TERMINATE_THREAD then 
        print( sprintf("Timer terminated after %d ticks", tickCount))
        return 
    end

    -- This code is executed at the end of every tick interval
    print( sprintf("[%d] ", tickCount+1)..tostring( GetTime()))

    C_Timer.After( tickerInterval, 
        function()
            ticker( tickerInterval ) 
        end)
    tickCount = tickCount + 1
end
-- local function createTimer( tickerInterval  )
--     if tickerInterval == nil then
--         tickerInterval = _DEFAULT_TICK_INTERVAL
--     end

--     local timerThread = coroutine.create( function() 
--         if ( tickCount ) > 5 then
--             coroutine.yield( tickCount )
--         end        
--         ticker( tickerInterval ) 
--     end)
--     coroutine.resume( timerThread )
--     return timerThread
-- end

local function suspendTimer()
    _TERMINATE_THREAD = true
end
local function restartTimer()
    _SUSPEND = false
    coroutine.resume( timerThread )
end

SLASH_TICKER_TESTS1 = "/run"
SlashCmdList["TICKER_TESTS"] = function( num )
    local tickerInterval = _DEFAULT_TICK_INTERVAL
    timerThread = createTimer( tickerInterval )
end

SLASH_CONTROL_TESTS1 = "/stop"
SlashCmdList["CONTROL_TESTS"] = function( num )
    suspendTimer()
end
SLASH_EXP1_TESTS1 = "/wait"
SlashCmdList["EXP1_TESTS"] = function( num )
    local seconds = 3.0
    local thd = coroutine.create( function() 
        while _SUSPEND == false do
            wait( seconds ) 
        end
    end)
    coroutine.resume( thd )
end
local function wait( seconds )
    C_Timer.After( seconds, function() print("Hello World!") end )
    C_Timer.After( seconds + 1, function() print("Hello World!") end )
    C_Timer.After( seconds + 2, function() print("Hello World!") end )
    C_Timer.After( seconds + 3, function() print("Hello World!") end )
end

SLASH_EXP2_TESTS1 = "/y2"
SlashCmdList["EXP2_TESTS"] = function( num )
    local seconds = 1
    for i = 1, 4 do
        seconds = seconds + (i - 1)
        wait( seconds )
    end
end





