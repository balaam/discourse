
StateStack = {}
StateStack.__index = StateStack
function StateStack:Create()
    local this =
    {
        mStates = {}
    }

    setmetatable(this, self)
    return this
end

function StateStack:IsEmpty()
    return not next(self.mStates)
end

function StateStack:Push(state)
    table.insert(self.mStates, state)
    state:Enter()
end

function StateStack:Pop()

    local top = self.mStates[#self.mStates]
    table.remove(self.mStates)
    top:Exit()
    return top
end

function StateStack:Top()
    return self.mStates[#self.mStates]
end

function StateStack:Step()
    local top = self.mStates[#self.mStates]

    if not top then
        return
    end

    top:Step()
end

function StateStack:Render(renderer)
    for _, v in ipairs(self.mStates) do
        v:Render(renderer)
    end
end
