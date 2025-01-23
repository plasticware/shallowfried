--!Type(Module)

local donutValues = {
    Plain = 1,
    Chocolate = 2,
    Cake = 3,
    Cinnamon = 4,
    Apple = 5,
}
-- Classic Flavors
-- Cinnamon Sugar
-- Apple Cider
-- Buttermilk
-- Vanilla Bean
-- Chocolate
-- Fruit-Inspired Flavors
-- Blueberry
-- Lemon Poppy Seed
-- Raspberry Swirl
-- Banana Nut
-- Strawberry
-- Exotic and Innovative Flavors
-- Lavender Honey
-- Matcha Green Tea
-- Maple Pecan
-- Chai Spice
-- Coconut Rum
-- Decadent Flavors
-- Chocolate Espresso
-- Salted Caramel
-- Red Velvet
-- Pistachio
-- Dark Chocolate Almond
-- Seasonal Specialties
-- Pumpkin Spice
-- Gingerbread
-- Apple Pie
-- Eggnog
-- Peppermint Mocha
-- Global-Inspired Flavors
-- Tiramisu
-- Churro
-- Mochi
-- Baklava
-- Tres Leches

local baseUpgradeCosts = {
    Plain = 10,
    Chocolate = 30,
    Cake = 100,
    Cinnamon = 500,
    Apple = 1500,

    BeltSpeed = 20,

    Glaze = 200,
    -- Glaze = 0,

    Prestige = 5000,
    -- Prestige = 1,
}

local upgradeDisplayName = {
    Plain = "Classic Donut Maker",
    Chocolate = "Chocolate Donut Maker",
    Cake = "Cake Donut Maker",
    Cinnamon = "Cinnamon Donut Maker",
    Apple = "Apple Donut Maker",

    BeltSpeed = "Conveyor Belt Speed",

    Glaze = "Glazed Donuts",

    Prestige = "Prestige",
}

local upgradeCostScaling = {
    Plain = 1.2,
    Chocolate = 1.2,
    Cake = 1.3,
    Cinnamon = 1.4,
    Apple = 1.5,

    BeltSpeed = 1.4,

    Glaze = 1.5,

    Prestige = 2,
}

local upgradeType = {
    Plain = "Donut",
    Chocolate = "Donut",
    Cake = "Donut",
    Cinnamon = "Donut",
    Apple = "Donut",

    BeltSpeed = "BeltSpeed",

    Glaze = "Multiplier",

    Prestige = "Prestige",
}

-- time it takes for a donut to travel the conveyor belt.
local baseBeltTime = 10
local beltSpeedScale = .9

local glazeMultScale = .2
local prestigeMultScale = .2

local makeDonutsRequest = Event.new("MakeDonutsRequest")
local setFactoryUpgradeLvlRequest = Event.new("SetFactoryUpgradeLvlRequest")
local setFactoryOwnerRequest = Event.new("SetFactoryOwnerRequest")
local displayFactoryOwnerRequest = Event.new("DisplayFactoryOwnerRequest")
local resetFactoryRequest = Event.new("ResetFactoryRequest")
local createUpgradeTextRequest = Event.new("CreateUpgradeTextRequest")

local timeBetweenTicks = 3

--!SerializeField
local greenText : GameObject = nil
--!SerializeField
local bigGreenText : GameObject = nil
--!SerializeField
local bigRedText : GameObject = nil

local floatingText = {
    SmallGreen = greenText,
    Green = bigGreenText,
    Red = bigRedText,
}

factoriesByPlayer = {}
playersByFactory = {}

local nextDonutID = 0

playerManager = self.gameObject:GetComponent(PlayerManager)

function getUpgradeCost(upgradeName, currentLevel)
    return math.floor(baseUpgradeCosts[upgradeName] * upgradeCostScaling[upgradeName] ^ currentLevel + .5)
end

function getTravelTime(currentLevel)
    return baseBeltTime * beltSpeedScale ^ currentLevel
end

function getGlazeMult(currentLevel)
    return 1 + glazeMultScale * currentLevel
end

function getPrestigeMult(currentLevel)
    return 1 + prestigeMultScale * currentLevel
end

function getPrestigeStr(prestigeLvl)
    return string.format("Prestige %i: x%.2f donut value", prestigeLvl, getPrestigeMult(prestigeLvl))
end

function updateUpgradeLabel(factoryScript, upgradeName, curLvl)
    if upgradeName == "Make Donut" then
        factoryScript.updateUpgradeLabel(upgradeName, "Make Donut Manually", "+1 Classic Donut", "", "")
        return
    end
    if upgradeName == "Reset" then
        factoryScript.updateUpgradeLabel(upgradeName, "Reset All Data", "You will not be asked to confirm", "PERMANENT!", "")
        return
    end
    if not baseUpgradeCosts[upgradeName] then return end
    if not curLvl then curLvl = 0 end
    local desc = ""
    local lvlText = "Lvl "..curLvl.." -> Lvl "..(curLvl+1)..""
    if upgradeType[upgradeName] == "Donut" then
        desc = "Base value: $"..donutValues[upgradeName].." each"
        lvlText = "Per batch: +"..curLvl.." -> +"..(curLvl+1)
    elseif upgradeType[upgradeName] == "BeltSpeed" then
        desc = "Belts take 10% less time"
        lvlText = string.format("%.2f sec -> %.2f sec", getTravelTime(curLvl), getTravelTime(curLvl+1))
    elseif upgradeType[upgradeName] == "Multiplier" then
        desc = "Increase donut value"
        lvlText = string.format("x%.2f -> x%.2f", getGlazeMult(curLvl), getGlazeMult(curLvl+1))
    elseif upgradeType[upgradeName] == "Prestige" then
        desc = "Reset factory, gain bonuses"
        lvlText = string.format("x%.2f -> x%.2f", getPrestigeMult(curLvl), getPrestigeMult(curLvl+1))
    end
    local costText = "$"..getUpgradeCost(upgradeName, curLvl)
    factoryScript.updateUpgradeLabel(upgradeName, upgradeDisplayName[upgradeName], desc, lvlText, costText)
end

function updateUpgradeLabelLocked(factoryScript, upgradeName, prereqName, prereqLevel)
    local prereqStr = "Requires "..upgradeDisplayName[prereqName].."!"
    if prereqLevel > 1 then
        prereqStr = "Requires "..upgradeDisplayName[prereqName].." level "..prereqLevel.."!"
    end
    factoryScript.updateUpgradeLabel(upgradeName, upgradeDisplayName[upgradeName], prereqStr, "", "LOCKED")
end

function self:ServerAwake()
    -- on tick, create donuts at all owned factories.
    Timer.Every(timeBetweenTicks, function()
        for player, factory in pairs(factoriesByPlayer) do
            local ownedDonutMakers = {}
            for donutType, _ in pairs(donutValues) do
                ownedDonutMakers[donutType] = playerManager.getUpgradeLvl(player, donutType)
            end
            makeDonutsRequest:FireClient(player, ownedDonutMakers)
        end
    end)

    function setFactoryUpgradeLvl(player, upgradeName, curLvl)
        setFactoryUpgradeLvlRequest:FireClient(player, upgradeName, curLvl)
    end

    function ClaimFactory(player)
        if factoriesByPlayer[player] then
            -- print("factory already claimed! on "..(client and "client" or "server"))
            return
        end
        local factories = GameObject.FindGameObjectsWithTag("Factory")
        for i, factory in ipairs(factories) do
            if playersByFactory[factory] then
                continue
            end
            factoriesByPlayer[player] = factory
            playersByFactory[factory] = player
            -- print("factory "..factory.name.." claimed! on server")
            if player.character then
                player.character.transform.position = factory:GetComponent(FactoryScript).getSpawnPos()
            end
            setFactoryOwnerRequest:FireAllClients(player, factory.name)
            return
        end
        -- print("no factories available! on "..(client and "client" or "server"))
    end

    function displayOtherFactoriesOwnership(player)
        local factories = GameObject.FindGameObjectsWithTag("Factory")
        for i, factory in ipairs(factories) do
            if playersByFactory[factory] and playersByFactory[factory] ~= player then
                displayFactoryOwnerRequest:FireClient(player, playersByFactory[factory], factory.name)
            end
        end
    end

    function unclaimFactory(player)
        local factory = factoriesByPlayer[player]
        factoriesByPlayer[player] = nil
        playersByFactory[factory] = nil
        setFactoryOwnerRequest:FireAllClients(nil, factory.name)
    end

    function createUpgradeText(player, upgradeName, color, text)
        createUpgradeTextRequest:FireClient(player, upgradeName, color, text)
    end

    function resetFactory(player)
        resetFactoryRequest:FireClient(player)
    end
end

function self:ClientAwake()
    -- you have to spawn things on client side, not server???
    makeDonutsRequest:Connect(function(ownedDonutMakers)
        local player = client.localPlayer
        local factory = factoriesByPlayer[player]
        local factoryScript = factory:GetComponent("FactoryScript")
        donutsArr = {}
        for donutType, numMakers in pairs(ownedDonutMakers) do
            if numMakers == 0 then continue end
            for i = 1,numMakers do
                nextDonutID += 1
                table.insert(donutsArr, {
                    id = player.id..":"..nextDonutID,
                    donutType = donutType,
                })
            end
        end
        if #donutsArr > 0 then
            factoryScript.makeDonuts(donutsArr)
            playerManager.playSFX("Bang")
            makeSmallGreenText("+"..#donutsArr, factoryScript.getMakerPos())
            factoryScript.startCountdown(timeBetweenTicks)
        end
    end)

    function SellDonut(owner, donutAttrs)
        if owner == client.localPlayer then
            local factoryScript = factoriesByPlayer[owner]:GetComponent("FactoryScript")
            local baseValue = donutValues[donutAttrs.donutType]
            local worth = baseValue * factoryScript.getPrestigeMult()
            if donutAttrs["glazeMult"] then worth *= donutAttrs["glazeMult"] end
            local worthInCents = math.floor(worth*100)
            playerManager.IncrementStat("CashInCents", worthInCents, false)
            makeSmallGreenText(string.format("+$%.2f",worth), factoryScript.getConveyorEndPos()+Vector3.new(0,-.75,0), Vector3.new(1+baseValue*.2,1+baseValue*.2,1))
        end
    end

    function MakeDonutManually()
        local player = client.localPlayer
        local factory = factoriesByPlayer[player]
        local factoryScript = factory:GetComponent("FactoryScript")
        nextDonutID += 1
        factoryScript.makeDonuts({{
            id = player.id..":"..nextDonutID,
            donutType = "Plain",
        }})
        makeSmallGreenText("+1", factoryScript.getMakerPos())
    end

    function setFactoryUpgradeLvl(upgradeName, curLvl)
        local player = client.localPlayer
        local factory = factoriesByPlayer[player]
        local factoryScript = factory:GetComponent("FactoryScript")
        factoryScript.setUpgradeLvl(upgradeName, curLvl)
    end

    function refreshUpgradeUIs(upgradeLevels)
        for upgradeName, curLvl in upgradeLevels do
            setFactoryUpgradeLvl(upgradeName, curLvl)
        end
    end

    setFactoryUpgradeLvlRequest:Connect(function(upgradeName, curLvl)
        setFactoryUpgradeLvl(upgradeName, curLvl)
    end)

    function resetFactory()
        local player = client.localPlayer
        local factory = factoriesByPlayer[player]
        local factoryScript = factory:GetComponent("FactoryScript")
        factoryScript.reset()
    end

    resetFactoryRequest:Connect(function()
        resetFactory()
    end)
    
    setFactoryOwnerRequest:Connect(function(player, factoryName)
        -- local player = client.localPlayer
        local factories = GameObject.FindGameObjectsWithTag("Factory")
        if player then
            for i, factory in ipairs(factories) do
                local factoryScript = factory:GetComponent(FactoryScript)
                if factory.name ~= factoryName then
                    -- if you are the player claiming a factory, hide all factory uis for factories that don't belong to you.
                    if player == client.localPlayer then
                        for upgradeName, _ in pairs(factoryScript.upgradeUIs) do
                            factoryScript.getUpgradeUIObj(upgradeName):SetActive(false)
                        end
                        factoryScript.getMakerLabel():SetActive(false)
                    end
                    continue
                end
                if player == client.localPlayer then
                    -- passing the ui elements makes unity crash :(
                    local upgradeNames = {}
                    for upgradeName, _ in pairs(factoryScript.upgradeUIs) do
                        upgradeNames[upgradeName] = true
                    end
                    playerManager.refreshUpgradeUIs(player, upgradeNames)
                    -- make 0 donuts in order to update the donut storage display.
                    factoryScript.makeDonuts({})
                    if player.character then
                        player.character:Teleport(factoryScript.getSpawnPos())
                    end
                end
                -- print("factory "..factory.name.." claimed! on client")
                factoriesByPlayer[player] = factory
                playersByFactory[factory] = player
                factoryScript.setOwner(player)
            end
        else
            -- unclaiming a factory.
            for i, factory in ipairs(factories) do
                if factory.name ~= factoryName then
                    continue
                end
                local factoryScript = factory:GetComponent(FactoryScript)
                local oldPlayer = playersByFactory[factory]
                factoriesByPlayer[oldPlayer] = nil
                playersByFactory[factory] = nil
                factoryScript.setOwner(nil)
            end
        end
    end)

    displayFactoryOwnerRequest:Connect(function(player, factoryName)
        local factories = GameObject.FindGameObjectsWithTag("Factory")
        for i, factory in ipairs(factories) do
            if factory.name ~= factoryName then
                continue
            end
            local factoryScript = factory:GetComponent(FactoryScript)
            factoriesByPlayer[player] = factory
            playersByFactory[factory] = player
            factoryScript.setOwner(player)
        end
    end)

    function makeSmallGreenText(str, pos, scale, noRandomOffset)
        makeFloatingText("SmallGreen", str, pos, scale, noRandomOffset)
    end

    function makeFloatingText(color, str, pos, scale, noRandomOffset)
        scale = scale or Vector3.new(2,2,1)
        local t = Object.Instantiate(floatingText[color])
        if not noRandomOffset then
            pos += Vector3.new(math.random()-.5, math.random()-.5, math.random()-.5)
        end
        t.transform.position = pos
        local holder = t:GetComponent(TextHolder)
        local label = holder.getLabel().gameObject
        if color == "Red" then
            label:GetComponent(RedText).setText(str)
        else
            label:GetComponent(GreenText).setText(str)
        end
        label.transform.localScale = scale
        holder.animateTo(t.transform.position + Vector3.new(0,2,0))
    end

    createUpgradeTextRequest:Connect(function(upgradeName, color, text)
        local player = client.localPlayer
        local factory = factoriesByPlayer[player]
        local factoryScript = factory:GetComponent("FactoryScript")
        local pos = factoryScript.getUpgradeUIObj(upgradeName).transform.position
        makeFloatingText(color, text, pos+Vector3.new(0,-2.5,-0.3), Vector3.new(2,2,1), true)
    end)

    function getFactorySpawnPos()
        local player = client.localPlayer
        local factory = factoriesByPlayer[player]
        local factoryScript = factory:GetComponent("FactoryScript")
        return factoryScript.getSpawnPos()
    end

    function setFactoryWallCash(player, cashInCents)
        local factory = factoriesByPlayer[player]
        local factoryScript = factory:GetComponent("FactoryScript")
        factoryScript.setWallCash(cashInCents)
    end

    function setFactoryWallPrestige(player, prestigeLvl)
        local factory = factoriesByPlayer[player]
        local factoryScript = factory:GetComponent("FactoryScript")
        factoryScript.setWallPrestige(prestigeLvl)
    end
end