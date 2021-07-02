if TBCEPGP == nil then TBCEPGP = {} end
TBCEPGP.Events = {}
TBCEPGP.Version = 17
local AddOnName = "TBC-EPGP"

local UpdateFrame, EventFrame, EPGPOptionsPanel = nil, nil, nil
local EPGPUserFrame, UserScrollPanel = nil, nil
local EPGPAdminFrame, AdminScrollPanel = nil, nil
local playerFrames = {}
local sortedColumn, filteredPlayers = nil, nil
local addonLoaded, variablesLoaded = false, false

-- Stuff To Use?
-- Interface\Artifacts\Artifacts-PerkRing-Final-Mask

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

    EPGPOptionsPanel.showAdminViewCheckButton = CreateFrame("CheckButton", "ShowAdminViewCheckButton", EPGPOptionsPanel, "ChatConfigCheckButtonTemplate");
    EPGPOptionsPanel.showAdminViewCheckButton:SetPoint("TOPLEFT", 25, -175);
    EPGPOptionsPanel.showAdminViewCheckButton:SetScript("OnClick", function()
        TBCEPGPShowAdminView = EPGPOptionsPanel.showAdminViewCheckButton:GetChecked()
        if TBCEPGPShowAdminView then
            EPGPUserFrame:Hide()
            EPGPAdminFrame:Show()
        else
            EPGPAdminFrame:Hide()
            EPGPUserFrame:Show()
        end
    end)
    ShowAdminViewCheckButtonText:SetText("Show Admin View")


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
    if curGUID:find("Player-") ~= nil then
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
    else
        print("NPC is not allowed.")
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
                    TBCEPGP:FillUserFrameUserScrollPanel(players)
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

    TBCEPGP.CreateAdminFrame()
    TBCEPGP.CreateUserFrame()

    if TBCEPGPShowAdminView then
        EPGPAdminFrame:Show()
    else
        EPGPUserFrame:Show()
    end
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

function TBCEPGP:CreateAdminFrame()
    EPGPAdminFrame = CreateFrame("Frame", nil, UIParent)
    EPGPAdminFrame:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame:SetSize(470, 400)
    EPGPAdminFrame:EnableMouse(true)
    EPGPAdminFrame:SetMovable(true)
    EPGPAdminFrame:RegisterForDrag("LeftButton")
    EPGPAdminFrame:SetScript("OnDragStart", EPGPAdminFrame.StartMoving)
    EPGPAdminFrame:SetScript("OnDragStop", EPGPAdminFrame.StopMovingOrSizing)

    EPGPAdminFrame.TopLeftBG     = CreateFrame("Frame", nil, EPGPAdminFrame, "BackdropTemplate")
    EPGPAdminFrame.TopBG         = CreateFrame("Frame", nil, EPGPAdminFrame, "BackdropTemplate")
    EPGPAdminFrame.TopRightBG    = CreateFrame("Frame", nil, EPGPAdminFrame, "BackdropTemplate")
    EPGPAdminFrame.BotLeftBG     = CreateFrame("Frame", nil, EPGPAdminFrame, "BackdropTemplate")
    EPGPAdminFrame.BotBG         = CreateFrame("Frame", nil, EPGPAdminFrame, "BackdropTemplate")
    EPGPAdminFrame.BotRightBG    = CreateFrame("Frame", nil, EPGPAdminFrame, "BackdropTemplate")

    EPGPAdminFrame.TopLeftBG :SetSize(200, EPGPAdminFrame:GetHeight() / 2)
    EPGPAdminFrame.TopBG     :SetSize(200, EPGPAdminFrame:GetHeight() / 2)
    EPGPAdminFrame.TopRightBG:SetSize(100, EPGPAdminFrame:GetHeight() / 2)
    EPGPAdminFrame.BotLeftBG :SetSize(200, EPGPAdminFrame:GetHeight() / 2)
    EPGPAdminFrame.BotBG     :SetSize(200, EPGPAdminFrame:GetHeight() / 2)
    EPGPAdminFrame.BotRightBG:SetSize(100, EPGPAdminFrame:GetHeight() / 2)

    EPGPAdminFrame.TopLeftBG :SetPoint("TOPLEFT", 0, 0)
    EPGPAdminFrame.TopBG     :SetPoint("LEFT", EPGPAdminFrame.TopLeftBG, "RIGHT", 0, 0)
    EPGPAdminFrame.TopRightBG:SetPoint("LEFT", EPGPAdminFrame.TopBG, "RIGHT", 0, 0)

    EPGPAdminFrame.BotLeftBG :SetPoint("TOP", EPGPAdminFrame.TopLeftBG, "BOTTOM", 0, 0)
    EPGPAdminFrame.BotBG     :SetPoint("TOP", EPGPAdminFrame.TopBG, "BOTTOM", 0, 0)
    EPGPAdminFrame.BotRightBG:SetPoint("TOP", EPGPAdminFrame.TopRightBG, "BOTTOM", 0, 0)

    EPGPAdminFrame.TopLeftBG :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-TOPLEFT"})
    EPGPAdminFrame.TopBG     :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-TOP"})
    EPGPAdminFrame.TopRightBG:SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-TOPRIGHT"})
    EPGPAdminFrame.BotLeftBG :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-BOTLEFT"})
    EPGPAdminFrame.BotBG     :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-BOTTOM"})
    EPGPAdminFrame.BotRightBG:SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-BOTRIGHT"})

    EPGPAdminFrame.Title = CreateFrame("FRAME", nil, EPGPAdminFrame)
    EPGPAdminFrame.Title:SetSize(300, 65)
    EPGPAdminFrame.Title:SetPoint("TOP", EPGPAdminFrame, "TOP", 0, EPGPAdminFrame.Title:GetHeight() * 0.35 - 4)
    EPGPAdminFrame.Title:SetFrameStrata("HIGH")

    EPGPAdminFrame.Title.Text = EPGPAdminFrame.Title:CreateFontString("EPGPAdminFrame", "ARTWORK", "GameFontNormalLarge")
    EPGPAdminFrame.Title.Text:SetPoint("TOP", 0, -EPGPAdminFrame.Title:GetHeight() * 0.25 + 3)
    EPGPAdminFrame.Title.Text:SetText(AddOnName .. " - v" .. TBCEPGP.Version)

    EPGPAdminFrame.Title.Texture = EPGPAdminFrame.Title:CreateTexture(nil, "BACKGROUND")
    EPGPAdminFrame.Title.Texture:SetAllPoints()
    EPGPAdminFrame.Title.Texture:SetTexture("Interface/DialogFrame/UI-DialogBox-Header")

    EPGPAdminFrame.ExtraBG = CreateFrame("FRAME", nil, EPGPAdminFrame, "BackdropTemplate")
    EPGPAdminFrame.ExtraBG:SetSize(EPGPAdminFrame:GetWidth() - 25, EPGPAdminFrame:GetHeight() - 79)
    EPGPAdminFrame.ExtraBG:SetPoint("TOP", 2, -41)
    EPGPAdminFrame.ExtraBG:SetFrameStrata("HIGH")
    EPGPAdminFrame.ExtraBG:SetBackdrop({
        bgFile = "Interface/BankFrame/Bank-Background",
        tile = true,
        tileSize = 100;
    })
    EPGPAdminFrame.ExtraBG:SetBackdropColor(0.25, 0.25, 0.25, 1)

    local scrollFrame = CreateFrame("ScrollFrame", "scrollFrame", EPGPAdminFrame, "UIPanelScrollFrameTemplate BackdropTemplate");
    scrollFrame:SetSize(EPGPAdminFrame:GetWidth() - 45, EPGPAdminFrame:GetHeight() - 77)
    scrollFrame:SetPoint("TOP", -11, -40)
    scrollFrame:SetFrameStrata("HIGH")

    UserScrollPanel = CreateFrame("Frame")
    UserScrollPanel:SetSize(scrollFrame:GetWidth(), 300)
    UserScrollPanel:SetPoint("TOP")

    EPGPAdminFrame.Header = CreateFrame("Frame", nil, EPGPAdminFrame, "BackdropTemplate")
    EPGPAdminFrame.Header:SetPoint("TOP", -11, -20)
    EPGPAdminFrame.Header:SetSize(UserScrollPanel:GetWidth(), 50)

    EPGPAdminFrame.Header.Name = CreateFrame("Frame", nil, EPGPAdminFrame.Header, "BackdropTemplate")
    EPGPAdminFrame.Header.Name:SetSize(100, 24)
    EPGPAdminFrame.Header.Name:SetPoint("TOPLEFT", 5, 0)
    EPGPAdminFrame.Header.Name:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPAdminFrame.Header.Name:SetBackdropColor(1, 1, 1, 1)

    EPGPAdminFrame.Header.Name.Text = EPGPAdminFrame.Header.Name:CreateFontString("EPGPAdminFrame.Header.Name.Text", "ARTWORK", "GameFontNormal")
    EPGPAdminFrame.Header.Name.Text:SetSize(EPGPAdminFrame.Header.Name:GetWidth(), EPGPAdminFrame.Header.Name:GetHeight())
    EPGPAdminFrame.Header.Name.Text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.Header.Name.Text:SetTextColor(1, 1, 1, 1)
    EPGPAdminFrame.Header.Name.Text:SetText("Name")

    EPGPAdminFrame.Header.Class = CreateFrame("Frame", nil, EPGPAdminFrame.Header, "BackdropTemplate")
    EPGPAdminFrame.Header.Class:SetSize(100, 24)
    EPGPAdminFrame.Header.Class:SetPoint("BOTTOMLEFT", EPGPAdminFrame.Header.Name, "BOTTOMRIGHT", -4, 0)
    EPGPAdminFrame.Header.Class:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPAdminFrame.Header.Class:SetBackdropColor(1, 1, 1, 1)

    EPGPAdminFrame.Header.Class.Text = EPGPAdminFrame.Header.Class:CreateFontString("EPGPAdminFrame.Header.Class.Text", "ARTWORK", "GameFontNormal")
    EPGPAdminFrame.Header.Class.Text:SetSize(EPGPAdminFrame.Header.Class:GetWidth(), EPGPAdminFrame.Header.Class:GetHeight())
    EPGPAdminFrame.Header.Class.Text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.Header.Class.Text:SetTextColor(1, 1, 1, 1)
    EPGPAdminFrame.Header.Class.Text:SetText("Class")

    -- local FilterButtons = {}
    -- for i = 1, 11 do
    --     if i == 6 or i == 10 then -- Parsing out Monk(6) and DeathKnight(10) index numbers. (DH == 12)
    --     else
    --         FilterButtons[i] = CreateFrame("Button", nil, EPGPAdminFrame.Header, "BackdropTemplate")
    --         FilterButtons[i]:SetSize(20, 16)

    --         local xOff, yOff = nil, nil
    --         if i == 1 or i == 4 or i == 8 then
    --             xOff = -18
    --         elseif i == 2 or i == 5 or i == 9 then
    --             xOff = -0
    --         elseif i == 3 or i == 7 or i == 11 then
    --             xOff = 18
    --         end
    --         if i == 1 or i == 2 or i == 3 then
    --             yOff = 13
    --         elseif i == 4 or i == 5 or i == 7 then
    --             yOff = 0
    --         elseif i == 8 or i == 9 or i == 11 then
    --             yOff = -13
    --         end

    --         FilterButtons[i]:SetPoint("LEFT", EPGPAdminFrame.Header.Class, "RIGHT", -60 + xOff, 30 + yOff)

    --         FilterButtons[i]:SetBackdrop({
    --             bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    --             edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    --             edgeSize = 10,
    --             insets = {left = 3, right = 3, top = 3, bottom = 3},
    --         })

    --         local r, g = 1, 0
    --         FilterButtons[i]:SetBackdropColor(1, 0, 0, 1)

    --         FilterButtons[i]:SetScript("OnClick",
    --         function()
    --             if filteredClasses[i] then
    --                 filteredClasses[i] = false
    --                 r = 1
    --                 g = 0
    --             else
    --                 filteredClasses[i] = true
    --                 r = 0
    --                 g = 1
    --             end
    --             TBCEPGP:filterPlayers(i)
    --             FilterButtons[i]:SetBackdropColor(r, g, 0, 1)
    --         end)

    --         FilterButtons[i].text = FilterButtons[i]:CreateFontString("FilterButton", "ARTWORK", "GameFontNormalTiny")
    --         FilterButtons[i].text:SetPoint("CENTER", 0, 0)
    --         FilterButtons[i].text:SetText(classNumbers[i][2])
    --     end
    -- end

    EPGPAdminFrame.Header.curEP = CreateFrame("Frame", nil, EPGPAdminFrame.Header, "BackdropTemplate")
    EPGPAdminFrame.Header.curEP:SetSize(75, 24)
    EPGPAdminFrame.Header.curEP:SetPoint("BOTTOMLEFT", EPGPAdminFrame.Header.Class, "BOTTOMRIGHT", -4, 0)
    EPGPAdminFrame.Header.curEP:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPAdminFrame.Header.curEP:SetBackdropColor(1, 1, 1, 1)

    EPGPAdminFrame.Header.curEP.Text = EPGPAdminFrame.Header.curEP:CreateFontString("EPGPAdminFrame.Header.curEP.Text", "ARTWORK", "GameFontNormal")
    EPGPAdminFrame.Header.curEP.Text:SetSize(EPGPAdminFrame.Header.curEP:GetWidth(), EPGPAdminFrame.Header.curEP:GetHeight())
    EPGPAdminFrame.Header.curEP.Text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.Header.curEP.Text:SetTextColor(1, 1, 1, 1)
    EPGPAdminFrame.Header.curEP.Text:SetText("EP")

    EPGPAdminFrame.Header.curGP = CreateFrame("Frame", nil, EPGPAdminFrame.Header, "BackdropTemplate")
    EPGPAdminFrame.Header.curGP:SetSize(75, 24)
    EPGPAdminFrame.Header.curGP:SetPoint("BOTTOMLEFT", EPGPAdminFrame.Header.curEP, "BOTTOMRIGHT", -4, 0)
    EPGPAdminFrame.Header.curGP:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPAdminFrame.Header.curGP:SetBackdropColor(1, 1, 1, 1)

    EPGPAdminFrame.Header.curGP.Text = EPGPAdminFrame.Header.curGP:CreateFontString("EPGPAdminFrame.Header.curGP.Text", "ARTWORK", "GameFontNormal")
    EPGPAdminFrame.Header.curGP.Text:SetSize(EPGPAdminFrame.Header.curGP:GetWidth(), EPGPAdminFrame.Header.curGP:GetHeight())
    EPGPAdminFrame.Header.curGP.Text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.Header.curGP.Text:SetTextColor(1, 1, 1, 1)
    EPGPAdminFrame.Header.curGP.Text:SetText("GP")

    EPGPAdminFrame.Header.curPR = CreateFrame("Frame", nil, EPGPAdminFrame.Header, "BackdropTemplate")
    EPGPAdminFrame.Header.curPR:SetSize(75, 24)
    EPGPAdminFrame.Header.curPR:SetPoint("BOTTOMLEFT", EPGPAdminFrame.Header.curGP, "BOTTOMRIGHT", -4, 0)
    EPGPAdminFrame.Header.curPR:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPAdminFrame.Header.curPR:SetBackdropColor(1, 1, 1, 1)

    EPGPAdminFrame.Header.curPR.Text = EPGPAdminFrame.Header.curPR:CreateFontString("EPGPAdminFrame.Header.curPR.Text", "ARTWORK", "GameFontNormal")
    EPGPAdminFrame.Header.curPR.Text:SetSize(EPGPAdminFrame.Header.curPR:GetWidth(), EPGPAdminFrame.Header.curPR:GetHeight())
    EPGPAdminFrame.Header.curPR.Text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.Header.curPR.Text:SetTextColor(1, 1, 1, 1)
    EPGPAdminFrame.Header.curPR.Text:SetText("PR")

    local curFont, curSize, curFlags = EPGPAdminFrame.Header.Name.Text:GetFont()
    EPGPAdminFrame.Header.Name.Text:SetFont(curFont, curSize - 2, curFlags)
    EPGPAdminFrame.Header.Class.Text:SetFont(curFont, curSize - 2, curFlags)
    EPGPAdminFrame.Header.curEP.Text:SetFont(curFont, curSize - 2, curFlags)
    EPGPAdminFrame.Header.curGP.Text:SetFont(curFont, curSize - 2, curFlags)
    EPGPAdminFrame.Header.curPR.Text:SetFont(curFont, curSize - 2, curFlags)

    local EPGPAdminFrameCloseButton = CreateFrame("Button", nil, EPGPAdminFrame, "UIPanelCloseButton, BackDropTemplate")
    EPGPAdminFrameCloseButton:SetSize(24, 24)
    EPGPAdminFrameCloseButton:SetPoint("TOPRIGHT", EPGPAdminFrame, "TOPRIGHT", -3, -3)
    EPGPAdminFrameCloseButton:SetScript("OnClick", function() EPGPAdminFrame:Hide() end)

    local AddToDataBaseButton = CreateFrame("Button", nil, EPGPAdminFrame, "UIPanelButtonTemplate")
    AddToDataBaseButton:SetSize(75, 20)
    AddToDataBaseButton:SetPoint("BOTTOMLEFT", EPGPAdminFrame, "BOTTOMLEFT", 9, 15)
    AddToDataBaseButton:SetFrameStrata("HIGH")
    AddToDataBaseButton:SetScript("OnClick",
    function()
        local players = TBCEPGP.DataTable.Players
        local unitGUID = UnitGUID("Target")
        local unitName = UnitName("Target")
        local _, _, unitClass = UnitClass("Target")
        TBCEPGP:AddPlayerToList(unitGUID, unitName, unitClass)
        TBCEPGP:FillUserFrameUserScrollPanel(players)
    end)
    AddToDataBaseButton.text = AddToDataBaseButton:CreateFontString("AddToDataBaseButton", "ARTWORK", "GameFontNormalTiny")
    AddToDataBaseButton.text:SetPoint("CENTER", 0, 0)
    AddToDataBaseButton.text:SetText("Add Target")

    local DecayConfirmWindow = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    DecayConfirmWindow:SetSize(300, 150)
    DecayConfirmWindow:SetPoint("CENTER", 0, 200)
    DecayConfirmWindow:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    DecayConfirmWindow:SetBackdropColor(1, 0.25, 0.25, 1)

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

    EPGPAdminFrame.DecayButton = CreateFrame("Button", nil, EPGPAdminFrame, "UIPanelButtonTemplate")
    EPGPAdminFrame.DecayButton:SetSize(75, 20)
    EPGPAdminFrame.DecayButton:SetPoint("BOTTOMRIGHT", EPGPAdminFrame, "BOTTOMRIGHT", -10, 15)
    EPGPAdminFrame.DecayButton:SetFrameStrata("HIGH")
    EPGPAdminFrame.DecayButton:SetScript("OnClick",
    function()
        DecayConfirmWindow:Show()
        print("DecayButtonPresssed!")
    end)
    EPGPAdminFrame.DecayButton.text = EPGPAdminFrame.DecayButton:CreateFontString("DecayButton", "ARTWORK", "GameFontNormalTiny")
    EPGPAdminFrame.DecayButton.text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.DecayButton.text:SetText("Decay")

    EPGPAdminFrame.SyncButton = CreateFrame("Button", nil, EPGPAdminFrame, "UIPanelButtonTemplate")
    EPGPAdminFrame.SyncButton:SetSize(75, 20)
    EPGPAdminFrame.SyncButton:SetPoint("Right", EPGPAdminFrame.DecayButton, "Left", -10, 0)
    EPGPAdminFrame.SyncButton:SetFrameStrata("HIGH")
    EPGPAdminFrame.SyncButton:SetScript("OnClick",
    function()
        print("Trying to sync...")
        TBCEPGP:SyncRaidersAddOnMsg()
    end)
    EPGPAdminFrame.SyncButton.text = EPGPAdminFrame.SyncButton:CreateFontString("SyncButton", "ARTWORK", "GameFontNormalTiny")
    EPGPAdminFrame.SyncButton.text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.SyncButton.text:SetText("Sync")

    local players = TBCEPGP.DataTable.Players
    TBCEPGP:FillAdminFrameUserScrollPanel(players)
    scrollFrame:SetScrollChild(UserScrollPanel)

    EPGPAdminFrame:Hide()
end

function TBCEPGP:CreateUserFrame()
    EPGPUserFrame = CreateFrame("Frame", nil, UIParent)
    EPGPUserFrame:SetPoint("CENTER", 0, 0)
    EPGPUserFrame:SetSize(470, 400)
    EPGPUserFrame:EnableMouse(true)
    EPGPUserFrame:SetMovable(true)
    EPGPUserFrame:RegisterForDrag("LeftButton")
    EPGPUserFrame:SetScript("OnDragStart", EPGPUserFrame.StartMoving)
    EPGPUserFrame:SetScript("OnDragStop", EPGPUserFrame.StopMovingOrSizing)

    EPGPUserFrame.TopLeftBG     = CreateFrame("Frame", nil, EPGPUserFrame, "BackdropTemplate")
    EPGPUserFrame.TopBG         = CreateFrame("Frame", nil, EPGPUserFrame, "BackdropTemplate")
    EPGPUserFrame.TopRightBG    = CreateFrame("Frame", nil, EPGPUserFrame, "BackdropTemplate")
    EPGPUserFrame.BotLeftBG     = CreateFrame("Frame", nil, EPGPUserFrame, "BackdropTemplate")
    EPGPUserFrame.BotBG         = CreateFrame("Frame", nil, EPGPUserFrame, "BackdropTemplate")
    EPGPUserFrame.BotRightBG    = CreateFrame("Frame", nil, EPGPUserFrame, "BackdropTemplate")

    EPGPUserFrame.TopLeftBG :SetSize(200, EPGPUserFrame:GetHeight() / 2)
    EPGPUserFrame.TopBG     :SetSize(200, EPGPUserFrame:GetHeight() / 2)
    EPGPUserFrame.TopRightBG:SetSize(100, EPGPUserFrame:GetHeight() / 2)
    EPGPUserFrame.BotLeftBG :SetSize(200, EPGPUserFrame:GetHeight() / 2)
    EPGPUserFrame.BotBG     :SetSize(200, EPGPUserFrame:GetHeight() / 2)
    EPGPUserFrame.BotRightBG:SetSize(100, EPGPUserFrame:GetHeight() / 2)

    EPGPUserFrame.TopLeftBG :SetPoint("TOPLEFT", 0, 0)
    EPGPUserFrame.TopBG     :SetPoint("LEFT", EPGPUserFrame.TopLeftBG, "RIGHT", 0, 0)
    EPGPUserFrame.TopRightBG:SetPoint("LEFT", EPGPUserFrame.TopBG, "RIGHT", 0, 0)

    EPGPUserFrame.BotLeftBG :SetPoint("TOP", EPGPUserFrame.TopLeftBG, "BOTTOM", 0, 0)
    EPGPUserFrame.BotBG     :SetPoint("TOP", EPGPUserFrame.TopBG, "BOTTOM", 0, 0)
    EPGPUserFrame.BotRightBG:SetPoint("TOP", EPGPUserFrame.TopRightBG, "BOTTOM", 0, 0)

    EPGPUserFrame.TopLeftBG :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-TOPLEFT"})
    EPGPUserFrame.TopBG     :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-TOP"})
    EPGPUserFrame.TopRightBG:SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-TOPRIGHT"})
    EPGPUserFrame.BotLeftBG :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-BOTLEFT"})
    EPGPUserFrame.BotBG     :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-BOTTOM"})
    EPGPUserFrame.BotRightBG:SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-BOTRIGHT"})

    EPGPUserFrame.Title = CreateFrame("FRAME", nil, EPGPUserFrame)
    EPGPUserFrame.Title:SetSize(300, 65)
    EPGPUserFrame.Title:SetPoint("TOP", EPGPUserFrame, "TOP", 0, EPGPUserFrame.Title:GetHeight() * 0.35 - 4)
    EPGPUserFrame.Title:SetFrameStrata("HIGH")

    EPGPUserFrame.Title.Text = EPGPUserFrame.Title:CreateFontString("EPGPUserFrame", "ARTWORK", "GameFontNormalLarge")
    EPGPUserFrame.Title.Text:SetPoint("TOP", 0, -EPGPUserFrame.Title:GetHeight() * 0.25 + 3)
    EPGPUserFrame.Title.Text:SetText(AddOnName .. " - v" .. TBCEPGP.Version)

    EPGPUserFrame.Title.Texture = EPGPUserFrame.Title:CreateTexture(nil, "BACKGROUND")
    EPGPUserFrame.Title.Texture:SetAllPoints()
    EPGPUserFrame.Title.Texture:SetTexture("Interface/DialogFrame/UI-DialogBox-Header")

    EPGPUserFrame.ExtraBG = CreateFrame("FRAME", nil, EPGPUserFrame, "BackdropTemplate")
    EPGPUserFrame.ExtraBG:SetSize(EPGPUserFrame:GetWidth() - 25, EPGPUserFrame:GetHeight() - 79)
    EPGPUserFrame.ExtraBG:SetPoint("TOP", 2, -41)
    EPGPUserFrame.ExtraBG:SetFrameStrata("HIGH")
    EPGPUserFrame.ExtraBG:SetBackdrop({
        bgFile = "Interface/BankFrame/Bank-Background",
        tile = true,
        tileSize = 100;
    })
    EPGPUserFrame.ExtraBG:SetBackdropColor(0.25, 0.25, 0.25, 1)

    local scrollFrame = CreateFrame("ScrollFrame", "scrollFrame", EPGPUserFrame, "UIPanelScrollFrameTemplate BackdropTemplate");
    scrollFrame:SetSize(EPGPUserFrame:GetWidth() - 45, EPGPUserFrame:GetHeight() - 77)
    scrollFrame:SetPoint("TOP", -11, -40)
    scrollFrame:SetFrameStrata("HIGH")

    UserScrollPanel = CreateFrame("Frame")
    UserScrollPanel:SetSize(scrollFrame:GetWidth(), 300)
    UserScrollPanel:SetPoint("TOP")

    EPGPUserFrame.Header = CreateFrame("Frame", nil, EPGPUserFrame, "BackdropTemplate")
    EPGPUserFrame.Header:SetPoint("TOP", -11, -20)
    EPGPUserFrame.Header:SetSize(UserScrollPanel:GetWidth(), 50)

    EPGPUserFrame.Header.Name = CreateFrame("Frame", nil, EPGPUserFrame.Header, "BackdropTemplate")
    EPGPUserFrame.Header.Name:SetSize(100, 24)
    EPGPUserFrame.Header.Name:SetPoint("TOPLEFT", 5, 0)
    EPGPUserFrame.Header.Name:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPUserFrame.Header.Name:SetBackdropColor(1, 1, 1, 1)

    EPGPUserFrame.Header.Name.Text = EPGPUserFrame.Header.Name:CreateFontString("EPGPUserFrame.Header.Name.Text", "ARTWORK", "GameFontNormal")
    EPGPUserFrame.Header.Name.Text:SetSize(EPGPUserFrame.Header.Name:GetWidth(), EPGPUserFrame.Header.Name:GetHeight())
    EPGPUserFrame.Header.Name.Text:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.Header.Name.Text:SetTextColor(1, 1, 1, 1)
    EPGPUserFrame.Header.Name.Text:SetText("Name")

    EPGPUserFrame.Header.Class = CreateFrame("Frame", nil, EPGPUserFrame.Header, "BackdropTemplate")
    EPGPUserFrame.Header.Class:SetSize(100, 24)
    EPGPUserFrame.Header.Class:SetPoint("BOTTOMLEFT", EPGPUserFrame.Header.Name, "BOTTOMRIGHT", -4, 0)
    EPGPUserFrame.Header.Class:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPUserFrame.Header.Class:SetBackdropColor(1, 1, 1, 1)

    EPGPUserFrame.Header.Class.Text = EPGPUserFrame.Header.Class:CreateFontString("EPGPUserFrame.Header.Class.Text", "ARTWORK", "GameFontNormal")
    EPGPUserFrame.Header.Class.Text:SetSize(EPGPUserFrame.Header.Class:GetWidth(), EPGPUserFrame.Header.Class:GetHeight())
    EPGPUserFrame.Header.Class.Text:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.Header.Class.Text:SetTextColor(1, 1, 1, 1)
    EPGPUserFrame.Header.Class.Text:SetText("Class")

    EPGPUserFrame.Header.curEP = CreateFrame("Frame", nil, EPGPUserFrame.Header, "BackdropTemplate")
    EPGPUserFrame.Header.curEP:SetSize(75, 24)
    EPGPUserFrame.Header.curEP:SetPoint("BOTTOMLEFT", EPGPUserFrame.Header.Class, "BOTTOMRIGHT", -4, 0)
    EPGPUserFrame.Header.curEP:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPUserFrame.Header.curEP:SetBackdropColor(1, 1, 1, 1)

    EPGPUserFrame.Header.curEP.Text = EPGPUserFrame.Header.curEP:CreateFontString("EPGPUserFrame.Header.curEP.Text", "ARTWORK", "GameFontNormal")
    EPGPUserFrame.Header.curEP.Text:SetSize(EPGPUserFrame.Header.curEP:GetWidth(), EPGPUserFrame.Header.curEP:GetHeight())
    EPGPUserFrame.Header.curEP.Text:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.Header.curEP.Text:SetTextColor(1, 1, 1, 1)
    EPGPUserFrame.Header.curEP.Text:SetText("EP")

    EPGPUserFrame.Header.curGP = CreateFrame("Frame", nil, EPGPUserFrame.Header, "BackdropTemplate")
    EPGPUserFrame.Header.curGP:SetSize(75, 24)
    EPGPUserFrame.Header.curGP:SetPoint("BOTTOMLEFT", EPGPUserFrame.Header.curEP, "BOTTOMRIGHT", -4, 0)
    EPGPUserFrame.Header.curGP:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPUserFrame.Header.curGP:SetBackdropColor(1, 1, 1, 1)

    EPGPUserFrame.Header.curGP.Text = EPGPUserFrame.Header.curGP:CreateFontString("EPGPUserFrame.Header.curGP.Text", "ARTWORK", "GameFontNormal")
    EPGPUserFrame.Header.curGP.Text:SetSize(EPGPUserFrame.Header.curGP:GetWidth(), EPGPUserFrame.Header.curGP:GetHeight())
    EPGPUserFrame.Header.curGP.Text:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.Header.curGP.Text:SetTextColor(1, 1, 1, 1)
    EPGPUserFrame.Header.curGP.Text:SetText("GP")

    EPGPUserFrame.Header.curPR = CreateFrame("Frame", nil, EPGPUserFrame.Header, "BackdropTemplate")
    EPGPUserFrame.Header.curPR:SetSize(75, 24)
    EPGPUserFrame.Header.curPR:SetPoint("BOTTOMLEFT", EPGPUserFrame.Header.curGP, "BOTTOMRIGHT", -4, 0)
    EPGPUserFrame.Header.curPR:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPUserFrame.Header.curPR:SetBackdropColor(1, 1, 1, 1)

    EPGPUserFrame.Header.curPR.Text = EPGPUserFrame.Header.curPR:CreateFontString("EPGPUserFrame.Header.curPR.Text", "ARTWORK", "GameFontNormal")
    EPGPUserFrame.Header.curPR.Text:SetSize(EPGPUserFrame.Header.curPR:GetWidth(), EPGPUserFrame.Header.curPR:GetHeight())
    EPGPUserFrame.Header.curPR.Text:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.Header.curPR.Text:SetTextColor(1, 1, 1, 1)
    EPGPUserFrame.Header.curPR.Text:SetText("PR")

    local curFont, curSize, curFlags = EPGPUserFrame.Header.Name.Text:GetFont()
    EPGPUserFrame.Header.Name.Text:SetFont(curFont, curSize - 2, curFlags)
    EPGPUserFrame.Header.Class.Text:SetFont(curFont, curSize - 2, curFlags)
    EPGPUserFrame.Header.curEP.Text:SetFont(curFont, curSize - 2, curFlags)
    EPGPUserFrame.Header.curGP.Text:SetFont(curFont, curSize - 2, curFlags)
    EPGPUserFrame.Header.curPR.Text:SetFont(curFont, curSize - 2, curFlags)

    local EPGPUserFrameCloseButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelCloseButton, BackDropTemplate")
    EPGPUserFrameCloseButton:SetSize(24, 24)
    EPGPUserFrameCloseButton:SetPoint("TOPRIGHT", EPGPUserFrame, "TOPRIGHT", -3, -3)
    EPGPUserFrameCloseButton:SetScript("OnClick", function() EPGPUserFrame:Hide() end)

    local players = TBCEPGP.DataTable.Players
    TBCEPGP:FillUserFrameUserScrollPanel(players)
    scrollFrame:SetScrollChild(UserScrollPanel)

    EPGPUserFrame:Hide()
end

function TBCEPGP:DecayDataTable()
    local players = TBCEPGP.DataTable.Players
    for key, value in pairs(players) do
        value.EP = TBCEPGP:MathRound(value.EP * 1000 * 0.85) / 1000
        value.GP = TBCEPGP:MathRound(value.GP * 1000 * 0.85) / 1000
        value.PR = TBCEPGP:CalculatePriority(value.EP, value.GP)
    end
    TBCEPGP:filterPlayers()
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
        TBCEPGP:FillUserFrameUserScrollPanel(filteredPlayers)
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
    TBCEPGP:FillUserFrameUserScrollPanel(filteredPlayers)
end

function TBCEPGP:FillAdminFrameUserScrollPanel(inputPlayers)        --Change User to Admin in function!
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
            curPlayerFrame = CreateFrame("Frame", nil, UserScrollPanel, "BackdropTemplate")
            playerFrames[index] = curPlayerFrame
            curPlayerFrame:SetSize(UserScrollPanel:GetWidth() - 4, 25)
            curPlayerFrame:EnableMouse(true)
            curPlayerFrame:SetBackdrop({
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                edgeSize = 8,
                insets = {left = 2, right = 2, top = 2, bottom = 2},
            })
            curPlayerFrame:SetBackdropColor(0.25, 0.25, 0.25, 1)

            curPlayerFrame.Name = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.Name:SetSize(EPGPAdminFrame.Header.Name:GetWidth(), 25)
            curPlayerFrame.Name:SetPoint("LEFT", 0, 0)
            curPlayerFrame.Name:SetTextColor(1, 1, 1, 1)

            curPlayerFrame.Class = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.Class:SetSize(100, 25)
            curPlayerFrame.Class:SetPoint("LEFT", curPlayerFrame.Name, "RIGHT", -4, 0)
            curPlayerFrame.Class:SetTextColor(1, 1, 1, 1)

            curPlayerFrame.curEP = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.curEP:SetSize(75, 25)
            curPlayerFrame.curEP:SetPoint("LEFT", curPlayerFrame.Class, "RIGHT", -4, 0)
            curPlayerFrame.curEP:SetTextColor(1, 1, 1, 1)

            curPlayerFrame.curGP = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.curGP:SetSize(75, 25)
            curPlayerFrame.curGP:SetPoint("LEFT", curPlayerFrame.curEP, "RIGHT", -4, 0)
            curPlayerFrame.curGP:SetTextColor(1, 1, 1, 1)

            curPlayerFrame.curPR = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.curPR:SetSize(75, 25)
            curPlayerFrame.curPR:SetPoint("LEFT", curPlayerFrame.curGP, "RIGHT", -4, 0)
            curPlayerFrame.curPR:SetTextColor(1, 1, 1, 1)
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
        frame:SetPoint("TOPLEFT", UserScrollPanel, "TOPLEFT", 5, -24 * j + 25)
    end
end

function TBCEPGP:FillUserFrameUserScrollPanel(inputPlayers)
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
            curPlayerFrame = CreateFrame("Frame", nil, UserScrollPanel, "BackdropTemplate")
            playerFrames[index] = curPlayerFrame
            curPlayerFrame:SetSize(UserScrollPanel:GetWidth() - 4, 25)
            curPlayerFrame:EnableMouse(true)
            curPlayerFrame:SetBackdrop({
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                edgeSize = 8,
                insets = {left = 2, right = 2, top = 2, bottom = 2},
            })
            curPlayerFrame:SetBackdropColor(0.25, 0.25, 0.25, 1)

            curPlayerFrame.Name = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.Name:SetSize(EPGPUserFrame.Header.Name:GetWidth(), 25)
            curPlayerFrame.Name:SetPoint("LEFT", 0, 0)
            curPlayerFrame.Name:SetTextColor(1, 1, 1, 1)

            curPlayerFrame.Class = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.Class:SetSize(100, 25)
            curPlayerFrame.Class:SetPoint("LEFT", curPlayerFrame.Name, "RIGHT", -4, 0)
            curPlayerFrame.Class:SetTextColor(1, 1, 1, 1)

            curPlayerFrame.curEP = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.curEP:SetSize(75, 25)
            curPlayerFrame.curEP:SetPoint("LEFT", curPlayerFrame.Class, "RIGHT", -4, 0)
            curPlayerFrame.curEP:SetTextColor(1, 1, 1, 1)

            curPlayerFrame.curGP = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.curGP:SetSize(75, 25)
            curPlayerFrame.curGP:SetPoint("LEFT", curPlayerFrame.curEP, "RIGHT", -4, 0)
            curPlayerFrame.curGP:SetTextColor(1, 1, 1, 1)

            curPlayerFrame.curPR = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.curPR:SetSize(75, 25)
            curPlayerFrame.curPR:SetPoint("LEFT", curPlayerFrame.curGP, "RIGHT", -4, 0)
            curPlayerFrame.curPR:SetTextColor(1, 1, 1, 1)
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
        frame:SetPoint("TOPLEFT", UserScrollPanel, "TOPLEFT", 5, -24 * j + 25)
    end
end

function TBCEPGP:CalculatePriority(curEP, curGP)
    local curPR = nil
    if curEP == 0 or curGP == 0 then curPR = "-" else curPR = TBCEPGP:MathRound(curEP/curGP * 1000) / 1000 end
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