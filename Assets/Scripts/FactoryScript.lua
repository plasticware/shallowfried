

--!SerializeField
local spawnPoint : GameObject = nil
--!SerializeField
local donutMaker : GameObject = nil
--!SerializeField
local glazer : GameObject = nil
--!SerializeField
local icer : GameObject = nil
--!SerializeField
local endOfConveyor : GameObject = nil
--!SerializeField
local wallLabel : GameObject = nil

local core = require("Core")

-- attributes of donuts that have been produced but are waiting to be placed on the conveyor belt.
readyDonuts = {}
-- donut objects that are on the conveyor belt.
activeDonuts = {}
-- donuts that made it to the end of the conveyor belt.
finishedDonuts = {}

upgradeUIs = {}

owner = nil
prestigeMult = 1

--!SerializeField
local plainDonutPrefab : GameObject = nil
--!SerializeField
local chocolateDonutPrefab : GameObject = nil
--!SerializeField
local cakeDonutPrefab : GameObject = nil
--!SerializeField
local cinnamonDonutPrefab : GameObject = nil
--!SerializeField
local appleDonutPrefab : GameObject = nil

local donutPrefabs = {
    Plain = plainDonutPrefab,
    Chocolate = chocolateDonutPrefab,
    Cake = cakeDonutPrefab,
    Cinnamon = cinnamonDonutPrefab,
    Apple = appleDonutPrefab
}

upgrades = {}

local donutOrigin = Vector3.new(0,0,0)
local donutDest = Vector3.new(0,0,0)
local ready = false

local donutMakerStorageLabel = nil

function setOwner(player)
    owner = player
    if player then
        setWallText(player.name.."'s Factory", "", "", "")
    else
        setWallText("Unclaimed Factory", "", "", "")
    end
end

function getSpawnPos()
    return spawnPoint.transform.position
end

function getUpgradeLvl(upgradeName)
    if upgrades[upgradeName] then return upgrades[upgradeName] else return 0 end
end

function setUpgradeLvl(upgradeName, lvl)
    upgrades[upgradeName] = lvl
    if upgradeName == "BeltSpeed" then
        -- increase speed of active donuts
        for _, donutObj in ipairs(activeDonuts) do
            donutObj:GetComponent("Donut").SetAttrs({travelTime = core.getTravelTime(getUpgradeLvl("BeltSpeed"))})
        end
    end
    if upgradeName == "Prestige" then
        prestigeMult = core.getPrestigeMult(lvl)
    end
    for iterUpgradeName, info in pairs(upgradeUIs) do
        local isLocked = true
        if info.prereqName == "" then isLocked = false end
        if isLocked and upgrades[info.prereqName] and upgrades[info.prereqName] >= info.prereqLevel then isLocked = false end
        if isLocked then
            local prereqInfo = upgradeUIs[info.prereqName]
            if upgrades[prereqInfo.prereqName] and upgrades[prereqInfo.prereqName] < prereqInfo.prereqLevel then
                -- if the prereq is not available, don't tell the player anything.
                updateUpgradeLabel(iterUpgradeName, "???", "", "", "LOCKED")
            else
                -- if the prereq is available, tell the player to buy it.
                core.updateUpgradeLabelLocked(self.gameObject:GetComponent(FactoryScript), iterUpgradeName, info.prereqName, info.prereqLevel)
            end
        else
            core.updateUpgradeLabel(self.gameObject:GetComponent(FactoryScript), iterUpgradeName, upgrades[iterUpgradeName])
        end
    end
end

function getMakerPos()
    return donutMaker.transform.position
end

function getMakerLabel()
    return donutMaker:GetComponent("DonutMaker").getLabel()
end

function getGlazerPos()
    return glazer.transform.position
end

function getConveyorEndPos()
    return endOfConveyor.transform.position
end

function getOwner()
    return owner
end

function getPrestigeMult()
    return prestigeMult
end

function getGlazeMult()
    return core.getGlazeMult(upgrades["Glaze"] and upgrades["Glaze"] or 0)
end

function makeGlazeParticles()
    glazer:GetComponent(ParticleSystem):Play()
end

function getUpgradeUIObj(upgradeName)
    return upgradeUIs[upgradeName].label.gameObject
end

function spawnDonut(donutAttrs)
    local d = Object.Instantiate(donutPrefabs[donutAttrs.donutType])
    d.transform.position = donutAttrs.orig
    return d
end

function makeDonuts(donutAttrsArr)
    for _, donutAttrs in ipairs(donutAttrsArr) do
        table.insert(readyDonuts, donutAttrs)
    end
    donutMakerStorageLabel.setText(#readyDonuts)
end

function self:ServerAwake()
end

function setWallText(line1, line2, line3, line4)
    wallLabel:GetComponent(UpgradeLabel).setText(line1, line2, line3, line4)
end

function setWallCash(cashInCents)
    wallLabel:GetComponent(UpgradeLabel).setWallCash(string.format("Cash: $%.2f", cashInCents/100))
end

function setWallPrestige(lvl)
    wallLabel:GetComponent(UpgradeLabel).setWallPrestige(core.getPrestigeStr(lvl))
end

function self:ClientAwake()
    donutOrigin = donutMaker.transform.position + Vector3.new(0,.75,0)
    donutDest = endOfConveyor.transform.position + Vector3.new(0,.75,0)
    donutMakerStorageLabel = getMakerLabel():GetComponent("DonutMakerLabel")
    ready = true

    setWallText("Unclaimed Factory", "", "", "")

    function registerUpgradeUI(upgradeName, upgradeUIObj, prereqName, prereqLevel)
        upgradeUIs[upgradeName] = {
            label = upgradeUIObj:GetComponent("UpgradeLabel"),
            prereqName = prereqName,
            prereqLevel = prereqLevel,
        }
    end

    function updateUpgradeLabel(upgradeName, displayName, desc, lvlText, costText)
        upgradeUIs[upgradeName].label.setText(displayName, desc, lvlText, costText)
    end

    function startCountdown(duration)
        donutMakerStorageLabel.StartMeter(duration)
    end

    function reset()
        for _, donutObj in ipairs(activeDonuts) do
            Object.Destroy(donutObj)
        end
        readyDonuts = {}
        activeDonuts = {}
        finishedDonuts = {}
        upgrades = {}
        upgradeNames = {}
        donutMakerStorageLabel.setText(#readyDonuts)
        donutMakerStorageLabel.CancelMeter()
        prestigeMult = 1
        for upgradeName, _ in pairs(upgradeUIs) do
            upgradeNames[upgradeName] = true
        end
        core.gameObject:GetComponent(PlayerManager).refreshUpgradeUIs(client.localPlayer, upgradeNames)
    end
end

function self:Update()
    if not ready then
        return
    end
    
    if #readyDonuts > 0 then
        local canMakeDonut = true
        -- spawn a donut object if the conveyor is clear.
        if #activeDonuts > 0 and (activeDonuts[#activeDonuts].transform.position - donutOrigin).magnitude < 0.4 then
            canMakeDonut = false
        end
        if canMakeDonut then
            -- choose a random donut from the ready donuts.
            local donutAttrs = table.remove(readyDonuts, math.random(#readyDonuts))
            donutAttrs.orig = donutOrigin
            donutAttrs.dest = donutDest
            donutAttrs.travelTime = core.getTravelTime(getUpgradeLvl("BeltSpeed"))
            local newDonut = spawnDonut(donutAttrs)
            newDonut:GetComponent("Donut").SetAttrs(donutAttrs)
            newDonut:GetComponent("Donut").setFactory(self.gameObject)
            donutMakerStorageLabel.setText(#readyDonuts)
            table.insert(activeDonuts, newDonut)
        end
    end
    -- check the oldest active donut. if it's at the end of the conveyor belt, sell it.
    if #activeDonuts > 0 and (activeDonuts[1].transform.position - donutOrigin).magnitude >= (donutDest - donutOrigin).magnitude then
        local donutObj = table.remove(activeDonuts, 1)
        local donutAttrs = donutObj:GetComponent("Donut").GetAttrs()
        -- i was originally going to add another step of buying machines to sell donuts for you, but decided that was probably too much.
        -- table.insert(finishedDonuts, donutAttrs)
        Object.Destroy(donutObj)
        core.SellDonut(owner, donutAttrs)
    end
end