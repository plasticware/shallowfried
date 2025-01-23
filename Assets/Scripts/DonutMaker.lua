--!Type(Client)

--!SerializeField
local label : GameObject = nil

-- local full = false

-- function isFull()
--     return full
-- end

-- function self:OnTriggerEnter(other : Collider)
--     local enteringGameObject = other.gameObject
--     print(enteringGameObject.name .. " has entered the trigger")
--     if enteringGameObject.name == "Donut" then
--         full = true
--     end
-- end

-- function self:OnTriggerExit(other : Collider)
--     local exitingGameObject = other.gameObject
--     print(exitingGameObject.name .. " has left the trigger")
--     if enteringGameObject.name == "Donut" then
--         full = false
--     end
-- end

function getLabel()
    return label
end