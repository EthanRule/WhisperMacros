-- Addon Name
local addonName = "WhisperMacros"
local addon = CreateFrame("Frame", addonName, UIParent)

-- Utility function for string trimming
local function trim(s)
    return s and s:match("^%s*(.-)%s*$") or ""
end

-- Function to get spec icon path
local function GetSpecIcon(class, spec)
    if not class or not spec then
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    
    local specIcons = {
        -- Death Knight
        ["DEATHKNIGHT"] = {
            ["Blood"] = "Interface\\Icons\\Spell_Deathknight_BloodPresence",
            ["Frost"] = "Interface\\Icons\\Spell_Deathknight_FrostPresence",
            ["Unholy"] = "Interface\\Icons\\Spell_Deathknight_UnholyPresence"
        },
        -- Demon Hunter
        ["DEMONHUNTER"] = {
            ["Havoc"] = "Interface\\Icons\\Ability_DemonHunter_SpecDPS",
            ["Vengeance"] = "Interface\\Icons\\Ability_DemonHunter_SpecTank"
        },
        -- Druid
        ["DRUID"] = {
            ["Balance"] = "Interface\\Icons\\Spell_Nature_StarFall",
            ["Feral"] = "Interface\\Icons\\Ability_Druid_CatForm",
            ["Guardian"] = "Interface\\Icons\\Ability_Racial_BearForm",
            ["Restoration"] = "Interface\\Icons\\Spell_Nature_HealingTouch"
        },
        -- Evoker
        ["EVOKER"] = {
            ["Devastation"] = "Interface\\Icons\\ClassIcon_Evoker_Devastation",
            ["Preservation"] = "Interface\\Icons\\ClassIcon_Evoker_Preservation",
            ["Augmentation"] = "Interface\\Icons\\ClassIcon_Evoker_Augmentation"
        },
        -- Hunter
        ["HUNTER"] = {
            ["Beast"] = "Interface\\Icons\\Ability_Hunter_BeastMastery",
            ["Marksmanship"] = "Interface\\Icons\\Ability_Hunter_FocusedAim",
            ["Survival"] = "Interface\\Icons\\Ability_Hunter_Camouflage"
        },
        -- Mage
        ["MAGE"] = {
            ["Arcane"] = "Interface\\Icons\\Spell_Holy_MagicalSentry",
            ["Fire"] = "Interface\\Icons\\Spell_Fire_FlameBolt",
            ["Frost"] = "Interface\\Icons\\Spell_Frost_FrostBolt02"
        },
        -- Monk
        ["MONK"] = {
            ["Brewmaster"] = "Interface\\Icons\\Spell_Monk_BrewmasterSpec",
            ["Mistweaver"] = "Interface\\Icons\\Spell_Monk_MistweaverSpec",
            ["Windwalker"] = "Interface\\Icons\\Spell_Monk_WindwalkerSpec"
        },
        -- Paladin
        ["PALADIN"] = {
            ["Holy"] = "Interface\\Icons\\Spell_Holy_HolyBolt",
            ["Protection"] = "Interface\\Icons\\Ability_Paladin_ShieldofVengeance",
            ["Retribution"] = "Interface\\Icons\\Spell_Holy_AuraOfLight"
        },
        -- Priest
        ["PRIEST"] = {
            ["Discipline"] = "Interface\\Icons\\Spell_Holy_PowerWordShield",
            ["Holy"] = "Interface\\Icons\\Spell_Holy_GuardianSpirit",
            ["Shadow"] = "Interface\\Icons\\Spell_Shadow_ShadowWordPain"
        },
        -- Rogue
        ["ROGUE"] = {
            ["Assassination"] = "Interface\\Icons\\Ability_Rogue_Eviscerate",
            ["Outlaw"] = "Interface\\Icons\\INV_Sword_30",
            ["Subtlety"] = "Interface\\Icons\\Ability_Stealth"
        },
        -- Shaman
        ["SHAMAN"] = {
            ["Elemental"] = "Interface\\Icons\\Spell_Nature_Lightning",
            ["Enhancement"] = "Interface\\Icons\\Spell_Shaman_ImprovedStormstrike",
            ["Restoration"] = "Interface\\Icons\\Spell_Nature_MagicImmunity"
        },
        -- Warlock
        ["WARLOCK"] = {
            ["Affliction"] = "Interface\\Icons\\Spell_Shadow_DeathCoil",
            ["Demonology"] = "Interface\\Icons\\Spell_Shadow_Metamorphosis",
            ["Destruction"] = "Interface\\Icons\\Spell_Shadow_RainOfFire"
        },
        -- Warrior
        ["WARRIOR"] = {
            ["Arms"] = "Interface\\Icons\\Ability_Warrior_SavageBlow",
            ["Fury"] = "Interface\\Icons\\Ability_Warrior_InnerRage",
            ["Protection"] = "Interface\\Icons\\Ability_Warrior_DefensiveStance"
        }
    }
    
    local classUpper = class:upper()
    if specIcons[classUpper] and specIcons[classUpper][spec] then
        return specIcons[classUpper][spec]
    end
    
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Saved Variables (will be automatically saved/loaded by WoW)
WhisperMacrosDB = WhisperMacrosDB or {}

-- Tutorial state variables (not saved, reset each session)
local tutorialHasBeenParsed = false
local tutorialWhisperMessageEdited = false
local tutorialPlayerListTabVisited = false

-- Tutorial glow animation variables
local playerListAnimGroups = {}
local helpTabAnimGroups = {}
local playerListBorderFrame = nil
local helpTabBorderFrame = nil
local helpTabTutorialFrame = nil -- Frame for the glowing command text in Help tab

-- Initialize default settings
local function InitializeDefaults()
    if not WhisperMacrosDB.players then
        WhisperMacrosDB.players = {}
    end
    if not WhisperMacrosDB.playerData then
        WhisperMacrosDB.playerData = {}
    end
    if not WhisperMacrosDB.whisperedPlayers then
        WhisperMacrosDB.whisperedPlayers = {}
    end
    if WhisperMacrosDB.removeAfterWhisper == nil then
        WhisperMacrosDB.removeAfterWhisper = true
    end
    if WhisperMacrosDB.showTips == nil then
        WhisperMacrosDB.showTips = true
    end
    if not WhisperMacrosDB.whisperMessage then
        WhisperMacrosDB.whisperMessage = "Hey want to run 3s sometime? I'm a 2100cr boomy with 2600exp. My btag is Bob#12345."
    end
end

-- Variables
local mainFrame = nil
local currentTab = 1
local tabButtons = {}
local tabContent = {}
local copyFrame = nil -- Track the URL copy frame

-- Function to parse player data from text input
local function ParsePlayerData(text)
    local newPlayers = {}
    local lines = {strsplit("\n", text)}
    
    for _, line in ipairs(lines) do
        if line and trim(line) ~= "" then
            -- Use a more flexible approach: split by multiple whitespace characters
            -- This handles tabs, multiple spaces, or mixed whitespace
            local cleanLine = line:gsub("%s+", " ") -- Replace multiple whitespace with single space
            local words = {strsplit(" ", cleanLine)}
            
            if #words >= 4 then
                local rank = trim(words[1])
                local rating = trim(words[2])
                local name = trim(words[3])
                local realm = trim(words[4])
                
                -- Initialize additional data variables
                local faction, race, gender, class, spec, winrate = nil, nil, nil, nil, nil, nil
                local wordIndex = 5
                
                -- Handle realm names with spaces dynamically
                if #words >= 5 then
                    local nextWord = trim(words[5])
                    -- If the next word is not a faction name, it's probably part of the realm
                    if nextWord:lower() ~= "alliance" and nextWord:lower() ~= "horde" then
                        realm = realm .. " " .. nextWord
                        wordIndex = 6
                    end
                end
                
                -- Extract additional information if available
                if #words >= wordIndex then
                    faction = words[wordIndex] -- Alliance/Horde
                    if #words >= wordIndex + 1 then race = words[wordIndex + 1] end
                    if #words >= wordIndex + 2 then gender = words[wordIndex + 2] end
                    if #words >= wordIndex + 3 then class = words[wordIndex + 3] end
                    if #words >= wordIndex + 4 then spec = words[wordIndex + 4] end
                    
                    -- Look for winrate percentage at the end
                    for i = #words, 1, -1 do
                        if words[i] and words[i]:match("%.%d+%%") then
                            winrate = words[i]
                            break
                        end
                    end
                end
                
                -- Validate that rank and rating are numbers (basic validation)
                if tonumber(rank) and tonumber(rating) and name ~= "" and realm ~= "" then
                    -- Remove spaces from realm names to make them one word
                    realm = realm:gsub(" ", "")
                    
                    local playerString = name .. "-" .. realm
                    table.insert(newPlayers, playerString)
                    
                    -- Store additional player data
                    WhisperMacrosDB.playerData[playerString] = {
                        rank = tonumber(rank),
                        rating = tonumber(rating),
                        faction = faction,
                        race = race,
                        gender = gender,
                        class = class,
                        spec = spec,
                        winrate = winrate
                    }
                    
                    print("Added: " .. playerString .. " (Rating: " .. rating .. ", Spec: " .. (spec or "Unknown") .. ", Winrate: " .. (winrate or "Unknown") .. ")")
                else
                    print("Skipped line - invalid data format")
                end
            else
                print("Skipped line - not enough columns")
            end
        end
    end
    
    print("Total players parsed: " .. #newPlayers)
    return newPlayers
end

-- Function to add players to saved list
local function AddPlayersToList(players)
    for _, player in ipairs(players) do
        -- Check if player already exists in main list
        local existsInMain = false
        for _, existingPlayer in ipairs(WhisperMacrosDB.players) do
            if existingPlayer == player then
                existsInMain = true
                break
            end
        end
        
        -- Check if player already exists in whispered list
        local existsInWhispered = false
        for _, whisperedPlayer in ipairs(WhisperMacrosDB.whisperedPlayers) do
            if whisperedPlayer == player then
                existsInWhispered = true
                break
            end
        end
        
        -- Only add if player doesn't exist in either list
        if not existsInMain and not existsInWhispered then
            table.insert(WhisperMacrosDB.players, player)
        elseif existsInWhispered then
            print("Skipped " .. player .. " (already whispered)")
        end
    end
end

-- Function to create tab buttons
local function CreateTabButton(parent, text, index, onClick)
    local button = CreateFrame("Button", nil, parent)
    -- Make the "Already Whispered" tab wider to accommodate the text
    local buttonWidth = (text == "Already Whispered") and 140 or 100
    button:SetSize(buttonWidth, 28)
    
    -- Custom styling instead of UIPanelButtonTemplate
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(button)
    bg:SetColorTexture(0.15, 0.15, 0.2, 0.8)
    button.bg = bg
    
    local border = button:CreateTexture(nil, "BORDER")
    border:SetAllPoints(button)
    border:SetColorTexture(0.25, 0.25, 0.3, 1)
    button.border = border
    
    local innerBg = button:CreateTexture(nil, "ARTWORK")
    innerBg:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    innerBg:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    innerBg:SetColorTexture(0.18, 0.18, 0.25, 0.9)
    button.innerBg = innerBg
    
    -- Button text
    local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buttonText:SetPoint("CENTER", button, "CENTER", 0, 0)
    buttonText:SetText(text)
    button.text = buttonText
    
    -- Adjust spacing to account for wider buttons
    local spacing = (text == "Already Whispered") and 145 or 105
    local xOffset = 10
    if index == 1 then
        xOffset = 10
    elseif index == 2 then
        xOffset = 10 + 105
    elseif index == 3 then
        xOffset = 10 + 105 + 105
    elseif index == 4 then
        xOffset = 10 + 105 + 105 + 145
    end
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -42)
    
    -- Hover effects
    button:SetScript("OnEnter", function()
        if button:IsEnabled() then
            button.innerBg:SetColorTexture(0.25, 0.35, 0.5, 0.9)
            button.text:SetTextColor(1, 1, 1, 1)
        end
    end)
    
    button:SetScript("OnLeave", function()
        if button:IsEnabled() then
            button.innerBg:SetColorTexture(0.18, 0.18, 0.25, 0.9)
            button.text:SetTextColor(0.9, 0.9, 0.9, 1)
        end
    end)
    
    button:SetScript("OnClick", function()
        currentTab = index
        -- Update all tab button states
        for i, tabButton in ipairs(tabButtons) do
            if i == index then
                -- Active tab styling
                tabButton:Disable()
                tabButton.innerBg:SetColorTexture(0.3, 0.5, 0.8, 1)
                tabButton.text:SetText("|cffffffff" .. text .. "|r")
                tabButton.text:SetTextColor(1, 1, 1, 1)
            else
                -- Inactive tab styling
                tabButton:Enable()
                tabButton.innerBg:SetColorTexture(0.18, 0.18, 0.25, 0.9)
                local originalText = tabButton.text:GetText():gsub("|c........", ""):gsub("|r", "")
                tabButton.text:SetText(originalText)
                tabButton.text:SetTextColor(0.9, 0.9, 0.9, 1)
            end
        end
        onClick()
    end)
    
    table.insert(tabButtons, button)
    return button
end

-- Function to create the main interface
local function CreateMainInterface()
    if mainFrame then
        mainFrame:Show()
        return
    end
    
    -- Clear tab buttons array and content
    tabButtons = {}
    tabContent = {}
    
    -- Main frame - Custom styled instead of BasicFrameTemplateWithInset
    mainFrame = CreateFrame("Frame", "WhisperMacrosMainFrame", UIParent)
    mainFrame:SetSize(600, 500)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:SetFrameStrata("DIALOG")
    
    -- Custom background with gradient effect
    local bg = mainFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(mainFrame)
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.95) -- Dark blue-gray with transparency
    
    -- Main border
    local border = mainFrame:CreateTexture(nil, "BORDER")
    border:SetAllPoints(mainFrame)
    border:SetColorTexture(0.2, 0.25, 0.35, 1) -- Lighter border
    
    -- Inner area (inset)
    local innerBg = mainFrame:CreateTexture(nil, "ARTWORK")
    innerBg:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 2, -2)
    innerBg:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -2, 2)
    innerBg:SetColorTexture(0.08, 0.08, 0.12, 0.98)
    
    -- Top accent line
    local topAccent = mainFrame:CreateTexture(nil, "OVERLAY")
    topAccent:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 2, -2)
    topAccent:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -2)
    topAccent:SetHeight(2)
    topAccent:SetColorTexture(0.3, 0.6, 1, 0.8) -- Blue accent
    
    -- Title bar area
    local titleBg = mainFrame:CreateTexture(nil, "ARTWORK")
    titleBg:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 2, -2)
    titleBg:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -2)
    titleBg:SetHeight(35)
    titleBg:SetColorTexture(0.12, 0.12, 0.18, 0.9)
    
    -- Close button (X)
    local closeButton = CreateFrame("Button", nil, mainFrame)
    closeButton:SetSize(20, 20)
    closeButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -8, -8)
    closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    closeButton:SetScript("OnClick", function() mainFrame:Hide() end)
    
    -- Modern title text
    mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    mainFrame.title:SetPoint("TOP", mainFrame, "TOP", 0, -12)
    mainFrame.title:SetText("|cff4da6ffWhisper Macros|r") -- Blue colored title
    
    -- Tab buttons
    local addPlayersTab = CreateTabButton(mainFrame, "Add Players", 1, function() ShowAddPlayersTab() end)
    local playerListTab = CreateTabButton(mainFrame, "Player List", 2, function() ShowPlayerListTab() end)
    local whisperedTab = CreateTabButton(mainFrame, "Already Whispered", 3, function() ShowWhisperedTab() end)
    local helpTab = CreateTabButton(mainFrame, "Help", 4, function() ShowHelpTab() end)
    
    -- Tips checkbox in top right
    local tipsCheckbox = CreateFrame("CheckButton", nil, mainFrame, "UICheckButtonTemplate")
    tipsCheckbox:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -40, -40)
    tipsCheckbox:SetChecked(WhisperMacrosDB.showTips)
    tipsCheckbox:SetScript("OnClick", function()
        WhisperMacrosDB.showTips = tipsCheckbox:GetChecked()
        -- Refresh current tab to apply/remove tips
        if currentTab == 1 then
            ShowAddPlayersTab()
        end
    end)
    
    local tipsLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tipsLabel:SetPoint("RIGHT", tipsCheckbox, "LEFT", -5, 0)
    tipsLabel:SetText("Tips")
    
    -- Content area with modern styling
    mainFrame.content = CreateFrame("Frame", nil, mainFrame)
    mainFrame.content:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 8, -78)
    mainFrame.content:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -8, 8)
    
    -- Content background
    local contentBg = mainFrame.content:CreateTexture(nil, "BACKGROUND")
    contentBg:SetAllPoints(mainFrame.content)
    contentBg:SetColorTexture(0.06, 0.06, 0.1, 0.95)
    
    -- Content border
    local contentBorder = mainFrame.content:CreateTexture(nil, "BORDER")
    contentBorder:SetAllPoints(mainFrame.content)
    contentBorder:SetColorTexture(0.2, 0.2, 0.3, 0.8)
    
    -- Content inner area
    local contentInner = mainFrame.content:CreateTexture(nil, "ARTWORK")
    contentInner:SetPoint("TOPLEFT", mainFrame.content, "TOPLEFT", 1, -1)
    contentInner:SetPoint("BOTTOMRIGHT", mainFrame.content, "BOTTOMRIGHT", -1, 1)
    contentInner:SetColorTexture(0.08, 0.08, 0.13, 0.98)
    
    -- Show first tab by default and set its state
    currentTab = 1
    addPlayersTab:Disable()
    addPlayersTab.innerBg:SetColorTexture(0.3, 0.5, 0.8, 1)
    addPlayersTab.text:SetText("|cffffffff" .. "Add Players" .. "|r")
    addPlayersTab.text:SetTextColor(1, 1, 1, 1)
    ShowAddPlayersTab()
end

-- Whisper functionality
local currentIndex = 1
local isWhispering = false
local whisperCount = 0
local totalWhispers = 0
local pendingWhispers = {} -- Track whispers waiting for confirmation

-- Function to handle whisper success/failure
local function OnWhisperResult(self, event, ...)
    if event == "CHAT_MSG_WHISPER_INFORM" then
        -- Whisper was sent successfully
        local message, playerName = ...
        if pendingWhispers[playerName] then
            print("Whisper confirmed sent to " .. playerName)
            
            -- Add to whispered list
            table.insert(WhisperMacrosDB.whisperedPlayers, playerName)
            
            -- Remove from main list if option is enabled
            if WhisperMacrosDB.removeAfterWhisper then
                for i, player in ipairs(WhisperMacrosDB.players) do
                    if player == playerName then
                        table.remove(WhisperMacrosDB.players, i)
                        break
                    end
                end
            end
            
            -- Clean up pending whisper
            pendingWhispers[playerName] = nil
        end
    elseif event == "CHAT_MSG_SYSTEM" then
        -- Check for whisper failure messages
        local message = ...
        -- Look for "No player named X is currently playing" or similar offline messages
        if message and (message:find("No player named") or message:find("is not online") or message:find("Player not found")) then
            -- Extract player name from the error message if possible
            local playerName = message:match("No player named '(.-)' is currently playing")
            if not playerName then
                playerName = message:match("'(.-)' is not online")
            end
            if not playerName then
                playerName = message:match("Player '(.-)' not found")
            end
            
            if playerName and pendingWhispers[playerName] then
                -- print("Whisper failed to " .. playerName .. " (player offline) - keeping in list")
                -- Don't add to whispered list, don't remove from main list
                pendingWhispers[playerName] = nil
            end
        end
    end
end

-- Function to send next whisper
local function SendNextWhisper()
    if currentIndex <= #WhisperMacrosDB.players then
        local playerName = WhisperMacrosDB.players[currentIndex]
        
        -- Check if we should skip whispered players
        local shouldSkip = false
        if WhisperMacrosDB.removeAfterWhisper then
            for _, whisperedPlayer in ipairs(WhisperMacrosDB.whisperedPlayers) do
                if whisperedPlayer == playerName then
                    shouldSkip = true
                    break
                end
            end
        end
        
        if not shouldSkip then
            whisperCount = whisperCount + 1
            
            -- Track this whisper as pending
            pendingWhispers[playerName] = true
            
            SendChatMessage(WhisperMacrosDB.whisperMessage, "WHISPER", nil, playerName)
            print("Sent whisper " .. whisperCount .. "/" .. totalWhispers .. " to " .. playerName .. "")
            
        else
            print("Skipping " .. playerName .. " (already whispered)")
        end
        
        currentIndex = currentIndex + 1
        
        -- Continue if there are more whispers
        if currentIndex <= #WhisperMacrosDB.players then
            C_Timer.After(1.5, SendNextWhisper) -- 1.5 second delay between whispers
        else
            -- Done sending all whispers
            isWhispering = false
            currentIndex = 1
            whisperCount = 0
            totalWhispers = 0
            
            -- Clean up any remaining pending whispers after a delay
            C_Timer.After(5, function()
                for playerName, _ in pairs(pendingWhispers) do
                    print("Whisper to " .. playerName .. " timed out - assuming offline")
                    pendingWhispers[playerName] = nil
                end
            end)
            
            print("Finished sending whispers!")
        end
    end
end

-- Function to start whispering
local function StartWhispering()
    if isWhispering then
        print("Already sending whispers...")
        return
    end
    
    if #WhisperMacrosDB.players == 0 then
        print("No players in the list! Use /lfg to add players.")
        return
    end
    
    -- Count how many players we'll actually whisper (excluding already whispered ones)
    totalWhispers = 0
    for _, player in ipairs(WhisperMacrosDB.players) do
        local shouldSkip = false
        if WhisperMacrosDB.removeAfterWhisper then
            for _, whisperedPlayer in ipairs(WhisperMacrosDB.whisperedPlayers) do
                if whisperedPlayer == player then
                    shouldSkip = true
                    break
                end
            end
        end
        if not shouldSkip then
            totalWhispers = totalWhispers + 1
        end
    end
    
    if totalWhispers == 0 then
        print("All players have already been whispered!")
        return
    end
    
    isWhispering = true
    currentIndex = 1
    whisperCount = 0
    print("Starting to send whispers... (1.5s delay between each)")
    SendNextWhisper()
end

-- Function to clear content area
local function ClearContentArea()
    -- Clear all tab content more safely
    for i = 1, 4 do
        if tabContent[i] then
            -- Stop all animations and hide all children
            local children = {tabContent[i]:GetChildren()}
            for _, child in ipairs(children) do
                -- Stop any animations on this child
                local animGroups = {child:GetAnimationGroups()}
                for _, animGroup in ipairs(animGroups) do
                    animGroup:Stop()
                end
                -- Hide child but don't detach - just clear it
                child:Hide()
                child:ClearAllPoints()
            end
            -- Hide the content frame itself
            tabContent[i]:Hide()
            -- Recreate the content frame to ensure a clean slate
            tabContent[i] = nil
        end
    end
    
    -- Clean up Help tab tutorial frame if it exists
    if helpTabTutorialFrame then
        local animGroups = {helpTabTutorialFrame:GetAnimationGroups()}
        for _, animGroup in ipairs(animGroups) do
            animGroup:Stop()
        end
        helpTabTutorialFrame:Hide()
        helpTabTutorialFrame = nil
    end
    
    -- Reset all tutorial glow variables to ensure clean state
    if playerListBorderFrame then
        local animGroups = {playerListBorderFrame:GetAnimationGroups()}
        for _, animGroup in ipairs(animGroups) do
            animGroup:Stop()
        end
        playerListBorderFrame:Hide()
        playerListBorderFrame = nil
    end
    if helpTabBorderFrame then
        local animGroups = {helpTabBorderFrame:GetAnimationGroups()}
        for _, animGroup in ipairs(animGroups) do
            animGroup:Stop()
        end
        helpTabBorderFrame:Hide()
        helpTabBorderFrame = nil
    end
    
    -- Clear animation groups
    for _, animGroup in ipairs(playerListAnimGroups) do
        if animGroup then animGroup:Stop() end
    end
    for _, animGroup in ipairs(helpTabAnimGroups) do
        if animGroup then animGroup:Stop() end
    end
    playerListAnimGroups = {}
    helpTabAnimGroups = {}
end

-- Function to show specific tab content
local function ShowTabContent(tabIndex)
    ClearContentArea()
    
    -- Always create a fresh content frame
    tabContent[tabIndex] = CreateFrame("Frame", nil, mainFrame.content)
    tabContent[tabIndex]:SetAllPoints(mainFrame.content)
    tabContent[tabIndex]:Show()
    return tabContent[tabIndex]
end

    -- Glow utility functions for tutorial system
local function CreateGlowBorder(parent, thickness)
    local borderFrame = CreateFrame("Frame", nil, parent)
    borderFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", -thickness, thickness)
    borderFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", thickness, -thickness)
    borderFrame:SetFrameLevel(parent:GetFrameLevel() + 1)
    
    -- Create 4 border textures (top, bottom, left, right)
    local borders = {}
    
    -- Top border
    borders.top = borderFrame:CreateTexture(nil, "OVERLAY")
    borders.top:SetPoint("TOPLEFT", borderFrame, "TOPLEFT")
    borders.top:SetPoint("TOPRIGHT", borderFrame, "TOPRIGHT")
    borders.top:SetHeight(thickness)
    borders.top:SetColorTexture(0, 1, 0, 0.8)
    
    -- Bottom border
    borders.bottom = borderFrame:CreateTexture(nil, "OVERLAY")
    borders.bottom:SetPoint("BOTTOMLEFT", borderFrame, "BOTTOMLEFT")
    borders.bottom:SetPoint("BOTTOMRIGHT", borderFrame, "BOTTOMRIGHT")
    borders.bottom:SetHeight(thickness)
    borders.bottom:SetColorTexture(0, 1, 0, 0.8)
    
    -- Left border
    borders.left = borderFrame:CreateTexture(nil, "OVERLAY")
    borders.left:SetPoint("TOPLEFT", borderFrame, "TOPLEFT")
    borders.left:SetPoint("BOTTOMLEFT", borderFrame, "BOTTOMLEFT")
    borders.left:SetWidth(thickness)
    borders.left:SetColorTexture(0, 1, 0, 0.8)
    
    -- Right border
    borders.right = borderFrame:CreateTexture(nil, "OVERLAY")
    borders.right:SetPoint("TOPRIGHT", borderFrame, "TOPRIGHT")
    borders.right:SetPoint("BOTTOMRIGHT", borderFrame, "BOTTOMRIGHT")
    borders.right:SetWidth(thickness)
    borders.right:SetColorTexture(0, 1, 0, 0.8)
    
    return borderFrame, borders
end

local function CreatePulseAnimation(borders, infinite)
    local animGroups = {}
    
    for _, border in pairs(borders) do
        local animGroup = border:CreateAnimationGroup()
        if infinite then
            animGroup:SetLooping("REPEAT")
        else
            animGroup:SetLooping("NONE")
        end
        
        -- Fade out
        local fadeOut = animGroup:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(0.8)
        fadeOut:SetToAlpha(0.3)
        fadeOut:SetDuration(1.0)
        fadeOut:SetOrder(1)
        
        -- Fade in
        local fadeIn = animGroup:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0.3)
        fadeIn:SetToAlpha(0.8)
        fadeIn:SetDuration(1.0)
        fadeIn:SetOrder(2)
        
        table.insert(animGroups, animGroup)
    end
    
    return animGroups
end

local function StopAndHideBorders(animGroups, borderFrame)
    for _, animGroup in ipairs(animGroups) do
        if animGroup then animGroup:Stop() end
    end
    if borderFrame then borderFrame:Hide() end
end

-- Function to create modern styled buttons
local function CreateModernButton(parent, width, height, text)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)
    
    -- Button background layers
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(button)
    bg:SetColorTexture(0.15, 0.15, 0.2, 0.9)
    button.bg = bg
    
    local border = button:CreateTexture(nil, "BORDER")
    border:SetAllPoints(button)
    border:SetColorTexture(0.3, 0.4, 0.6, 1)
    button.border = border
    
    local innerBg = button:CreateTexture(nil, "ARTWORK")
    innerBg:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    innerBg:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    innerBg:SetColorTexture(0.2, 0.25, 0.35, 0.95)
    button.innerBg = innerBg
    
    -- Gradient effect
    local gradient = button:CreateTexture(nil, "OVERLAY")
    gradient:SetPoint("TOPLEFT", innerBg, "TOPLEFT", 0, 0)
    gradient:SetPoint("BOTTOMRIGHT", innerBg, "BOTTOMRIGHT", 0, 0)
    gradient:SetColorTexture(0.25, 0.35, 0.5, 0.3)
    button.gradient = gradient
    
    -- Button text
    local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buttonText:SetPoint("CENTER", button, "CENTER", 0, 0)
    buttonText:SetText(text)
    buttonText:SetTextColor(0.9, 0.9, 0.9, 1)
    button.text = buttonText
    
    -- Hover and click effects
    button:SetScript("OnEnter", function()
        button.innerBg:SetColorTexture(0.3, 0.4, 0.6, 0.95)
        button.gradient:SetColorTexture(0.4, 0.5, 0.7, 0.4)
        button.text:SetTextColor(1, 1, 1, 1)
    end)
    
    button:SetScript("OnLeave", function()
        button.innerBg:SetColorTexture(0.2, 0.25, 0.35, 0.95)
        button.gradient:SetColorTexture(0.25, 0.35, 0.5, 0.3)
        button.text:SetTextColor(0.9, 0.9, 0.9, 1)
    end)
    
    button:SetScript("OnMouseDown", function()
        button.innerBg:SetColorTexture(0.15, 0.2, 0.3, 0.95)
        button.gradient:SetColorTexture(0.2, 0.3, 0.4, 0.5)
    end)
    
    button:SetScript("OnMouseUp", function()
        button.innerBg:SetColorTexture(0.3, 0.4, 0.6, 0.95)
        button.gradient:SetColorTexture(0.4, 0.5, 0.7, 0.4)
    end)
    
    return button
end

-- Add Players Tab
function ShowAddPlayersTab()
    local contentFrame = ShowTabContent(1)
    
    -- Content is always cleared by ShowTabContent, so always recreate
    
    -- Instructions
    local instructions = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instructions:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, -10)
    instructions:SetText("Paste player data from PvP Leaderboard:")
    
    -- Text input area
    local scrollFrame = CreateFrame("ScrollFrame", nil, contentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetSize(540, 200)
    
    -- Add background to scroll frame with modern styling
    local bg = scrollFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(scrollFrame)
    bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
    
    -- Modern border for scroll frame
    local border = scrollFrame:CreateTexture(nil, "BORDER")
    border:SetAllPoints(scrollFrame)
    border:SetColorTexture(0.2, 0.25, 0.35, 0.8)
    
    -- Inner background
    local innerBg = scrollFrame:CreateTexture(nil, "ARTWORK")
    innerBg:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 2, -2)
    innerBg:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -2, 2)
    innerBg:SetColorTexture(0.08, 0.08, 0.12, 0.98)
    
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetSize(520, 200)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetTextColor(1, 1, 1, 1) -- White text
    editBox:SetTextInsets(8, 8, 8, 8) -- Add padding inside the edit box
    editBox:SetScript("OnEscapePressed", function() editBox:ClearFocus() end)
    
    -- Add placeholder text functionality
    local placeholderText = "Paste rows of player data here...\n\nExample:\n125 2725 Rudar Sargeras Alliance Night Elf Female Druid Balance Stay Hydrated 242 - 130 65.1%"
    
    local function UpdatePlaceholder()
        if editBox:GetText() == "" then
            editBox:SetText(placeholderText)
            editBox:SetTextColor(0.6, 0.6, 0.6, 1) -- Grey text for placeholder
        end
    end
    
    local function ClearPlaceholder()
        if editBox:GetText() == placeholderText then
            editBox:SetText("")
            editBox:SetTextColor(1, 1, 1, 1) -- White text for actual content
        end
    end
    
    editBox:SetScript("OnEditFocusGained", ClearPlaceholder)
    editBox:SetScript("OnEditFocusLost", UpdatePlaceholder)
    
    -- Set initial placeholder
    UpdatePlaceholder()
    
    scrollFrame:SetScrollChild(editBox)
    
    -- Find Players button (opens website) - positioned first with modern styling
    local findButton = CreateModernButton(contentFrame, 120, 32, "Find Players")
    findButton:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -10)
    findButton:SetScript("OnClick", function()
        -- Check if copy frame already exists and is shown
        if copyFrame and copyFrame:IsShown() then
            -- Bring existing frame to front
            copyFrame:Raise()
            return
        end
        
        local url = "https://www.pvpleaderboard.com/leaderboards/filter?leaderboard=3v3&region=US"
        
        -- Create a visible frame for copying URL with modern styling
        copyFrame = CreateFrame("Frame", nil, UIParent)
        copyFrame:SetSize(520, 180)
        copyFrame:SetPoint("CENTER")
        copyFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        copyFrame:SetFrameLevel(1000)
        copyFrame:SetToplevel(true)
        copyFrame:SetMovable(true)
        copyFrame:EnableMouse(true)
        copyFrame:RegisterForDrag("LeftButton")
        copyFrame:SetScript("OnDragStart", copyFrame.StartMoving)
        copyFrame:SetScript("OnDragStop", copyFrame.StopMovingOrSizing)
        
        -- Modern frame styling
        local bg = copyFrame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(copyFrame)
        bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
        
        local border = copyFrame:CreateTexture(nil, "BORDER")
        border:SetAllPoints(copyFrame)
        border:SetColorTexture(0.2, 0.25, 0.35, 1)
        
        local innerBg = copyFrame:CreateTexture(nil, "ARTWORK")
        innerBg:SetPoint("TOPLEFT", copyFrame, "TOPLEFT", 2, -2)
        innerBg:SetPoint("BOTTOMRIGHT", copyFrame, "BOTTOMRIGHT", -2, 2)
        innerBg:SetColorTexture(0.08, 0.08, 0.12, 0.98)
        
        -- Top accent line
        local topAccent = copyFrame:CreateTexture(nil, "OVERLAY")
        topAccent:SetPoint("TOPLEFT", copyFrame, "TOPLEFT", 2, -2)
        topAccent:SetPoint("TOPRIGHT", copyFrame, "TOPRIGHT", -2, -2)
        topAccent:SetHeight(2)
        topAccent:SetColorTexture(0.3, 0.6, 1, 0.8)
        
        -- Title bar area
        local titleBg = copyFrame:CreateTexture(nil, "ARTWORK")
        titleBg:SetPoint("TOPLEFT", copyFrame, "TOPLEFT", 2, -2)
        titleBg:SetPoint("TOPRIGHT", copyFrame, "TOPRIGHT", -2, -2)
        titleBg:SetHeight(35)
        titleBg:SetColorTexture(0.12, 0.12, 0.18, 0.9)
        
        -- Close button (X)
        local closeButton = CreateFrame("Button", nil, copyFrame)
        closeButton:SetSize(20, 20)
        closeButton:SetPoint("TOPRIGHT", copyFrame, "TOPRIGHT", -8, -8)
        closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
        closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
        closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
        closeButton:SetScript("OnClick", function() 
            copyFrame:Hide() 
            copyFrame = nil
        end)
        
        -- Title
        copyFrame.title = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        copyFrame.title:SetPoint("TOP", copyFrame, "TOP", 0, -12)
        copyFrame.title:SetText("|cff4da6ffPvP Leaderboard URL|r")
        
        -- Instructions
        local instructions = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        instructions:SetPoint("TOPLEFT", copyFrame, "TOPLEFT", 15, -45)
        instructions:SetText("Select all text below and copy it (Ctrl+C):")
        
        -- Create edit box with the URL
        local copyEditBox = CreateFrame("EditBox", nil, copyFrame, "InputBoxTemplate")
        copyEditBox:SetSize(480, 25)
        copyEditBox:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -10)
        copyEditBox:SetTextInsets(6, 6, 4, 4) -- Add padding inside the edit box
        copyEditBox:SetText(url)
        copyEditBox:SetAutoFocus(true)
        copyEditBox:HighlightText()
        copyEditBox:SetCursorPosition(0)
        copyEditBox:SetScript("OnEscapePressed", function()
            copyFrame:Hide()
            copyFrame = nil
        end)
        copyEditBox:SetScript("OnEnterPressed", function()
            copyFrame:Hide()
            copyFrame = nil
        end)
        
        -- More instructions
        local instructions2 = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        instructions2:SetPoint("TOPLEFT", copyEditBox, "BOTTOMLEFT", 0, -10)
        instructions2:SetText("1. Copy the URL above")
        
        local instructions3 = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        instructions3:SetPoint("TOPLEFT", instructions2, "BOTTOMLEFT", 0, -5)
        instructions3:SetText("2. Paste it in your web browser")
        
        local instructions4 = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        instructions4:SetPoint("TOPLEFT", instructions3, "BOTTOMLEFT", 0, -5)
        instructions4:SetText("3. Copy entire rows of player data from the website and paste it in the Add Players tab")
        
        copyFrame:Show()
        
        print("LFG Arena Tool: Copy the URL from the dialog and paste it in your browser!")
    end)
    
    -- Parse button - positioned to the right of Find Players button with modern styling
    local parseButton = CreateModernButton(contentFrame, 120, 32, "Parse Players")
    parseButton:SetPoint("LEFT", findButton, "RIGHT", 10, 0)
    
    -- Function to update parse button color based on text content
    local function UpdateParseButtonState()
        local text = editBox:GetText()
        local hasValidContent = text and trim(text) ~= "" and text ~= placeholderText
        
        if hasValidContent then
            -- Green color when text is available to parse
            parseButton.innerBg:SetColorTexture(0.2, 0.6, 0.2, 0.95)
            parseButton.gradient:SetColorTexture(0.3, 0.7, 0.3, 0.4)
            parseButton.border:SetColorTexture(0.3, 0.7, 0.3, 1)
        else
            -- Default color when no text
            parseButton.innerBg:SetColorTexture(0.2, 0.25, 0.35, 0.95)
            parseButton.gradient:SetColorTexture(0.25, 0.35, 0.5, 0.3)
            parseButton.border:SetColorTexture(0.3, 0.4, 0.6, 1)
        end
    end
    parseButton:SetScript("OnClick", function()
        local text = editBox:GetText()
        -- Don't parse if it's just the placeholder text
        if text and trim(text) ~= "" and text ~= placeholderText then
            local players = ParsePlayerData(text)
            if #players > 0 then
                AddPlayersToList(players)
                print("Added " .. #players .. " players to the list!")
                editBox:SetText("")
                UpdatePlaceholder() -- Show placeholder again after clearing
            else
                print("No valid players found in the text.")
            end
        else
            print("Please paste player data first.")
        end
    end)
    
    -- Whisper message customization area
    local whisperLabel = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    whisperLabel:SetPoint("TOPLEFT", findButton, "BOTTOMLEFT", 0, -20)
    whisperLabel:SetText("Whisper Message:")
    
    -- Whisper message text box
    local whisperScrollFrame = CreateFrame("ScrollFrame", nil, contentFrame, "UIPanelScrollFrameTemplate")
    whisperScrollFrame:SetPoint("TOPLEFT", whisperLabel, "BOTTOMLEFT", 0, -5)
    whisperScrollFrame:SetSize(540, 80)
    
    -- Add background to whisper scroll frame with modern styling
    local whisperBg = whisperScrollFrame:CreateTexture(nil, "BACKGROUND")
    whisperBg:SetAllPoints(whisperScrollFrame)
    whisperBg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
    
    -- Modern border for whisper scroll frame
    local whisperBorder = whisperScrollFrame:CreateTexture(nil, "BORDER")
    whisperBorder:SetAllPoints(whisperScrollFrame)
    whisperBorder:SetColorTexture(0.2, 0.25, 0.35, 0.8)
    
    -- Inner background for whisper scroll frame
    local whisperInnerBg = whisperScrollFrame:CreateTexture(nil, "ARTWORK")
    whisperInnerBg:SetPoint("TOPLEFT", whisperScrollFrame, "TOPLEFT", 2, -2)
    whisperInnerBg:SetPoint("BOTTOMRIGHT", whisperScrollFrame, "BOTTOMRIGHT", -2, 2)
    whisperInnerBg:SetColorTexture(0.08, 0.08, 0.12, 0.98)
    
    local whisperEditBox = CreateFrame("EditBox", nil, whisperScrollFrame)
    whisperEditBox:SetSize(520, 80)
    whisperEditBox:SetMultiLine(true)
    whisperEditBox:SetAutoFocus(false)
    whisperEditBox:SetFontObject("ChatFontNormal")
    whisperEditBox:SetTextColor(1, 1, 1, 1) -- White text
    whisperEditBox:SetTextInsets(8, 8, 8, 8) -- Add padding inside the edit box
    whisperEditBox:SetText(WhisperMacrosDB.whisperMessage)
    whisperEditBox:SetScript("OnEscapePressed", function() whisperEditBox:ClearFocus() end)
    whisperEditBox:SetScript("OnTextChanged", function()
        WhisperMacrosDB.whisperMessage = whisperEditBox:GetText()
    end)
    
    whisperScrollFrame:SetScrollChild(whisperEditBox)


    
    -- Add tips highlighting if enabled
    if WhisperMacrosDB.showTips then
        -- Create initial glowing borders (infinite until text is entered)
        local textBorderFrame, textBorders = CreateGlowBorder(scrollFrame, 3)
        local findButtonBorderFrame, findButtonBorders = CreateGlowBorder(findButton, 2)
        local parseButtonBorderFrame, parseButtonBorders = CreateGlowBorder(parseButton, 2)
        local whisperMessageBorderFrame, whisperMessageBorders = CreateGlowBorder(whisperScrollFrame, 2)
        
        -- Create Player List tab button glow
        local playerListTab = tabButtons[2] -- Player List is the second tab
        local playerListBorders
        playerListBorderFrame, playerListBorders = CreateGlowBorder(playerListTab, 2)
        
        -- Create Help tab button glow
        local helpTab = tabButtons[4] -- Help is the fourth tab
        local helpTabBorders
        helpTabBorderFrame, helpTabBorders = CreateGlowBorder(helpTab, 2)
        
        -- Start infinite animations for text box and find button
        local textAnimGroups = CreatePulseAnimation(textBorders, true)
        local findButtonAnimGroups = CreatePulseAnimation(findButtonBorders, true)
        local parseButtonAnimGroups = CreatePulseAnimation(parseButtonBorders, false)
        local whisperMessageAnimGroups = CreatePulseAnimation(whisperMessageBorders, false)
        playerListAnimGroups = CreatePulseAnimation(playerListBorders, false)
        helpTabAnimGroups = CreatePulseAnimation(helpTabBorders, false)
        
        -- Track tutorial state
        tutorialHasBeenParsed = false
        tutorialWhisperMessageEdited = false
        tutorialPlayerListTabVisited = false
        
        -- Start initial animations (infinite)
        for _, animGroup in ipairs(textAnimGroups) do
            animGroup:Play()
        end
        for _, animGroup in ipairs(findButtonAnimGroups) do
            animGroup:Play()
        end
        
        -- Hide other glows initially
        parseButtonBorderFrame:Hide()
        whisperMessageBorderFrame:Hide()
        playerListBorderFrame:Hide()
        helpTabBorderFrame:Hide()
        
        -- Function to check if text box has valid content
        local function HasValidContent()
            local text = editBox:GetText()
            return text and trim(text) ~= "" and text ~= placeholderText
        end
        
        -- Function to update glow states based on content
        local function UpdateGlowStates()
            if tutorialHasBeenParsed then
                -- After parsing, don't restart text/find button glows
                StopAndHideBorders(textAnimGroups, textBorderFrame)
                StopAndHideBorders(findButtonAnimGroups, findButtonBorderFrame)
                StopAndHideBorders(parseButtonAnimGroups, parseButtonBorderFrame)
                
                if not tutorialWhisperMessageEdited then
                    -- Show whisper message glow after parsing
                    StopAndHideBorders(playerListAnimGroups, playerListBorderFrame)
                    whisperMessageBorderFrame:Show()
                    for _, animGroup in ipairs(whisperMessageAnimGroups) do
                        animGroup:SetLooping("REPEAT")
                        animGroup:Play()
                    end
                else
                    -- Show Player List tab glow after whisper message is edited
                    StopAndHideBorders(whisperMessageAnimGroups, whisperMessageBorderFrame)
                    playerListBorderFrame:Show()
                    for _, animGroup in ipairs(playerListAnimGroups) do
                        animGroup:SetLooping("REPEAT")
                        animGroup:Play()
                    end
                end
            elseif HasValidContent() then
                -- Stop text box and find button glow when content is added
                StopAndHideBorders(textAnimGroups, textBorderFrame)
                StopAndHideBorders(findButtonAnimGroups, findButtonBorderFrame)
                
                -- Start parse button glow
                parseButtonBorderFrame:Show()
                for _, animGroup in ipairs(parseButtonAnimGroups) do
                    animGroup:SetLooping("REPEAT")
                    animGroup:Play()
                end
            else
                -- Only show text box and find button glow if parsing hasn't happened yet
                if not tutorialHasBeenParsed then
                    textBorderFrame:Show()
                    findButtonBorderFrame:Show()
                    for _, animGroup in ipairs(textAnimGroups) do
                        animGroup:SetLooping("REPEAT")
                        animGroup:Play()
                    end
                    for _, animGroup in ipairs(findButtonAnimGroups) do
                        animGroup:SetLooping("REPEAT")
                        animGroup:Play()
                    end
                else
                    -- Ensure text/find button glows stay off after parsing
                    StopAndHideBorders(textAnimGroups, textBorderFrame)
                    StopAndHideBorders(findButtonAnimGroups, findButtonBorderFrame)
                end
                
                -- Stop parse button glow
                StopAndHideBorders(parseButtonAnimGroups, parseButtonBorderFrame)
            end
        end
        
        -- Hook into whisper message text change events
        whisperEditBox:SetScript("OnTextChanged", function()
            WhisperMacrosDB.whisperMessage = whisperEditBox:GetText()
            if WhisperMacrosDB.showTips and tutorialHasBeenParsed then
                tutorialWhisperMessageEdited = true
                UpdateGlowStates()
            end
        end)
        
        -- Hook into text change events
        editBox:SetScript("OnTextChanged", function()
            -- Keep existing placeholder functionality working
            UpdateGlowStates()
        end)
        
        -- Also check on focus events (preserve existing functionality)
        editBox:SetScript("OnEditFocusGained", function()
            ClearPlaceholder()
            UpdateGlowStates()
        end)
        
        editBox:SetScript("OnEditFocusLost", function()
            UpdatePlaceholder()
            UpdateGlowStates()
        end)
        
        -- Update parse button to set tutorialHasBeenParsed flag
        local originalParseClick = parseButton:GetScript("OnClick")
        parseButton:SetScript("OnClick", function()
            local text = editBox:GetText()
            -- Don't parse if it's just the placeholder text
            if text and trim(text) ~= "" and text ~= placeholderText then
                local players = ParsePlayerData(text)
                if #players > 0 then
                    AddPlayersToList(players)
                    print("Added " .. #players .. " players to the list!")
                    editBox:SetText("")
                    UpdatePlaceholder() -- Show placeholder again after clearing
                    if WhisperMacrosDB.showTips then
                        tutorialHasBeenParsed = true
                        UpdateGlowStates()
                    end
                else
                    print("No valid players found in the text.")
                end
            else
                print("Please paste player data first.")
            end
        end)
        
        -- Initial state check
        UpdateGlowStates()
    end
end

-- Player List Tab
function ShowPlayerListTab()
    local contentFrame = ShowTabContent(2)
    
    -- Tutorial: Track when Player List tab is visited after whisper message editing
    if WhisperMacrosDB.showTips and tutorialWhisperMessageEdited and not tutorialPlayerListTabVisited then
        tutorialPlayerListTabVisited = true
        
        -- Stop Player List tab glow (only if it exists)
        if playerListBorderFrame then
            for _, animGroup in ipairs(playerListAnimGroups) do
                animGroup:Stop()
            end
            playerListBorderFrame:Hide()
        end
        
        -- Start Help tab glow - create it if it doesn't exist
        if not helpTabBorderFrame then
            -- Create Help tab button glow
            local helpTab = tabButtons[4] -- Help is the fourth tab
            local helpTabBorders
            helpTabBorderFrame, helpTabBorders = CreateGlowBorder(helpTab, 2)
            helpTabAnimGroups = CreatePulseAnimation(helpTabBorders, false)
        end
        
        helpTabBorderFrame:Show()
        for _, animGroup in ipairs(helpTabAnimGroups) do
            animGroup:SetLooping("REPEAT")
            animGroup:Play()
        end
    end
    
    -- Content is always cleared by ShowTabContent, so always recreate
    
    -- Header with controls
    local header = CreateFrame("Frame", nil, contentFrame)
    header:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, -10)
    header:SetSize(540, 40)
    
    local playerCount = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerCount:SetPoint("TOPLEFT", header, "TOPLEFT", 0, -5)
    playerCount:SetText("Players: " .. #WhisperMacrosDB.players)
    
    -- Remove after whisper checkbox
    local checkbox = CreateFrame("CheckButton", nil, header, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", playerCount, "BOTTOMLEFT", 0, -5)
    checkbox:SetChecked(WhisperMacrosDB.removeAfterWhisper)
    checkbox:SetScript("OnClick", function()
        WhisperMacrosDB.removeAfterWhisper = checkbox:GetChecked()
    end)
    
    local checkboxLabel = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    checkboxLabel:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkboxLabel:SetText("Remove players after whispering")
    
    -- Clear list button
    local clearListButton = CreateModernButton(header, 100, 25, "Clear List")
    clearListButton:SetPoint("TOPRIGHT", header, "TOPRIGHT", 0, -5)
    clearListButton:SetScript("OnClick", function()
        WhisperMacrosDB.players = {}
        WhisperMacrosDB.whisperedPlayers = {}
        WhisperMacrosDB.playerData = {}
        ShowPlayerListTab() -- Refresh
    end)
    
    -- Player list scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, contentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -45)
    scrollFrame:SetSize(540, 315)
    
    -- Custom scroll speed handling
    local function CustomScrollHandler(self, delta)
        local scrollStep = 15 -- Smaller step = slower scroll (default is usually 20-30)
        local currentScroll = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        
        -- Calculate new scroll position
        local newScroll = currentScroll - (delta * scrollStep)
        newScroll = math.max(0, math.min(newScroll, maxScroll))
        
        -- Apply smooth scroll
        self:SetVerticalScroll(newScroll)
    end
    
    -- Enable mouse wheel scrolling with custom speed
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", CustomScrollHandler)
    
    -- Column headers
    local headerFrame = CreateFrame("Frame", nil, contentFrame)
    headerFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
    headerFrame:SetSize(540, 25)
    
    local nameHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameHeader:SetPoint("LEFT", headerFrame, "LEFT", 5, 0)
    nameHeader:SetText("|cffffd700Player|r") -- Bold gold color
    
    local ratingHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ratingHeader:SetPoint("LEFT", headerFrame, "LEFT", 265, 0)
    ratingHeader:SetText("|cffffd700Rating|r") -- Bold gold color
    
    local specHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    specHeader:SetPoint("LEFT", headerFrame, "LEFT", 335, 0)
    specHeader:SetText("|cffffd700Spec|r") -- Bold gold color
    
    local winrateHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    winrateHeader:SetPoint("LEFT", headerFrame, "LEFT", 385, 0)
    winrateHeader:SetText("|cffffd700Winrate|r") -- Bold gold color
    
    -- Horizontal separator line
    local separatorLine = headerFrame:CreateTexture(nil, "OVERLAY")
    separatorLine:SetPoint("BOTTOMLEFT", headerFrame, "BOTTOMLEFT", 0, -2)
    separatorLine:SetPoint("BOTTOMRIGHT", headerFrame, "BOTTOMRIGHT", 0, -2)
    separatorLine:SetHeight(1)
    separatorLine:SetColorTexture(0.5, 0.5, 0.5, 0.8) -- Gray line
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(520, 1)
    scrollFrame:SetScrollChild(content)
    
    -- Display players
    local yOffset = -10 -- Add spacing before first row
    for i, player in ipairs(WhisperMacrosDB.players) do
        local playerFrame = CreateFrame("Frame", nil, content)
        playerFrame:SetSize(520, 25)
        playerFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        
        -- Get player data
        local playerData = WhisperMacrosDB.playerData[player] or {}
        local rating = playerData.rating or "?"
        local spec = playerData.spec or "Unknown"
        local class = playerData.class or "Unknown"
        local winrate = playerData.winrate or "?"
        
        -- Check if player was whispered
        local wasWhispered = false
        for _, whisperedPlayer in ipairs(WhisperMacrosDB.whisperedPlayers) do
            if whisperedPlayer == player then
                wasWhispered = true
                break
            end
        end
        
        -- Player name
        local playerText = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        playerText:SetPoint("LEFT", playerFrame, "LEFT", 5, 0)
        playerText:SetWidth(250)
        playerText:SetJustifyH("LEFT")
        
        if wasWhispered then
            playerText:SetText("|cff888888" .. player .. "|r")
        else
            playerText:SetText(player)
        end
        
        -- Player rating
        local ratingText = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        ratingText:SetPoint("LEFT", playerFrame, "LEFT", 265, 0)
        ratingText:SetWidth(60)
        ratingText:SetJustifyH("LEFT")
        
        if wasWhispered then
            ratingText:SetText("|cff888888" .. rating .. "|r")
        else
            ratingText:SetText(rating)
        end
        
        -- Spec icon (positioned to align with Spec header)
        local specIcon = playerFrame:CreateTexture(nil, "ARTWORK")
        specIcon:SetSize(20, 20)
        specIcon:SetPoint("LEFT", playerFrame, "LEFT", 335, 0)
        specIcon:SetTexture(GetSpecIcon(class, spec))
        if wasWhispered then
            specIcon:SetVertexColor(0.5, 0.5, 0.5) -- Dim the icon for whispered players
        end
        
        -- Winrate text (positioned to align with Winrate header)
        local winrateText = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        winrateText:SetPoint("LEFT", playerFrame, "LEFT", 385, 0)
        winrateText:SetWidth(60)
        winrateText:SetJustifyH("LEFT")
        if wasWhispered then
            winrateText:SetText("|cff888888" .. winrate .. "|r")
        else
            -- Color code winrate
            local winrateColor = "|cffffffff" -- Default white
            if winrate ~= "?" then
                local percentage = tonumber(winrate:match("(%d+%.?%d*)"))
                if percentage then
                    if percentage >= 58 then
                        winrateColor = "|cff00ff00" -- Green for high winrate (58%+)
                    elseif percentage >= 50 then
                        winrateColor = "|cffffff00" -- Yellow for medium winrate (50-57%)
                    else
                        winrateColor = "|cffff0000" -- Red for low winrate (below 50%)
                    end
                end
            end
            winrateText:SetText(winrateColor .. winrate .. "|r")
        end
        
        -- Remove button
        local removeButton = CreateModernButton(playerFrame, 60, 18, "Remove")
        removeButton:SetPoint("RIGHT", playerFrame, "RIGHT", -5, 0)
        removeButton:SetScript("OnClick", function()
            -- Also remove from playerData when removing from list
            WhisperMacrosDB.playerData[player] = nil
            table.remove(WhisperMacrosDB.players, i)
            ShowPlayerListTab() -- Refresh
        end)
        
        yOffset = yOffset - 30
    end
    
    content:SetHeight(math.max(20, #WhisperMacrosDB.players * 30 + 10)) -- Add 10px for spacing
end

-- Already Whispered Tab
function ShowWhisperedTab()
    local contentFrame = ShowTabContent(3)
    
    -- Content is always cleared by ShowTabContent, so always recreate
    
    -- Header with controls
    local header = CreateFrame("Frame", nil, contentFrame)
    header:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, -10)
    header:SetSize(540, 40)
    
    local playerCount = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerCount:SetPoint("TOPLEFT", header, "TOPLEFT", 0, -5)
    playerCount:SetText("Already Whispered: " .. #WhisperMacrosDB.whisperedPlayers)
    
    -- Clear whispered list button
    local clearWhisperedButton = CreateModernButton(header, 120, 25, "Clear Whispered")
    clearWhisperedButton:SetPoint("TOPRIGHT", header, "TOPRIGHT", 0, -5)
    clearWhisperedButton:SetScript("OnClick", function()
        WhisperMacrosDB.whisperedPlayers = {}
        ShowWhisperedTab() -- Refresh
    end)
    
    -- Whispered players list scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, contentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -50)
    scrollFrame:SetSize(540, 310)
    
    -- Custom scroll speed handling for whispered tab
    local function CustomScrollHandler(self, delta)
        local scrollStep = 15 -- Smaller step = slower scroll
        local currentScroll = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        
        -- Calculate new scroll position
        local newScroll = currentScroll - (delta * scrollStep)
        newScroll = math.max(0, math.min(newScroll, maxScroll))
        
        -- Apply smooth scroll
        self:SetVerticalScroll(newScroll)
    end
    
    -- Enable mouse wheel scrolling with custom speed
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", CustomScrollHandler)
    
    -- Column headers for whispered tab
    local headerFrame = CreateFrame("Frame", nil, contentFrame)
    headerFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
    headerFrame:SetSize(540, 25)
    
    local nameHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameHeader:SetPoint("LEFT", headerFrame, "LEFT", 5, 0)
    nameHeader:SetText("|cffffd700Player|r") -- Bold gold color
    
    local ratingHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ratingHeader:SetPoint("LEFT", headerFrame, "LEFT", 265, 0)
    ratingHeader:SetText("|cffffd700Rating|r") -- Bold gold color
    
    local specHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    specHeader:SetPoint("LEFT", headerFrame, "LEFT", 335, 0)
    specHeader:SetText("|cffffd700Spec|r") -- Bold gold color
    
    local winrateHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    winrateHeader:SetPoint("LEFT", headerFrame, "LEFT", 385, 0)
    winrateHeader:SetText("|cffffd700Winrate|r") -- Bold gold color
    
    -- Horizontal separator line
    local separatorLine = headerFrame:CreateTexture(nil, "OVERLAY")
    separatorLine:SetPoint("BOTTOMLEFT", headerFrame, "BOTTOMLEFT", 0, -2)
    separatorLine:SetPoint("BOTTOMRIGHT", headerFrame, "BOTTOMRIGHT", 0, -2)
    separatorLine:SetHeight(1)
    separatorLine:SetColorTexture(0.5, 0.5, 0.5, 0.8) -- Gray line
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(520, 1)
    scrollFrame:SetScrollChild(content)
    
    -- Display whispered players
    local yOffset = -10 -- Add spacing before first row
    for i, player in ipairs(WhisperMacrosDB.whisperedPlayers) do
        local playerFrame = CreateFrame("Frame", nil, content)
        playerFrame:SetSize(520, 25)
        playerFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        
        -- Get player data
        local playerData = WhisperMacrosDB.playerData[player] or {}
        local rating = playerData.rating or "?"
        local spec = playerData.spec or "Unknown"
        local class = playerData.class or "Unknown"
        local winrate = playerData.winrate or "?"
        
        -- Player name
        local playerText = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        playerText:SetPoint("LEFT", playerFrame, "LEFT", 5, 0)
        playerText:SetWidth(250)
        playerText:SetJustifyH("LEFT")
        playerText:SetText("|cff888888" .. player .. "|r")
        
        -- Player rating
        local ratingText = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        ratingText:SetPoint("LEFT", playerFrame, "LEFT", 265, 0)
        ratingText:SetWidth(60)
        ratingText:SetJustifyH("LEFT")
        ratingText:SetText("|cff888888" .. rating .. "|r")
        
        -- Spec icon (positioned to align with Spec header)
        local specIcon = playerFrame:CreateTexture(nil, "ARTWORK")
        specIcon:SetSize(20, 20)
        specIcon:SetPoint("LEFT", playerFrame, "LEFT", 335, 0)
        specIcon:SetTexture(GetSpecIcon(class, spec))
        specIcon:SetVertexColor(0.5, 0.5, 0.5) -- Dim the icon for whispered players
        
        -- Winrate text (positioned to align with Winrate header)
        local winrateText = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        winrateText:SetPoint("LEFT", playerFrame, "LEFT", 385, 0)
        winrateText:SetWidth(60)
        winrateText:SetJustifyH("LEFT")
        winrateText:SetText("|cff888888" .. winrate .. "|r")
        
        -- Remove button
        local removeButton = CreateModernButton(playerFrame, 60, 18, "Remove")
        removeButton:SetPoint("RIGHT", playerFrame, "RIGHT", -5, 0)
        removeButton:SetScript("OnClick", function()
            table.remove(WhisperMacrosDB.whisperedPlayers, i)
            ShowWhisperedTab() -- Refresh
        end)
        
        yOffset = yOffset - 30
    end
    
    content:SetHeight(math.max(20, #WhisperMacrosDB.whisperedPlayers * 30 + 10)) -- Add 10px for spacing
end



-- Help Tab
function ShowHelpTab()
    local contentFrame = ShowTabContent(4)
    
    -- Tutorial: Stop Help tab button glow when visited
    if WhisperMacrosDB.showTips and tutorialPlayerListTabVisited and helpTabBorderFrame then
        for _, animGroup in ipairs(helpTabAnimGroups) do
            animGroup:Stop()
        end
        helpTabBorderFrame:Hide()
    end
    
    -- Content is always cleared by ShowTabContent, so always recreate
    
    local helpText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    helpText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, -10)
    helpText:SetWidth(520)
    helpText:SetJustifyH("LEFT")
    helpText:SetText("How to use this addon:\n\n" ..
        "1. Go to https://www.pvpleaderboard.com/leaderboards/filter?leaderboard=3v3&region=US\n\n" ..
        "2. Copy player data from the leaderboard (the entire line for each player)\n\n" ..
        "3. Paste it in the 'Add Players' tab and click 'Parse Players'\n\n" ..
        "4. Go to 'Player List' tab to see your players\n\n" ..
        "5. Use '/lfg w' to start whispering players\n\n" ..
        "Commands:\n" ..
        "/lfg - Opens this interface\n" ..
        "/lfg w - Start whispering players")
    
    -- Tutorial: Create glow around the "/lfg w" command text (always check/recreate if needed)
    if WhisperMacrosDB.showTips and tutorialPlayerListTabVisited and not helpTabTutorialFrame then
        -- Create a frame container for the command text
        helpTabTutorialFrame = CreateFrame("Frame", nil, contentFrame)
        helpTabTutorialFrame:SetPoint("BOTTOM", contentFrame, "BOTTOM", 0, 20) -- Position at bottom center
        helpTabTutorialFrame:SetSize(300, 20) -- Set appropriate size for the text
        
        -- Create the text element inside the frame
        local commandText = helpTabTutorialFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        commandText:SetPoint("CENTER", helpTabTutorialFrame, "CENTER", 0, 0) -- Center the text in the frame
        commandText:SetJustifyH("CENTER") -- Center justify the text
        commandText:SetText("/lfg w - Start whispering players")
        
        -- Create glow border around the command frame (not the text directly)
        local commandBorderFrame, commandBorders = CreateGlowBorder(helpTabTutorialFrame, 2)
        local commandAnimGroups = CreatePulseAnimation(commandBorders, true)
        
        -- Start the glow animation
        commandBorderFrame:Show()
        for _, animGroup in ipairs(commandAnimGroups) do
            animGroup:Play()
        end
    end
end

-- Slash command handlers
SLASH_LFG1 = "/lfg"
SlashCmdList["LFG"] = function(msg)
    msg = trim(msg):lower()
    
    if msg == "w" then
        StartWhispering()
    else
        CreateMainInterface()
    end
end

-- Event handler for addon loaded
local function OnAddonLoaded(self, event, addonName)
    if addonName == "WhisperMacros" then
        InitializeDefaults()
        print("|cff4da6ffWhisper Macros|r |cff00ff00loaded!|r Use |cffffd700/lfg|r to open interface, |cffffd700/lfg w|r to whisper players")
    end
end

-- Register events
addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("CHAT_MSG_WHISPER_INFORM") -- Fired when we send a whisper
addon:RegisterEvent("CHAT_MSG_SYSTEM") -- Fired for system messages like "player not found"
addon:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        OnAddonLoaded(self, event, ...)
    else
        OnWhisperResult(self, event, ...)
    end
end)
