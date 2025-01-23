--!Type(Client)

--!SerializeField
local label : GameObject = nil

function getLabel()
    return label
end

function animateTo(pos)
    self.transform:TweenPosition(self.transform.position, pos)
        :Duration(2)
        :EaseInOutCubic()
        :Play();
    Timer.After(2, function()
        Object.Destroy(self.gameObject)
    end)
end