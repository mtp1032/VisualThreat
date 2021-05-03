--------------------------------------------------------------------------------------
-- ThreadsTest.lua 
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 9 March, 2021
local _, VisualThreat = ...
VisualThreat.ThreadsTest = {}
test = VisualThreat.ThreadsTest

E:where()
local L = VisualThreat.L
local E = errors

local DEBUG = E:isDebug()
local SUCCESS   = errors.STATUS_SUCCESS
local FAILURE   = errors.STATUS_FAILURE

local sprintf = _G.string.format

timer.SIG_NONE      = 1
timer.SIG_RETURN    = 2
timer.SIG_DIE       = 3
timer.SIG_WAKEUP    = 4

timer.SIG_LAST      = timer.SIG_WAKEUP
timer.SIG_FIRST     = timer.SIG_NONE
E:where()

local function generator()
    local greeting = "Hello World!"
    local count = 1
    local done = false
    while not done do
        wow:threadYield()
        count = count + 1
        if count == 4 then done = true end
    end
    wow:threadExit( greeting )
end
local function capacity()
	local signal = SIG_NONE
	local threadId = wow:getThreadId()
	local thread_h = wow:getThreadSelf()

	while signal ~= SIG_RETURN or signal ~= SIG_WAKEUP do
		wow:threadYield()
		signal = wow:threadGetSignal( thread_h )
	end
	mf:postMsg(sprintf("Thread %d received %s, exiting.\n", threadId, wow:getSignalName( SIG_WAKEUP )))
end
local function helloWorld( greeting )
    mf:postMsg( sprintf("Single Parameter: %s\n\n", greeting ))
end
local function whoAmI( thread_h )
    local id = wow:getThreadId( thread_h )
    mf:postMsg( sprintf("Thread Handle Parameter: I am thread %d\n", tostring( id )))
end
local function sum( v )
    local a, b, c = unpack(v)
    mf:postMsg( sprintf("Multiple Parameters: sum = %d\n", a + b + c))
end
local talonInterval = timer:mgmt_getTimerInterval()
print( talonInterval )
local function main()
	local result = {SUCCESS, nil, nil }

    mf:postMsg(sprintf("*************************************\n"))
    mf:postMsg(sprintf("****** TEST: PARAMETER PASSING ********\n"))
    mf:postMsg(sprintf("*************************************\n\n"))

    local yieldInterval =  talonInterval*25    -- yield time 25 ticks or approx. 0.4 seconds

    local status = {SUCCESS, nil, nil }
    local v = {1, 2, 3}
    local th1, status = wow:threadCreate( yieldInterval, sum, v )
    if status[1] ~= SUCCESS then
        mf:postResult( status )
    end

    local th2, status = wow:threadCreate( yieldInterval, whoAmI, "HANDLE" )
    if status[1] ~= SUCCESS then
        mf:postResult( status )
    end

    local greeting = "Hello World!"
    local th3, status = wow:threadCreate( yieldInterval, helloWorld, greeting )
    if status[1] ~= SUCCESS then
        mf:postResult( status )
    end

    mf:postMsg(sprintf("*************************************\n"))
    mf:postMsg(sprintf("***********TEST: THREAD DELAY *************\n"))
    mf:postMsg(sprintf("*************************************\n\n"))
    wow:threadDelay( 2.0 )

    mf:postMsg(sprintf("*************************************\n"))
    mf:postMsg(sprintf("***********TEST: JOIN/EXIT *************\n"))
    mf:postMsg(sprintf("*************************************\n\n"))

    local generator_h, result = wow:threadCreate( yieldInterval, generator )
    if result[1] ~= SUCCESS then 
        mf:postResult( result )
        return 
    end

    local data = wow:threadJoin( generator_h )
    mf:postMsg( sprintf("Joined Data: %s\n\n", data ))

	local numThreads = 20

    mf:postMsg(sprintf("*************************************\n"))
    mf:postMsg(sprintf("************ TEST: SIG_RETURN *********\n"))
    mf:postMsg(sprintf("*************************************\n\n"))
	local threads = {}
    mf:postMsg( sprintf("Creating %d threads.\n", numThreads ))
	local yieldInterval = talonInterval*random(20,30)
	for i = 1, numThreads do
		threads[i] = wow:threadCreate( yieldInterval, capacity )
	end

	-- this is to make sure that the test threads are up and running.
	wow:threadDelay( 2.0 )

    mf:postMsg(sprintf("Sending SIG_RETURN to the previously created %d threads.\n\n", numThreads))
	for i = 1, numThreads do
		local successful, result = wow:threadSendSignal( threads[i], SIG_RETURN )
        if successful then
            local threadId = wow:getThreadId(  threads[i] )
            mf:postMsg(sprintf("SIG_RETURN successfully sent to thread %d\n", threadId ))
        end
	end

    mf:postMsg(sprintf("*************************************\n"))
    mf:postMsg(sprintf("************ TEST: SIG_WAKEUP *********\n"))
    mf:postMsg(sprintf("*************************************\n\n"))

    mf:postMsg( sprintf("SIG_WAKEUP: Creating %d threads.\n", numThreads ))
	local yieldInterval = talonInterval*3600 -- approx. 60 seconds (0.0167 * 3600 =~ 60 seconds )
	for i = 1, numThreads do
		threads[i] = wow:threadCreate( yieldInterval, capacity )
	end

    	-- this is to make sure that the test threads are up and running.
	wow:threadDelay( 2.0 )


    mf:postMsg(sprintf("Sending SIG_WAKEUP to the previously created %d threads.\n\n", numThreads))
	for i = 1, numThreads do
		local successful, result = wow:threadSendSignal( threads[i], SIG_WAKEUP )
        if successful then
            local threadId = wow:getThreadId(  threads[i] )
            mf:postMsg(sprintf("SIG_WAKEUP successfully sent to thread %d\n", threadId ))
        end
	end
    
    mf:postMsg(sprintf("\n\n********* REGRESSION TESTS COMPLETE ***********\n\n"))

    local done = false
	while not done do
		wow:threadYield()
		local signal = wow:threadGetSignal()
        if signal == SIG_RETURN then
            done = true
        end
	end
	mf:postMsg( sprintf("Thread Tests Terminated.\n"))
end

SLASH_THREADS_TEST1 = "/threads"
SlashCmdList["THREADS_TEST"] = function( msg )
    msg = strupper( msg )

    if msg == "RUN" then

        local yieldInterval = talonInterval*300    -- 300 ticks = approx. 5 seconds
	    if main_h == nil then
		    main_h, status = wow:threadCreate( yieldInterval, main  )
            if status[1] ~= SUCCESS then
                mf:postResult( status )
                return
            end
	    end
        return
    end
    if msg == "STOP" then
        if main_h == nil then E:where() return end

        E:where()
		wow:threadSendSignal( main_h, SIG_RETURN )
        return
	end
end

if E:isDebug() then
	local fileName = "ThreadsTest.lua"
    DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
