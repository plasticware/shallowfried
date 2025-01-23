--!Type(UI)

--!Bind
local Title : UILabel = nil
--!Bind
local Description : UILabel = nil
--!Bind
local Level : UILabel = nil
--!Bind
local Cost : UILabel = nil

local playerManager = require("PlayerManager")

function setText(titleStr, descStr, lvlStr, costStr)
    Title:SetPrelocalizedText(titleStr)
    Description:SetPrelocalizedText(descStr)
    Level:SetPrelocalizedText(lvlStr)
    Cost:SetPrelocalizedText(costStr)
end

function setWallCash(str)
    Description:SetPrelocalizedText(str)
end

function setWallPrestige(str)
    Level:SetPrelocalizedText(str)
end