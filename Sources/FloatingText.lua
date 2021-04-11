--------------------------------------------------------------------------------------
-- FloatingText.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 11 December, 2021
local _, VisualThreat = ...
VisualThreat.FloatingText = {}
ft = VisualThreat.FloatingText

local L = VisualThreat.L
local E = errors
local sprintf = _G.string.format

local STATUS_SUCCESS 	= errors.STATUS_SUCCESS
local STATUS_FAILURE 	= errors.STATUS_FAILURE
------------- FLOATING TEXT METHODS ----------------------

ft.DEFAULT_STARTING_REGION  = "CENTER"
ft.DEFAULT_STARTING_XPOS    = 250
ft.DEFAULT_STARTING_YPOS    = -100

local DEFAULT_STARTING_REGION   = ft.DEFAULT_STARTING_REGION
local DEFAULT_STARTING_XPOS     = ft.DEFAULT_STARTING_XPOS
local DEFAULT_STARTING_YPOS     = ft.DEFAULT_STARTING_YPOS
local READY = true

local function delay( seconds )
    C_Timer.After( seconds, function()
        -- do nothing
    end)
end

local framePool = CreateFramePool("frame", UIParent, "BackdropTemplate")
local function configAnimation(f)

    f.animGroup = f:CreateAnimationGroup()

    -- ORDER - Refers to the order in which the animations are executed.
    --          For example, all animations of order 1 are executed first
    --          and simultaneously. In the code below, fadein and movein 
    --          are order 1 animations
    f.animGroup.fadein = f.animGroup:CreateAnimation("alpha")
    f.animGroup.fadein:SetFromAlpha(0)
    f.animGroup.fadein:SetToAlpha(1)
    f.animGroup.fadein:SetOrder(1)
    f.animGroup.movein = f.animGroup:CreateAnimation("translation")
    f.animGroup.movein:SetOrder(1)

    -- fadein and movein are executed concurrently and before 
    -- any order 2 or order 3 animations.

    f.animGroup.move = f.animGroup:CreateAnimation("translation")
    f.animGroup.move:SetOrder(2)

    -- fadeout and moveout are order 3 animations and are 
    -- executed last.
    f.animGroup.fadeout = f.animGroup:CreateAnimation("alpha")
    f.animGroup.fadeout:SetFromAlpha(1)
    f.animGroup.fadeout:SetToAlpha(0)
    f.animGroup.fadeout:SetOrder(3)

    f.animGroup.moveout = f.animGroup:CreateAnimation("translation")
    f.animGroup.moveout:SetOrder(3)
    
    -- hide frame when animation ends
    f.animGroup:SetScript("OnFinished",
    function(self) 
        self:GetParent():Hide() 
        framePool:Release(f)
    end)
end
local function updateAnimation(f, duration, Xdistance, Ydistance )
    -- These are order 1 animations
    local fadeDuration = duration/4         -- fadeDuration = 3
    local moveDuration = duration/2         -- moveDuration = 6

    -- The order 1 animations
    -- Assuming a duration of 12 seconds, the fadeDuration is 3 seconds.
    --  During that 3 seconds, the text will move 96 pixels assuming
    --  the screen height is 384.
    f.animGroup.fadein:SetDuration(  fadeDuration )
    f.animGroup.movein:SetOffset( Xdistance/4, Ydistance/4 )    -- Ydistance/4 = 96
    f.animGroup.movein:SetDuration( fadeDuration )

    -- These two are order 2 animations
    f.animGroup.move:SetOffset( Xdistance/2,Ydistance/2 )       -- Ydistance/2 = 192
    f.animGroup.move:SetDuration( moveDuration)

    -- These are order 3 animations
    f.animGroup.fadeout:SetDuration( fadeDuration )
    f.animGroup.moveout:SetOffset( Xdistance/4, Ydistance/4 )   -- Ydistance/4 = 96
    f.animGroup.moveout:SetDuration( fadeDuration )
end
function ft:getFrame( region, startingXpos, startingYpos)
    f = framePool:Acquire()
    f.Text = f:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
    f.Text:SetPoint("LEFT", 0, 0 )      -- text will be justified left.
    f:SetSize(400,20)

    -- When the frame is created f.SetPoint() is the starting position
    if startingXpos == nil then startingXpos = DEFAULT_STARTING_XPOS end
    if startingYpos == nil then startingYpos = DEFAULT_STARTING_YPOS end

    f:SetPoint(region, startingXpos, startingYpos )
    f:SetAlpha(0)
    f.ScrollXMax = (UIParent:GetWidth() * UIParent:GetEffectiveScale())/2 -- one half of max scroll width
    f.ScrollYMax = (UIParent:GetHeight() * UIParent:GetEffectiveScale())/2 -- one half of max scroll height

    configAnimation(f)
    f:Show()
    return f
end

function ft:displayString( threatStr )

    local f = ft:getFrame("CENTER", 350, -100 )
    f.Text:SetText("")
    f.Text:SetText( threatStr )

    local duration = 12
    local Xdistance = 0
    local Ydistance = f.ScrollYMax   -- ScrollYMax = 384 on my display
    updateAnimation(f, duration, Xdistance, Ydistance )
    E:where( f.Text:GetText() )
    f.animGroup:Play()
end
function ft:displayStrings( threatStrings )
    if not READY then
        return
    end
    READY = false
    local str = {}
	for i, entry in ipairs( threatStrings ) do
        local f = ft:getFrame("CENTER", 0, DEFAULT_STARTING_YPOS )
		f.Text:SetText( entry[2] )
        -- msg:postMsg( sprintf("%s\n", entry[2]))

        -- the duration specifies the number seconds the line of text will take
        -- to scroll across the region.
		local duration = 12
		local Xdistance = 0
		local Ydistance = f.ScrollYMax/2   -- ScrollYMax = 384
		updateAnimation(f, duration, Xdistance, Ydistance )
        -- local delay = (i - 1)/2             -- 0,   0.5, 1.0, 1.5, ...
        -- local delay = (i - 1)/2 + 0.5    -- 0.5, 1.0, 1.5, ... 
        local delay = (i - 1)/2 + 1.0    -- 1:0, 2:1.5, 3:3 
	    C_Timer.After( delay,                   -- f.animGroup:Play() fires once per second.
		    function(self)
                -- msg:postMsg( sprintf("%0.1f : %s\n", delay, f.Text:GetText() ))
			    f.animGroup:Play()
		end)
	end
    READY = true
end
if E:isDebug() then
    local fileName = "FloatingText.lua"
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
