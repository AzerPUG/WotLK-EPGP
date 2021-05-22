if TBCEPGP == nil then TBCEPGP = {} end
TBCEPGP.events = {}
TBCEPGP.Version = 4
local AddOnName = "TBC-EPGP"

local UpdateFrame, EventFrame, EPGPUserFrame, scrollPanel = nil, nil, nil, nil

function TBCEPGP:OnLoad()
    EventFrame = CreateFrame("Frame", nil, UIParent)
    TBCEPGP:RegisterEvents("ENCOUNTER_START", function(...) TBCEPGP.events:EncounterStart(...) end)
    TBCEPGP:RegisterEvents("ADDON_LOADED", function(...) TBCEPGP.events:AddonLoaded(...) end)

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

function TBCEPGP:SaveEncounterPull(encounterID)
    local year, month, date = TBCEPGP:GetDateTime()
    local dateString = year .. month .. date
    local DataTable = TBCEPGP.DataTable

    local Dates = DataTable.Dates

    if DataTable[dateString] == nil then DataTable[dateString] = {} end
    local curDate = DataTable[dateString]
    local datePresent = false
    for i = 1, #Dates do
        if Dates[i] == dateString then datePresent = true end
    end
    if datePresent == false then
        Dates[#Dates + 1] = dateString
    end

    if curDate.Encounters == nil then curDate.Encounters = {} end
    local Encounters = curDate.Encounters
    if curDate[encounterID] == nil then curDate[encounterID] = {} end
    local curEncounter = curDate[encounterID]
    local encounterPresent = false
    for i = 1, #Dates do
        if Encounters[i] == encounterID then encounterPresent = true end
    end
    if encounterPresent == false then
        Encounters[#Encounters + 1] = encounterID
    end
    curDate.Encounters = Encounters

    if curEncounter.Pulls == nil then curEncounter.Pulls = {} end
    local Pulls = curEncounter.Pulls
    local curPullNumber = #Pulls + 1
    if curEncounter[curPullNumber] == nil then curEncounter[curPullNumber] = {} end
    local curPull = curEncounter[curPullNumber]
    Pulls[#Pulls + 1] = curPullNumber

    curPull.Players = TBCEPGP:SaveRaiders()

    TBCEPGPDataTable = TBCEPGP.DataTable
end

function TBCEPGP:SaveRaiders()
    local RaidersList = {}
    for i = 1, 40 do
        local curGUID = UnitGUID("Raid" .. i)
        RaidersList[i] = curGUID
        if curGUID ~= nil then
            if TBCEPGP.DataTable.Players[curGUID] == nil then
                TBCEPGP.DataTable.Players[curGUID] = {}
                TBCEPGP.DataTable.Players[curGUID].Name = UnitName("Raid" .. i)
                TBCEPGP.DataTable.Players[curGUID].EP = 0
                TBCEPGP.DataTable.Players[curGUID].GP = 0
                local year, month, date = TBCEPGP:GetDateTime()
                local dateString = year .. "/" .. month .. "/" .. date
                TBCEPGP.DataTable.Players[curGUID][dateString] = {}
            end
        end
    end

    return RaidersList
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
    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc = GetItemInfo(inputLink)
    if itemEquipLoc == nil or itemEquipLoc == "" then itemEquipLoc = "Not Equipable!" end
    print("EPGP Rolling Item:", itemLink)
    print("iLevel:", itemLevel, " - Quality:", itemQuality, " - Slot:", itemEquipLoc)
    print("Quality/iLevel Modifier:", TBCEPGP:GetQualityMultiplier(itemQuality, itemLevel))
    print("Slot Modifier:", TBCEPGP:GetSlotMultiplier(itemEquipLoc))
    print("Rounded Price:", TBCEPGP:CalculateTotalPrice(itemQuality, itemEquipLoc, itemLevel))
end

function TBCEPGP:OnEvent(_, event, ...)
    for _, handler in pairs(TBCEPGP.RegisteredEvents[event]) do
        handler(...)
    end
end

function TBCEPGP.events:EncounterStart(encounterID)
    TBCEPGP:SaveEncounterPull(encounterID)
end

function TBCEPGP.events:AddonLoaded(...)
    if ... == "TBC-EPGP" then
        TBCEPGP.DataTable = TBCEPGPDataTable
        TBCEPGP.CreateFrameStuffs()
    end
end

function TBCEPGP.CreateFrameStuffs()
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
    AddToDataBaseButton:SetScript("OnClick", function() TBCEPGP:AddTargetToDataBase() end)
    AddToDataBaseButton.text = AddToDataBaseButton:CreateFontString("AddToDataBaseButton", "ARTWORK", "GameFontNormalTiny")
    AddToDataBaseButton.text:SetPoint("CENTER", 0, -1)
    AddToDataBaseButton.text:SetText("Add\nTarget")

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

function TBCEPGP:AddTargetToDataBase()
    local unitName = UnitName("Target")
    local unitGUID = UnitGUID("Target")
    local players = TBCEPGP.DataTable.Players
    if players[unitGUID] == nil then
        players[unitGUID] = {}
        players[unitGUID].Name = unitName
        players[unitGUID].EP = 0
        players[unitGUID].GP = 0
        local year, month, date = TBCEPGP:GetDateTime()
        local dateString = year .. "/" .. month .. "/" .. date
        players[unitGUID][dateString] = {}
        print("Adding Target to DataTable:", unitName, "-", unitGUID)
    end
    TBCEPGP:FillUserFrameScrollPanel(scrollPanel)
end

function TBCEPGP:FillUserFrameScrollPanel(panel)
    local players = TBCEPGP.DataTable.Players
    local index = 0
    local playerFrames = {}
    for key, value in pairs(players) do
        index = index + 1
        local curPlayerFrame = playerFrames[index]
        curPlayerFrame = CreateFrame("Frame", nil, scrollPanel, "BackdropTemplate")
        curPlayerFrame:SetSize(scrollPanel:GetWidth(), 25)
        curPlayerFrame:SetPoint("TOPLEFT", scrollPanel, "TOPLEFT", 0, -24 * index + 24)
        curPlayerFrame:EnableMouse(true)
        curPlayerFrame:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            edgeSize = 12,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        curPlayerFrame:SetBackdropColor(1, 1, 1, 0.80)

        curPlayerFrame.Name = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
        curPlayerFrame.Name:SetSize(100, 25)
        curPlayerFrame.Name:SetPoint("LEFT", 5, 0)
        curPlayerFrame.Name:SetText(value.Name)

        curPlayerFrame.EP = CreateFrame("EditBox", nil, scrollPanel, "InputBoxTemplate")
        curPlayerFrame.EP:SetSize(50, 25)
        curPlayerFrame.EP:SetPoint("LEFT", curPlayerFrame.Name, "RIGHT", 10, 0)
        curPlayerFrame.EP:SetText(value.EP)
        curPlayerFrame.EP:SetAutoFocus(false)
        curPlayerFrame.EP:SetFrameStrata("HIGH")
        curPlayerFrame.EP:SetNumeric(true)
        curPlayerFrame.EP:HookScript("OnEditFocusLost", function() print("FocusLost EP:", curPlayerFrame.EP:GetText()) end)

        curPlayerFrame.GP = CreateFrame("EditBox", nil, scrollPanel, "InputBoxTemplate")
        curPlayerFrame.GP:SetSize(50, 25)
        curPlayerFrame.GP:SetPoint("LEFT", curPlayerFrame.EP, "RIGHT", 10, 0)
        curPlayerFrame.GP:SetText(value.GP)
        curPlayerFrame.GP:SetAutoFocus(false)
        curPlayerFrame.GP:SetFrameStrata("HIGH")
        curPlayerFrame.GP:SetNumeric(true)
        curPlayerFrame.GP:HookScript("OnEditFocusLost", function() print("FocusLost GP:", curPlayerFrame.GP:GetText()) end)

        -- ToDo Later Version:
        -- Add Up and Down buttons to text box, to easily add/deduct x points.
        -- Shift / Alt / CTRL + Click for other values.
        -- UIPanelScrollUpButtonTemplate
        -- UIPanelScrollDownButtonTemplate
    end
end

TBCEPGP:OnLoad()

TBCEPGP.SlashCommands["roll"] = function(value)
    TBCEPGP:RollItem(value)
end

TBCEPGP.SlashCommands["show"] = function(value)
    EPGPUserFrame:Show()
end