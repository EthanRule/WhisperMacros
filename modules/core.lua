local frame = CreateFrame("Frame")

-- Core initialization routines
function frame:Initialize()
    -- Add core initialization logic here
end

-- Utility functions
function frame:SomeUtilityFunction()
    -- Add utility function logic here
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        self:Initialize()
    end
end)