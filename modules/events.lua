local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Add event handling logic here
    end
end)

frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGOUT" then
        -- Add logout handling logic here
    end
end)

frame:RegisterEvent("UNIT_HEALTH")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_HEALTH" then
        local unit = ...
        -- Add health update logic here for the specified unit
    end
end)