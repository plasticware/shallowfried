--!Type(Module) -- Module type declaration, typically used in specific game engines or frameworks.

-- Create events for different types of requests, these will be used for communication between client and server.
local getStatsRequest = Event.new("GetStatsRequest")
local saveStatsRequest = Event.new("SaveStatsRequest")
local incrementStatRequest = Event.new("IncrementStatRequest")
local buyUpgradeRequest = Event.new("BuyUpgradeRequest")
local refreshUIRequest = Event.new("RefreshUIRequest")
local getUpgradeLevelsRequest = Event.new("GetUpgradeLevelsRequest")
local refreshUpgradeUIRequest = Event.new("RefreshUpgradeUIRequest")
local refreshWallStatsRequest = Event.new("RefreshWallStatsRequest")
local resetRequest = Event.new("ResetRequest")
local audioRequest = Event.new("AudioRequest")
local spawnRequest = Event.new("SpawnRequest")
local spawnClientRequest = Event.new("SpawnClientRequest")

-- Variable to hold the player's statistics GUI component
local playerStatGui = nil

-- Table to keep track of players and their associated stats
players = {}

local core = require("Core")

local defaultStats = {
    CashInCents = 0,
    upgrades = {},
}
--!SerializeField
local failSound : AudioShader = nil
--!SerializeField
local clickSound : AudioShader = nil
--!SerializeField
local spendSound : AudioShader = nil
--!SerializeField
local whooshSound : AudioShader = nil
--!SerializeField
local bangSound : AudioShader = nil

local sfx = {
    Fail = failSound,
    Click = clickSound,
    Spend = spendSound,
    Bang = bangSound,
}

local lastSaveTime = {}

-- turn tables of (tables of) intvalues into tables of (tables of) numbers.
-- use this format for saving to storage.
local function numberizeRecursive(input)
    local output = {}
    for key, val in pairs(input) do
        if type(val) == "table" then
            output[key] = numberizeRecursive(val)
        else
            output[key] = val.value
        end
    end
    return output
end

-- Function to save a player's stats to persistent storage
local function SaveStats(player, mustSave)
    local now = os.time()
    if not mustSave then
        local lastSaveTime = lastSaveTime[player] or 0
        if now - lastSaveTime < 5 then return end
    end
    lastSaveTime[player] = now
    -- Save the stats to storage and handle any errors
    Storage.SetPlayerValue(player, "PlayerStats", numberizeRecursive(players[player]), function(errorCode)
    end)
end

-- Function to track players joining and leaving the game
local function TrackPlayers(game, characterCallback)
    -- Connect to the event when a player joins the game
    scene.PlayerJoined:Connect(function(scene, player)
        -- Initialize player's stats and store them in the players table
        players[player] = {
            player = player,
            CashInCents = IntValue.new("CashInCents"..player.id, 0),
            upgrades = {},
        }

        if (client and (client.localPlayer == player)) or server then
            -- Connect to the event when the player's character changes (e.g., respawn)
            player.CharacterChanged:Connect(function(player, character)
                local playerinfo = players[player]
                -- If character is nil, do nothing
                if (character == nil) then
                    return
                end

                -- If a character callback function is provided, call it with the player information
                if characterCallback then
                    characterCallback(playerinfo)
                end
            end)
        end
        
        if server then
            core.ClaimFactory(player)
            core.displayOtherFactoriesOwnership(player)
        end
    end)

    -- Connect to the event when a player leaves the game
    scene.PlayerLeft:Connect(function(scene, player)
        if server then
            core.unclaimFactory(player)
            SaveStats(player, true)
        end
        players[player] = nil
    end)
end

-- Function to find the key with the maximum value in a table
local function findMaxKey(tbl)
    local maxKey = nil
    local maxValue = -math.huge -- Start with negative infinity as initial maximum value

    -- Iterate through the table to find the key with the maximum value
    for key, value in pairs(tbl) do
        if value > maxValue then
            maxValue = value
            maxKey = key
        elseif value == maxValue then
            maxValue = value
            maxKey = nil -- If there is a tie, set maxKey to nil
        end
    end

    return maxKey
end

local function printRecursive(input)
    output = "{"
    for key, val in pairs(input) do
        if key == "player" then continue end
        if type(val) == "table" then
            output ..= key..":"..printRecursive(val)
        elseif type(val) == "number" then
            output ..= (key..":"..val)
        else
            output ..= (key..":"..val.value)
        end
        output ..= ","
    end
    output ..="}"
    return output
end

--[[

    Client-side functionality

--]]

-- Function to initialize the client-side logic
function self:ClientAwake()
    -- Get the PlayerStatGui component from the game object to interact with the player's stat UI
    playerStatGui = self.gameObject:GetComponent(PlayerStatGui)

    -- Function to handle character instantiation for a player
    function OnCharacterInstantiate(playerinfo)
        local player = playerinfo.player
        local character = player.character
        if player == client.localPlayer then
            playerinfo.CashInCents.Changed:Connect(function(currentCashInCents, oldVal)
                -- Update the local UI to reflect the new cash value
                playerStatGui.SetCashUI(currentCashInCents)
            end)
            local destPos = core.getFactorySpawnPos()
            spawnRequest:FireServer(destPos)
        end
    end

    -- Function to increment a specific stat by a given value
    function IncrementStat(stat, value, mustSave)
        incrementStatRequest:FireServer(stat, value, mustSave)
    end

    function BuyUpgrade(upgradeName, prereqName, prereqLevel)
        buyUpgradeRequest:FireServer(upgradeName, prereqName, prereqLevel)
    end

    -- Request the server to send the player's stats
    getStatsRequest:FireServer()

    refreshUIRequest:Connect(function(playerinfo)
        local cashInCents = playerinfo.CashInCents
        local prestigeLvl = playerinfo.upgrades.Prestige and playerinfo.upgrades.Prestige or 0
        playerStatGui.SetCashUI(cashInCents)
        playerStatGui.SetPrestigeUI(core.getPrestigeStr(prestigeLvl))
    end)

    function refreshUpgradeUIs(player, uiTable)
        if client.localPlayer == player then
            getUpgradeLevelsRequest:FireServer(uiTable)
        else
            print("???")
        end
    end

    refreshUpgradeUIRequest:Connect(function(upgradeLevels)
        core.refreshUpgradeUIs(upgradeLevels)
    end)

    refreshWallStatsRequest:Connect(function(player, playerinfo)
        local cashInCents = playerinfo.CashInCents
        local prestigeLvl = playerinfo.upgrades.Prestige and playerinfo.upgrades.Prestige or 0
        core.setFactoryWallCash(player, cashInCents)
        core.setFactoryWallPrestige(player, prestigeLvl)
    end)

    function reset()
        resetRequest:FireServer()
        playerStatGui.SetCashUI(0)
        playerStatGui.SetPrestigeUI(core.getPrestigeStr(0))
    end

    audioRequest:Connect(function(track)
        Audio:PlayShader(sfx[track])
    end)

    function playSFX(track)
        Audio:PlayShader(sfx[track])
    end

    spawnClientRequest:Connect(function(player, destPos)
        player.character:Teleport(destPos)
    end)

    -- Track players joining and leaving, and handle character instantiation
    TrackPlayers(client, OnCharacterInstantiate)
end

--[[

    Server-side functionality

--]]

local function setValuesRecursive(input, output, player)
    for key, val in pairs(input) do
        if type(val) == "table" then
            setValuesRecursive(val, output[key], player)
        else
            local outVal = output[key]
            if outVal then
                output[key].value = val
            else
                output[key] = IntValue.new(key..player.id, val)
            end
        end
    end
end

local function zeroOutRecursive(t)
    for key, val in pairs(t) do
        if type(val) == "table" then
            zeroOutRecursive(t)
        else
            val.value = 0
        end
    end
end

-- Function to initialize the server-side logic
function self:ServerAwake()
    -- Track players joining and leaving the game
    TrackPlayers(server)
    
    -- autosave every 10 seconds.
    Timer.Every(10, function()
        for player, _ in pairs(players) do
            SaveStats(player)
        end
    end)

    function getUpgradeLvl(player, upgradeName)
        local stats = players[player]
        local lvl = 0
        local stat = stats.upgrades[upgradeName]
        if stat then
            lvl = stat.value
        end
        return lvl
    end

    -- Fetch a player's stats from storage when they join
    getStatsRequest:Connect(function(player)
        Storage.GetPlayerValue(player, "PlayerStats", function(stats)
            -- If no existing stats are found, create default stats
            if stats == nil then
                stats = defaultStats
                Storage.SetPlayerValue(player, "PlayerStats", stats) 
            end
            -- print(printRecursive(stats))
            -- Update the player's current networked stats from storage
            setValuesRecursive(stats, players[player], player)

            local ownedUpgrades = players[player].upgrades
            if not ownedUpgrades then
                players[player].upgrades = {}
            end
            local numberized = numberizeRecursive(players[player])
            refreshUIRequest:FireClient(player, numberized)
            refreshUpgradeUIRequest:FireClient(player, numberized.upgrades)
            refreshWallStatsRequest:FireAllClients(player, numberized)
        end)
    end)

    -- Save the player's stats when requested by the client
    saveStatsRequest:Connect(function(player)
        SaveStats(player, true)
    end)

    -- Increment a player's stat when requested by the client
    incrementStatRequest:Connect(function(player, stat, value, mustSave)
        players[player][stat].value += value
        -- Save the updated stats to storage
        SaveStats(player, mustSave)
        refreshWallStatsRequest:FireAllClients(player, numberizeRecursive(players[player]))
    end)

    buyUpgradeRequest:Connect(function(player, upgradeName, prereqName, prereqLevel)
        if prereqName ~= "" then
            if not players[player].upgrades[prereqName] or players[player].upgrades[prereqName].value < prereqLevel then
                audioRequest:FireClient(player, "Fail")
                core.createUpgradeText(player, upgradeName, "Red", "LOCKED!")
                return
            end
        end
        local upgradeLevel = 0
        local upgradeItem = players[player].upgrades[upgradeName]
        if upgradeItem then
            upgradeLevel = upgradeItem.value
        end
        local upgradeCost = core.getUpgradeCost(upgradeName, upgradeLevel)
        if players[player].CashInCents.value >= upgradeCost*100 then
            players[player].CashInCents.value -= upgradeCost*100
            if upgradeItem then
                upgradeItem.value += 1
            else
                players[player].upgrades[upgradeName] = IntValue.new(upgradeName..player.id, 1)
            end
            if upgradeName == "Prestige" then
                players[player].CashInCents.value = 0
                zeroOutRecursive(players[player].upgrades)
                players[player].upgrades["Prestige"].value = upgradeLevel + 1
                core.resetFactory(player)
                refreshUIRequest:FireClient(player, numberizeRecursive(players[player]))
            else
                core.setFactoryUpgradeLvl(player, upgradeName, upgradeLevel + 1)
            end
            SaveStats(player, true)
            audioRequest:FireClient(player, "Spend")
            core.createUpgradeText(player, upgradeName, "Green", "Purchased!")
            refreshWallStatsRequest:FireAllClients(player, numberizeRecursive(players[player]))
        else
            audioRequest:FireClient(player, "Fail")
            core.createUpgradeText(player, upgradeName, "Red", "Can't afford!")
        end
    end)

    getUpgradeLevelsRequest:Connect(function(player, uiTable)
        local upgradeLevels = {}
        for upgradeName, _ in uiTable do
            upgradeLevels[upgradeName] = getUpgradeLvl(player, upgradeName)
        end
        refreshUpgradeUIRequest:FireClient(player, upgradeLevels)
    end)

    resetRequest:Connect(function(player)
        players[player].CashInCents.value = defaultStats.CashInCents
        zeroOutRecursive(players[player].upgrades)
        SaveStats(player, true)
        -- Storage.SetPlayerValue(player, "PlayerStats", numberizeRecursive(players[player]))
        local numberized = numberizeRecursive(players[player])
        refreshUIRequest:FireClient(player, numberized)
        refreshWallStatsRequest:FireAllClients(player, numberized)
    end)

    function playSFX(player, track)
        audioRequest:FireClient(player, track)
    end

    spawnRequest:Connect(function(player, destPos)
        player.character.transform.position = destPos
        spawnClientRequest:FireAllClients(player, destPos)
    end)
end
