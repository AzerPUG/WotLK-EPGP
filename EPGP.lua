if TBCEPGP == nil then TBCEPGP = {} end
TBCEPGP.events = {}
TBCEPGP.Version = 5
local AddOnName = "TBC-EPGP"

local UpdateFrame, EventFrame, EPGPUserFrame, scrollPanel = nil, nil, nil, nil
local playerFrames = {}

function TBCEPGP:OnLoad()
    C_ChatInfo.RegisterAddonMessagePrefix("TBCEPGP")

    EventFrame = CreateFrame("Frame", nil, UIParent)
    TBCEPGP:RegisterEvents("ENCOUNTER_START", function(...) TBCEPGP.events:EncounterStart(...) end)
    TBCEPGP:RegisterEvents("ADDON_LOADED", function(...) TBCEPGP.events:AddonLoaded(...) end)
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

function TBCEPGP:AddPlayerToList(curGUID, curName)
    local numPlayers = TBCEPGP:CountPlayersInList()
    local epoch = time()
    local players = TBCEPGP.DataTable.Players
    if players[curGUID] == nil then
        players[curGUID] = {}
        players[curGUID].Name = curName
        players[curGUID].Update = epoch
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
    if ... == "TBC-EPGP" then
        TBCEPGP.DataTable = TBCEPGPDataTable
        TBCEPGP.CreateFrameStuffs()
    end
end

function TBCEPGP:CreateFrameStuffs()
    EPGPUserFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    EPGPUserFrame:SetPoint("CENTER", 0, 0)
    EPGPUserFrame:SetSize(500, 300)
    EPGPUserFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    EPGPUserFrame:SetBackdropColor(0.25, 0.25, 0.25, 0.80)

    EPGPUserFrame:EnableMouse(true)
    EPGPUserFrame:SetMovable(true)
    EPGPUserFrame:RegisterForDrag("LeftButton")
    EPGPUserFrame:SetScript("OnDragStart", EPGPUserFrame.StartMoving)
    EPGPUserFrame:SetScript("OnDragStop", EPGPUserFrame.StopMovingOrSizing)

    EPGPUserFrame.header = EPGPUserFrame:CreateFontString("EPGPUserFrame", "ARTWORK", "GameFontNormalHuge")
    EPGPUserFrame.header:SetPoint("TOP", 0, -10)
    EPGPUserFrame.header:SetText("|cFF00FFFF" .. AddOnName .. "|r")

    local EPGPUserFrameCloseButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelCloseButton")
    EPGPUserFrameCloseButton:SetSize(25, 25)
    EPGPUserFrameCloseButton:SetPoint("TOPRIGHT", EPGPUserFrame, "TOPRIGHT", 2, 2)
    EPGPUserFrameCloseButton:SetScript("OnClick", function() EPGPUserFrame:Hide() end)

    local AddToDataBaseButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelButtonTemplate")
    AddToDataBaseButton:SetSize(50, 30)
    AddToDataBaseButton:SetPoint("TOPLEFT", EPGPUserFrame, "TOPLEFT", 2, -2)
    AddToDataBaseButton:SetScript("OnClick",
    function()
        local unitGUID = UnitGUID("Target")
        local unitName = UnitName("Target")
        TBCEPGP:AddPlayerToList(unitGUID, unitName)
        --TBCEPGP:FillUserFrameScrollPanel(scrollPanel)
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

    local scrollFrame = CreateFrame("ScrollFrame", "scrollFrame", EPGPUserFrame, "UIPanelScrollFrameTemplate, BackdropTemplate");
    scrollFrame:SetSize(EPGPUserFrame:GetWidth() - 30, EPGPUserFrame:GetHeight() - 40)
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

    TBCEPGP:FillUserFrameScrollPanel(scrollPanel)
    scrollFrame:SetScrollChild(scrollPanel)
end

function TBCEPGP:FillUserFrameScrollPanel(panel)
    local players = TBCEPGP.DataTable.Players
    local index = 1

    for key, value in pairs(players) do
        local curPlayerFrame = playerFrames[index]
        curPlayerFrame = CreateFrame("Frame", nil, scrollPanel, "BackdropTemplate")
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
        curPlayerFrame.curEP:SetSize(25, 25)
        curPlayerFrame.curEP:SetPoint("LEFT", curPlayerFrame.Class, "RIGHT", 10, 0)

        curPlayerFrame.changeEP = CreateFrame("EditBox", nil, scrollPanel, "InputBoxTemplate")
        curPlayerFrame.changeEP:SetSize(30, 25)
        curPlayerFrame.changeEP:SetPoint("LEFT", curPlayerFrame.curEP, "RIGHT", 10, 0)
        curPlayerFrame.changeEP:SetAutoFocus(false)
        curPlayerFrame.changeEP:SetFrameStrata("HIGH")
        
        curPlayerFrame.curGP = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
        curPlayerFrame.curGP:SetSize(25, 25)
        curPlayerFrame.curGP:SetPoint("LEFT", curPlayerFrame.changeEP, "RIGHT", 25, 0)

        curPlayerFrame.changeGP = CreateFrame("EditBox", nil, scrollPanel, "InputBoxTemplate")
        curPlayerFrame.changeGP:SetSize(30, 25)
        curPlayerFrame.changeGP:SetPoint("LEFT", curPlayerFrame.curGP, "RIGHT", 10, 0)
        curPlayerFrame.changeGP:SetAutoFocus(false)
        curPlayerFrame.changeGP:SetFrameStrata("HIGH")

        local curName, curClass, curEP, curGP = nil

        if index == 1 then
            curName = "Name"
            curClass = "Class"
            curEP = "EP"
            curGP = "GP"
        else
            curName = value.Name
            curClass = value.Class
            curEP = value.EP
            curGP = value.GP

            curPlayerFrame.changeEP:HookScript("OnEditFocusLost",
            function()
                players[key].EP = players[key].EP + tonumber(curPlayerFrame.changeEP:GetText())
                curPlayerFrame.curEP:SetText(value.EP)
                curPlayerFrame.changeEP:SetText(0)
            end)

            curPlayerFrame.changeGP:HookScript("OnEditFocusLost",
            function()
                players[key].GP = players[key].GP + tonumber(curPlayerFrame.changeGP:GetText())
                curPlayerFrame.curGP:SetText(value.GP)
                curPlayerFrame.changeGP:SetText(0)
            end)
        end

        curPlayerFrame.Name:SetText(curName)
        curPlayerFrame.Class:SetText(curClass)
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
end

function TBCEPGP.events:EncounterStart()
    local epoch = time()
    local players = TBCEPGP.DataTable.Players
    for i = 1, 40 do
        local curGUID = UnitGUID("Raid" .. i)
        local curName = UnitName("Raid" .. i)
        if players[curGUID] == nil then
            TBCEPGP:AddPlayerToList(curGUID, curName)
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
    TBCEPGP:AddPlayerToList(curGUID, curName)
end

TBCEPGP.SlashCommands["show"] = function(value)
    EPGPUserFrame:Show()
end