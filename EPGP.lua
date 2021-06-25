if TBCEPGP == nil then TBCEPGP = {} end
TBCEPGP.Events = {}
TBCEPGP.Version = 15
local AddOnName = "TBC-EPGP"

local UpdateFrame, EventFrame, EPGPUserFrame, scrollPanel, EPGPOptionsPanel = nil, nil, nil, nil, nil
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
    C_ChatInfo.RegisterAddonMessagePrefix("TBCEPGPVersion")

    EventFrame = CreateFrame("Frame", nil, UIParent)
    TBCEPGP:RegisterEvents("ENCOUNTER_START", function(...) TBCEPGP.Events:EncounterStart(...) end)
    TBCEPGP:RegisterEvents("ADDON_LOADED", function(...) TBCEPGP.Events:AddonLoaded(...) end)
    TBCEPGP:RegisterEvents("VARIABLES_LOADED", function(...) TBCEPGP.Events:VariablesLoaded(...) end)
    TBCEPGP:RegisterEvents("CHAT_MSG_ADDON", function(...) TBCEPGP.Events:ChatMsgAddon(...) end)
    TBCEPGP:RegisterEvents("GROUP_ROSTER_UPDATE", function(...) TBCEPGP.Events:GroupRosterUpdate(...) end)

    EventFrame:SetScript("OnEvent", function(...)
        TBCEPGP:OnEvent(...)
    end)

    UpdateFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    UpdateFrame:SetPoint("CENTER", 0, 250)
    UpdateFrame:SetSize(400, 100)
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

    UpdateFrame.text = UpdateFrame:CreateFontString("UpdateFrame", "ARTWORK", "GameFontNormal")
    UpdateFrame.text:SetPoint("TOP", 0, -30)
    UpdateFrame.text:SetText("-----")

    local UpdateFrameCloseButton = CreateFrame("Button", nil, UpdateFrame, "UIPanelCloseButton")
    UpdateFrameCloseButton:SetWidth(25)
    UpdateFrameCloseButton:SetHeight(25)
    UpdateFrameCloseButton:SetPoint("TOPRIGHT", UpdateFrame, "TOPRIGHT", 2, 2)
    UpdateFrameCloseButton:SetScript("OnClick", function() UpdateFrame:Hide() end )

    UpdateFrame:Hide()

    EPGPOptionsPanel = CreateFrame("FRAME", nil)
    EPGPOptionsPanel.name = "TBC-EPGP"
    InterfaceOptions_AddCategory(EPGPOptionsPanel)

    EPGPOptionsPanel.header = EPGPOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    EPGPOptionsPanel.header:SetPoint("TOP", 0, -10)
    EPGPOptionsPanel.header:SetText("|cFF00FFFFTBC EPGP Options!|r")

    EPGPOptionsPanel.subheader = EPGPOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    EPGPOptionsPanel.subheader:SetPoint("TOP", 0, -35)
    EPGPOptionsPanel.subheader:SetText("|cFF00FFFFBy AzerPUG and Punch&Pie!|r")

    EPGPOptionsPanel.adminsEditBoxText = EPGPOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    EPGPOptionsPanel.adminsEditBoxText:SetSize(200, 25)
    EPGPOptionsPanel.adminsEditBoxText:SetPoint("TOPLEFT", 25, -100)
    EPGPOptionsPanel.adminsEditBoxText:SetText("Add Admins for Sync\n(multi-names split by a space)")

    EPGPOptionsPanel.adminsEditBox = CreateFrame("EditBox", nil, EPGPOptionsPanel, "InputBoxTemplate")
    EPGPOptionsPanel.adminsEditBox:SetSize(200, 25)
    EPGPOptionsPanel.adminsEditBox:SetPoint("TOPLEFT", 25, -125)
    EPGPOptionsPanel.adminsEditBox:SetAutoFocus(false)
    EPGPOptionsPanel.adminsEditBox:SetScript("OnEditFocusLost", function() TBCEPGPAdminList = TBCEPGP:splitCharacterNames(EPGPOptionsPanel.adminsEditBox:GetText()) end)
    EPGPOptionsPanel.adminsEditBox:SetScript("OnShow",
    function()
        local adminsToSet = ""
        if TBCEPGPAdminList ~= nil and #TBCEPGPAdminList > 0 then
            for i = 1, #TBCEPGPAdminList do
                adminsToSet = TBCEPGPAdminList[i] .. " "
            end
            EPGPOptionsPanel.adminsEditBox:SetText(adminsToSet)
        end
    end)

    EPGPOptionsPanel:Hide()
end

function TBCEPGP:splitCharacterNames(input)
    local names = {}
    local inputLen = #input
    local index = 1
    while index < inputLen do
        local _, matchEnd = string.find(input, "%s?([^%s]+)%s?", index)
        local assistName = string.match(input, "%s?([^%s]+)%s?", index)
        index = matchEnd + 1
        table.insert(names, assistName)
    end
    return names
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
    if string.find(DateTimeString, "  ") then
        day, month, _, date, time, year = strsplit(" ", DateTimeString)
    else
        day, month, date, time, year = strsplit(" ", DateTimeString)
    end
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
        if playerData.EP == nil then playerData.EP = 0 end
        if playerData.GP == nil then playerData.GP = 0 end
        message = message .. playerGUID .. ":" .. playerData.Name .. ":" .. playerData.Update .. ":" .. playerData.Class .. ":" .. playerData.EP .. ":" .. playerData.GP .. ":"
        if IsInRaid() then
            C_ChatInfo.SendAddonMessage("TBCEPGP", message ,"RAID", 1)
        else
            C_ChatInfo.SendAddonMessage("TBCEPGP", message ,"GUILD", 1)
        end
    end
    if IsInRaid() then
        C_ChatInfo.SendAddonMessage("TBCEPGP", "EndOfSync" ,"RAID", 1)
    else
        C_ChatInfo.SendAddonMessage("TBCEPGP", "EndOfSync" ,"GUILD", 1)
    end
    print("Sync AddOn Messages Send!")
end

function TBCEPGP.Events:GroupRosterUpdate()
    TBCEPGP:ShareVersion()
end

function TBCEPGP.Events:ChatMsgAddon(prefix, payload, channel, sender)
    local player = UnitName("PLAYER")
    if prefix == "TBCEPGPVersion" and sender ~= player then
        local version = TBCEPGP:GetSpecificAddonVersion(payload, "TBCEPGP")
        if version ~= nil then
            TBCEPGP:ReceiveVersion(version)
        end
    elseif prefix == "TBCEPGP" then
        local playerName = UnitName("player")
        local subPayload = payload
        local players = TBCEPGPDataTable.Players
        local subStringList = {}
        sender = string.match(sender, "(.*)-")
        print("TBC-EPGP Sync Received from:", sender)
        if TBCEPGPAdminList ~= nil and #TBCEPGPAdminList > 0 then
            if sender ~= playerName and tContains(TBCEPGPAdminList, sender) then
                if payload == "EndOfSync" then print("Sync Received from", sender)
                else
                    for i = 1, 6 do
                        if subPayload ~= nil then
                            subPayload = string.sub(subPayload, string.find(subPayload, ":") + 1, #subPayload)
                            local stringFind = string.find(subPayload, ":", 1)
                            if stringFind ~= nil then
                                subStringList[i] = string.sub(subPayload, 0, stringFind - 1)
                            end
                        end
                        subStringList[3] = tonumber(subStringList[3])
                        subStringList[4] = tonumber(subStringList[4])
                        subStringList[5] = tonumber(subStringList[5])
                        subStringList[6] = tonumber(subStringList[6])
                    end

                    if players[subStringList[1]] == nil then
                        local curGUID = subStringList[1]
                        players[curGUID] = {}
                        players[curGUID].Name = subStringList[2]
                        players[curGUID].Update = subStringList[3]
                        players[curGUID].Class = subStringList[4]
                        players[curGUID].EP = subStringList[5]
                        players[curGUID].GP = subStringList[6]
                    else
                        local curGUID = subStringList[1]
                        if players[curGUID].Update < subStringList[3] then
                            players[curGUID].Name = subStringList[2]
                            players[curGUID].Update = subStringList[3]
                            players[curGUID].Class = subStringList[4]
                            players[curGUID].EP = subStringList[5]
                            players[curGUID].GP = subStringList[6]
                        end
                    end
                    for _, value in pairs(players) do
                        if value.EP == nil then value.EP = 0 end
                        if value.GP == nil then value.GP = 0 end
                    end
                    TBCEPGPDataTable.Players = players
                    TBCEPGP:FillUserFrameScrollPanel(players)
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

function TBCEPGP.Events:AddonLoaded(...)
    local addonName = ...
    if addonName == "TBC-EPGP" then
        if variablesLoaded == true then TBCEPGP:VarsAndAddonLoaded() else addonLoaded = true end
    end
end

function TBCEPGP.Events:VariablesLoaded(...)
    if addonLoaded == true then TBCEPGP:VarsAndAddonLoaded() else variablesLoaded = true end
end

function TBCEPGP:VarsAndAddonLoaded()
    if TBCEPGPDataTable == nil then
        TBCEPGPDataTable = TBCEPGP.DataTable
    elseif TBCEPGPDataTable ~= nil then
        TBCEPGP.DataTable = TBCEPGPDataTable
    end

    TBCEPGP:TempDataChanger()

    TBCEPGP.CreateUserFrame()
    TBCEPGP:ShareVersion()
end

function TBCEPGP:DelayedExecution(delayTime, delayedFunction)
    local frame = CreateFrame("Frame")
    frame.start_time = GetServerTime()
    frame:SetScript("OnUpdate",
        function(self)
            if GetServerTime() - self.start_time > delayTime then
                delayedFunction()
                self:SetScript("OnUpdate", nil)
                self:Hide()
            end
        end
    )
    frame:Show()
end

function TBCEPGP:ShareVersion() -- Change DelayedExecution to native WoW Function.
    local versionString = string.format("|TBCEPGP:%d|", TBCEPGP.Version)
    TBCEPGP:DelayedExecution(10, function()
        if UnitInBattleground("player") ~= nil then
            -- BG stuff?
        else
            if IsInGroup() then
                if IsInRaid() then
                    C_ChatInfo.SendAddonMessage("TBCEPGPVersion", versionString ,"RAID", 1)
                else
                    C_ChatInfo.SendAddonMessage("TBCEPGPVersion", versionString ,"PARTY", 1)
                end
            end
            if IsInGuild() then
                C_ChatInfo.SendAddonMessage("TBCEPGPVersion", versionString ,"GUILD", 1)
            end
        end
    end)
end

function TBCEPGP:ReceiveVersion(version)
    if version > TBCEPGP.Version then
        if (not HaveShowedUpdateNotification) then
            HaveShowedUpdateNotification = true
            UpdateFrame:Show()
            UpdateFrame.text:SetText(
                "Please download the new version through the CurseForge app.\n" ..
                "Or use the CurseForge website to download it manually!\n\n" .. 
                "Newer Version: v" .. version .. "\n" .. 
                "Your version: v" .. TBCEPGP.Version
            )
        end
    end
end

function TBCEPGP:GetSpecificAddonVersion(versionString, addonWanted)
    local pattern = "|([A-Z]+):([0-9]+)|"
    local index = 1
    while index < #versionString do
        local _, endPos = string.find(versionString, pattern, index)
        local addon, version = string.match(versionString, pattern, index)
        index = endPos + 1
        if addon == addonWanted then
            return tonumber(version)
        end
    end
end

function TBCEPGP:TempDataChanger()
    for key, value in pairs(TBCEPGP.DataTable.Players) do
        if TBCEPGP.DataTable.Players[key].Class == "Warrior" then TBCEPGP.DataTable.Players[key].Class = 1 end
        if TBCEPGP.DataTable.Players[key].Class == "Paladin" then TBCEPGP.DataTable.Players[key].Class = 2 end
        if TBCEPGP.DataTable.Players[key].Class == "Hunter" then TBCEPGP.DataTable.Players[key].Class = 3 end
        if TBCEPGP.DataTable.Players[key].Class == "Rogue" then TBCEPGP.DataTable.Players[key].Class = 4 end
        if TBCEPGP.DataTable.Players[key].Class == "Priest" then TBCEPGP.DataTable.Players[key].Class = 5 end
        if TBCEPGP.DataTable.Players[key].Class == "Shaman" then TBCEPGP.DataTable.Players[key].Class = 7 end
        if TBCEPGP.DataTable.Players[key].Class == "Mage" then TBCEPGP.DataTable.Players[key].Class = 8 end
        if TBCEPGP.DataTable.Players[key].Class == "Warlock" then TBCEPGP.DataTable.Players[key].Class = 9 end
        if TBCEPGP.DataTable.Players[key].Class == "Druid" then TBCEPGP.DataTable.Players[key].Class = 11 end
    end
end

function TBCEPGP:CreateUserFrame()
    EPGPUserFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    EPGPUserFrame:SetPoint("CENTER", 0, 0)
    EPGPUserFrame:SetSize(600, 400)
    EPGPUserFrame:EnableMouse(true)
    EPGPUserFrame:SetMovable(true)
    EPGPUserFrame:RegisterForDrag("LeftButton")
    EPGPUserFrame:SetScript("OnDragStart", EPGPUserFrame.StartMoving)
    EPGPUserFrame:SetScript("OnDragStop", EPGPUserFrame.StopMovingOrSizing)
    EPGPUserFrame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        edgeSize = 36,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    EPGPUserFrame:SetBackdropColor(1, 1, 1, 1)

    EPGPUserFrame.Title = CreateFrame("FRAME", nil, EPGPUserFrame)
    EPGPUserFrame.Title:SetSize(300, 65)
    EPGPUserFrame.Title:SetPoint("TOP", EPGPUserFrame, "TOP", 0, EPGPUserFrame.Title:GetHeight() * 0.25 - 4)

    EPGPUserFrame.Title.Text = EPGPUserFrame.Title:CreateFontString("EPGPUserFrame", "ARTWORK", "GameFontNormalLarge")
    EPGPUserFrame.Title.Text:SetPoint("TOP", 0, -EPGPUserFrame.Title:GetHeight() * 0.25 + 4)
    EPGPUserFrame.Title.Text:SetText(AddOnName .. " - v" .. TBCEPGP.Version)

    EPGPUserFrame.Title.Texture = EPGPUserFrame.Title:CreateTexture(nil, "BACKGROUND")
    EPGPUserFrame.Title.Texture:SetAllPoints()
    EPGPUserFrame.Title.Texture:SetTexture("Interface/DialogFrame/UI-DialogBox-Header")

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
    EPGPUserFrame.Header.changeEP:HookScript("OnEditFocusLost", function() TBCEPGP:MassChange("EP") end)

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
    EPGPUserFrame.Header.changeGP:HookScript("OnEditFocusLost", function() TBCEPGP:MassChange("GP") end)

    EPGPUserFrame.Header.curPR = EPGPUserFrame.Header:CreateFontString("EPGPUserFrame.Header", "ARTWORK", "GameFontNormal")
    EPGPUserFrame.Header.curPR:SetSize(50, 25)
    EPGPUserFrame.Header.curPR:SetPoint("BOTTOMLEFT", EPGPUserFrame.Header.changeGP, "BOTTOMRIGHT", 25, 0)
    EPGPUserFrame.Header.curPR:SetText("PR")

    local EPGPUserFrameCloseButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelCloseButton, BackDropTemplate")
    EPGPUserFrameCloseButton:SetSize(30, 30)
    EPGPUserFrameCloseButton:SetPoint("TOPRIGHT", EPGPUserFrame, "TOPRIGHT", -4, -4)
    EPGPUserFrameCloseButton:SetScript("OnClick", function() EPGPUserFrame:Hide() end)

    local AddToDataBaseButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelButtonTemplate")
    AddToDataBaseButton:SetSize(50, 30)
    AddToDataBaseButton:SetPoint("TOPLEFT", EPGPUserFrame, "TOPLEFT", 35, -10)
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

    local SortButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelButtonTemplate")
    SortButton:SetSize(50, 30)
    SortButton:SetPoint("LEFT", AddToDataBaseButton, "RIGHT", 10, 0)
    SortButton:SetScript("OnClick",
    function()
        sortedColumn = "Class"
        TBCEPGP:FillUserFrameScrollPanel(filteredPlayers)
    end)
    SortButton.text = SortButton:CreateFontString("SortButton", "ARTWORK", "GameFontNormalTiny")
    SortButton.text:SetPoint("CENTER", 0, -1)
    SortButton.text:SetText("Sort\nClasses")

    local DecayConfirmWindow = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    DecayConfirmWindow:SetSize(300, 150)
    DecayConfirmWindow:SetPoint("CENTER", 0, 200)
    DecayConfirmWindow:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    DecayConfirmWindow:SetBackdropColor(1, 0, 0, 1)

    DecayConfirmWindow.Header = DecayConfirmWindow:CreateFontString("DecayConfirmWindow", "ARTWORK", "GameFontNormalHuge")
    DecayConfirmWindow.Header:SetSize(DecayConfirmWindow:GetWidth(), 25)
    DecayConfirmWindow.Header:SetPoint("TOP", 0, -5)
    DecayConfirmWindow.Header:SetText("|cFFFF0000WARNING!|r")

    DecayConfirmWindow.WarningText = DecayConfirmWindow:CreateFontString("DecayConfirmWindow", "ARTWORK", "GameFontNormalLarge")
    DecayConfirmWindow.WarningText:SetSize(DecayConfirmWindow:GetWidth(), 50)
    DecayConfirmWindow.WarningText:SetPoint("TOP", DecayConfirmWindow.Header, "BOTTOM", 0, -10)
    DecayConfirmWindow.WarningText:SetText("|cFFFF0000Are you sure you want to decay\nthe entire dataTable?\nThis can not be undone!|r")

    DecayConfirmWindow.ConfirmButton = CreateFrame("Button", nil, DecayConfirmWindow, "UIPanelButtonTemplate")
    DecayConfirmWindow.ConfirmButton:SetSize(75, 25)
    DecayConfirmWindow.ConfirmButton:SetPoint("TOP", DecayConfirmWindow, "BOTTOM", -50, 35)
    DecayConfirmWindow.ConfirmButton:SetText("Confirm")
    DecayConfirmWindow.ConfirmButton:SetScript("OnClick", function() TBCEPGP:DecayDataTable() DecayConfirmWindow:Hide() end)

    DecayConfirmWindow.CancelButton = CreateFrame("Button", nil, DecayConfirmWindow, "UIPanelButtonTemplate")
    DecayConfirmWindow.CancelButton:SetSize(75, 25)
    DecayConfirmWindow.CancelButton:SetPoint("TOP", DecayConfirmWindow, "BOTTOM", 50, 35)
    DecayConfirmWindow.CancelButton:SetText("Cancel")
    DecayConfirmWindow.CancelButton:SetScript("OnClick", function() DecayConfirmWindow:Hide() end)

    DecayConfirmWindow:Hide()

    local DecayButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelButtonTemplate")
    DecayButton:SetSize(50, 30)
    DecayButton:SetPoint("TOPRIGHT", EPGPUserFrame, "TOPRIGHT", -35, -10)
    DecayButton:SetScript("OnClick",
    function()
        DecayConfirmWindow:Show()
        print("DecayButtonPresssed!")
    end)
    DecayButton.text = DecayButton:CreateFontString("DecayButton", "ARTWORK", "GameFontNormalTiny")
    DecayButton.text:SetPoint("CENTER", 0, -1)
    DecayButton.text:SetText("Decay\nPlayers")

    local SyncButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelButtonTemplate")
    SyncButton:SetSize(50, 30)
    SyncButton:SetPoint("Right", DecayButton, "Left", -10, 0)
    SyncButton:SetScript("OnClick",
    function()
        print("Trying to sync...")
        TBCEPGP:SyncRaidersAddOnMsg()
    end)
    SyncButton.text = SyncButton:CreateFontString("SyncButton", "ARTWORK", "GameFontNormalTiny")
    SyncButton.text:SetPoint("CENTER", 0, -1)
    SyncButton.text:SetText("Sync\nNow")

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

function TBCEPGP:DecayDataTable()
    local players = TBCEPGP.DataTable.Players
    for key, value in pairs(players) do
        value.GP = value.GP * 0.85
        value.EP = value.EP * 0.85
    end
end

function TBCEPGP:MassChange(Points)
    local PointsChange = tonumber(EPGPUserFrame.Header["change" .. Points]:GetText())
    if PointsChange ~= nil then
        local players = TBCEPGPDataTable.Players
        if filteredPlayers == nil then filteredPlayers = players end
        for key, value in pairs(filteredPlayers) do
            value[Points] = value[Points] + PointsChange
            value.Update = time()
        end
        EPGPUserFrame.Header["change" .. Points]:SetText(0)
        TBCEPGP:FillUserFrameScrollPanel(filteredPlayers)
    end
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
    local allFiltersOff = true
    for i = 1, 11 do
        if i == 6 or i == 10 then
        else
            if filteredClasses[i] == true then allFiltersOff = false end
        end
    end
    if allFiltersOff == true then filteredPlayers = players end
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

            curPlayerFrame.curPR = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.curPR:SetSize(50, 25)
            curPlayerFrame.curPR:SetPoint("LEFT", curPlayerFrame.changeGP, "RIGHT", 25, 0)

            curPlayerFrame.changeEP:HookScript("OnEditFocusLost",
            function()
                players[curPlayerFrame.key].EP = players[curPlayerFrame.key].EP + tonumber(curPlayerFrame.changeEP:GetText())
                players[curPlayerFrame.key].Update = time()
                curPlayerFrame.curEP:SetText(players[curPlayerFrame.key].EP)
                curPlayerFrame.changeEP:SetText(0)

                local curPR = nil
                curPR = TBCEPGP:CalculatePriority(players[curPlayerFrame.key].EP, players[curPlayerFrame.key].GP)
                curPlayerFrame.curPR:SetText(curPR)
            end)

            curPlayerFrame.changeGP:HookScript("OnEditFocusLost",
            function()
                players[curPlayerFrame.key].GP = players[curPlayerFrame.key].GP + tonumber(curPlayerFrame.changeGP:GetText())
                players[curPlayerFrame.key].Update = time()
                curPlayerFrame.curGP:SetText(players[curPlayerFrame.key].GP)
                curPlayerFrame.changeGP:SetText(0)

                local curPR = nil
                curPR = TBCEPGP:CalculatePriority(players[curPlayerFrame.key].EP, players[curPlayerFrame.key].GP)
                curPlayerFrame.curPR:SetText(curPR)
            end)
        end

        filteredPlayerFrames[index] = curPlayerFrame

        local curName, curClass, curEP, curGP, curPR = nil, nil, nil, nil, nil
        curPlayerFrame.key = key

        curName = value.Name
        curClass = value.Class
        curEP = value.EP
        curGP = value.GP
        
        curPR = TBCEPGP:CalculatePriority(curEP, curGP)

        curPlayerFrame:Show()

        curPlayerFrame.Name:SetText(curName)
        curPlayerFrame.Class:SetText(classNumbers[curClass][1])
        curPlayerFrame.curEP:SetText(curEP)
        curPlayerFrame.curGP:SetText(curGP)
        curPlayerFrame.curPR:SetText(curPR)
        curPlayerFrame.changeEP:SetText(0)
        curPlayerFrame.changeGP:SetText(0)

        index = index + 1
    end

    if sortedColumn ~= nil then
        table.sort(filteredPlayerFrames, function(a, b)
            if sortedColumn == "Class" then
                return players[a.key].Class > players[b.key].Class
            end
        end)
    end

    for j, frame in pairs(filteredPlayerFrames) do
        frame:SetPoint("TOPLEFT", scrollPanel, "TOPLEFT", 0, -24 * j + 24)
    end
end

function TBCEPGP:CalculatePriority(curEP, curGP)
    local curPR = nil
    if curEP == 0 or curGP == 0 then curPR = "-" else curPR = curEP/curGP end
    return curPR
end

function TBCEPGP.Events:EncounterStart()
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