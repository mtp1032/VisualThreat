--------------------------------------------------------------------------------------
-- PrototypeAnimation.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 11 December, 2021
local _, VisualThreat = ...
VisualThreat.PrototypeAnimation = {}
animate = VisualThreat.PrototypeAnimation

local L = VisualThreat.L
local E = errors
local sprintf = _G.string.format

local framePool = CreateFramePool("frame", UIParent, "BackdropTemplate")

local function animate(f)

    f.anim = f:CreateAnimationGroup()
    -- ORDER - Refers to the order in which the animations are executed.
    --          For example, all animations or order 1 are executed first
    --          and simultaneously. .fadein and .movein are order 1
    --          animations
    f.anim.fadein = f.anim:CreateAnimation("alpha")
    f.anim.fadein:SetFromAlpha(0)
    f.anim.fadein:SetToAlpha(1)
    f.anim.movein = f.anim:CreateAnimation("translation")

    -- fadein and movein are executed concurrently and before 
    -- any order 2 or order 3 animations.
    f.anim.fadein:SetOrder(1)
    f.anim.movein:SetOrder(1)

    -- move is an order 2 animation and so is executed AFTER
    -- the order 1 animations complete
    f.anim.move = f.anim:CreateAnimation("translation")
    f.anim.move:SetOrder(2)

    -- fadeout and moveout are order 3 animations and are 
    -- executed last.
    f.anim.fadeout = f.anim:CreateAnimation("alpha")
    f.anim.fadeout:SetFromAlpha(1)
    f.anim.fadeout:SetToAlpha(0)
    f.anim.fadeout:SetOrder(3)

    f.anim.moveout = f.anim:CreateAnimation("translation")
    f.anim.moveout:SetOrder(3)
    
    -- hide frame when animation ends
    f.anim:SetScript("OnFinished",
    function(self) 
        self:GetParent():Hide() 
        framePool:Release(f)
    end)
end

local function updateAnimation(f, duration, xOffset, yOffset )
    -- These are order 1 animations
    local fadeDuration = duration/4
    local moveDuration = duration/2

    f.anim.fadein:SetDuration(  fadeDuration )
    f.anim.movein:SetOffset( xOffset, yOffset)
    f.anim.movein:SetDuration( moveDuration )

    -- These two are order 2 animations
    f.anim.move:SetOffset(xOffset,yOffset)
    f.anim.move:SetDuration(moveDuration)

    -- These are order 3 animations
    f.anim.fadeout:SetDuration( fadeDuration )
    f.anim.moveout:SetOffset( xOffset, yOffset)
    f.anim.moveout:SetDuration( moveDuration)
end
  
local function getFrame()
    f = framePool:Acquire()
    
    f:SetSize(200,20)
    f:SetPoint("CENTER")
    f:SetAlpha(0)
    f.Text = f:CreateFontString(nil,"ARTWORK","GameFontNormalHuge")
    f.Text:SetPoint("CENTER", 200, 0 )
    f.ScrollXMax = (UIParent:GetWidth() * UIParent:GetEffectiveScale())/2 -- max scroll width
    f.ScrollYMax = (UIParent:GetHeight() * UIParent:GetEffectiveScale())/2 -- max scroll height
    animate(f)
    f:Show()
    return f
end
  
SLASH_ANIM1 = "/anim"
SlashCmdList["ANIM"] = function(msg)

    local f = getFrame()
    f.Text:SetFormattedText("%s hit %s for %d damage.", UnitName("player"), UnitName("target"), random(100,200))
    local xPos = 0
    local yPos = 0
    f:SetPoint("CENTER",200, yPos )

    local duration = 5
    local xOffset = 0
    local yOffset = f.ScrollYMax/4

    updateAnimation(f, duration, xOffset, yOffset )

    -- This formula staggers the generation of the text.
    -- C_Timer.After((i-1)/2,
    C_Timer.After(1,function() 
        f.anim:Play() 
    end)
end

