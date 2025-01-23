--!Type(Client)
local playerManager = require("PlayerManager")
local core = require("Core")

--!SerializeField
local isUpgrade : boolean = true
--!SerializeField
local upgradeName : string = ""
--!SerializeField
local prereqName : string = ""
--!SerializeField
local prereqLevel : number = 0
--!SerializeField
local label : GameObject = nil
--!SerializeField
local factory : GameObject = nil
--!SerializeField
local lever : GameObject = nil

local isAnimating = false
local isReturnSwing = false
local hasCrossedZero = false

-- local labelScript = nil
-- local displayNameStr = ""
-- local descStr = ""
-- local lvlStr = ""
-- local costStr = ""
local canBuy = true
local prereqText = ""

function self:ClientAwake()
    self.gameObject:GetComponent(TapHandler).Tapped:Connect(function()
        if factory:GetComponent(FactoryScript).getOwner() ~= client.localPlayer then
            playerManager.playSFX("Fail")
            core.makeFloatingText("Red", "Not yours!", label.transform.position+Vector3.new(0,-2.5,-0.3), Vector3.new(2,2,1), true)
            return
        end
        if isAnimating then
            -- playerManager.playSFX("Fail")
            return
        end
        isAnimating = true
        if isUpgrade then
            playerManager.BuyUpgrade(upgradeName, prereqName, prereqLevel)
        else
            if upgradeName == "Make Donut" then
                core.MakeDonutManually()
            elseif upgradeName == "Reset" then
                playerManager.reset()
                core.resetFactory()
            end
            playerManager.playSFX("Click")
        end
    end)

    -- labelScript = label:GetComponent("Label")
    factory:GetComponent(FactoryScript).registerUpgradeUI(upgradeName, label, prereqName, prereqLevel)
end

-- function upgradeBought(upgradeName, newLvl)
--     if prereqName ~= upgradeName then return end
--     if newLvl < prereqLevel then return end
    
-- end

-- function setLabel(displayName, desc, lvlText, costText)
--     displayNameStr = displayName
--     descStr = desc
--     lvlStr = lvlText
--     costStr = costText
-- end

function self:Update()
    -- don't look at this...
    if isAnimating then
        local degs = -180 * Time.deltaTime
        -- prevent lag spikes from setting lever into mathematically unfavorable angles.
        if degs < -20 then degs = -20 end
        local movement = Vector3.new(degs,0,0)
        if isReturnSwing then
            movement *= -1
        end
        if hasCrossedZero then
            movement *= -1
        end
        local oldAngle = lever.transform.eulerAngles
        lever.transform.eulerAngles += movement
        if not isReturnSwing then
            if hasCrossedZero and lever.transform.eulerAngles.x >= 315 then
                lever.transform.eulerAngles = Vector3.new(315,180,180)
                isReturnSwing = true
            end
            if not hasCrossedZero and lever.transform.eulerAngles.y > 90 then
                hasCrossedZero = true
            end
        else
            if not hasCrossedZero and lever.transform.eulerAngles.x >= 315 then
                lever.transform.eulerAngles = Vector3.new(315,0,0)
                isReturnSwing = false
                isAnimating = false
            end
            if hasCrossedZero and lever.transform.eulerAngles.y < 90 then
                hasCrossedZero = false
            end
        end
    end
end