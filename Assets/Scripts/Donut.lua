local factory : GameObject = nil
local factoryScript = nil

Attrs = {
    id = "",
    donutType = "",
    orig = Vector3.new(0,0,0),
    dest = Vector3.new(0,0,0),
    travelTime = 10.0,
}

local glazerDist = math.huge

function setFactory(f)
    factory = f
    factoryScript = factory:GetComponent("FactoryScript")
    glazerDist = (factoryScript.getGlazerPos() - factoryScript.getMakerPos()).magnitude
end

function GetAttrs()
    return Attrs
end

function SetAttrs(newAttrs)
    for attr, _ in pairs(Attrs) do
        if newAttrs[attr] then
            Attrs[attr] = newAttrs[attr]
        end
    end
end

function self:ServerAwake()
end

function self:ClientAwake()
end

function self:Update()
    local oldPos = self.gameObject.transform.position
    local totalDist = (Attrs.dest - Attrs.orig)
    self.gameObject.transform.position += (Attrs.dest - Attrs.orig) * Time.deltaTime / Attrs.travelTime
    local newPos = self.gameObject.transform.position

    if not Attrs["glazed"] and (self.gameObject.transform.position - factoryScript.getMakerPos()).magnitude >= glazerDist then
        Attrs["glazed"] = true
        Attrs["glazeMult"] = factoryScript.getGlazeMult()
        if factoryScript.getGlazeMult() > 1 then
            factoryScript.makeGlazeParticles()
        end
    end
end

-- function self:OnTriggerEnter(other : Collider)
--     local enteringGameObject = other.gameObject
--     print(enteringGameObject.name .. " has entered the trigger")
--     -- if enteringGameObject.name == "Donut" then
--     --     local donutScript = enteringGameObject:GetComponent("Donut")
--     --     local factoryScript = factory:GetComponent("FactoryScript")
--     --     factoryScript.FinishDonut(enteringGameObject, donutScript.Attrs)
--     -- end
-- end