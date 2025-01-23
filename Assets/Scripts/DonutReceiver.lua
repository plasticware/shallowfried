--!SerializeField
local factory : GameObject = nil

function self:ClientAwake()
    function self:OnTriggerEnter(other : Collider)
        local enteringGameObject = other.gameObject
        print(enteringGameObject.name .. " has entered the trigger")
        if enteringGameObject.name == "Donut" then
            local donutScript = enteringGameObject:GetComponent("Donut")
            local factoryScript = factory:GetComponent("FactoryScript")
            factoryScript.FinishDonut(enteringGameObject, donutScript.Attrs)
        end
    end
    function self:OnCollisionEnter(other : Collider)
        local enteringGameObject = other.gameObject
        print(enteringGameObject.name .. " has entered the collider")
        if enteringGameObject.name == "Donut" then
            local donutScript = enteringGameObject:GetComponent("Donut")
            local factoryScript = factory:GetComponent("FactoryScript")
            factoryScript.FinishDonut(enteringGameObject, donutScript.Attrs)
        end
    end
end