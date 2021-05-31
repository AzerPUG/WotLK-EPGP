if TBCEPGP == nil then TBCEPGP = {} end
TBCEPGP.events = {}
TBCEPGP.Version = 8
local AddOnName = "TBC-EPGP"

local UpdateFrame, EventFrame, EPGPUserFrame, scrollPanel = nil, nil, nil, nil
local playerFrames = {}
local sortedColumn, filteredPlayers = nil, nil

local addonLoaded, variablesLoaded = false, false

local classNumbers =
{
     [1] = {"Warrior", "Wa",},
     [2] = {"Paladin", "Pa",},
     [3] = {"Hunter", "Hu",},
     [4] = {"Rogue", "Ro",},
     [5] = {"Priest", "Pr",},
     [7] = {"Shaman", "Sh",},
     [8] = {"Mage", "Ma",},
     [9] = {"Warlock", "Wl",},
    [11] = {"Druid", "Dr",},
}

local filteredClasses =
{
     [1] = false,
     [2] = false,
     [3] = false,
     [4] = false,
     [5] = false,
     [7] = false,
     [8] = false,
     [9] = false,
    [11] = false,
}

function TBCEPGP:OnLoad()
    C_ChatInfo.RegisterAddonMessagePrefix("TBCEPGP")

    EventFrame = CreateFrame("Frame", nil, UIParent)
    TBCEPGP:RegisterEvents("ENCOUNTER_START", function(...) TBCEPGP.events:EncounterStart(...) end)
    TBCEPGP:RegisterEvents("ADDON_LOADED", function(...) TBCEPGP.events:AddonLoaded(...) end)
    TBCEPGP:RegisterEvents("VARIABLES_LOADED", function(...) TBCEPGP.events:VariablesLoaded(...) end)
    TBCEPGP:RegisterEvents("CHAT_MSG_ADDON", function(...) TBCEPGP.events:ChatMsgAddon(...) end)

    EventFrame:SetScript("OnEvent", function(...)
        TBCEPGP:OnEvent(...)
    end)

    UpdateFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    UpdateFrame:SetPoint("CENTER", 0, 250)
    UpdateFrame:SetSize(250, 300)
    UpdateFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    UpdateFrame:SetBackdropColor(0.25, 0.25, 0.25, 0.80)
    UpdateFrame.header = UpdateFrame:CreateFontString("UpdateFrame", "ARTWORK", "GameFontNormalHuge")
    UpdateFrame.header:SetPoint("TOP", 0, -10)
    UpdateFrame.header:SetText("|cFFFF0000" .. AddOnName .. " out of date!|r")

    local UpdateFrameCloseButton = CreateFrame("Button", nil, UpdateFrame, "UIPanelCloseButton")
    UpdateFrameCloseButton:SetWidth(25)
    UpdateFrameCloseButton:SetHeight(25)
    UpdateFrameCloseButton:SetPoint("TOPRIGHT", UpdateFrame, "TOPRIGHT", 2, 2)
    UpdateFrameCloseButton:SetScript("OnClick", function() UpdateFrame:Hide() end )

    UpdateFrame:Hide()
end

function TBCEPGP:RegisterEvents(event, func)
    local handlers = TBCEPGP.RegisteredEvents[event]
    if handlers == nil then
        handlers = {}
        TBCEPGP.RegisteredEvents[event] = handlers
        EventFrame:RegisterEvent(event)
    end
    handlers[#handlers + 1] = func
end

function TBCEPGP:GetDateTime()
    local DateTimeString = date()
    local year, month, date, day, time = nil, nil, nil, nil, nil
    day, month, date, time, year = strsplit(" ", DateTimeString)
    day = TBCEPGP:GetFullDayName(day)
    month = TBCEPGP:GetNumericMonth(month)
    date = tonumber(date)
    year = tonumber(year)
    return year, month, date
end

function TBCEPGP:GetFullDayName(day)
    local dayF
    if day == "Mon" or day == "mon" then dayF =    "Monday" end
    if day == "Tue" or day == "tue" then dayF =   "Tuesday" end
    if day == "Wed" or day == "wed" then dayF = "Wednesday" end
    if day == "Thu" or day == "thu" then dayF =  "Thursday" end
    if day == "Fri" or day == "fri" then dayF =    "Friday" end
    if day == "Sat" or day == "sat" then dayF =  "Saturday" end
    if day == "Sun" or day == "sun" then dayF =    "Sunday" end
    return dayF
end

function TBCEPGP:GetNumericMonth(month)
    local monthN
    if month == "Jan" or month == "jan" then monthN = "01" end
    if month == "Feb" or month == "feb" then monthN = "02" end
    if month == "Mar" or month == "mar" then monthN = "03" end
    if month == "Apr" or month == "apr" then monthN = "04" end
    if month == "May" or month == "may" then monthN = "05" end
    if month == "Jun" or month == "jun" then monthN = "06" end
    if month == "Jul" or month == "jul" then monthN = "07" end
    if month == "Aug" or month == "aug" then monthN = "08" end
    if month == "Sep" or month == "sep" then monthN = "09" end
    if month == "Oct" or month == "oct" then monthN = "10" end
    if month == "Nov" or month == "nov" then monthN = "11" end
    if month == "Dec" or month == "dec" then monthN = "12" end
    return monthN
end

function TBCEPGP:GetQualityMultiplier(quality, iLevel)
    local multiplier = TBCEPGP.InfoTable.Quality[quality](iLevel)
    return multiplier
end

function TBCEPGP:GetSlotMultiplier(slot)
    local multiplier = TBCEPGP.InfoTable.Slot[slot]
    return multiplier
end

function TBCEPGP:CalculateTotalPrice(quality, slot, iLevel)
    local TotalPrice, CalcPrice, QMulty, SMulty = nil, nil, nil, nil
    QMulty = TBCEPGP:GetQualityMultiplier(quality, iLevel)
    SMulty = TBCEPGP:GetSlotMultiplier(slot)

    CalcPrice = QMulty * QMulty * 0.04 * SMulty
    print("Total Price:", CalcPrice)
    TotalPrice = TBCEPGP:MathRound(CalcPrice)
    return TotalPrice
end

function TBCEPGP:MathRound(value)
    value = math.floor(value + 0.5)
    return value
end

function TBCEPGP:RollItem(inputLink)
    if inputLink == nil then print("No ItemLink provided!")
    else
        local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc = GetItemInfo(inputLink)
        if itemEquipLoc == nil or itemEquipLoc == "" then itemEquipLoc = "Not Equipable!" end
        print("EPGP Rolling Item:", itemLink)
        print("iLevel:", itemLevel, " - Quality:", itemQuality, " - Slot:", itemEquipLoc)
        print("Quality/iLevel Modifier:", TBCEPGP:GetQualityMultiplier(itemQuality, itemLevel))
        print("Slot Modifier:", TBCEPGP:GetSlotMultiplier(itemEquipLoc))
        print("Rounded Price:", TBCEPGP:CalculateTotalPrice(itemQuality, itemEquipLoc, itemLevel))
    end
end

function TBCEPGP:AddPlayerToList(curGUID, curName, curClass)
    local numPlayers = TBCEPGP:CountPlayersInList()
    local epoch = time()
    local players = TBCEPGP.DataTable.Players
    if players[curGUID] == nil then
        players[curGUID] = {}
        players[curGUID].Name = curName
        players[curGUID].Update = epoch
        players[curGUID].Class = curClass
        players[curGUID].EP = 0
        players[curGUID].GP = 0
        local year, month, date = TBCEPGP:GetDateTime()
        local dateString = year .. month .. date
        print("Adding Target to DataTable:", curName, "-", curGUID)
        players[curGUID][dateString] = {}
    else
        print("Player already in list!")
    end
end

function TBCEPGP:CountPlayersInList()
    local numPlayers = 0
    local players = TBCEPGP.DataTable.Players
    for key, value in pairs(players) do
        numPlayers = numPlayers + 1
    end

    return numPlayers
end

function TBCEPGP:SyncRaidersAddOnMsg()
    local players = TBCEPGPDataTable.Players
    for playerGUID, playerData in pairs(players) do
        local message = "Player:"
        message = message .. playerGUID .. ":" .. playerData.Name .. ":" .. playerData.Update .. ":" .. playerData.EP .. ":" .. playerData.GP
        if IsInRaid() then
            C_ChatInfo.SendAddonMessage("TBCEPGP", message ,"RAID", 1)
        else
            C_ChatInfo.SendAddonMessage("TBCEPGP", message ,"GUILD", 1)
        end
    end
    print("Sync AddOn Messages Send!")
end

function TBCEPGP.events:ChatMsgAddon(prefix, payload, channel, sender)
    local playerName = UnitName("player")
    local playerServer = GetRealmName()
    local subPayload = payload
    local players = TBCEPGPDataTable.Players
    local subStringList = {}
    if sender == playerName .. "-" .. playerServer then print("Received Own AddOn Message!")
    else
        if prefix == "TBCEPGP" then
            for i = 1, 5 do
                if subPayload ~= nil then
                    subPayload = string.sub(subPayload, string.find(subPayload, ":") + 1, #subPayload)
                    local stringFind = string.find(subPayload, ":", 1)
                    if stringFind ~= nil then
                        subStringList[i] = string.sub(subPayload, 0, stringFind - 1)
                    end
                end
                subStringList[3] = tonumber(subStringList[3])
            end
            print("Sync Received from:", sender)

            for player, playerData in pairs(players) do
                if players[subStringList[1]] == nil then
                    local curGUID = subStringList[1]
                    players[curGUID] = {}
                    players[curGUID].Name = subStringList[2]
                    players[curGUID].Update = subStringList[3]
                    players[curGUID].EP = subStringList[4]
                    players[curGUID].GP = subStringList[5]
                else
                    if playerData.Update < subStringList[3] then
                        local curGUID = subStringList[1]
                        players[curGUID].Name = subStringList[2]
                        players[curGUID].Update = subStringList[3]
                        players[curGUID].EP = subStringList[4]
                        players[curGUID].GP = subStringList[5]
                    end
                end
            end
        end
    end
end

function TBCEPGP:OnEvent(_, event, ...)
    for _, handler in pairs(TBCEPGP.RegisteredEvents[event]) do
        handler(...)
    end
end

function TBCEPGP.events:AddonLoaded(...)
    local addonName = ...
    if addonName == "TBC-EPGP" then
        if variablesLoaded == true then TBCEPGP:VarsAndAddonLoaded() else addonLoaded = true end
    end
end

function TBCEPGP.events:VariablesLoaded(...)
    if addonLoaded == true then TBCEPGP:VarsAndAddonLoaded() else variablesLoaded = true end
end

function TBCEPGP:VarsAndAddonLoaded()
    if TBCEPGPDataTable == nil then
        print("TBCEPGPDataTable == nil")
        TBCEPGPDataTable = TBCEPGP.DataTable
    elseif TBCEPGPDataTable ~= nil then
        print("TBCEPGPDataTable == not nil")
        TBCEPGP.DataTable = TBCEPGPDataTable
    end
    TBCEPGP.CreateUserFrame()
end

function TBCEPGP:CreateUserFrame()
    EPGPUserFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    EPGPUserFrame:SetPoint("CENTER", 0, 0)
    EPGPUserFrame:SetSize(500, 400)
    EPGPUserFrame:EnableMouse(true)
    EPGPUserFrame:SetMovable(true)
    EPGPUserFrame:RegisterForDrag("LeftButton")
    EPGPUserFrame:SetScript("OnDragStart", EPGPUserFrame.StartMoving)
    EPGPUserFrame:SetScript("OnDragStop", EPGPUserFrame.StopMovingOrSizing)
    EPGPUserFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    EPGPUserFrame:SetBackdropColor(0.25, 0.25, 0.25, 0.80)

    EPGPUserFrame.Title = EPGPUserFrame:CreateFontString("EPGPUserFrame", "ARTWORK", "GameFontNormalHuge")
    EPGPUserFrame.Title:SetPoint("TOP", 0, -10)
    EPGPUserFrame.Title:SetText("|cFF00FFFF" .. AddOnName .. "|r")

    EPGPUserFrame.Header = CreateFrame("Frame", nil, EPGPUserFrame, "BackdropTemplate")
    EPGPUserFrame.Header:SetPoint("TOP", -10, -85)
    EPGPUserFrame.Header:SetSize(EPGPUserFrame:GetWidth() -30, 50)
    EPGPUserFrame.Header:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    EPGPUserFrame.Header:SetBackdropColor(0.25, 0.25, 0.75, 0.80)

    EPGPUserFrame.Header.Name = EPGPUserFrame.Header:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
    EPGPUserFrame.Header.Name:SetSize(100, 25)
    EPGPUserFrame.Header.Name:SetPoint("BOTTOMLEFT", 5, 0)
    EPGPUserFrame.Header.Name:SetText("Name")

    EPGPUserFrame.Header.Class = EPGPUserFrame.Header:CreateFontString("EPGPUserFrame.Header", "ARTWORK", "GameFontNormal")
    EPGPUserFrame.Header.Class:SetSize(100, 25)
    EPGPUserFrame.Header.Class:SetPoint("BOTTOMLEFT", EPGPUserFrame.Header.Name, "BOTTOMRIGHT", 0, 0)
    EPGPUserFrame.Header.Class:SetText("Class")

    local FilterButtons = {}
    for i = 1, 11 do
        if i == 6 or i == 10 then -- Parsing out Monk(6) and DeathKnight(10) index numbers. (DH == 12)
        else
            FilterButtons[i] = CreateFrame("Button", nil, EPGPUserFrame.Header, "BackdropTemplate")
            FilterButtons[i]:SetSize(20, 16)

            local xOff, yOff = nil, nil
            if i == 1 or i == 4 or i == 8 then
                xOff = -18
            elseif i == 2 or i == 5 or i == 9 then
                xOff = -0
            elseif i == 3 or i == 7 or i == 11 then
                xOff = 18
            end
            if i == 1 or i == 2 or i == 3 then
                yOff = 13
            elseif i == 4 or i == 5 or i == 7 then
                yOff = 0
            elseif i == 8 or i == 9 or i == 11 then
                yOff = -13
            end

            FilterButtons[i]:SetPoint("LEFT", EPGPUserFrame.Header.Class, "RIGHT", -60 + xOff, 30 + yOff)

            FilterButtons[i]:SetBackdrop({
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                edgeSize = 10,
                insets = {left = 3, right = 3, top = 3, bottom = 3},
            })

            local r, g = 1, 0
            FilterButtons[i]:SetBackdropColor(1, 0, 0, 1)

            FilterButtons[i]:SetScript("OnClick",
            function()
                print("FilterButton", i, "clicked!", filteredClasses[i])
                if filteredClasses[i] then
                    filteredClasses[i] = false
                    r = 1
                    g = 0
                else
                    filteredClasses[i] = true
                    r = 0
                    g = 1
                end
                TBCEPGP:filterPlayers(i)
                FilterButtons[i]:SetBackdropColor(r, g, 0, 1)
            end)

            FilterButtons[i].text = FilterButtons[i]:CreateFontString("FilterButton", "ARTWORK", "GameFontNormalTiny")
            FilterButtons[i].text:SetPoint("CENTER", 0, 0)
            FilterButtons[i].text:SetText(classNumbers[i][2])
        end
    end

    EPGPUserFrame.Header.curEP = EPGPUserFrame.Header:CreateFontString("EPGPUserFrame.Header", "ARTWORK", "GameFontNormal")
    EPGPUserFrame.Header.curEP:SetSize(50, 25)
    EPGPUserFrame.Header.curEP:SetPoint("BOTTOMLEFT", EPGPUserFrame.Header.Class, "BOTTOMRIGHT", 10, 0)
    EPGPUserFrame.Header.curEP:SetText("EP")

    EPGPUserFrame.Header.changeEP = CreateFrame("EditBox", nil, EPGPUserFrame.Header, "InputBoxTemplate")
    EPGPUserFrame.Header.changeEP:SetSize(30, 25)
    EPGPUserFrame.Header.changeEP:SetPoint("BOTTOMLEFT", EPGPUserFrame.Header.curEP, "BOTTOMRIGHT", 10, 0)
    EPGPUserFrame.Header.changeEP:SetAutoFocus(false)
    EPGPUserFrame.Header.changeEP:SetFrameStrata("HIGH")
    EPGPUserFrame.Header.changeEP:SetText(0)

    EPGPUserFrame.Header.curGP = EPGPUserFrame.Header:CreateFontString("EPGPUserFrame.Header", "ARTWORK", "GameFontNormal")
    EPGPUserFrame.Header.curGP:SetSize(50, 25)
    EPGPUserFrame.Header.curGP:SetPoint("BOTTOMLEFT", EPGPUserFrame.Header.changeEP, "BOTTOMRIGHT", 25, 0)
    EPGPUserFrame.Header.curGP:SetText("GP")

    EPGPUserFrame.Header.changeGP = CreateFrame("EditBox", nil, EPGPUserFrame.Header, "InputBoxTemplate")
    EPGPUserFrame.Header.changeGP:SetSize(30, 25)
    EPGPUserFrame.Header.changeGP:SetPoint("BOTTOMLEFT", EPGPUserFrame.Header.curGP, "BOTTOMRIGHT", 10, 0)
    EPGPUserFrame.Header.changeGP:SetAutoFocus(false)
    EPGPUserFrame.Header.changeGP:SetFrameStrata("HIGH")
    EPGPUserFrame.Header.changeGP:SetText(0)

    local EPGPUserFrameCloseButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelCloseButton")
    EPGPUserFrameCloseButton:SetSize(25, 25)
    EPGPUserFrameCloseButton:SetPoint("TOPRIGHT", EPGPUserFrame, "TOPRIGHT", 2, 2)
    EPGPUserFrameCloseButton:SetScript("OnClick", function() EPGPUserFrame:Hide() end)

    local AddToDataBaseButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelButtonTemplate")
    AddToDataBaseButton:SetSize(50, 30)
    AddToDataBaseButton:SetPoint("TOPLEFT", EPGPUserFrame, "TOPLEFT", 2, -2)
    AddToDataBaseButton:SetScript("OnClick",
    function()
        local players = TBCEPGP.DataTable.Players
        local unitGUID = UnitGUID("Target")
        local unitName = UnitName("Target")
        local _, _, unitClass = UnitClass("Target")
        TBCEPGP:AddPlayerToList(unitGUID, unitName, unitClass)
        TBCEPGP:FillUserFrameScrollPanel(players)
    end)
    AddToDataBaseButton.text = AddToDataBaseButton:CreateFontString("AddToDataBaseButton", "ARTWORK", "GameFontNormalTiny")
    AddToDataBaseButton.text:SetPoint("CENTER", 0, -1)
    AddToDataBaseButton.text:SetText("Add\nTarget")

    local SyncButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelButtonTemplate")
    SyncButton:SetSize(50, 30)
    SyncButton:SetPoint("LEFT", AddToDataBaseButton, "RIGHT", 10, 0)
    SyncButton:SetScript("OnClick",
    function()
        print("Trying to sync!")
        TBCEPGP:SyncRaidersAddOnMsg()
    end)
    SyncButton.text = SyncButton:CreateFontString("SyncButton", "ARTWORK", "GameFontNormalTiny")
    SyncButton.text:SetPoint("CENTER", 0, -1)
    SyncButton.text:SetText("Sync\nNow")

    local SortButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelButtonTemplate")
    SortButton:SetSize(50, 30)
    SortButton:SetPoint("LEFT", SyncButton, "RIGHT", 10, 0)
    SortButton:SetScript("OnClick",
    function()
        local players = TBCEPGPDataTable.Players
        sortedColumn = "Class"
        TBCEPGP:FillUserFrameScrollPanel(filteredPlayers)
    end)
    SortButton.text = SortButton:CreateFontString("SortButton", "ARTWORK", "GameFontNormalTiny")
    SortButton.text:SetPoint("CENTER", 0, -1)
    SortButton.text:SetText("Sort\nClasses")

    local scrollFrame = CreateFrame("ScrollFrame", "scrollFrame", EPGPUserFrame, "UIPanelScrollFrameTemplate, BackdropTemplate");
    scrollFrame:SetSize(EPGPUserFrame:GetWidth() - 30, EPGPUserFrame:GetHeight() - 140)
    scrollFrame:SetPoint("BOTTOM", -10, 5)
    scrollFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    scrollFrame:SetBackdropColor(1, 0.25, 0.25, 0.80)
    scrollPanel = CreateFrame("Frame")
    scrollPanel:SetSize(scrollFrame:GetWidth(), 300)
    scrollPanel:SetPoint("TOP")

    local players = TBCEPGP.DataTable.Players
    TBCEPGP:FillUserFrameScrollPanel(players)
    scrollFrame:SetScrollChild(scrollPanel)
end

function TBCEPGP:filterPlayers()
    filteredPlayers = {}
    local players = TBCEPGPDataTable.Players
    for key, value in pairs(players) do
        for i = 1, 11 do
            if i == 6 or i == 10 then -- Parsing out Monk(6) and DeathKnight(10) index numbers. (DH == 12)
            else
                if filteredClasses[i] == true then
                    if players[key].Class == i then
                        filteredPlayers[key] = value
                    end
                end
            end
        end
    end
    TBCEPGP:FillUserFrameScrollPanel(filteredPlayers)
end

function TBCEPGP:FillUserFrameScrollPanel(inputPlayers)
    local players = inputPlayers
    local filteredPlayerFrames = {}
    local index = 1

    if inputPlayers == nil then players = TBCEPGP.DataTable.Players end

    for _, value in pairs(playerFrames) do
        value:Hide()
    end

    for key, value in pairs(players) do
        local curPlayerFrame = playerFrames[index]
        if curPlayerFrame == nil then
            curPlayerFrame = CreateFrame("Frame", nil, scrollPanel, "BackdropTemplate")
            playerFrames[index] = curPlayerFrame
            curPlayerFrame:SetSize(scrollPanel:GetWidth(), 25)
            curPlayerFrame:SetPoint("TOPLEFT", scrollPanel, "TOPLEFT", 0, -24 * index + 24)
            curPlayerFrame:EnableMouse(true)
            curPlayerFrame:SetBackdrop({
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                edgeSize = 12,
                insets = {left = 2, right = 2, top = 2, bottom = 2},
            })
            curPlayerFrame:SetBackdropColor(1, 1, 1, 0.80)

            curPlayerFrame.Name = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.Name:SetSize(100, 25)
            curPlayerFrame.Name:SetPoint("LEFT", 5, 0)

            curPlayerFrame.Class = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.Class:SetSize(100, 25)
            curPlayerFrame.Class:SetPoint("LEFT", curPlayerFrame.Name, "RIGHT", 0, 0)

            curPlayerFrame.curEP = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.curEP:SetSize(50, 25)
            curPlayerFrame.curEP:SetPoint("LEFT", curPlayerFrame.Class, "RIGHT", 10, 0)

            curPlayerFrame.changeEP = CreateFrame("EditBox", nil, curPlayerFrame, "InputBoxTemplate")
            curPlayerFrame.changeEP:SetSize(30, 25)
            curPlayerFrame.changeEP:SetPoint("LEFT", curPlayerFrame.curEP, "RIGHT", 10, 0)
            curPlayerFrame.changeEP:SetAutoFocus(false)
            curPlayerFrame.changeEP:SetFrameStrata("HIGH")

            curPlayerFrame.curGP = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.curGP:SetSize(50, 25)
            curPlayerFrame.curGP:SetPoint("LEFT", curPlayerFrame.changeEP, "RIGHT", 25, 0)

            curPlayerFrame.changeGP = CreateFrame("EditBox", nil, curPlayerFrame, "InputBoxTemplate")
            curPlayerFrame.changeGP:SetSize(30, 25)
            curPlayerFrame.changeGP:SetPoint("LEFT", curPlayerFrame.curGP, "RIGHT", 10, 0)
            curPlayerFrame.changeGP:SetAutoFocus(false)
            curPlayerFrame.changeGP:SetFrameStrata("HIGH")

            curPlayerFrame.changeEP:HookScript("OnEditFocusLost",
            function()
                players[curPlayerFrame.key].EP = players[curPlayerFrame.key].EP + tonumber(curPlayerFrame.changeEP:GetText())
                curPlayerFrame.curEP:SetText(players[curPlayerFrame.key].EP)
                curPlayerFrame.changeEP:SetText(0)
            end)

            curPlayerFrame.changeGP:HookScript("OnEditFocusLost",
            function()
                players[curPlayerFrame.key].GP = players[curPlayerFrame.key].GP + tonumber(curPlayerFrame.changeGP:GetText())
                curPlayerFrame.curGP:SetText(players[curPlayerFrame.key].GP)
                curPlayerFrame.changeGP:SetText(0)
            end)
        end

        filteredPlayerFrames[index] = curPlayerFrame

        local curName, curClass, curEP, curGP = nil, nil, nil, nil
        curPlayerFrame.key = key

        curName = value.Name
        curClass = value.Class
        curEP = value.EP
        curGP = value.GP

        curPlayerFrame:Show()

        curPlayerFrame.Name:SetText(curName)
        curPlayerFrame.Class:SetText(classNumbers[curClass][1])
        curPlayerFrame.curEP:SetText(curEP)
        curPlayerFrame.curGP:SetText(curGP)
        curPlayerFrame.changeEP:SetText(0)
        curPlayerFrame.changeGP:SetText(0)

        index = index + 1
        -- ToDo Later Version:
        -- Add Up and Down buttons to text box, to easily add/deduct x points.
        -- Shift / Alt / CTRL + Click for other values.
        -- UIPanelScrollUpButtonTemplate
        -- UIPanelScrollDownButtonTemplate
    end

    if sortedColumn ~= nil then
        table.sort(filteredPlayerFrames, function(a, b)
            --if a:IsShown() == false then print("a:IsShown() == false", a.Name:GetText(), "-", a.Class:GetText()) return false end
            --if b:IsShown() == false then print("b:IsShown() == false", b.Name:GetText(), "-", b.Class:GetText()) return false end
            if sortedColumn == "Class" then
                print(a.key, players[a.key])
                return players[a.key].Class > players[b.key].Class
            end
        end)
    end

    for j, frame in pairs(filteredPlayerFrames) do
        frame:SetPoint("TOPLEFT", scrollPanel, "TOPLEFT", 0, -24 * j + 24)
    end
end

function TBCEPGP.events:EncounterStart()
    local epoch = time()
    local players = TBCEPGP.DataTable.Players
    for i = 1, 40 do
        local curGUID = UnitGUID("Raid" .. i)
        local curName = UnitName("Raid" .. i)
        local _, _, curClass = UnitClass("Raid" .. i)
        if players[curGUID] == nil then
            TBCEPGP:AddPlayerToList(curGUID, curName, curClass)
        end
    end
end

TBCEPGP:OnLoad()

TBCEPGP.SlashCommands["roll"] = function(value)
    TBCEPGP:RollItem(value)
end

TBCEPGP.SlashCommands["sync"] = function(value)
    print("Trying to sync!")
    TBCEPGP:SyncRaidersAddOnMsg()
end

TBCEPGP.SlashCommands["add"] = function(value)
    local curGUID = UnitGUID("Target")
    local curName = UnitName("Target")
    local _, _, curClass = UnitClass("Target")
    TBCEPGP:AddPlayerToList(curGUID, curName, curClass)
end

TBCEPGP.SlashCommands["show"] = function(value)
    EPGPUserFrame:Show()
end