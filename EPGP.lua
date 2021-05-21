if TBCEPGP == nil then TBCEPGP = {} end
TBCEPGP.events = {}
TBCEPGP.Version = 3
local AddOnName = "TBC-EPGP"

local UpdateFrame, EventFrame = nil, nil

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
    Dates[#Dates + 1] = dateString

    if curDate.Encounters == nil then curDate.Encounters = {} end
    local Encounters = curDate.Encounters
    if curDate[encounterID] == nil then curDate[encounterID] = {} end
    local curEncounter = curDate[encounterID]
    Encounters[#Encounters + 1] = encounterID

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
    end
end

TBCEPGP:OnLoad()

TBCEPGP.SlashCommands["roll"] = function(value)
    TBCEPGP:RollItem(value)
end