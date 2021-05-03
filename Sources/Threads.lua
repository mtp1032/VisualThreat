--------------------------------------------------------------------------------------
-- Threads.lua 
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 9 March, 2021
local _, VisualThreat = ...
VisualThreat.Threads = {}
wow = VisualThreat.Threads

local fileName = "Threads.lua"

local E = errors
local L = VisualThreat.L

local DEBUG = errors.DEBUG
local sprintf = _G.string.format

local SUCCESS   = errors.STATUS_SUCCESS
local FAILURE   = errors.STATUS_FAILURE

-- Indices into the thread handle table
local TH_EXECUTABLE             = timer.TH_EXECUTABLE
local TH_IDENTIFIER             = timer.TH_IDENTIFIER
local TH_ADDRESS                = timer.TH_ADDRESS
local TH_STATUS                 = timer.TH_STATUS
local TH_FUNC_ARGS              = timer.TH_FUNC_ARGS
local TH_JOIN_RESULTS           = timer.TH_JOIN_RESULTS
local TH_DELAY_TICKS_REMAINING  = timer.TH_DELAY_TICKS_REMAINING
local TH_SIGNAL                 = timer.TH_SIGNAL
local TH_YIELD_TIME             = timer.TH_YIELD_TIME
local TH_YIELD_COUNT            = timer.TH_YIELD_C
local TH_DURATION_TICKS         = timer.TH_DURATION_TICKS
local TH_REMAINING_TICKS        = timer.TH_REMAINING_TICKS

local TH_NUM_ELEMENTS           = timer.TH_NUM_ELEMENTS

local SIG_NONE      = timer.SIG_NONE    -- default value. Means no signal is pending
local SIG_RETURN    = timer.SIG_RETURN  -- cleanup state and return from the action routine
local SIG_DIE       = timer.SIG_DIE     -- call threadDestroy()
local SIG_WAKEUP    = timer.SIG_WAKEUP  -- You've returned prematurely from a yield. Do what's appropriate.
local SIG_LAST      = timer.SIG_WAKEUP
local SIG_FIRST     = timer.SIG_FIRST

-- used for debugging
function wow:isThreadHandleValid( thread_h )
    local result = {SUCCESS, nil, nil }
    local isValid = false

    -- is thread_h nil?
    if thread_h == nil then
        isValid, result = E:setResult( L["THREAD_HANDLE_NIL"], debugstack() )
        assert( result ~= nil )

    elseif type(thread_h) ~= "table" then
        isValid, result = E:setResult(L["THREAD_INVALID_HANDLE_TYPE"], debugstack() )
        assert( result ~= nil )

    elseif thread_h[TH_EXECUTABLE] ~= nil then
        if type( thread_h[TH_EXECUTABLE] ) ~= "thread" then
            isValid, result = E:setResult( L["THREAD_INVALID_EXE"], debugstack() )
            assert( result ~= nil )
        end
    end
    assert( result ~= nil )
    if result[1] ~= SUCCESS then
        return isValid, result
    end

    return true, result
end
----------------------------------------------------------
--              CREATE THREAD
----------------------------------------------------------
function wow:threadCreate( interval, f, ... ) 
    local result = {SUCCESS, nil,nil }
    local isValid = true
    local arg = ...
    
    -- Check the arguments -- THESE HAVE TO BE CORRECT.
    if DEBUG then
        assert( interval ~= nil, L["ARG_NIL"])
        assert( type(interval == "number", L["ARG_INVALID_TYPE"]))
        assert( f ~= nil, L["ARG_NIL"])
        assert( type(f) == "function", L["INVALID ARG"] )
    end
    if interval == nil then
        result = E:setResult( L["ARG_NIL"], debugstack() )
        return nil, result
    elseif type(interval) ~= "number" then
        result = E:setResult( L["ARG_INVALID_TYPE"], debugstack())
        return nil, result
    end

    local thread_h = timer:initThreadHandle( interval, f, arg )
    isValid, result = wow:isThreadHandleValid( thread_h )
    if result[1] == FAILURE then
        return nil, result
    end
        
    -- if f == nil then
    --     result = E:setResult( L["FUNCTION_ARG_NIL"], debugstack() )
    --     return nil, result
    -- elseif type(f) ~= "function" then
    --     result = E:setResult( L["ARG_INVALID_TYPE"], debugstack())
    --     return nil, result
    -- end

    -- local thread_h = timer:initThreadHandle( interval, f, arg )
    -- isValid, result = wow:isThreadHandleValid( thread_h )
    -- if result[1] == FAILURE then
    --     return nil, result
    -- end

    -- mf:postMsg(sprintf("Thread %d created.\n", thread_h[TH_IDENTIFIER]))
    return thread_h, result
end
----------------------------------------------------------
--              THREAD YIELD
----------------------------------------------------------
function wow:threadYield() 
    timer:yield() 
end
----------------------------------------------------------
--              THREAD DESTROY
----------------------------------------------------------
function wow:threadDestroy( thread_h )
    -- remove the handle from the dispatch queue
    timer:removeThread( thread_h)
    return true
end
----------------------------------------------------------
--              THREAD SIGNALS
----------------------------------------------------------
function wow:threadSendSignal( thread_h, signal )
    local result = {SUCCESS, nil, nil }
    local delivered = false
    delivered, result = sig:sendSignal( thread_h, signal)
    return delivered, result
end
function wow:threadGetSignal( thread_h )
    local signal = SIG_NONE
    if thread_h == nil then
        thread_h = wow:getThreadSelf()
    end
    signal = thread_h[TH_SIGNAL]
    thread_h[TH_SIGNAL] = SIG_NONE
    return signal
end
function wow:threadGetSignalName( signal )
    return sig:getSigName( signal )
end
----------------------------------------------------------
--              THREAD SELF
----------------------------------------------------------
function wow:getThreadSelf()
    local thread_h = timer:getCurrentThreadHandle()
    assert( thread_h ~= nil, "Failed to get current thread handle" )
    return thread_h
end
----------------------------------------------------------
--              THREAD JOIN
--  Used to wait for the termination of another thread.
----------------------------------------------------------
function wow:threadJoin( producer_h )
    local self_h = wow:getThreadSelf()

    local joinResults = producer_h[TH_JOIN_RESULTS]
    while( joinResults == nil ) do
        wow:threadYield()
        joinResults = producer_h[TH_JOIN_RESULTS]
    end
    self_h[TH_JOIN_RESULTS] = joinResults
    return joinResults
end
----------------------------------------------------------
--              THREAD EXIT
----------------------------------------------------------
function wow:threadExit( returnData )
    local producer_h = timer:getCurrentThreadHandle()
    producer_h[TH_JOIN_RESULTS] = returnData
end
---------------------------------------------------------
--            SOME USEFUL UTILITIES
---------------------------------------------------------
-- The calling thread delays its execution forthe amount of
-- time.
function wow:threadDelay( seconds )
    local self_h = wow:getThreadSelf()
    local originalDuration = self_h[TH_DURATION_TICKS]

    local timerInterval = timer:mgmt_getTimerInterval()
    local sleepTicks = floor( seconds/timerInterval )
    self_h[TH_DURATION_TICKS] = sleepTicks
    self_h[TH_REMAINING_TICKS] = sleepTicks
    wow:threadYield()
    self_h[TH_DURATION_TICKS] = originalDuration
    self_h[TH_REMAINING_TICKS] = 1
end

function wow:getThreadId( thread_h ) 
    if thread_h == nil then
        thread_h = timer:getCurrentThreadHandle()
    end
    return thread_h[TH_IDENTIFIER]
end
-- returns true if handles refer to the same thread.
-- false otherwise
function wow:threadsEqual( thread1_h, thread2_h )
    local id1 = thread1_h[TH_IDENTIFIER]
    local id2 = thread2_h[TH_IDENTIFIER]
    return id1 == id2
end
function wow:getThreadIntervalTime( thread_h )
    local ticks = thread_h[TH_DURATION_TICKS]
    local intervalTime = ticks * timer:mgmt_getTimerInterval()
    return intervalTime, ticks
end


if E:isDebug() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
