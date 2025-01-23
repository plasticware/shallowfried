--!Type(UI)

--!Bind
local Title : UILabel = nil
--!Bind
local Amount : UILabel = nil
--!Bind
local CountdownTitle : UILabel = nil
--!Bind
local Countdown : UISlider = nil

-- Variables for meter control
local duration = 10
local elapsedTime = 0
local value = 0
local animating = false

function setText(amount)
    Amount:SetPrelocalizedText(amount)
end

function self:Start()
    Title:SetPrelocalizedText("Donuts stored:")
    Amount:SetPrelocalizedText(0)
    CountdownTitle:SetPrelocalizedText("Next Donut Batch:")
    Countdown.lowValue, Countdown.highValue = 0, 100
end

-- Function to start the meter with specified durations
function StartMeter(duration_)
    duration = duration_
    elapsedTime = 0
    value = 0
    animating = true
    Countdown:SetValueWithoutNotify(0)
end

function CancelMeter()
    elapsedTime = 0
    value = 0
    animating = false
    Countdown:SetValueWithoutNotify(0)
end

function self:Update()
    if animating then
        elapsedTime = elapsedTime + Time.deltaTime
        local t = Mathf.Clamp01(elapsedTime / duration)
        value = Mathf.Lerp(0.0, 1.0, t)
        Countdown:SetValueWithoutNotify(value * 100)
        if t >= 1 then
            t = 1
            animating = false
            elapsedTime = 0
            Countdown:SetValueWithoutNotify(0)
        end
    end
end