--!Type(UI)

--!Bind
-- Binding the UILabel for displaying the player's current cash amount
local cashCount : UILabel = nil

--!Bind
-- Binding the UILabel for displaying the player's current experience points
local prestige : UILabel = nil

-- Importing the PlayerManager module to handle player-related functionalities
local playerManager = require("PlayerManager")

-- Function to set the cash count on the UI
function SetCashUI(cashInCents)
    -- Converts the cash amount to string and updates the UI
    cashCount:SetPrelocalizedText(tostring(math.floor(cashInCents/100)), true)
end

-- Function to set the experience points on the UI
function SetPrestigeUI(str)
    -- Converts XP to a formatted string to display progression and updates the UI
    prestige:SetPrelocalizedText(str, true)
end

-- Initialize the UI with default values for cash, and XP
SetCashUI(0)
