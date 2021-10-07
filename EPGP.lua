if TBCEPGP == nil then TBCEPGP = {} end
TBCEPGP.Events = {}
TBCEPGP.Version = 33
local AddOnName = "TBC-EPGP"

local UpdateFrame, EventFrame, EPGPOptionsPanel = nil, nil, nil
local EPGPUserFrame, UserScrollPanel = nil, nil
local EPGPAdminFrame, AdminScrollPanel = nil, nil
local EPGPLootFrame, LootScrollPanel = nil, nil
local EPGPChangeLogFrame, ChangeLogScrollPanel = nil, nil
local adminPlayerFrames, userPlayerFrames = {}, {}
local EPGPActiveLootItems, LootItemFrames = {}, {}
local ChangeLogsFrames = {}
local sortCol, sortDir, filteredPlayers = nil, "Asc", nil
local addonLoaded, variablesLoaded = false, false
local FilterButtonFrame = nil
local FilterRaid = false

if TBCEPGPShowAdminView == nil then TBCEPGPShowAdminView = false end
if EPGPChangeLog == nil then EPGPChangeLog = {} end

local classInfo =
{
     [1] = {ClassName = "Warrior", ClassColor = "FFC69B6D"},
     [2] = {ClassName = "Paladin", ClassColor = "FFF48CBA"},
     [3] = {ClassName =  "Hunter", ClassColor = "FFAAD372"},
     [4] = {ClassName =   "Rogue", ClassColor = "FFFFF468"},
     [5] = {ClassName =  "Priest", ClassColor = "FFFFFFFF"},
     [7] = {ClassName =  "Shaman", ClassColor = "FF0070DD"},
     [8] = {ClassName =    "Mage", ClassColor = "FF3FC7EB"},
     [9] = {ClassName = "Warlock", ClassColor = "FF8788EE"},
    [11] = {ClassName =   "Druid", ClassColor = "FFFF7C0A"},
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
    C_ChatInfo.RegisterAddonMessagePrefix("TBCEPGPItem")
    C_ChatInfo.RegisterAddonMessagePrefix("TBCEPGPRoll")
    C_ChatInfo.RegisterAddonMessagePrefix("TBCEPGPVersion")

    EventFrame = CreateFrame("Frame", nil, UIParent)
    TBCEPGP:RegisterEvents("ADDON_LOADED", function(...) TBCEPGP.Events:AddonLoaded(...) end)
    TBCEPGP:RegisterEvents("VARIABLES_LOADED", function(...) TBCEPGP.Events:VariablesLoaded(...) end)
    TBCEPGP:RegisterEvents("CHAT_MSG_ADDON", function(...) TBCEPGP.Events:ChatMsgAddon(...) end)
    TBCEPGP:RegisterEvents("GROUP_ROSTER_UPDATE", function(...) TBCEPGP.Events:GroupRosterUpdate(...) end)
    TBCEPGP:RegisterEvents("LOOT_OPENED", function(...) TBCEPGP.Events:LootOpened(...) end)

    EventFrame:SetScript("OnEvent", function(...) TBCEPGP:OnEvent(...) end)

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
    EPGPOptionsPanel.adminsEditBox:SetPoint("TOP", EPGPOptionsPanel.adminsEditBoxText, "BOTTOM", 0, -5)
    EPGPOptionsPanel.adminsEditBox:SetAutoFocus(false)
    EPGPOptionsPanel.adminsEditBox:SetScript("OnEditFocusLost", function() TBCEPGPAdminList = TBCEPGP:splitCharacterNames(EPGPOptionsPanel.adminsEditBox:GetText()) end)

    EPGPOptionsPanel.showAdminViewCheckButton = CreateFrame("CheckButton", "ShowAdminViewCheckButton", EPGPOptionsPanel, "ChatConfigCheckButtonTemplate");
    EPGPOptionsPanel.showAdminViewCheckButton:SetPoint("TOP", EPGPOptionsPanel.adminsEditBox, "BOTTOMLEFT", 0, -20);
    EPGPOptionsPanel.showAdminViewCheckButton:SetScript("OnClick", function()
        TBCEPGPShowAdminView = EPGPOptionsPanel.showAdminViewCheckButton:GetChecked()
        if TBCEPGPShowAdminView == true then
            EPGPUserFrame:Hide()
            EPGPAdminFrame:Show()
        elseif TBCEPGPShowAdminView == false then
            EPGPAdminFrame:Hide()
            EPGPUserFrame:Show()
        end
        TBCEPGP:FilterPlayers()
    end)
    ShowAdminViewCheckButtonText:SetText("Show Admin View")

    EPGPOptionsPanel.CalculationsText = EPGPOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    EPGPOptionsPanel.CalculationsText:SetSize(200, 50)
    EPGPOptionsPanel.CalculationsText:SetJustifyH("LEFT")
    EPGPOptionsPanel.CalculationsText:SetPoint("TOPLEFT", EPGPOptionsPanel.showAdminViewCheckButton, "BOTTOMLEFT", 0, -20)
    EPGPOptionsPanel.CalculationsText:SetText("OffSet for PR Calculations.\nUsually: PR = EP / GP.\n\nCurrent Calculations:")

    EPGPOptionsPanel.CalculationsLabel = EPGPOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    EPGPOptionsPanel.CalculationsLabel:SetSize(200, 25)
    EPGPOptionsPanel.CalculationsLabel:SetJustifyH("LEFT")
    EPGPOptionsPanel.CalculationsLabel:SetPoint("TOPLEFT", EPGPOptionsPanel.CalculationsText, "BOTTOMLEFT", 0, 5)

    EPGPOptionsPanel.EPOffSetText = EPGPOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    EPGPOptionsPanel.EPOffSetText:SetSize(75, 25)
    EPGPOptionsPanel.EPOffSetText:SetJustifyH("LEFT")
    EPGPOptionsPanel.EPOffSetText:SetPoint("TOPLEFT", EPGPOptionsPanel.CalculationsLabel, "BOTTOMLEFT", 0, -10)
    EPGPOptionsPanel.EPOffSetText:SetText("EP OffSet:")

    EPGPOptionsPanel.EPOffSet = CreateFrame("EditBox", nil, EPGPOptionsPanel, "InputBoxTemplate")
    EPGPOptionsPanel.EPOffSet:SetSize(50, 25)
    EPGPOptionsPanel.EPOffSet:SetPoint("LEFT", EPGPOptionsPanel.EPOffSetText, "RIGHT", 0, 0)
    EPGPOptionsPanel.EPOffSet:SetAutoFocus(false)
    EPGPOptionsPanel.EPOffSet:SetScript("OnEditFocusLost",
    function()
        TBCEPGP:ChangePRCalculations()
        TBCEPGP:SavePRCalculations()
    end)

    EPGPOptionsPanel.GPOffSetText = EPGPOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    EPGPOptionsPanel.GPOffSetText:SetSize(75, 25)
    EPGPOptionsPanel.GPOffSetText:SetJustifyH("LEFT")
    EPGPOptionsPanel.GPOffSetText:SetPoint("TOPLEFT", EPGPOptionsPanel.EPOffSetText, "BOTTOMLEFT", 0, -10)
    EPGPOptionsPanel.GPOffSetText:SetText("GP OffSet:")

    EPGPOptionsPanel.GPOffSet = CreateFrame("EditBox", nil, EPGPOptionsPanel, "InputBoxTemplate")
    EPGPOptionsPanel.GPOffSet:SetSize(50, 25)
    EPGPOptionsPanel.GPOffSet:SetPoint("LEFT", EPGPOptionsPanel.GPOffSetText, "RIGHT", 0, 0)
    EPGPOptionsPanel.GPOffSet:SetAutoFocus(false)
    EPGPOptionsPanel.GPOffSet:SetScript("OnEditFocusLost",
    function()
        TBCEPGP:ChangePRCalculations()
        TBCEPGP:SavePRCalculations()
    end)

    TBCEPGP:ChangePRCalculations()

    TBCEPGP:AddTooltipScript()
    TBCEPGP:CreateLootFrame()
    TBCEPGP:CreateLogFrame()

    EPGPOptionsPanel:SetScript("OnShow",
    function()
        TBCEPGP:ChangePRCalculations()
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

function TBCEPGP:ChangePRCalculations()
    local EPOffSet = EPGPOptionsPanel.EPOffSet:GetNumber()
    local GPOffSet = EPGPOptionsPanel.GPOffSet:GetNumber()
    if EPOffSet > 0 then EPOffSet = string.format("+%d", EPOffSet) elseif EPOffSet == 0 then EPOffSet = "" end
    if GPOffSet > 0 then GPOffSet = string.format("+%d", GPOffSet) elseif GPOffSet == 0 then GPOffSet = "" end
    local CalcString = string.format("|cFF00FFFFPR = (EP%s) / (GP%s)|r", tostring(EPOffSet), tostring(GPOffSet))
    EPGPOptionsPanel.CalculationsLabel:SetText(CalcString)
end

function TBCEPGP:SavePRCalculations()
    local EPOffSet = EPGPOptionsPanel.EPOffSet:GetNumber()
    local GPOffSet = EPGPOptionsPanel.GPOffSet:GetNumber()
    TBCEPGPPRCalc = {tostring(EPOffSet), tostring(GPOffSet)}
end

function TBCEPGP:CreateLogFrame()
    EPGPChangeLogFrame = CreateFrame("Frame", nil, UIParent)
    EPGPChangeLogFrame:SetPoint("CENTER", 0, 0)
    EPGPChangeLogFrame:SetSize(670, 400)
    EPGPChangeLogFrame:EnableMouse(true)
    EPGPChangeLogFrame:SetMovable(true)
    EPGPChangeLogFrame:RegisterForDrag("LeftButton")
    EPGPChangeLogFrame:SetScript("OnDragStart", EPGPChangeLogFrame.StartMoving)
    EPGPChangeLogFrame:SetScript("OnDragStop", EPGPChangeLogFrame.StopMovingOrSizing)

    EPGPChangeLogFrame.TopLeftBG     = CreateFrame("Frame", nil, EPGPChangeLogFrame, "BackdropTemplate")
    EPGPChangeLogFrame.TopBG1        = CreateFrame("Frame", nil, EPGPChangeLogFrame, "BackdropTemplate")
    EPGPChangeLogFrame.TopBG2        = CreateFrame("Frame", nil, EPGPChangeLogFrame, "BackdropTemplate")
    EPGPChangeLogFrame.TopRightBG    = CreateFrame("Frame", nil, EPGPChangeLogFrame, "BackdropTemplate")
    EPGPChangeLogFrame.BotLeftBG     = CreateFrame("Frame", nil, EPGPChangeLogFrame, "BackdropTemplate")
    EPGPChangeLogFrame.BotBG1        = CreateFrame("Frame", nil, EPGPChangeLogFrame, "BackdropTemplate")
    EPGPChangeLogFrame.BotBG2        = CreateFrame("Frame", nil, EPGPChangeLogFrame, "BackdropTemplate")
    EPGPChangeLogFrame.BotRightBG    = CreateFrame("Frame", nil, EPGPChangeLogFrame, "BackdropTemplate")

    EPGPChangeLogFrame.TopLeftBG :SetSize(200, EPGPChangeLogFrame:GetHeight() / 2)
    EPGPChangeLogFrame.TopBG1    :SetSize(200, EPGPChangeLogFrame:GetHeight() / 2)
    EPGPChangeLogFrame.TopBG2    :SetSize(200, EPGPChangeLogFrame:GetHeight() / 2)
    EPGPChangeLogFrame.TopRightBG:SetSize(100, EPGPChangeLogFrame:GetHeight() / 2)
    EPGPChangeLogFrame.BotLeftBG :SetSize(200, EPGPChangeLogFrame:GetHeight() / 2)
    EPGPChangeLogFrame.BotBG1    :SetSize(200, EPGPChangeLogFrame:GetHeight() / 2)
    EPGPChangeLogFrame.BotBG2    :SetSize(200, EPGPChangeLogFrame:GetHeight() / 2)
    EPGPChangeLogFrame.BotRightBG:SetSize(100, EPGPChangeLogFrame:GetHeight() / 2)

    EPGPChangeLogFrame.TopLeftBG :SetPoint("TOPLEFT", 0, 0)
    EPGPChangeLogFrame.TopBG1    :SetPoint("LEFT", EPGPChangeLogFrame.TopLeftBG, "RIGHT", 0, 0)
    EPGPChangeLogFrame.TopBG2    :SetPoint("LEFT", EPGPChangeLogFrame.TopBG1, "RIGHT", 0, 0)
    EPGPChangeLogFrame.TopRightBG:SetPoint("LEFT", EPGPChangeLogFrame.TopBG2, "RIGHT", 0, 0)

    EPGPChangeLogFrame.BotLeftBG :SetPoint("TOP", EPGPChangeLogFrame.TopLeftBG, "BOTTOM", 0, 0)
    EPGPChangeLogFrame.BotBG1    :SetPoint("TOP", EPGPChangeLogFrame.TopBG1, "BOTTOM", 0, 0)
    EPGPChangeLogFrame.BotBG2    :SetPoint("TOP", EPGPChangeLogFrame.TopBG2, "BOTTOM", 0, 0)
    EPGPChangeLogFrame.BotRightBG:SetPoint("TOP", EPGPChangeLogFrame.TopRightBG, "BOTTOM", 0, 0)

    EPGPChangeLogFrame.TopLeftBG :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-TOPLEFT"})
    EPGPChangeLogFrame.TopBG1    :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-TOP"})
    EPGPChangeLogFrame.TopBG2    :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-TOP"})
    EPGPChangeLogFrame.TopRightBG:SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-TOPRIGHT"})
    EPGPChangeLogFrame.BotLeftBG :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-BOTLEFT"})
    EPGPChangeLogFrame.BotBG1    :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-BOTTOM"})
    EPGPChangeLogFrame.BotBG2    :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-BOTTOM"})
    EPGPChangeLogFrame.BotRightBG:SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-BOTRIGHT"})

    EPGPChangeLogFrame.Title = CreateFrame("FRAME", nil, EPGPChangeLogFrame)
    EPGPChangeLogFrame.Title:SetSize(300, 65)
    EPGPChangeLogFrame.Title:SetPoint("TOP", EPGPChangeLogFrame, "TOP", 0, EPGPChangeLogFrame.Title:GetHeight() * 0.35 - 4)
    EPGPChangeLogFrame.Title:SetFrameStrata("HIGH")

    EPGPChangeLogFrame.Title.Text = EPGPChangeLogFrame.Title:CreateFontString("EPGPChangeLogFrame", "ARTWORK", "GameFontNormalLarge")
    EPGPChangeLogFrame.Title.Text:SetPoint("TOP", 0, -EPGPChangeLogFrame.Title:GetHeight() * 0.25 + 3)
    EPGPChangeLogFrame.Title.Text:SetText(AddOnName .. " - v" .. TBCEPGP.Version)

    EPGPChangeLogFrame.Title.Texture = EPGPChangeLogFrame.Title:CreateTexture(nil, "BACKGROUND")
    EPGPChangeLogFrame.Title.Texture:SetAllPoints()
    EPGPChangeLogFrame.Title.Texture:SetTexture("Interface/DialogFrame/UI-DialogBox-Header")

    EPGPChangeLogFrame.ExtraBG = CreateFrame("FRAME", nil, EPGPChangeLogFrame, "BackdropTemplate")
    EPGPChangeLogFrame.ExtraBG:SetSize(EPGPChangeLogFrame:GetWidth() - 25, EPGPChangeLogFrame:GetHeight() - 79)
    EPGPChangeLogFrame.ExtraBG:SetPoint("TOP", 2, -41)
    EPGPChangeLogFrame.ExtraBG:SetFrameStrata("HIGH")
    EPGPChangeLogFrame.ExtraBG:SetBackdrop({
        bgFile = "Interface/BankFrame/Bank-Background",
        tile = true,
        tileSize = 100;
    })
    EPGPChangeLogFrame.ExtraBG:SetBackdropColor(0.25, 0.25, 0.25, 1)

    local scrollFrame = CreateFrame("ScrollFrame", nil, EPGPChangeLogFrame, "UIPanelScrollFrameTemplate BackdropTemplate");
    scrollFrame:SetSize(EPGPChangeLogFrame:GetWidth() - 45, EPGPChangeLogFrame:GetHeight() - 77)
    scrollFrame:SetPoint("TOP", -11, -40)
    scrollFrame:SetFrameStrata("HIGH")

    ChangeLogScrollPanel = CreateFrame("Frame")
    ChangeLogScrollPanel:SetSize(scrollFrame:GetWidth(), 300)
    ChangeLogScrollPanel:SetPoint("TOP")

    EPGPChangeLogFrame.Header = CreateFrame("Frame", nil, EPGPChangeLogFrame, "BackdropTemplate")
    EPGPChangeLogFrame.Header:SetPoint("TOP", -11, -20)
    EPGPChangeLogFrame.Header:SetSize(ChangeLogScrollPanel:GetWidth(), 50)

    EPGPChangeLogFrame.Header.Name = CreateFrame("Frame", nil, EPGPChangeLogFrame.Header, "BackdropTemplate")
    EPGPChangeLogFrame.Header.Name:SetSize(100, 24)
    EPGPChangeLogFrame.Header.Name:SetPoint("TOPLEFT", 2, 0)
    EPGPChangeLogFrame.Header.Name:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPChangeLogFrame.Header.Name:SetBackdropColor(1, 1, 1, 1)

    EPGPChangeLogFrame.Header.Name.Text = EPGPChangeLogFrame.Header.Name:CreateFontString("EPGPChangeLogFrame.Header.Name.Text", "ARTWORK", "GameFontNormal")
    EPGPChangeLogFrame.Header.Name.Text:SetSize(EPGPChangeLogFrame.Header.Name:GetWidth(), EPGPChangeLogFrame.Header.Name:GetHeight())
    EPGPChangeLogFrame.Header.Name.Text:SetPoint("CENTER", 0, 0)
    EPGPChangeLogFrame.Header.Name.Text:SetTextColor(1, 1, 1, 1)
    EPGPChangeLogFrame.Header.Name.Text:SetText("Name")

    EPGPChangeLogFrame.Header.Points = CreateFrame("Frame", nil, EPGPChangeLogFrame.Header, "BackdropTemplate")
    EPGPChangeLogFrame.Header.Points:SetSize(50, 24)
    EPGPChangeLogFrame.Header.Points:SetPoint("BOTTOMLEFT", EPGPChangeLogFrame.Header.Name, "BOTTOMRIGHT", -4, 0)
    EPGPChangeLogFrame.Header.Points:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPChangeLogFrame.Header.Points:SetBackdropColor(1, 1, 1, 1)

    EPGPChangeLogFrame.Header.Points.Text = EPGPChangeLogFrame.Header.Points:CreateFontString("EPGPChangeLogFrame.Header.Points.Text", "ARTWORK", "GameFontNormal")
    EPGPChangeLogFrame.Header.Points.Text:SetSize(EPGPChangeLogFrame.Header.Points:GetWidth(), EPGPChangeLogFrame.Header.Points:GetHeight())
    EPGPChangeLogFrame.Header.Points.Text:SetPoint("CENTER", 0, 0)
    EPGPChangeLogFrame.Header.Points.Text:SetTextColor(1, 1, 1, 1)
    EPGPChangeLogFrame.Header.Points.Text:SetText("Points")

    EPGPChangeLogFrame.Header.Amount = CreateFrame("Frame", nil, EPGPChangeLogFrame.Header, "BackdropTemplate")
    EPGPChangeLogFrame.Header.Amount:SetSize(75, 24)
    EPGPChangeLogFrame.Header.Amount:SetPoint("BOTTOMLEFT", EPGPChangeLogFrame.Header.Points, "BOTTOMRIGHT", -4, 0)
    EPGPChangeLogFrame.Header.Amount:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPChangeLogFrame.Header.Amount:SetBackdropColor(1, 1, 1, 1)

    EPGPChangeLogFrame.Header.Amount.Text = EPGPChangeLogFrame.Header.Amount:CreateFontString("EPGPChangeLogFrame.Header.Amount.Text", "ARTWORK", "GameFontNormal")
    EPGPChangeLogFrame.Header.Amount.Text:SetSize(EPGPChangeLogFrame.Header.Amount:GetWidth(), EPGPChangeLogFrame.Header.Amount:GetHeight())
    EPGPChangeLogFrame.Header.Amount.Text:SetPoint("CENTER", 0, 0)
    EPGPChangeLogFrame.Header.Amount.Text:SetTextColor(1, 1, 1, 1)
    EPGPChangeLogFrame.Header.Amount.Text:SetText("Amount")

    EPGPChangeLogFrame.Header.DateTime = CreateFrame("Frame", nil, EPGPChangeLogFrame.Header, "BackdropTemplate")
    EPGPChangeLogFrame.Header.DateTime:SetSize(150, 24)
    EPGPChangeLogFrame.Header.DateTime:SetPoint("BOTTOMLEFT", EPGPChangeLogFrame.Header.Amount, "BOTTOMRIGHT", -4, 0)
    EPGPChangeLogFrame.Header.DateTime:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPChangeLogFrame.Header.DateTime:SetBackdropColor(1, 1, 1, 1)

    EPGPChangeLogFrame.Header.DateTime.Text = EPGPChangeLogFrame.Header.DateTime:CreateFontString("EPGPChangeLogFrame.Header.DateTime.Text", "ARTWORK", "GameFontNormal")
    EPGPChangeLogFrame.Header.DateTime.Text:SetSize(EPGPChangeLogFrame.Header.DateTime:GetWidth(), EPGPChangeLogFrame.Header.DateTime:GetHeight())
    EPGPChangeLogFrame.Header.DateTime.Text:SetPoint("CENTER", 0, 0)
    EPGPChangeLogFrame.Header.DateTime.Text:SetTextColor(1, 1, 1, 1)
    EPGPChangeLogFrame.Header.DateTime.Text:SetText("DateTime")

    EPGPChangeLogFrame.Header.Admin = CreateFrame("Frame", nil, EPGPChangeLogFrame.Header, "BackdropTemplate")
    EPGPChangeLogFrame.Header.Admin:SetSize(100, 24)
    EPGPChangeLogFrame.Header.Admin:SetPoint("BOTTOMLEFT", EPGPChangeLogFrame.Header.DateTime, "BOTTOMRIGHT", -4, 0)
    EPGPChangeLogFrame.Header.Admin:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPChangeLogFrame.Header.Admin:SetBackdropColor(1, 1, 1, 1)

    EPGPChangeLogFrame.Header.Admin.Text = EPGPChangeLogFrame.Header.Admin:CreateFontString("EPGPChangeLogFrame.Header.Admin.Text", "ARTWORK", "GameFontNormal")
    EPGPChangeLogFrame.Header.Admin.Text:SetSize(EPGPChangeLogFrame.Header.Admin:GetWidth(), EPGPChangeLogFrame.Header.Admin:GetHeight())
    EPGPChangeLogFrame.Header.Admin.Text:SetPoint("CENTER", 0, 0)
    EPGPChangeLogFrame.Header.Admin.Text:SetTextColor(1, 1, 1, 1)
    EPGPChangeLogFrame.Header.Admin.Text:SetText("Admin")

    EPGPChangeLogFrame.Header.Reason = CreateFrame("Frame", nil, EPGPChangeLogFrame.Header, "BackdropTemplate")
    EPGPChangeLogFrame.Header.Reason:SetSize(175, 24)
    EPGPChangeLogFrame.Header.Reason:SetPoint("BOTTOMLEFT", EPGPChangeLogFrame.Header.Admin, "BOTTOMRIGHT", -4, 0)
    EPGPChangeLogFrame.Header.Reason:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPChangeLogFrame.Header.Reason:SetBackdropColor(1, 1, 1, 1)

    EPGPChangeLogFrame.Header.Reason.Text = EPGPChangeLogFrame.Header.Reason:CreateFontString("EPGPChangeLogFrame.Header.Reason.Text", "ARTWORK", "GameFontNormal")
    EPGPChangeLogFrame.Header.Reason.Text:SetSize(EPGPChangeLogFrame.Header.Reason:GetWidth(), EPGPChangeLogFrame.Header.Reason:GetHeight())
    EPGPChangeLogFrame.Header.Reason.Text:SetPoint("CENTER", 0, 0)
    EPGPChangeLogFrame.Header.Reason.Text:SetTextColor(1, 1, 1, 1)
    EPGPChangeLogFrame.Header.Reason.Text:SetText("Reason")

    local curFont, curSize, curFlags = EPGPChangeLogFrame.Header.Name.Text:GetFont()
    EPGPChangeLogFrame.Header.Name  .Text:SetFont(curFont, curSize - 2, curFlags)
    EPGPChangeLogFrame.Header.Points.Text:SetFont(curFont, curSize - 2, curFlags)
    EPGPChangeLogFrame.Header.Admin .Text:SetFont(curFont, curSize - 2, curFlags)
    EPGPChangeLogFrame.Header.Reason.Text:SetFont(curFont, curSize - 2, curFlags)

    local EPGPChangeLogFrameCloseButton = CreateFrame("Button", nil, EPGPChangeLogFrame, "UIPanelCloseButton, BackDropTemplate")
    EPGPChangeLogFrameCloseButton:SetSize(24, 24)
    EPGPChangeLogFrameCloseButton:SetPoint("TOPRIGHT", EPGPChangeLogFrame, "TOPRIGHT", -3, -3)
    EPGPChangeLogFrameCloseButton:SetScript("OnClick", function() EPGPChangeLogFrame:Hide() end)

    scrollFrame:SetScrollChild(ChangeLogScrollPanel)

    EPGPChangeLogFrame:Hide()
end

function TBCEPGP:CreateLootFrame()
    EPGPLootFrame = CreateFrame("Frame", nil, UIParent)
    EPGPLootFrame:SetPoint("CENTER", 0, 0)
    EPGPLootFrame:SetSize(670, 400)
    EPGPLootFrame:EnableMouse(true)
    EPGPLootFrame:SetMovable(true)
    EPGPLootFrame:RegisterForDrag("LeftButton")
    EPGPLootFrame:SetScript("OnDragStart", EPGPLootFrame.StartMoving)
    EPGPLootFrame:SetScript("OnDragStop", EPGPLootFrame.StopMovingOrSizing)

    EPGPLootFrame.TopLeftBG     = CreateFrame("Frame", nil, EPGPLootFrame, "BackdropTemplate")
    EPGPLootFrame.TopBG1        = CreateFrame("Frame", nil, EPGPLootFrame, "BackdropTemplate")
    EPGPLootFrame.TopBG2        = CreateFrame("Frame", nil, EPGPLootFrame, "BackdropTemplate")
    EPGPLootFrame.TopRightBG    = CreateFrame("Frame", nil, EPGPLootFrame, "BackdropTemplate")
    EPGPLootFrame.BotLeftBG     = CreateFrame("Frame", nil, EPGPLootFrame, "BackdropTemplate")
    EPGPLootFrame.BotBG1        = CreateFrame("Frame", nil, EPGPLootFrame, "BackdropTemplate")
    EPGPLootFrame.BotBG2        = CreateFrame("Frame", nil, EPGPLootFrame, "BackdropTemplate")
    EPGPLootFrame.BotRightBG    = CreateFrame("Frame", nil, EPGPLootFrame, "BackdropTemplate")

    EPGPLootFrame.TopLeftBG :SetSize(200, EPGPLootFrame:GetHeight() / 2)
    EPGPLootFrame.TopBG1    :SetSize(200, EPGPLootFrame:GetHeight() / 2)
    EPGPLootFrame.TopBG2    :SetSize(200, EPGPLootFrame:GetHeight() / 2)
    EPGPLootFrame.TopRightBG:SetSize(100, EPGPLootFrame:GetHeight() / 2)
    EPGPLootFrame.BotLeftBG :SetSize(200, EPGPLootFrame:GetHeight() / 2)
    EPGPLootFrame.BotBG1    :SetSize(200, EPGPLootFrame:GetHeight() / 2)
    EPGPLootFrame.BotBG2    :SetSize(200, EPGPLootFrame:GetHeight() / 2)
    EPGPLootFrame.BotRightBG:SetSize(100, EPGPLootFrame:GetHeight() / 2)

    EPGPLootFrame.TopLeftBG :SetPoint("TOPLEFT", 0, 0)
    EPGPLootFrame.TopBG1    :SetPoint("LEFT", EPGPLootFrame.TopLeftBG, "RIGHT", 0, 0)
    EPGPLootFrame.TopBG2    :SetPoint("LEFT", EPGPLootFrame.TopBG1, "RIGHT", 0, 0)
    EPGPLootFrame.TopRightBG:SetPoint("LEFT", EPGPLootFrame.TopBG2, "RIGHT", 0, 0)

    EPGPLootFrame.BotLeftBG :SetPoint("TOP", EPGPLootFrame.TopLeftBG, "BOTTOM", 0, 0)
    EPGPLootFrame.BotBG1    :SetPoint("TOP", EPGPLootFrame.TopBG1, "BOTTOM", 0, 0)
    EPGPLootFrame.BotBG2    :SetPoint("TOP", EPGPLootFrame.TopBG2, "BOTTOM", 0, 0)
    EPGPLootFrame.BotRightBG:SetPoint("TOP", EPGPLootFrame.TopRightBG, "BOTTOM", 0, 0)

    EPGPLootFrame.TopLeftBG :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-TOPLEFT"})
    EPGPLootFrame.TopBG1    :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-TOP"})
    EPGPLootFrame.TopBG2    :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-TOP"})
    EPGPLootFrame.TopRightBG:SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-TOPRIGHT"})
    EPGPLootFrame.BotLeftBG :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-BOTLEFT"})
    EPGPLootFrame.BotBG1    :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-BOTTOM"})
    EPGPLootFrame.BotBG2    :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-BOTTOM"})
    EPGPLootFrame.BotRightBG:SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-BOTRIGHT"})

    EPGPLootFrame.Title = CreateFrame("FRAME", nil, EPGPLootFrame)
    EPGPLootFrame.Title:SetSize(300, 65)
    EPGPLootFrame.Title:SetPoint("TOP", EPGPLootFrame, "TOP", 0, EPGPLootFrame.Title:GetHeight() * 0.35 - 4)
    EPGPLootFrame.Title:SetFrameStrata("HIGH")

    EPGPLootFrame.Title.Text = EPGPLootFrame.Title:CreateFontString("EPGPLootFrame", "ARTWORK", "GameFontNormalLarge")
    EPGPLootFrame.Title.Text:SetPoint("TOP", 0, -EPGPLootFrame.Title:GetHeight() * 0.25 + 3)
    EPGPLootFrame.Title.Text:SetText(AddOnName .. " - v" .. TBCEPGP.Version)

    EPGPLootFrame.Title.Texture = EPGPLootFrame.Title:CreateTexture(nil, "BACKGROUND")
    EPGPLootFrame.Title.Texture:SetAllPoints()
    EPGPLootFrame.Title.Texture:SetTexture("Interface/DialogFrame/UI-DialogBox-Header")

    EPGPLootFrame.ExtraBG = CreateFrame("FRAME", nil, EPGPLootFrame, "BackdropTemplate")
    EPGPLootFrame.ExtraBG:SetSize(EPGPLootFrame:GetWidth() - 25, EPGPLootFrame:GetHeight() - 79)
    EPGPLootFrame.ExtraBG:SetPoint("TOP", 2, -41)
    EPGPLootFrame.ExtraBG:SetFrameStrata("HIGH")
    EPGPLootFrame.ExtraBG:SetBackdrop({
        bgFile = "Interface/BankFrame/Bank-Background",
        tile = true,
        tileSize = 100;
    })
    EPGPLootFrame.ExtraBG:SetBackdropColor(0.25, 0.25, 0.25, 1)

    local scrollFrame = CreateFrame("ScrollFrame", nil, EPGPLootFrame, "UIPanelScrollFrameTemplate BackdropTemplate");
    scrollFrame:SetSize(EPGPLootFrame:GetWidth() - 45, EPGPLootFrame:GetHeight() - 77)
    scrollFrame:SetPoint("TOP", -11, -40)
    scrollFrame:SetFrameStrata("HIGH")

    LootScrollPanel = CreateFrame("Frame")
    LootScrollPanel:SetSize(scrollFrame:GetWidth(), 300)
    LootScrollPanel:SetPoint("TOP")

    EPGPLootFrame.Header = CreateFrame("Frame", nil, EPGPLootFrame, "BackdropTemplate")
    EPGPLootFrame.Header:SetPoint("TOP", -11, -20)
    EPGPLootFrame.Header:SetSize(LootScrollPanel:GetWidth(), 50)

    EPGPLootFrame.Header.Icon = CreateFrame("Frame", nil, EPGPLootFrame.Header, "BackdropTemplate")
    EPGPLootFrame.Header.Icon:SetSize(34, 24)
    EPGPLootFrame.Header.Icon:SetPoint("TOPLEFT", 5, 0)
    EPGPLootFrame.Header.Icon:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPLootFrame.Header.Icon:SetBackdropColor(1, 1, 1, 1)

    EPGPLootFrame.Header.Icon.Text = EPGPLootFrame.Header.Icon:CreateFontString("EPGPLootFrame.Header.Icon.Text", "ARTWORK", "GameFontNormal")
    EPGPLootFrame.Header.Icon.Text:SetSize(EPGPLootFrame.Header.Icon:GetWidth(), EPGPLootFrame.Header.Icon:GetHeight())
    EPGPLootFrame.Header.Icon.Text:SetPoint("CENTER", 0, 0)
    EPGPLootFrame.Header.Icon.Text:SetTextColor(1, 1, 1, 1)
    EPGPLootFrame.Header.Icon.Text:SetText("Icon")

    EPGPLootFrame.Header.Name = CreateFrame("Frame", nil, EPGPLootFrame.Header, "BackdropTemplate")
    EPGPLootFrame.Header.Name:SetSize(200, 24)
    EPGPLootFrame.Header.Name:SetPoint("BOTTOMLEFT", EPGPLootFrame.Header.Icon, "BOTTOMRIGHT", -4, 0)
    EPGPLootFrame.Header.Name:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPLootFrame.Header.Name:SetBackdropColor(1, 1, 1, 1)

    EPGPLootFrame.Header.Name.Text = EPGPLootFrame.Header.Name:CreateFontString("EPGPLootFrame.Header.Name.Text", "ARTWORK", "GameFontNormal")
    EPGPLootFrame.Header.Name.Text:SetSize(EPGPLootFrame.Header.Name:GetWidth(), EPGPLootFrame.Header.Name:GetHeight())
    EPGPLootFrame.Header.Name.Text:SetPoint("CENTER", 0, 0)
    EPGPLootFrame.Header.Name.Text:SetTextColor(1, 1, 1, 1)
    EPGPLootFrame.Header.Name.Text:SetText("Name")

    EPGPLootFrame.Header.curGP = CreateFrame("Frame", nil, EPGPLootFrame.Header, "BackdropTemplate")
    EPGPLootFrame.Header.curGP:SetSize(50, 24)
    EPGPLootFrame.Header.curGP:SetPoint("BOTTOMLEFT", EPGPLootFrame.Header.Name, "BOTTOMRIGHT", -4, 0)
    EPGPLootFrame.Header.curGP:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPLootFrame.Header.curGP:SetBackdropColor(1, 1, 1, 1)

    EPGPLootFrame.Header.curGP.Text = EPGPLootFrame.Header.curGP:CreateFontString("EPGPLootFrame.Header.curGP.Text", "ARTWORK", "GameFontNormal")
    EPGPLootFrame.Header.curGP.Text:SetSize(EPGPLootFrame.Header.curGP:GetWidth(), EPGPLootFrame.Header.curGP:GetHeight())
    EPGPLootFrame.Header.curGP.Text:SetPoint("CENTER", 0, 0)
    EPGPLootFrame.Header.curGP.Text:SetTextColor(1, 1, 1, 1)
    EPGPLootFrame.Header.curGP.Text:SetText("GP Cost")

    EPGPLootFrame.Header.playersNeed = CreateFrame("Frame", nil, EPGPLootFrame.Header, "BackdropTemplate")
    EPGPLootFrame.Header.playersNeed:SetSize(100, 24)
    EPGPLootFrame.Header.playersNeed:SetPoint("BOTTOMLEFT", EPGPLootFrame.Header.curGP, "BOTTOMRIGHT", -4, 0)
    EPGPLootFrame.Header.playersNeed:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPLootFrame.Header.playersNeed:SetBackdropColor(1, 1, 1, 1)

    EPGPLootFrame.Header.playersNeed.Text = EPGPLootFrame.Header.playersNeed:CreateFontString("EPGPLootFrame.Header.playersNeed.Text", "ARTWORK", "GameFontNormal")
    EPGPLootFrame.Header.playersNeed.Text:SetSize(EPGPLootFrame.Header.playersNeed:GetWidth(), EPGPLootFrame.Header.playersNeed:GetHeight())
    EPGPLootFrame.Header.playersNeed.Text:SetPoint("CENTER", 0, 0)
    EPGPLootFrame.Header.playersNeed.Text:SetTextColor(1, 1, 1, 1)
    EPGPLootFrame.Header.playersNeed.Text:SetText("Need")

    EPGPLootFrame.Header.playersGreed = CreateFrame("Frame", nil, EPGPLootFrame.Header, "BackdropTemplate")
    EPGPLootFrame.Header.playersGreed:SetSize(100, 24)
    EPGPLootFrame.Header.playersGreed:SetPoint("BOTTOMLEFT", EPGPLootFrame.Header.playersNeed, "BOTTOMRIGHT", -4, 0)
    EPGPLootFrame.Header.playersGreed:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPLootFrame.Header.playersGreed:SetBackdropColor(1, 1, 1, 1)

    EPGPLootFrame.Header.playersGreed.Text = EPGPLootFrame.Header.playersGreed:CreateFontString("EPGPLootFrame.Header.playersGreed.Text", "ARTWORK", "GameFontNormal")
    EPGPLootFrame.Header.playersGreed.Text:SetSize(EPGPLootFrame.Header.playersGreed:GetWidth(), EPGPLootFrame.Header.playersGreed:GetHeight())
    EPGPLootFrame.Header.playersGreed.Text:SetPoint("CENTER", 0, 0)
    EPGPLootFrame.Header.playersGreed.Text:SetTextColor(1, 1, 1, 1)
    EPGPLootFrame.Header.playersGreed.Text:SetText("Greed")

    EPGPLootFrame.Header.buttons = CreateFrame("Frame", nil, EPGPLootFrame.Header, "BackdropTemplate")
    EPGPLootFrame.Header.buttons:SetSize(155, 24)
    EPGPLootFrame.Header.buttons:SetPoint("BOTTOMLEFT", EPGPLootFrame.Header.playersGreed, "BOTTOMRIGHT", -4, 0)
    EPGPLootFrame.Header.buttons:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPLootFrame.Header.buttons:SetBackdropColor(1, 1, 1, 1)

    EPGPLootFrame.Header.buttons.Text = EPGPLootFrame.Header.buttons:CreateFontString("EPGPLootFrame.Header.buttons.Text", "ARTWORK", "GameFontNormal")
    EPGPLootFrame.Header.buttons.Text:SetSize(EPGPLootFrame.Header.buttons:GetWidth(), EPGPLootFrame.Header.buttons:GetHeight())
    EPGPLootFrame.Header.buttons.Text:SetPoint("CENTER", 0, 0)
    EPGPLootFrame.Header.buttons.Text:SetTextColor(1, 1, 1, 1)
    EPGPLootFrame.Header.buttons.Text:SetText("Buttons")

    local curFont, curSize, curFlags = EPGPLootFrame.Header.Name.Text:GetFont()
    EPGPLootFrame.Header.Icon .Text:SetFont(curFont, curSize - 2, curFlags)
    EPGPLootFrame.Header.Name .Text:SetFont(curFont, curSize - 2, curFlags)
    EPGPLootFrame.Header.curGP.Text:SetFont(curFont, curSize - 2, curFlags)

    local EPGPLootFrameCloseButton = CreateFrame("Button", nil, EPGPLootFrame, "UIPanelCloseButton, BackDropTemplate")
    EPGPLootFrameCloseButton:SetSize(24, 24)
    EPGPLootFrameCloseButton:SetPoint("TOPRIGHT", EPGPLootFrame, "TOPRIGHT", -3, -3)
    EPGPLootFrameCloseButton:SetScript("OnClick", function() EPGPLootFrame:Hide() end)

    scrollFrame:SetScrollChild(LootScrollPanel)

    EPGPLootFrame:Hide()
end

function TBCEPGP:AddTooltipScript()
    GameTooltip:HookScript("OnTooltipSetItem", function(...)
        local _, itemLink = GameTooltip:GetItem()
        if itemLink ~= nil then
            --local itemName, _, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc = GetItemInfo(itemLink)
            local itemStuff = TBCEPGP:CheckItemInfo(itemLink)

            --if itemEquipLoc ~= nil and TBCEPGP.InfoTable.Slot[itemEquipLoc] ~= nil then
            if itemStuff.itemEquipLoc ~= nil and TBCEPGP.InfoTable.Slot[itemStuff.itemEquipLoc] ~= nil then
                --local price = TBCEPGP:CalculateTotalPrice(itemQuality, itemEquipLoc, itemLevel)
                local price = TBCEPGP:CalculateTotalPrice(itemStuff.itemQuality, itemStuff.itemEquipLoc, itemStuff.itemLevel)
                price = TBCEPGP:MathRound(price * 1000) / 1000
                GameTooltip:AddLine("TBC-EPGP: " .. price .. "GP")
            end
        end
    end)
end

function TBCEPGP:CheckItemInfo(itemInfoStuff)
    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expacID, setID, isCraftingReagent = GetItemInfo(itemInfoStuff)

    local itemID = tonumber(string.match(itemLink, "[^:]*:([^:]*)"))

    local value = TBCEPGP.InfoTable.PreCalculatedItems[itemID]
    if value ~= nil then
        itemLevel = value.itemLevel
        itemQuality = value.itemQuality
        itemEquipLoc = value.itemEquipLoc
    end

    local itemStuff = {itemName = itemName, itemLink = itemLink, itemID = itemID, itemLevel = itemLevel, itemQuality = itemQuality, itemEquipLoc = itemEquipLoc, itemTexture = itemTexture}

    return itemStuff
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
    if quality ~= 0 and quality ~= 1 then
        local multiplier = TBCEPGP.InfoTable.Quality[quality](iLevel)
        return multiplier
    else
        return 1
    end
end

function TBCEPGP:GetSlotMultiplier(slot)    
    if TBCEPGP.InfoTable.Slot[slot] ~= nil then
        local multiplier = TBCEPGP.InfoTable.Slot[slot]
        return multiplier
    else
        return 1
    end
end

function TBCEPGP:CalculateTotalPrice(quality, slot, iLevel)
    local TotalPrice, CalcPrice, QMulty, SMulty = nil, nil, nil, nil
    QMulty = TBCEPGP:GetQualityMultiplier(quality, iLevel)
    SMulty = TBCEPGP:GetSlotMultiplier(slot)

    CalcPrice = QMulty * QMulty * 0.04 * SMulty
    return CalcPrice
end

function TBCEPGP:MathRound(value)
    value = math.floor(value + 0.5)
    return value
end

function TBCEPGP:RollItem(inputLink)
    if inputLink == nil then print("No ItemLink provided!")
    else
        --local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc = GetItemInfo(inputLink)
        local itemStuff = TBCEPGP:CheckItemInfo(inputLink)
        --if itemEquipLoc == nil or itemEquipLoc == "" then itemEquipLoc = "Not Equipable!" end
        if itemStuff.itemEquipLoc == nil or itemStuff.itemEquipLoc == "" then itemStuff.itemEquipLoc = "Not Equipable!" end
        --local totalPrice = TBCEPGP:CalculateTotalPrice(itemQuality, itemEquipLoc, itemLevel)
        local totalPrice = TBCEPGP:CalculateTotalPrice(itemStuff.itemQuality, itemStuff.itemEquipLoc, itemStuff.itemLevel)
        local roundedPrice = TBCEPGP:MathRound(totalPrice)
        --print("EPGP Rolling Item:", itemLink)
        print("EPGP Rolling Item:", itemStuff.itemLink)
        --print("iLevel:", itemLevel, " - Quality:", itemQuality, " - Slot:", itemEquipLoc)
        print("iLevel:", itemStuff.itemLevel, " - Quality:", itemStuff.itemQuality, " - Slot:", itemStuff.itemEquipLoc)
        --print("Quality/iLevel Modifier:", TBCEPGP:GetQualityMultiplier(itemQuality, itemLevel))
        print("Quality/iLevel Modifier:", TBCEPGP:GetQualityMultiplier(itemStuff.itemQuality, itemStuff.itemLevel))
        --print("Slot Modifier:", TBCEPGP:GetSlotMultiplier(itemEquipLoc))
        print("Slot Modifier:", TBCEPGP:GetSlotMultiplier(itemStuff.itemEquipLoc))
        print("Total Price:", totalPrice)
        print("Rounded Price:", roundedPrice)
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
            players[curGUID].EP = 1
            players[curGUID].GP = 1
            players[curGUID].PR = players[curGUID].EP / players[curGUID].GP
            local year, month, date = TBCEPGP:GetDateTime()
            local dateString = year .. month .. date
            print("Adding Target to DataTable:", curName, "-", curGUID)
            players[curGUID][dateString] = {}
            TBCEPGP:FilterPlayers()
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
    print("Trying to sync!")
    local players = TBCEPGPDataTable.Players
    for playerGUID, playerData in pairs(players) do
        local message = "Player:"
        if playerData.EP == nil then playerData.EP = 1 end
        if playerData.GP == nil then playerData.GP = 1 end
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

function TBCEPGP:CreateFilterButtons()
    EPGPAdminFrame:HookScript("OnShow", function()
        FilterButtonFrame:SetParent(EPGPAdminFrame.FilterClassesButton)
        FilterButtonFrame:SetPoint("BOTTOM", EPGPAdminFrame.FilterClassesButton, "TOP")
    end)

    EPGPUserFrame:HookScript("OnShow", function()
        FilterButtonFrame:SetParent(EPGPUserFrame.FilterClassesButton)
        FilterButtonFrame:SetPoint("BOTTOM", EPGPUserFrame.FilterClassesButton, "TOP")
    end)

    FilterButtonFrame = CreateFrame("FRAME", nil, UIParent, "BackdropTemplate")
    FilterButtonFrame:SetSize(91, 115)
    FilterButtonFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    FilterButtonFrame:SetBackdropColor(1, 1, 1, 1)
    FilterButtonFrame:Hide()
    FilterButtonFrame.FilterRaidGroup = CreateFrame("Button", nil, FilterButtonFrame, "UIPanelButtonTemplate")
    FilterButtonFrame.FilterRaidGroup:SetSize(81, 20)
    FilterButtonFrame.FilterRaidGroup:SetPoint("TOP", 0, -5)
    FilterButtonFrame.FilterRaidGroup:SetFrameStrata("HIGH")
    FilterButtonFrame.FilterRaidGroup:SetScript("OnClick",
    function()
        FilterRaid = not FilterRaid
        TBCEPGP:FilterPlayers()
    end)
    FilterButtonFrame.FilterRaidGroup.text = FilterButtonFrame.FilterRaidGroup:CreateFontString("FilterClassesButton", "ARTWORK", "GameFontNormalTiny")
    FilterButtonFrame.FilterRaidGroup.text:SetPoint("CENTER", 0, 0)
    FilterButtonFrame.FilterRaidGroup.text:SetText("Filter Raid")
    FilterButtonFrame.FilterRaidGroup:SetFrameStrata("HIGH")
    FilterButtonFrame.FilterRaidGroup:SetFrameLevel(4)

    local FilterButtons = {}
    for i = 1, 11 do
        if i == 6 or i == 10 then -- Parsing out Monk(6) and DeathKnight(10) index numbers. (DH == 12)
        else
            FilterButtons[i] = CreateFrame("Button", nil, FilterButtonFrame, "BackdropTemplate")
            FilterButtons[i]:SetSize(25, 25)

            local xOff, yOff = nil, nil
            if i == 1 or i == 4 or i == 8 then
                xOff = 5
            elseif i == 2 or i == 5 or i == 9 then
                xOff = 33
            elseif i == 3 or i == 7 or i == 11 then
                xOff = 61
            end
            if i == 1 or i == 2 or i == 3 then
                yOff = -30
            elseif i == 4 or i == 5 or i == 7 then
                yOff = -58
            elseif i == 8 or i == 9 or i == 11 then
                yOff = -86
            end

            FilterButtons[i]:SetPoint("TOPLEFT", xOff, yOff)

            FilterButtons[i]:SetBackdrop({
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                edgeSize = 10,
                insets = {left = 3, right = 3, top = 3, bottom = 3},
            })

            FilterButtons[i].Texture = FilterButtons[i]:CreateTexture(nil, nil)
            FilterButtons[i].Texture:SetSize(FilterButtons[i]:GetWidth(), FilterButtons[i]:GetHeight())
            FilterButtons[i].Texture:SetPoint("CENTER", 0, 0)
            FilterButtons[i].Texture:SetTexture("Interface/GLUES/CHARACTERCREATE/UI-CharacterCreate-Classes")

            local CoordX1, CoordX2, CoordY1, CoordY2 = nil, nil, nil, nil
            if i == 1 or i == 4 or i == 8 or i == 11 then
                CoordY1 = 0
                CoordY2 = 0.25
            elseif i == 3 or i == 5 or i == 7 or i == 9 then
                CoordY1 = 0.25
                CoordY2 = 0.5
            elseif i == 2 then
                CoordY1 = 0.5
                CoordY2 = 0.75
            end

            if i == 1 or i == 2 or i == 3 then
                CoordX1 = 0
                CoordX2 = 0.25
            elseif i == 7 or i == 8 then
                CoordX1 = 0.25
                CoordX2 = 0.5
            elseif i == 4 or i == 5 then
                CoordX1 = 0.5
                CoordX2 = 0.75
            elseif i == 9 or i == 11 then
                CoordX1 = 0.75
                CoordX2 = 1
            end

            FilterButtons[i].Texture:SetTexCoord(CoordX1, CoordX2, CoordY1, CoordY2)
            FilterButtons[i].Texture:SetDesaturated(true)

            local r, g = 1, 0
            FilterButtons[i]:SetBackdropColor(1, 0, 0, 1)

            FilterButtons[i]:SetScript("OnClick",
            function()
                if filteredClasses[i] then
                    filteredClasses[i] = false
                    FilterButtons[i].Texture:SetDesaturated(true)
                else
                    filteredClasses[i] = true
                    FilterButtons[i].Texture:SetDesaturated(false)
                end
                TBCEPGP:FilterPlayers(i)
            end)
        end
    end
end

function TBCEPGP.Events:GroupRosterUpdate()
    TBCEPGP:ShareVersion()
end

function TBCEPGP:CollectPlayersInRaid()
    local playerNames = {}
    for i=1,40 do
        local name = UnitGUID("raid" .. i)
        if name ~= nil then
            tinsert(playerNames, name)
        end
    end
    return playerNames
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
                        TBCEPGP:CalculatePriority(curGUID, subStringList[5], subStringList[6])
                    else
                        local curGUID = subStringList[1]
                        if players[curGUID].Update < subStringList[3] then
                            players[curGUID].Name = subStringList[2]
                            players[curGUID].Update = subStringList[3]
                            players[curGUID].Class = subStringList[4]
                            players[curGUID].EP = subStringList[5]
                            players[curGUID].GP = subStringList[6]
                            TBCEPGP:CalculatePriority(curGUID, subStringList[5], subStringList[6])
                        end
                    end
                    for _, value in pairs(players) do
                        if value.EP == nil then value.EP = 0 end
                        if value.GP == nil then value.GP = 0 end
                    end
                    TBCEPGPDataTable.Players = players
                    TBCEPGP:FillAdminFrameScrollPanel(players)
                    TBCEPGP:FillUserFrameScrollPanel(players)
                end
            end
        end
    elseif prefix == "TBCEPGPItem" then
        local subPayload = payload
        local itemName, itemTexture, GPValue, itemLink = string.match(payload, "Item:([^:]*):([^:]*):([^:]*):(.*):$")
        TBCEPGP:AddItemToLootList(itemName, itemTexture, GPValue, itemLink)
    elseif prefix == "TBCEPGPRoll" then
        local subPayload = payload
        local subStringList = {}

        for i = 1, 3 do
            if subPayload ~= nil then
                subPayload = string.sub(subPayload, string.find(subPayload, ":") + 1, #subPayload)
                local stringFind = string.find(subPayload, ":", 1)
                if stringFind ~= nil then
                    subStringList[i] = string.sub(subPayload, 0, stringFind - 1)
                end
            end
        end
        subStringList[2] = tonumber(subStringList[2])

        TBCEPGP:AddPlayerToItem(subStringList[1], subStringList[2], subStringList[3])
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
    TBCEPGP:CreateFilterButtons()
    ShowAdminViewCheckButton:SetChecked(TBCEPGPShowAdminView)
    TBCEPGP:ShareVersion()

    TBCEPGP:ForceRecalculate()

    if TBCEPGPVersionNumber ~= nil then TBCEPGPVersionNumber = nil end
    TBCEPGPVersionData = {GUID = UnitGUID("Player"), Name = UnitName("Player"), Version = TBCEPGP.Version, ErrorInfo = {}}
    DevTools_Dump(TBCEPGPVersionData)

    TBCEPGP:ChangePRCalculations()
    EPGPOptionsPanel.EPOffSet:SetText(TBCEPGPPRCalc[1])
    EPGPOptionsPanel.GPOffSet:SetText(TBCEPGPPRCalc[2])
end

function TBCEPGP:ForceRecalculate()
    local Players = TBCEPGPDataTable.Players
    for curPlayer, playerData in pairs(Players) do
        Players[curPlayer].PR = TBCEPGP:CalculatePriority(curPlayer, playerData.EP, playerData.GP)
    end
    TBCEPGP:FilterPlayers()
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
    EPGPAdminFrame:SetSize(670, 400)
    EPGPAdminFrame:EnableMouse(true)
    EPGPAdminFrame:SetMovable(true)
    EPGPAdminFrame:RegisterForDrag("LeftButton")
    EPGPAdminFrame:SetScript("OnDragStart", EPGPAdminFrame.StartMoving)
    EPGPAdminFrame:SetScript("OnDragStop", EPGPAdminFrame.StopMovingOrSizing)

    EPGPAdminFrame.TopLeftBG     = CreateFrame("Frame", nil, EPGPAdminFrame, "BackdropTemplate")
    EPGPAdminFrame.TopBG1        = CreateFrame("Frame", nil, EPGPAdminFrame, "BackdropTemplate")
    EPGPAdminFrame.TopBG2        = CreateFrame("Frame", nil, EPGPAdminFrame, "BackdropTemplate")
    EPGPAdminFrame.TopRightBG    = CreateFrame("Frame", nil, EPGPAdminFrame, "BackdropTemplate")
    EPGPAdminFrame.BotLeftBG     = CreateFrame("Frame", nil, EPGPAdminFrame, "BackdropTemplate")
    EPGPAdminFrame.BotBG1        = CreateFrame("Frame", nil, EPGPAdminFrame, "BackdropTemplate")
    EPGPAdminFrame.BotBG2        = CreateFrame("Frame", nil, EPGPAdminFrame, "BackdropTemplate")
    EPGPAdminFrame.BotRightBG    = CreateFrame("Frame", nil, EPGPAdminFrame, "BackdropTemplate")

    EPGPAdminFrame.TopLeftBG :SetSize(200, EPGPAdminFrame:GetHeight() / 2)
    EPGPAdminFrame.TopBG1    :SetSize(200, EPGPAdminFrame:GetHeight() / 2)
    EPGPAdminFrame.TopBG2    :SetSize(200, EPGPAdminFrame:GetHeight() / 2)
    EPGPAdminFrame.TopRightBG:SetSize(100, EPGPAdminFrame:GetHeight() / 2)
    EPGPAdminFrame.BotLeftBG :SetSize(200, EPGPAdminFrame:GetHeight() / 2)
    EPGPAdminFrame.BotBG1    :SetSize(200, EPGPAdminFrame:GetHeight() / 2)
    EPGPAdminFrame.BotBG2    :SetSize(200, EPGPAdminFrame:GetHeight() / 2)
    EPGPAdminFrame.BotRightBG:SetSize(100, EPGPAdminFrame:GetHeight() / 2)

    EPGPAdminFrame.TopLeftBG :SetPoint("TOPLEFT", 0, 0)
    EPGPAdminFrame.TopBG1    :SetPoint("LEFT", EPGPAdminFrame.TopLeftBG, "RIGHT", 0, 0)
    EPGPAdminFrame.TopBG2    :SetPoint("LEFT", EPGPAdminFrame.TopBG1, "RIGHT", 0, 0)
    EPGPAdminFrame.TopRightBG:SetPoint("LEFT", EPGPAdminFrame.TopBG2, "RIGHT", 0, 0)

    EPGPAdminFrame.BotLeftBG :SetPoint("TOP", EPGPAdminFrame.TopLeftBG, "BOTTOM", 0, 0)
    EPGPAdminFrame.BotBG1    :SetPoint("TOP", EPGPAdminFrame.TopBG1, "BOTTOM", 0, 0)
    EPGPAdminFrame.BotBG2    :SetPoint("TOP", EPGPAdminFrame.TopBG2, "BOTTOM", 0, 0)
    EPGPAdminFrame.BotRightBG:SetPoint("TOP", EPGPAdminFrame.TopRightBG, "BOTTOM", 0, 0)

    EPGPAdminFrame.TopLeftBG :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-TOPLEFT"})
    EPGPAdminFrame.TopBG1    :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-TOP"})
    EPGPAdminFrame.TopBG2    :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-TOP"})
    EPGPAdminFrame.TopRightBG:SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-TOPRIGHT"})
    EPGPAdminFrame.BotLeftBG :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-BOTLEFT"})
    EPGPAdminFrame.BotBG1    :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-BOTTOM"})
    EPGPAdminFrame.BotBG2    :SetBackdrop({bgFile = "Interface/HELPFRAME/HelpFrame-BOTTOM"})
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

    local scrollFrame = CreateFrame("ScrollFrame", nil, EPGPAdminFrame, "UIPanelScrollFrameTemplate BackdropTemplate");
    scrollFrame:SetSize(EPGPAdminFrame:GetWidth() - 45, EPGPAdminFrame:GetHeight() - 77)
    scrollFrame:SetPoint("TOP", -11, -40)
    scrollFrame:SetFrameStrata("HIGH")

    AdminScrollPanel = CreateFrame("Frame")
    AdminScrollPanel:SetSize(scrollFrame:GetWidth(), 300)
    AdminScrollPanel:SetPoint("TOP")

    EPGPAdminFrame.Header = CreateFrame("Frame", nil, EPGPAdminFrame, "BackdropTemplate")
    EPGPAdminFrame.Header:SetPoint("TOP", -11, -20)
    EPGPAdminFrame.Header:SetSize(AdminScrollPanel:GetWidth(), 50)

    EPGPAdminFrame.Header.Number = CreateFrame("Frame", nil, EPGPAdminFrame.Header, "BackdropTemplate")
    EPGPAdminFrame.Header.Number:SetSize(20, 24)
    EPGPAdminFrame.Header.Number:SetPoint("TOPLEFT", 5, 0)
    EPGPAdminFrame.Header.Number:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPAdminFrame.Header.Number:SetBackdropColor(1, 1, 1, 1)

    EPGPAdminFrame.Header.Number.Text = EPGPAdminFrame.Header.Number:CreateFontString("EPGPAdminFrame.Header.Number.Text", "ARTWORK", "GameFontNormal")
    EPGPAdminFrame.Header.Number.Text:SetSize(EPGPAdminFrame.Header.Number:GetWidth(), EPGPAdminFrame.Header.Number:GetHeight())
    EPGPAdminFrame.Header.Number.Text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.Header.Number.Text:SetTextColor(1, 1, 1, 1)
    EPGPAdminFrame.Header.Number.Text:SetText("#")

    EPGPAdminFrame.Header.Name = CreateFrame("Frame", nil, EPGPAdminFrame.Header, "BackdropTemplate")
    EPGPAdminFrame.Header.Name:SetSize(100, 24)
    EPGPAdminFrame.Header.Name:SetPoint("BOTTOMLEFT", EPGPAdminFrame.Header.Number, "BOTTOMRIGHT", -4, 0)
    EPGPAdminFrame.Header.Name:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPAdminFrame.Header.Name:SetBackdropColor(1, 1, 1, 1)

    EPGPAdminFrame.Header.Name.Text = EPGPAdminFrame.Header.Name:CreateFontString("EPGPAdminFrame.Header.Name.Text", "ARTWORK", "GameFontNormal")
    EPGPAdminFrame.Header.Name.Text:SetSize(EPGPAdminFrame.Header.Name:GetWidth(), EPGPAdminFrame.Header.Name:GetHeight())
    EPGPAdminFrame.Header.Name.Text:SetPoint("BOTTOMLEFT", EPGPAdminFrame.Header.Number, "BOTTOMRIGHT", -4, 0)
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

    EPGPAdminFrame.Header.curEP = CreateFrame("Frame", nil, EPGPAdminFrame.Header, "BackdropTemplate")
    EPGPAdminFrame.Header.curEP:SetSize(165, 24)
    EPGPAdminFrame.Header.curEP:SetPoint("BOTTOMLEFT", EPGPAdminFrame.Header.Class, "BOTTOMRIGHT", -4, 0)
    EPGPAdminFrame.Header.curEP:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPAdminFrame.Header.curEP:SetBackdropColor(1, 1, 1, 1)

    EPGPAdminFrame.Header.curEP.Text = EPGPAdminFrame.Header.curEP:CreateFontString("EPGPAdminFrame.Header.curEP.Text", "ARTWORK", "GameFontNormal")
    EPGPAdminFrame.Header.curEP.Text:SetSize(EPGPAdminFrame.Header.curEP:GetWidth(), EPGPAdminFrame.Header.curEP:GetHeight())
    EPGPAdminFrame.Header.curEP.Text:SetPoint("CENTER", -25, 0)
    EPGPAdminFrame.Header.curEP.Text:SetTextColor(1, 1, 1, 1)
    EPGPAdminFrame.Header.curEP.Text:SetText("EP")

    EPGPAdminFrame.EPLocked = true

    EPGPAdminFrame.Header.curEP.LockUnlockButton = CreateFrame("BUTTON", nil, EPGPAdminFrame.Header.curEP, "BackdropTemplate")
    EPGPAdminFrame.Header.curEP.LockUnlockButton:SetSize(25, 25)
    EPGPAdminFrame.Header.curEP.LockUnlockButton:SetPoint("RIGHT", 0, 0)
    EPGPAdminFrame.Header.curEP.LockUnlockButton:SetScript("OnClick", function() TBCEPGP:LockUnlockAdminControls("EP") end)
    EPGPAdminFrame.Header.curEP.LockUnlockButton:SetBackdrop({
        bgFile = "Interface/Buttons/LockButton-Locked-Up"
    })

    EPGPAdminFrame.Header.curEP.changeEP = CreateFrame("EditBox", nil, EPGPAdminFrame.Header.curEP, "InputBoxTemplate")
    EPGPAdminFrame.Header.curEP.changeEP:SetSize(50, 25)
    EPGPAdminFrame.Header.curEP.changeEP:SetPoint("BOTTOMLEFT", EPGPAdminFrame.Header.curEP, "BOTTOMRIGHT", -75, 0)
    EPGPAdminFrame.Header.curEP.changeEP:SetAutoFocus(false)
    EPGPAdminFrame.Header.curEP.changeEP:SetFrameStrata("HIGH")
    EPGPAdminFrame.Header.curEP.changeEP:SetText(0)
    EPGPAdminFrame.Header.curEP.changeEP:HookScript("OnEditFocusLost", function() TBCEPGP:MassChange("EP") end)
    EPGPAdminFrame.Header.curEP.changeEP:Hide()

    EPGPAdminFrame.Header.curGP = CreateFrame("Frame", nil, EPGPAdminFrame.Header, "BackdropTemplate")
    EPGPAdminFrame.Header.curGP:SetSize(165, 24)
    EPGPAdminFrame.Header.curGP:SetPoint("BOTTOMLEFT", EPGPAdminFrame.Header.curEP, "BOTTOMRIGHT", -4, 0)
    EPGPAdminFrame.Header.curGP:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPAdminFrame.Header.curGP:SetBackdropColor(1, 1, 1, 1)

    EPGPAdminFrame.GPLocked = true

    EPGPAdminFrame.Header.curGP.LockUnlockButton = CreateFrame("BUTTON", nil, EPGPAdminFrame.Header.curGP, "BackdropTemplate")
    EPGPAdminFrame.Header.curGP.LockUnlockButton:SetSize(25, 25)
    EPGPAdminFrame.Header.curGP.LockUnlockButton:SetPoint("RIGHT", 0, 0)
    EPGPAdminFrame.Header.curGP.LockUnlockButton:SetScript("OnClick", function() TBCEPGP:LockUnlockAdminControls("GP") end)
    EPGPAdminFrame.Header.curGP.LockUnlockButton:SetBackdrop({
        bgFile = "Interface/Buttons/LockButton-Locked-Up"
    })

    EPGPAdminFrame.Header.curGP.Text = EPGPAdminFrame.Header.curGP:CreateFontString("EPGPAdminFrame.Header.curGP.Text", "ARTWORK", "GameFontNormal")
    EPGPAdminFrame.Header.curGP.Text:SetSize(EPGPAdminFrame.Header.curGP:GetWidth(), EPGPAdminFrame.Header.curGP:GetHeight())
    EPGPAdminFrame.Header.curGP.Text:SetPoint("CENTER", -25, 0)
    EPGPAdminFrame.Header.curGP.Text:SetTextColor(1, 1, 1, 1)
    EPGPAdminFrame.Header.curGP.Text:SetText("GP")

    EPGPAdminFrame.Header.curGP.changeGP = CreateFrame("EditBox", nil, EPGPAdminFrame.Header.curGP, "InputBoxTemplate")
    EPGPAdminFrame.Header.curGP.changeGP:SetSize(50, 25)
    EPGPAdminFrame.Header.curGP.changeGP:SetPoint("BOTTOMLEFT", EPGPAdminFrame.Header.curGP, "BOTTOMRIGHT", -75, 0)
    EPGPAdminFrame.Header.curGP.changeGP:SetAutoFocus(false)
    EPGPAdminFrame.Header.curGP.changeGP:SetFrameStrata("HIGH")
    EPGPAdminFrame.Header.curGP.changeGP:SetText(0)
    EPGPAdminFrame.Header.curGP.changeGP:HookScript("OnEditFocusLost", function() TBCEPGP:MassChange("GP") end)
    EPGPAdminFrame.Header.curGP.changeGP:Hide()

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

    EPGPAdminFrame.Header.Name .SortUpButton = CreateFrame("BUTTON", nil, EPGPAdminFrame.Header .Name, "BackDropTemplate")
    EPGPAdminFrame.Header.Class.SortUpButton = CreateFrame("BUTTON", nil, EPGPAdminFrame.Header.Class, "BackDropTemplate")
    EPGPAdminFrame.Header.curEP.SortUpButton = CreateFrame("BUTTON", nil, EPGPAdminFrame.Header.curEP, "BackDropTemplate")
    EPGPAdminFrame.Header.curGP.SortUpButton = CreateFrame("BUTTON", nil, EPGPAdminFrame.Header.curGP, "BackDropTemplate")
    EPGPAdminFrame.Header.curPR.SortUpButton = CreateFrame("BUTTON", nil, EPGPAdminFrame.Header.curPR, "BackDropTemplate")

    EPGPAdminFrame.Header.Name .SortDownButton = CreateFrame("BUTTON", nil, EPGPAdminFrame.Header .Name, "BackDropTemplate")
    EPGPAdminFrame.Header.Class.SortDownButton = CreateFrame("BUTTON", nil, EPGPAdminFrame.Header.Class, "BackDropTemplate")
    EPGPAdminFrame.Header.curEP.SortDownButton = CreateFrame("BUTTON", nil, EPGPAdminFrame.Header.curEP, "BackDropTemplate")
    EPGPAdminFrame.Header.curGP.SortDownButton = CreateFrame("BUTTON", nil, EPGPAdminFrame.Header.curGP, "BackDropTemplate")
    EPGPAdminFrame.Header.curPR.SortDownButton = CreateFrame("BUTTON", nil, EPGPAdminFrame.Header.curPR, "BackDropTemplate")

    EPGPAdminFrame.Header.Name .SortUpButton:SetSize(10, 10)
    EPGPAdminFrame.Header.Class.SortUpButton:SetSize(10, 10)
    EPGPAdminFrame.Header.curEP.SortUpButton:SetSize(10, 10)
    EPGPAdminFrame.Header.curGP.SortUpButton:SetSize(10, 10)
    EPGPAdminFrame.Header.curPR.SortUpButton:SetSize(10, 10)

    EPGPAdminFrame.Header.Name .SortDownButton:SetSize(10, 10)
    EPGPAdminFrame.Header.Class.SortDownButton:SetSize(10, 10)
    EPGPAdminFrame.Header.curEP.SortDownButton:SetSize(10, 10)
    EPGPAdminFrame.Header.curGP.SortDownButton:SetSize(10, 10)
    EPGPAdminFrame.Header.curPR.SortDownButton:SetSize(10, 10)

    EPGPAdminFrame.Header.Name .SortUpButton:SetPoint("LEFT", 4, 5)
    EPGPAdminFrame.Header.Class.SortUpButton:SetPoint("LEFT", 4, 5)
    EPGPAdminFrame.Header.curEP.SortUpButton:SetPoint("LEFT", 4, 5)
    EPGPAdminFrame.Header.curGP.SortUpButton:SetPoint("LEFT", 4, 5)
    EPGPAdminFrame.Header.curPR.SortUpButton:SetPoint("LEFT", 4, 5)

    EPGPAdminFrame.Header.Name .SortDownButton:SetPoint("LEFT", 4, -3)
    EPGPAdminFrame.Header.Class.SortDownButton:SetPoint("LEFT", 4, -3)
    EPGPAdminFrame.Header.curEP.SortDownButton:SetPoint("LEFT", 4, -3)
    EPGPAdminFrame.Header.curGP.SortDownButton:SetPoint("LEFT", 4, -3)
    EPGPAdminFrame.Header.curPR.SortDownButton:SetPoint("LEFT", 4, -3)

    EPGPAdminFrame.Header.Name .SortUpButton  .Texture = EPGPAdminFrame.Header.Name .SortUpButton  :CreateTexture(nil, nil)
    EPGPAdminFrame.Header.Class.SortUpButton  .Texture = EPGPAdminFrame.Header.Class.SortUpButton  :CreateTexture(nil, nil)
    EPGPAdminFrame.Header.curEP.SortUpButton  .Texture = EPGPAdminFrame.Header.curEP.SortUpButton  :CreateTexture(nil, nil)
    EPGPAdminFrame.Header.curGP.SortUpButton  .Texture = EPGPAdminFrame.Header.curGP.SortUpButton  :CreateTexture(nil, nil)
    EPGPAdminFrame.Header.curPR.SortUpButton  .Texture = EPGPAdminFrame.Header.curPR.SortUpButton  :CreateTexture(nil, nil)
    EPGPAdminFrame.Header.Name .SortDownButton.Texture = EPGPAdminFrame.Header.Name .SortDownButton:CreateTexture(nil, nil)
    EPGPAdminFrame.Header.Class.SortDownButton.Texture = EPGPAdminFrame.Header.Class.SortDownButton:CreateTexture(nil, nil)
    EPGPAdminFrame.Header.curEP.SortDownButton.Texture = EPGPAdminFrame.Header.curEP.SortDownButton:CreateTexture(nil, nil)
    EPGPAdminFrame.Header.curGP.SortDownButton.Texture = EPGPAdminFrame.Header.curGP.SortDownButton:CreateTexture(nil, nil)
    EPGPAdminFrame.Header.curPR.SortDownButton.Texture = EPGPAdminFrame.Header.curPR.SortDownButton:CreateTexture(nil, nil)

    EPGPAdminFrame.Header.Name .SortUpButton  .Texture:SetTexture("Interface/Buttons/UI-Panel-CollapseButton-Up")
    EPGPAdminFrame.Header.Class.SortUpButton  .Texture:SetTexture("Interface/Buttons/UI-Panel-CollapseButton-Up")
    EPGPAdminFrame.Header.curEP.SortUpButton  .Texture:SetTexture("Interface/Buttons/UI-Panel-CollapseButton-Up")
    EPGPAdminFrame.Header.curGP.SortUpButton  .Texture:SetTexture("Interface/Buttons/UI-Panel-CollapseButton-Up")
    EPGPAdminFrame.Header.curPR.SortUpButton  .Texture:SetTexture("Interface/Buttons/UI-Panel-CollapseButton-Up")
    EPGPAdminFrame.Header.Name .SortDownButton.Texture:SetTexture("Interface/Buttons/UI-Panel-ExpandButton-Up")
    EPGPAdminFrame.Header.Class.SortDownButton.Texture:SetTexture("Interface/Buttons/UI-Panel-ExpandButton-Up")
    EPGPAdminFrame.Header.curEP.SortDownButton.Texture:SetTexture("Interface/Buttons/UI-Panel-ExpandButton-Up")
    EPGPAdminFrame.Header.curGP.SortDownButton.Texture:SetTexture("Interface/Buttons/UI-Panel-ExpandButton-Up")
    EPGPAdminFrame.Header.curPR.SortDownButton.Texture:SetTexture("Interface/Buttons/UI-Panel-ExpandButton-Up")

    EPGPAdminFrame.Header.Name .SortUpButton  .Texture:SetSize(16, 16)
    EPGPAdminFrame.Header.Class.SortUpButton  .Texture:SetSize(16, 16)
    EPGPAdminFrame.Header.curEP.SortUpButton  .Texture:SetSize(16, 16)
    EPGPAdminFrame.Header.curGP.SortUpButton  .Texture:SetSize(16, 16)
    EPGPAdminFrame.Header.curPR.SortUpButton  .Texture:SetSize(16, 16)
    EPGPAdminFrame.Header.Name .SortDownButton.Texture:SetSize(16, 16)
    EPGPAdminFrame.Header.Class.SortDownButton.Texture:SetSize(16, 16)
    EPGPAdminFrame.Header.curEP.SortDownButton.Texture:SetSize(16, 16)
    EPGPAdminFrame.Header.curGP.SortDownButton.Texture:SetSize(16, 16)
    EPGPAdminFrame.Header.curPR.SortDownButton.Texture:SetSize(16, 16)

    EPGPAdminFrame.Header.Name .SortUpButton  .Texture:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.Header.Class.SortUpButton  .Texture:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.Header.curEP.SortUpButton  .Texture:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.Header.curGP.SortUpButton  .Texture:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.Header.curPR.SortUpButton  .Texture:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.Header.Name .SortDownButton.Texture:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.Header.Class.SortDownButton.Texture:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.Header.curEP.SortDownButton.Texture:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.Header.curGP.SortDownButton.Texture:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.Header.curPR.SortDownButton.Texture:SetPoint("CENTER", 0, 0)

    EPGPAdminFrame.Header.Name .SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "Name"  TBCEPGP:FilterPlayers() end)
    EPGPAdminFrame.Header.Class.SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "Class" TBCEPGP:FilterPlayers() end)
    EPGPAdminFrame.Header.curEP.SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "EP"    TBCEPGP:FilterPlayers() end)
    EPGPAdminFrame.Header.curGP.SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "GP"    TBCEPGP:FilterPlayers() end)
    EPGPAdminFrame.Header.curPR.SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "PR"    TBCEPGP:FilterPlayers() end)

    EPGPAdminFrame.Header.Name .SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "Name"  TBCEPGP:FilterPlayers() end)
    EPGPAdminFrame.Header.Class.SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "Class" TBCEPGP:FilterPlayers() end)
    EPGPAdminFrame.Header.curEP.SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "EP"    TBCEPGP:FilterPlayers() end)
    EPGPAdminFrame.Header.curGP.SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "GP"    TBCEPGP:FilterPlayers() end)
    EPGPAdminFrame.Header.curPR.SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "PR"    TBCEPGP:FilterPlayers() end)

    local EPGPAdminFrameCloseButton = CreateFrame("Button", nil, EPGPAdminFrame, "UIPanelCloseButton, BackDropTemplate")
    EPGPAdminFrameCloseButton:SetSize(24, 24)
    EPGPAdminFrameCloseButton:SetPoint("TOPRIGHT", EPGPAdminFrame, "TOPRIGHT", -3, -3)
    EPGPAdminFrameCloseButton:SetScript("OnClick", function() EPGPAdminFrame:Hide() end)

    EPGPAdminFrame.FilterClassesButton = CreateFrame("Button", nil, EPGPAdminFrame, "UIPanelButtonTemplate")
    EPGPAdminFrame.FilterClassesButton:SetSize(75, 20)
    EPGPAdminFrame.FilterClassesButton:SetPoint("TOP", EPGPAdminFrame.Header.Class, "BOTTOM", 0, -321)
    EPGPAdminFrame.FilterClassesButton:SetFrameStrata("HIGH")
    EPGPAdminFrame.FilterClassesButton:SetScript("OnClick",
    function()
        if FilterButtonFrame:IsShown() then FilterButtonFrame:Hide() else FilterButtonFrame:Show() end
    end)
    EPGPAdminFrame.FilterClassesButton.text = EPGPAdminFrame.FilterClassesButton:CreateFontString("FilterClassesButton", "ARTWORK", "GameFontNormalTiny")
    EPGPAdminFrame.FilterClassesButton.text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.FilterClassesButton.text:SetText("Filters")
    EPGPAdminFrame.FilterClassesButton:SetFrameStrata("HIGH")
    EPGPAdminFrame.FilterClassesButton:SetFrameLevel(4)

    local PurgeConfirmWindow = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    PurgeConfirmWindow:SetSize(300, 150)
    PurgeConfirmWindow:SetPoint("CENTER", 0, 200)
    PurgeConfirmWindow:SetFrameStrata("DIALOG")
    PurgeConfirmWindow:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    PurgeConfirmWindow:SetBackdropColor(1, 0.25, 0.25, 1)

    PurgeConfirmWindow.Header = PurgeConfirmWindow:CreateFontString("PurgeConfirmWindow", "ARTWORK", "GameFontNormalHuge")
    PurgeConfirmWindow.Header:SetSize(PurgeConfirmWindow:GetWidth(), 25)
    PurgeConfirmWindow.Header:SetPoint("TOP", 0, -5)
    PurgeConfirmWindow.Header:SetText("|cFFFF0000WARNING!|r")

    PurgeConfirmWindow.WarningText = PurgeConfirmWindow:CreateFontString("PurgeConfirmWindow", "ARTWORK", "GameFontNormalLarge")
    PurgeConfirmWindow.WarningText:SetSize(PurgeConfirmWindow:GetWidth(), 50)
    PurgeConfirmWindow.WarningText:SetPoint("TOP", PurgeConfirmWindow.Header, "BOTTOM", 0, -10)
    PurgeConfirmWindow.WarningText:SetText("|cFFFF0000Are you sure you want to purge\nthe entire dataTable?\nThis can not be undone!|r")

    PurgeConfirmWindow.ConfirmButton = CreateFrame("Button", nil, PurgeConfirmWindow, "UIPanelButtonTemplate")
    PurgeConfirmWindow.ConfirmButton:SetSize(75, 25)
    PurgeConfirmWindow.ConfirmButton:SetPoint("TOP", PurgeConfirmWindow, "BOTTOM", -50, 35)
    PurgeConfirmWindow.ConfirmButton:SetText("Confirm")
    PurgeConfirmWindow.ConfirmButton:SetScript("OnClick", function() TBCEPGP:PurgeDataTable() PurgeConfirmWindow:Hide() end)

    PurgeConfirmWindow.CancelButton = CreateFrame("Button", nil, PurgeConfirmWindow, "UIPanelButtonTemplate")
    PurgeConfirmWindow.CancelButton:SetSize(75, 25)
    PurgeConfirmWindow.CancelButton:SetPoint("TOP", PurgeConfirmWindow, "BOTTOM", 50, 35)
    PurgeConfirmWindow.CancelButton:SetText("Cancel")
    PurgeConfirmWindow.CancelButton:SetScript("OnClick", function() PurgeConfirmWindow:Hide() end)

    PurgeConfirmWindow:Hide()

    local DecayConfirmWindow = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    DecayConfirmWindow:SetSize(300, 150)
    DecayConfirmWindow:SetPoint("CENTER", 0, 200)
    DecayConfirmWindow:SetFrameStrata("DIALOG")
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

    EPGPAdminFrame.PurgeButton = CreateFrame("Button", nil, EPGPAdminFrame, "UIPanelButtonTemplate")
    EPGPAdminFrame.PurgeButton:SetSize(75, 20)
    EPGPAdminFrame.PurgeButton:SetPoint("BOTTOMLEFT", EPGPAdminFrame, "BOTTOMLEFT", 10, 15)
    EPGPAdminFrame.PurgeButton:SetFrameStrata("HIGH")
    EPGPAdminFrame.PurgeButton:SetScript("OnClick",
    function()
        PurgeConfirmWindow:Show()
    end)
    EPGPAdminFrame.PurgeButton.text = EPGPAdminFrame.PurgeButton:CreateFontString("PurgeButton", "ARTWORK", "GameFontNormalTiny")
    EPGPAdminFrame.PurgeButton.text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.PurgeButton.text:SetText("Purge")

    EPGPAdminFrame.OptionsButton = CreateFrame("Button", nil, EPGPAdminFrame, "UIPanelButtonTemplate")
    EPGPAdminFrame.OptionsButton:SetSize(75, 20)
    EPGPAdminFrame.OptionsButton:SetPoint("BOTTOMRIGHT", EPGPAdminFrame, "BOTTOMRIGHT", -10, 15)
    EPGPAdminFrame.OptionsButton:SetFrameStrata("HIGH")
    EPGPAdminFrame.OptionsButton:SetScript("OnClick",
    function()
        InterfaceOptionsFrame_OpenToCategory("TBC-EPGP")
        InterfaceOptionsFrame_OpenToCategory("TBC-EPGP")
    end)
    EPGPAdminFrame.OptionsButton.text = EPGPAdminFrame.OptionsButton:CreateFontString("OptionsButton", "ARTWORK", "GameFontNormalTiny")
    EPGPAdminFrame.OptionsButton.text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.OptionsButton.text:SetText("Options")

    EPGPAdminFrame.AddToDataBaseButton = CreateFrame("Button", nil, EPGPAdminFrame, "UIPanelButtonTemplate")
    EPGPAdminFrame.AddToDataBaseButton:SetSize(75, 20)
    EPGPAdminFrame.AddToDataBaseButton:SetPoint("Right", EPGPAdminFrame.OptionsButton, "Left", -10, 0)
    EPGPAdminFrame.AddToDataBaseButton:SetFrameStrata("HIGH")
    EPGPAdminFrame.AddToDataBaseButton:SetScript("OnClick",
    function()
        local players = TBCEPGP.DataTable.Players
        local unitGUID = UnitGUID("Target")
        local unitName = UnitName("Target")
        local _, _, unitClass = UnitClass("Target")
        TBCEPGP:AddPlayerToList(unitGUID, unitName, unitClass)
        TBCEPGP:FillAdminFrameScrollPanel(players)
    end)
    EPGPAdminFrame.AddToDataBaseButton.text = EPGPAdminFrame.AddToDataBaseButton:CreateFontString("AddToDataBaseButton", "ARTWORK", "GameFontNormalTiny")
    EPGPAdminFrame.AddToDataBaseButton.text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.AddToDataBaseButton.text:SetText("Add Target")

    EPGPAdminFrame.DecayButton = CreateFrame("Button", nil, EPGPAdminFrame, "UIPanelButtonTemplate")
    EPGPAdminFrame.DecayButton:SetSize(75, 20)
    EPGPAdminFrame.DecayButton:SetPoint("Right", EPGPAdminFrame.AddToDataBaseButton, "Left", -10, 0)
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
        TBCEPGP:SyncRaidersAddOnMsg()
    end)
    EPGPAdminFrame.SyncButton.text = EPGPAdminFrame.SyncButton:CreateFontString("SyncButton", "ARTWORK", "GameFontNormalTiny")
    EPGPAdminFrame.SyncButton.text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.SyncButton.text:SetText("Sync")

    EPGPAdminFrame.LogsButton = CreateFrame("Button", nil, EPGPAdminFrame, "UIPanelButtonTemplate")
    EPGPAdminFrame.LogsButton:SetSize(75, 20)
    EPGPAdminFrame.LogsButton:SetPoint("Right", EPGPAdminFrame.SyncButton, "Left", -10, 0)
    EPGPAdminFrame.LogsButton:SetFrameStrata("HIGH")
    EPGPAdminFrame.LogsButton:SetScript("OnClick",
    function()
        EPGPAdminFrame:Hide()
        TBCEPGP:UpdateLogs()
        EPGPChangeLogFrame:Show()
    end)
    EPGPAdminFrame.LogsButton.text = EPGPAdminFrame.LogsButton:CreateFontString("SyncButton", "ARTWORK", "GameFontNormalTiny")
    EPGPAdminFrame.LogsButton.text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.LogsButton.text:SetText("Logs")

    local players = TBCEPGP.DataTable.Players
    TBCEPGP:FillAdminFrameScrollPanel(players)
    scrollFrame:SetScrollChild(AdminScrollPanel)

    EPGPAdminFrame:Hide()
end

function TBCEPGP:LockUnlockAdminControls(Points)
    if EPGPAdminFrame[Points .. "Locked"] == true then
        EPGPAdminFrame[Points .. "Locked"] = false
        EPGPAdminFrame.Header["cur" .. Points]["change" .. Points]:Show()
        EPGPAdminFrame.Header["cur" .. Points].LockUnlockButton:SetBackdrop({bgFile = "Interface/Buttons/LockButton-Unlocked-Up"})
    elseif EPGPAdminFrame[Points .. "Locked"] == false then
        EPGPAdminFrame[Points .. "Locked"] = true
        EPGPAdminFrame.Header["cur" .. Points]["change" .. Points]:Hide()
        EPGPAdminFrame.Header["cur" .. Points].LockUnlockButton:SetBackdrop({bgFile = "Interface/Buttons/LockButton-Locked-Up"})
    end
    TBCEPGP:FillAdminFrameScrollPanel(filteredPlayers)
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

    local scrollFrame = CreateFrame("ScrollFrame", nil, EPGPUserFrame, "UIPanelScrollFrameTemplate BackdropTemplate");
    scrollFrame:SetSize(EPGPUserFrame:GetWidth() - 45, EPGPUserFrame:GetHeight() - 77)
    scrollFrame:SetPoint("TOP", -11, -40)
    scrollFrame:SetFrameStrata("HIGH")

    UserScrollPanel = CreateFrame("Frame")
    UserScrollPanel:SetSize(scrollFrame:GetWidth(), 300)
    UserScrollPanel:SetPoint("TOP")

    EPGPUserFrame.Header = CreateFrame("Frame", nil, EPGPUserFrame, "BackdropTemplate")
    EPGPUserFrame.Header:SetPoint("TOP", -11, -20)
    EPGPUserFrame.Header:SetSize(UserScrollPanel:GetWidth(), 50)

    EPGPUserFrame.Header.Number = CreateFrame("Frame", nil, EPGPUserFrame.Header, "BackdropTemplate")
    EPGPUserFrame.Header.Number:SetSize(20, 24)
    EPGPUserFrame.Header.Number:SetPoint("TOPLEFT", 5, 0)
    EPGPUserFrame.Header.Number:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    EPGPUserFrame.Header.Number:SetBackdropColor(1, 1, 1, 1)

    EPGPUserFrame.Header.Number.Text = EPGPUserFrame.Header.Number:CreateFontString("EPGPUserFrame.Header.Number.Text", "ARTWORK", "GameFontNormal")
    EPGPUserFrame.Header.Number.Text:SetSize(EPGPUserFrame.Header.Number:GetWidth(), EPGPUserFrame.Header.Number:GetHeight())
    EPGPUserFrame.Header.Number.Text:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.Header.Number.Text:SetTextColor(1, 1, 1, 1)
    EPGPUserFrame.Header.Number.Text:SetText("#")

    EPGPUserFrame.Header.Name = CreateFrame("Frame", nil, EPGPUserFrame.Header, "BackdropTemplate")
    EPGPUserFrame.Header.Name:SetSize(100, 24)
    EPGPUserFrame.Header.Name:SetPoint("BOTTOMLEFT", EPGPUserFrame.Header.Number, "BOTTOMRIGHT", -4, 0)
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

    EPGPUserFrame.FilterClassesButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelButtonTemplate")
    EPGPUserFrame.FilterClassesButton:SetSize(75, 20)
    EPGPUserFrame.FilterClassesButton:SetPoint("TOP", EPGPUserFrame.Header.Class, "BOTTOM", 0, -321)
    EPGPUserFrame.FilterClassesButton:SetFrameStrata("HIGH")
    EPGPUserFrame.FilterClassesButton:SetScript("OnClick",
    function()
        if FilterButtonFrame:IsShown() then FilterButtonFrame:Hide() else FilterButtonFrame:Show() end
    end)
    EPGPUserFrame.FilterClassesButton.text = EPGPUserFrame.FilterClassesButton:CreateFontString("FilterClassesButton", "ARTWORK", "GameFontNormalTiny")
    EPGPUserFrame.FilterClassesButton.text:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.FilterClassesButton.text:SetText("Filters")

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
    EPGPUserFrame.Header.Name .Text:SetFont(curFont, curSize - 2, curFlags)
    EPGPUserFrame.Header.Class.Text:SetFont(curFont, curSize - 2, curFlags)
    EPGPUserFrame.Header.curEP.Text:SetFont(curFont, curSize - 2, curFlags)
    EPGPUserFrame.Header.curGP.Text:SetFont(curFont, curSize - 2, curFlags)
    EPGPUserFrame.Header.curPR.Text:SetFont(curFont, curSize - 2, curFlags)

    EPGPUserFrame.Header.Name .SortUpButton = CreateFrame("BUTTON", nil, EPGPUserFrame.Header .Name, "BackDropTemplate")
    EPGPUserFrame.Header.Class.SortUpButton = CreateFrame("BUTTON", nil, EPGPUserFrame.Header.Class, "BackDropTemplate")
    EPGPUserFrame.Header.curEP.SortUpButton = CreateFrame("BUTTON", nil, EPGPUserFrame.Header.curEP, "BackDropTemplate")
    EPGPUserFrame.Header.curGP.SortUpButton = CreateFrame("BUTTON", nil, EPGPUserFrame.Header.curGP, "BackDropTemplate")
    EPGPUserFrame.Header.curPR.SortUpButton = CreateFrame("BUTTON", nil, EPGPUserFrame.Header.curPR, "BackDropTemplate")

    EPGPUserFrame.Header.Name .SortDownButton = CreateFrame("BUTTON", nil, EPGPUserFrame.Header .Name, "BackDropTemplate")
    EPGPUserFrame.Header.Class.SortDownButton = CreateFrame("BUTTON", nil, EPGPUserFrame.Header.Class, "BackDropTemplate")
    EPGPUserFrame.Header.curEP.SortDownButton = CreateFrame("BUTTON", nil, EPGPUserFrame.Header.curEP, "BackDropTemplate")
    EPGPUserFrame.Header.curGP.SortDownButton = CreateFrame("BUTTON", nil, EPGPUserFrame.Header.curGP, "BackDropTemplate")
    EPGPUserFrame.Header.curPR.SortDownButton = CreateFrame("BUTTON", nil, EPGPUserFrame.Header.curPR, "BackDropTemplate")

    EPGPUserFrame.Header.Name .SortUpButton:SetSize(10, 10)
    EPGPUserFrame.Header.Class.SortUpButton:SetSize(10, 10)
    EPGPUserFrame.Header.curEP.SortUpButton:SetSize(10, 10)
    EPGPUserFrame.Header.curGP.SortUpButton:SetSize(10, 10)
    EPGPUserFrame.Header.curPR.SortUpButton:SetSize(10, 10)

    EPGPUserFrame.Header.Name .SortDownButton:SetSize(10, 10)
    EPGPUserFrame.Header.Class.SortDownButton:SetSize(10, 10)
    EPGPUserFrame.Header.curEP.SortDownButton:SetSize(10, 10)
    EPGPUserFrame.Header.curGP.SortDownButton:SetSize(10, 10)
    EPGPUserFrame.Header.curPR.SortDownButton:SetSize(10, 10)

    EPGPUserFrame.Header.Name .SortUpButton:SetPoint("LEFT", 4, 5)
    EPGPUserFrame.Header.Class.SortUpButton:SetPoint("LEFT", 4, 5)
    EPGPUserFrame.Header.curEP.SortUpButton:SetPoint("LEFT", 4, 5)
    EPGPUserFrame.Header.curGP.SortUpButton:SetPoint("LEFT", 4, 5)
    EPGPUserFrame.Header.curPR.SortUpButton:SetPoint("LEFT", 4, 5)

    EPGPUserFrame.Header.Name .SortDownButton:SetPoint("LEFT", 4, -3)
    EPGPUserFrame.Header.Class.SortDownButton:SetPoint("LEFT", 4, -3)
    EPGPUserFrame.Header.curEP.SortDownButton:SetPoint("LEFT", 4, -3)
    EPGPUserFrame.Header.curGP.SortDownButton:SetPoint("LEFT", 4, -3)
    EPGPUserFrame.Header.curPR.SortDownButton:SetPoint("LEFT", 4, -3)

    EPGPUserFrame.Header.Name .SortUpButton  .Texture = EPGPUserFrame.Header.Name .SortUpButton  :CreateTexture(nil, nil)
    EPGPUserFrame.Header.Class.SortUpButton  .Texture = EPGPUserFrame.Header.Class.SortUpButton  :CreateTexture(nil, nil)
    EPGPUserFrame.Header.curEP.SortUpButton  .Texture = EPGPUserFrame.Header.curEP.SortUpButton  :CreateTexture(nil, nil)
    EPGPUserFrame.Header.curGP.SortUpButton  .Texture = EPGPUserFrame.Header.curGP.SortUpButton  :CreateTexture(nil, nil)
    EPGPUserFrame.Header.curPR.SortUpButton  .Texture = EPGPUserFrame.Header.curPR.SortUpButton  :CreateTexture(nil, nil)
    EPGPUserFrame.Header.Name .SortDownButton.Texture = EPGPUserFrame.Header.Name .SortDownButton:CreateTexture(nil, nil)
    EPGPUserFrame.Header.Class.SortDownButton.Texture = EPGPUserFrame.Header.Class.SortDownButton:CreateTexture(nil, nil)
    EPGPUserFrame.Header.curEP.SortDownButton.Texture = EPGPUserFrame.Header.curEP.SortDownButton:CreateTexture(nil, nil)
    EPGPUserFrame.Header.curGP.SortDownButton.Texture = EPGPUserFrame.Header.curGP.SortDownButton:CreateTexture(nil, nil)
    EPGPUserFrame.Header.curPR.SortDownButton.Texture = EPGPUserFrame.Header.curPR.SortDownButton:CreateTexture(nil, nil)

    EPGPUserFrame.Header.Name .SortUpButton  .Texture:SetTexture("Interface/Buttons/UI-Panel-CollapseButton-Up")
    EPGPUserFrame.Header.Class.SortUpButton  .Texture:SetTexture("Interface/Buttons/UI-Panel-CollapseButton-Up")
    EPGPUserFrame.Header.curEP.SortUpButton  .Texture:SetTexture("Interface/Buttons/UI-Panel-CollapseButton-Up")
    EPGPUserFrame.Header.curGP.SortUpButton  .Texture:SetTexture("Interface/Buttons/UI-Panel-CollapseButton-Up")
    EPGPUserFrame.Header.curPR.SortUpButton  .Texture:SetTexture("Interface/Buttons/UI-Panel-CollapseButton-Up")
    EPGPUserFrame.Header.Name .SortDownButton.Texture:SetTexture("Interface/Buttons/UI-Panel-ExpandButton-Up")
    EPGPUserFrame.Header.Class.SortDownButton.Texture:SetTexture("Interface/Buttons/UI-Panel-ExpandButton-Up")
    EPGPUserFrame.Header.curEP.SortDownButton.Texture:SetTexture("Interface/Buttons/UI-Panel-ExpandButton-Up")
    EPGPUserFrame.Header.curGP.SortDownButton.Texture:SetTexture("Interface/Buttons/UI-Panel-ExpandButton-Up")
    EPGPUserFrame.Header.curPR.SortDownButton.Texture:SetTexture("Interface/Buttons/UI-Panel-ExpandButton-Up")

    EPGPUserFrame.Header.Name .SortUpButton  .Texture:SetSize(16, 16)
    EPGPUserFrame.Header.Class.SortUpButton  .Texture:SetSize(16, 16)
    EPGPUserFrame.Header.curEP.SortUpButton  .Texture:SetSize(16, 16)
    EPGPUserFrame.Header.curGP.SortUpButton  .Texture:SetSize(16, 16)
    EPGPUserFrame.Header.curPR.SortUpButton  .Texture:SetSize(16, 16)
    EPGPUserFrame.Header.Name .SortDownButton.Texture:SetSize(16, 16)
    EPGPUserFrame.Header.Class.SortDownButton.Texture:SetSize(16, 16)
    EPGPUserFrame.Header.curEP.SortDownButton.Texture:SetSize(16, 16)
    EPGPUserFrame.Header.curGP.SortDownButton.Texture:SetSize(16, 16)
    EPGPUserFrame.Header.curPR.SortDownButton.Texture:SetSize(16, 16)

    EPGPUserFrame.Header.Name .SortUpButton  .Texture:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.Header.Class.SortUpButton  .Texture:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.Header.curEP.SortUpButton  .Texture:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.Header.curGP.SortUpButton  .Texture:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.Header.curPR.SortUpButton  .Texture:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.Header.Name .SortDownButton.Texture:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.Header.Class.SortDownButton.Texture:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.Header.curEP.SortDownButton.Texture:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.Header.curGP.SortDownButton.Texture:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.Header.curPR.SortDownButton.Texture:SetPoint("CENTER", 0, 0)

    EPGPUserFrame.Header.Name .SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "Name"  TBCEPGP:FilterPlayers() end)
    EPGPUserFrame.Header.Class.SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "Class" TBCEPGP:FilterPlayers() end)
    EPGPUserFrame.Header.curEP.SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "EP"    TBCEPGP:FilterPlayers() end)
    EPGPUserFrame.Header.curGP.SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "GP"    TBCEPGP:FilterPlayers() end)
    EPGPUserFrame.Header.curPR.SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "PR"    TBCEPGP:FilterPlayers() end)

    EPGPUserFrame.Header.Name .SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "Name"  TBCEPGP:FilterPlayers() end)
    EPGPUserFrame.Header.Class.SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "Class" TBCEPGP:FilterPlayers() end)
    EPGPUserFrame.Header.curEP.SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "EP"    TBCEPGP:FilterPlayers() end)
    EPGPUserFrame.Header.curGP.SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "GP"    TBCEPGP:FilterPlayers() end)
    EPGPUserFrame.Header.curPR.SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "PR"    TBCEPGP:FilterPlayers() end)

    EPGPUserFrame.PurgeButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelButtonTemplate")
    EPGPUserFrame.PurgeButton:SetSize(75, 20)
    EPGPUserFrame.PurgeButton:SetPoint("BOTTOMLEFT", EPGPUserFrame, "BOTTOMLEFT", 10, 15)
    EPGPUserFrame.PurgeButton:SetFrameStrata("HIGH")
    EPGPUserFrame.PurgeButton:SetScript("OnClick",
    function()
        PurgeConfirmWindow:Show()
    end)
    EPGPUserFrame.PurgeButton.text = EPGPUserFrame.PurgeButton:CreateFontString("PurgeButton", "ARTWORK", "GameFontNormalTiny")
    EPGPUserFrame.PurgeButton.text:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.PurgeButton.text:SetText("Purge")

    EPGPUserFrame.OptionsButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelButtonTemplate")
    EPGPUserFrame.OptionsButton:SetSize(75, 20)
    EPGPUserFrame.OptionsButton:SetPoint("BOTTOMRIGHT", EPGPUserFrame, "BOTTOMRIGHT", -10, 15)
    EPGPUserFrame.OptionsButton:SetFrameStrata("HIGH")
    EPGPUserFrame.OptionsButton:SetScript("OnClick",
    function()
        InterfaceOptionsFrame_OpenToCategory("TBC-EPGP")
        InterfaceOptionsFrame_OpenToCategory("TBC-EPGP")
    end)
    EPGPUserFrame.OptionsButton.text = EPGPUserFrame.OptionsButton:CreateFontString("OptionsButton", "ARTWORK", "GameFontNormalTiny")
    EPGPUserFrame.OptionsButton.text:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.OptionsButton.text:SetText("Options")

    local EPGPUserFrameCloseButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelCloseButton, BackDropTemplate")
    EPGPUserFrameCloseButton:SetSize(24, 24)
    EPGPUserFrameCloseButton:SetPoint("TOPRIGHT", EPGPUserFrame, "TOPRIGHT", -3, -3)
    EPGPUserFrameCloseButton:SetScript("OnClick", function() EPGPUserFrame:Hide() end)

    local players = TBCEPGP.DataTable.Players
    TBCEPGP:FillUserFrameScrollPanel(players)
    scrollFrame:SetScrollChild(UserScrollPanel)

    EPGPUserFrame:Hide()
end

function TBCEPGP:UpdateLogs()
    local Index = 1
    for key, value in pairs(EPGPChangeLog) do
        local curLogFrame = ChangeLogsFrames[Index]
        if curLogFrame == nil then
            curLogFrame = CreateFrame("Frame", nil, ChangeLogScrollPanel, "BackdropTemplate")
            ChangeLogsFrames[Index] = curLogFrame
            curLogFrame:SetSize(ChangeLogScrollPanel:GetWidth() - 4, 25)
            curLogFrame:EnableMouse(true)
            curLogFrame:SetBackdrop({
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                edgeSize = 8,
                insets = {left = 2, right = 2, top = 2, bottom = 2},
            })
            curLogFrame:SetBackdropColor(0.25, 0.25, 0.25, 1)
            curLogFrame:SetPoint("TOPLEFT", ChangeLogScrollPanel, "TOPLEFT", 5, -24 * Index + 25)

            curLogFrame.Name = curLogFrame:CreateFontString("curLogFrame", "ARTWORK", "GameFontNormal")
            curLogFrame.Name:SetSize(EPGPChangeLogFrame.Header.Name:GetWidth(), 25)
            curLogFrame.Name:SetPoint("LEFT", 0, 0)
            curLogFrame.Name:SetTextColor(1, 1, 1, 1)
            curLogFrame.Name:SetText(value.Name)

            curLogFrame.Points = curLogFrame:CreateFontString("curLogFrame", "ARTWORK", "GameFontNormal")
            curLogFrame.Points:SetSize(EPGPChangeLogFrame.Header.Points:GetWidth(), 25)
            curLogFrame.Points:SetPoint("LEFT", curLogFrame.Name, "RIGHT", -4, 0)
            curLogFrame.Points:SetTextColor(1, 1, 1, 1)
            curLogFrame.Points:SetText(value.Change)

            curLogFrame.Amount = curLogFrame:CreateFontString("curLogFrame", "ARTWORK", "GameFontNormal")
            curLogFrame.Amount:SetSize(EPGPChangeLogFrame.Header.Amount:GetWidth(), 25)
            curLogFrame.Amount:SetPoint("LEFT", curLogFrame.Points, "RIGHT", -4, 0)
            curLogFrame.Amount:SetTextColor(1, 1, 1, 1)
            curLogFrame.Amount:SetText(string.format("%+.3f", value.Amount))

            curLogFrame.DateTime = curLogFrame:CreateFontString("curLogFrame", "ARTWORK", "GameFontNormal")
            curLogFrame.DateTime:SetSize(EPGPChangeLogFrame.Header.DateTime:GetWidth(), 25)
            curLogFrame.DateTime:SetPoint("LEFT", curLogFrame.Amount, "RIGHT", -4, 0)
            curLogFrame.DateTime:SetTextColor(1, 1, 1, 1)
            curLogFrame.DateTime:SetText(value.Date)

            curLogFrame.Admin = curLogFrame:CreateFontString("curLogFrame", "ARTWORK", "GameFontNormal")
            curLogFrame.Admin:SetSize(EPGPChangeLogFrame.Header.Admin:GetWidth(), 25)
            curLogFrame.Admin:SetPoint("LEFT", curLogFrame.DateTime, "RIGHT", -4, 0)
            curLogFrame.Admin:SetTextColor(1, 1, 1, 1)
            curLogFrame.Admin:SetText(value.Admin)

            curLogFrame.Reason = curLogFrame:CreateFontString("curLogFrame", "ARTWORK", "GameFontNormal")
            curLogFrame.Reason:SetSize(EPGPChangeLogFrame.Header.Reason:GetWidth(), 25)
            curLogFrame.Reason:SetPoint("LEFT", curLogFrame.Admin, "RIGHT", -4, 0)
            curLogFrame.Reason:SetTextColor(1, 1, 1, 1)
            --curLogFrame.Reason:SetText(value.Reason)
            curLogFrame.Reason:SetText("Not Yet Implemented!")

            curLogFrame:Show()
        end

        Index = Index + 1
    end
end

function TBCEPGP:DecayDataTable()
    local players = TBCEPGP.DataTable.Players
    for key, value in pairs(players) do
        value.EP = TBCEPGP:MathRound(value.EP * 1000 * 0.85) / 1000
        if value.EP < 1 then value.EP = 1 end
        value.GP = TBCEPGP:MathRound(value.GP * 1000 * 0.85) / 1000
        if value.GP < 1 then value.GP = 1 end
        value.PR = TBCEPGP:CalculatePriority(key, value.EP, value.GP)
    end
    TBCEPGP:FilterPlayers()
end

function TBCEPGP:PurgeDataTable()
    TBCEPGPDataTable.Players = {}
    TBCEPGP:FilterPlayers()
end

function TBCEPGP:MassChange(Points)
    local PointsChange = tonumber(EPGPAdminFrame.Header["cur" .. Points]["change" .. Points]:GetText())
    if PointsChange ~= nil and PointsChange ~= 0 then
        local players = TBCEPGPDataTable.Players
        if filteredPlayers == nil then filteredPlayers = players end
        for key, _ in pairs(filteredPlayers) do
            TBCEPGP:ChangePoints(key, Points, PointsChange)
        end
        EPGPAdminFrame.Header["cur" .. Points]["change" .. Points]:SetText(0)
        TBCEPGP:FillUserFrameScrollPanel(filteredPlayers)
        TBCEPGP:FillAdminFrameScrollPanel(filteredPlayers)
    end
end

function TBCEPGP:ChangePoints(curGUID, Points, Amount)
    Amount = TBCEPGP:MathRound(Amount * 1000) / 1000
    local curPlayer = TBCEPGPDataTable.Players[curGUID]
    curPlayer[Points] = curPlayer[Points] + Amount
    curPlayer.Update = time()
    if curGUID == nil or curPlayer.Update == nil then
        local tempNumber = #TBCEPGPVersionData.ErrorInfo + 1
        local y, m, d = TBCEPGP:GetDateTime()
        TBCEPGPVersionData.ErrorInfo[tempNumber] = {Time = time(), Date = string.format("%s/%s/%s", d, m, y), GUID = UnitGUID("Player"), Name = UnitName("Player"), Version = TBCEPGP.Version}
    end
    EPGPChangeLog[string.format("%s-%d", curGUID, curPlayer.Update)] = {Name = curPlayer.Name, Date = date("%m/%d/%y - %H:%M:%S"), Change = Points, Amount = Amount, Admin = UnitName("Player")}
    TBCEPGP:CalculatePriority(curGUID, curPlayer.EP, curPlayer.GP)
end

function TBCEPGP:FilterPlayers()
    filteredPlayers = {}
    local players = TBCEPGPDataTable.Players
    local raidGUIDs = TBCEPGP:CollectPlayersInRaid()

    for key, value in pairs(players) do
        for i = 1, 11 do
            if i == 6 or i == 10 then   -- Parsing out Monk(6) and DeathKnight(10) index numbers. (DH == 12)
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

    if FilterRaid == true then
        local raidPlayers = {}
        for _, GUID in ipairs(raidGUIDs) do
            if filteredPlayers[GUID] ~= nil then
                raidPlayers[GUID] = filteredPlayers[GUID]
            end
        end

        filteredPlayers = raidPlayers
    end

    TBCEPGP:FillUserFrameScrollPanel(filteredPlayers)
    TBCEPGP:FillAdminFrameScrollPanel(filteredPlayers)
end

function TBCEPGP:FillAdminFrameScrollPanel(inputPlayers)
    local players = inputPlayers
    local filteredPlayerFrames = {}
    local index = 1

    if inputPlayers == nil then players = TBCEPGP.DataTable.Players end

    for _, value in pairs(adminPlayerFrames) do
        value:Hide()
    end

    for key, value in pairs(players) do
        local curPlayerFrame = adminPlayerFrames[index]
        if curPlayerFrame == nil then
            curPlayerFrame = CreateFrame("Frame", nil, AdminScrollPanel, "BackdropTemplate")
            adminPlayerFrames[index] = curPlayerFrame
            curPlayerFrame:SetSize(AdminScrollPanel:GetWidth() - 4, 25)
            curPlayerFrame:EnableMouse(true)
            curPlayerFrame:SetBackdrop({
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                edgeSize = 8,
                insets = {left = 2, right = 2, top = 2, bottom = 2},
            })
            curPlayerFrame:SetBackdropColor(0.25, 0.25, 0.25, 1)

            curPlayerFrame.Number = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.Number:SetSize(EPGPAdminFrame.Header.Number:GetWidth(), 25)
            curPlayerFrame.Number:SetPoint("LEFT", 0, 0)
            curPlayerFrame.Number:SetTextColor(1, 1, 1, 1)

            curPlayerFrame.Name = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.Name:SetSize(EPGPAdminFrame.Header.Name:GetWidth(), 25)
            curPlayerFrame.Name:SetPoint("LEFT", curPlayerFrame.Number, "RIGHT", -4, 0)
            curPlayerFrame.Name:SetTextColor(1, 1, 1, 1)

            curPlayerFrame.Class = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.Class:SetSize(EPGPAdminFrame.Header.Class:GetWidth(), 25)
            curPlayerFrame.Class:SetPoint("LEFT", curPlayerFrame.Name, "RIGHT", -4, 0)
            curPlayerFrame.Class:SetTextColor(1, 1, 1, 1)

            curPlayerFrame.curEP = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.curEP:SetSize(EPGPAdminFrame.Header.curEP:GetWidth(), 25)
            curPlayerFrame.curEP:SetPoint("LEFT", curPlayerFrame.Class, "RIGHT", -29, 0)
            curPlayerFrame.curEP:SetTextColor(1, 1, 1, 1)

            curPlayerFrame.changeEP = CreateFrame("EditBox", nil, curPlayerFrame, "InputBoxTemplate")
            curPlayerFrame.changeEP:SetSize(50, 25)
            curPlayerFrame.changeEP:SetPoint("LEFT", curPlayerFrame.curEP, "RIGHT", -50, 0)
            curPlayerFrame.changeEP:SetAutoFocus(false)
            curPlayerFrame.changeEP:SetFrameStrata("HIGH")
            curPlayerFrame.changeEP:SetText(0)

            curPlayerFrame.curGP = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.curGP:SetSize(EPGPAdminFrame.Header.curGP:GetWidth(), 25)
            curPlayerFrame.curGP:SetPoint("LEFT", curPlayerFrame.curEP, "RIGHT", -4, 0)
            curPlayerFrame.curGP:SetTextColor(1, 1, 1, 1)

            curPlayerFrame.changeGP = CreateFrame("EditBox", nil, curPlayerFrame, "InputBoxTemplate")
            curPlayerFrame.changeGP:SetSize(50, 25)
            curPlayerFrame.changeGP:SetPoint("LEFT", curPlayerFrame.curGP, "RIGHT", -50, 0)
            curPlayerFrame.changeGP:SetAutoFocus(false)
            curPlayerFrame.changeGP:SetFrameStrata("HIGH")
            curPlayerFrame.changeGP:SetText(0)

            curPlayerFrame.curPR = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.curPR:SetSize(EPGPAdminFrame.Header.curPR:GetWidth() + 50, 25)
            curPlayerFrame.curPR:SetPoint("LEFT", curPlayerFrame.curGP, "RIGHT", -4, 0)
            curPlayerFrame.curPR:SetTextColor(1, 1, 1, 1)

            curPlayerFrame.delButton = CreateFrame("Button", nil, curPlayerFrame, "UIPanelCloseButton")
            curPlayerFrame.delButton:SetSize(20, 20)
            curPlayerFrame.delButton:SetPoint("RIGHT", curPlayerFrame.curPR, "RIGHT", -12, 0)

            curPlayerFrame.changeEP:HookScript("OnEditFocusLost",
            function()
                local PointsChange = tonumber(curPlayerFrame.changeEP:GetText())

                TBCEPGP:ChangePoints(curPlayerFrame.key, "EP", PointsChange)

                curPlayerFrame.curEP:SetText(players[curPlayerFrame.key].EP)
                curPlayerFrame.changeEP:SetText(0)

                local curPR = TBCEPGP:CalculatePriority(curPlayerFrame.key, players[curPlayerFrame.key].EP, players[curPlayerFrame.key].GP)
                curPlayerFrame.curPR:SetText(curPR)
            end)

            curPlayerFrame.changeGP:HookScript("OnEditFocusLost",
            function()
                local PointsChange = tonumber(curPlayerFrame.changeGP:GetText())

                TBCEPGP:ChangePoints(curPlayerFrame.key, "GP", PointsChange)

                curPlayerFrame.curGP:SetText(players[curPlayerFrame.key].GP)
                curPlayerFrame.changeGP:SetText(0)

                local curPR = TBCEPGP:CalculatePriority(curPlayerFrame.key, players[curPlayerFrame.key].EP, players[curPlayerFrame.key].GP)
                curPlayerFrame.curPR:SetText(curPR)
            end)
        end

        curPlayerFrame.delButton:SetScript("OnClick", function()
            TBCEPGPDataTable.Players[key] = nil
            TBCEPGP:FilterPlayers()
        end)

        if EPGPAdminFrame.EPLocked == true then
            curPlayerFrame.changeEP:Hide()
        elseif EPGPAdminFrame.EPLocked == false then
            curPlayerFrame.changeEP:Show()
        end

        if EPGPAdminFrame.GPLocked == true then
            curPlayerFrame.changeGP:Hide()
        elseif EPGPAdminFrame.GPLocked == false then
            curPlayerFrame.changeGP:Show()
        end

        filteredPlayerFrames[index] = curPlayerFrame

        local curName, curClass, curEP, curGP, curPR = nil, nil, nil, nil, nil
        curPlayerFrame.key = key

        curName = value.Name
        curClass = value.Class
        curEP = value.EP
        curGP = value.GP
        curPR = TBCEPGP:CalculatePriority(key, value.EP, value.GP)

        curPlayerFrame:Show()

        local curClassColor = "|c" .. classInfo[curClass].ClassColor
        local curClassName = classInfo[curClass].ClassName

        curPlayerFrame.Name:SetText(curClassColor .. curName .. "|r")
        curPlayerFrame.Class:SetText(curClassColor .. curClassName .. "|r")
        curPlayerFrame.curEP:SetText(curEP)
        curPlayerFrame.curGP:SetText(curGP)
        curPlayerFrame.curPR:SetText(curPR)
        curPlayerFrame.Number:SetText(index)

        index = index + 1
    end

    if sortCol ~= nil then
        table.sort(filteredPlayerFrames, function(a, b)
            return TBCEPGP:ComparePlayers(players, a, b)
        end)
    end

    for i, frame in ipairs(filteredPlayerFrames) do
        frame:SetPoint("TOPLEFT", AdminScrollPanel, "TOPLEFT", 5, -24 * i + 25)
    end
end

function TBCEPGP:FillUserFrameScrollPanel(inputPlayers)
    local players = inputPlayers
    local filteredPlayerFrames = {}
    local index = 1

    if inputPlayers == nil then players = TBCEPGP.DataTable.Players end

    for _, value in pairs(userPlayerFrames) do
        value:Hide()
    end

    for key, value in pairs(players) do
        local curPlayerFrame = userPlayerFrames[index]
        if curPlayerFrame == nil then
            curPlayerFrame = CreateFrame("Frame", nil, UserScrollPanel, "BackdropTemplate")
            userPlayerFrames[index] = curPlayerFrame
            curPlayerFrame:SetSize(UserScrollPanel:GetWidth() - 4, 25)
            curPlayerFrame:EnableMouse(true)
            curPlayerFrame:SetBackdrop({
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                edgeSize = 8,
                insets = {left = 2, right = 2, top = 2, bottom = 2},
            })
            curPlayerFrame:SetBackdropColor(0.25, 0.25, 0.25, 1)

            curPlayerFrame.Number = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.Number:SetSize(EPGPUserFrame.Header.Number:GetWidth(), 25)
            curPlayerFrame.Number:SetPoint("LEFT", 0, 0)
            curPlayerFrame.Number:SetTextColor(1, 1, 1, 1)

            curPlayerFrame.Name = curPlayerFrame:CreateFontString("curPlayerFrame", "ARTWORK", "GameFontNormal")
            curPlayerFrame.Name:SetSize(EPGPUserFrame.Header.Name:GetWidth(), 25)
            curPlayerFrame.Name:SetPoint("LEFT", curPlayerFrame.Number, "RIGHT", -4, 0)
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
        curPR = TBCEPGP:CalculatePriority(key, value.EP, value.GP)

        curPlayerFrame:Show()

        local curClassColor = "|c" .. classInfo[curClass].ClassColor
        local curClassName = classInfo[curClass].ClassName

        curPlayerFrame.Name:SetText(curClassColor .. curName .. "|r")
        curPlayerFrame.Class:SetText(curClassColor .. curClassName .. "|r")
        curPlayerFrame.curEP:SetText(curEP)
        curPlayerFrame.curGP:SetText(curGP)
        curPlayerFrame.curPR:SetText(curPR)
        curPlayerFrame.Number:SetText(index)

        index = index + 1
    end

    if sortCol ~= nil then
        table.sort(filteredPlayerFrames, function(a, b)
            return TBCEPGP:ComparePlayers(players, a, b)
        end)
    end

    for i, frame in ipairs(filteredPlayerFrames) do
        frame:SetPoint("TOPLEFT", UserScrollPanel, "TOPLEFT", 5, -24 * i + 25)
    end
end

function TBCEPGP:ComparePlayers(sortTable, a, b)
    local aSort = sortTable[a.key][sortCol]
    local bSort = sortTable[b.key][sortCol]

    if sortDir == "Asc" then
        return (aSort < bSort)
    elseif sortDir == "Dsc" then
        return (aSort > bSort)
    end
end

function TBCEPGP:CalculatePriority(curGUID, curEP, curGP)
    curEP = curEP + TBCEPGPPRCalc[1]
    curGP = curGP + TBCEPGPPRCalc[2]
    local curPR = nil
    if curEP == 0 or curGP == 0 then curPR = 0 else curPR = TBCEPGP:MathRound(curEP/curGP * 1000) / 1000 end
    TBCEPGP.DataTable.Players[curGUID].PR = curPR
    return curPR
end

function TBCEPGP.Events:LootOpened()
    local lootmethod, _, MLRaidIndex = GetLootMethod()

    if lootmethod == "master" and MLRaidIndex == UnitInRaid("player") then
        for i = 1, GetNumLootItems() do
            local _, lootName, lootQuantity, _, lootQuality, _, isQuestItem, _, isActive = GetLootSlotInfo(i)
            if lootName ~= nil and isQuestItem == false and isActive == nil and lootQuality >= 1 then
                local itemLink = GetLootSlotLink(i)
                TBCEPGP:LootItemAddOnMsg(itemLink)
            end
        end
    end
end

function TBCEPGP:AddItemToLootList(itemName, itemTexture, GPValue, itemLink)
    EPGPLootFrame:Show()
    local ItemAlreadyInList = false
    for i = 1, #EPGPActiveLootItems do
        if EPGPActiveLootItems[i].name == itemName then ItemAlreadyInList = true break end
    end
    if ItemAlreadyInList == false then
        EPGPActiveLootItems[#EPGPActiveLootItems + 1] =
        {
            name = itemName,
            link = itemLink,
            texture = itemTexture,
            cost = GPValue,
            players = {Need = {}, Greed = {},},
        }
    end
    TBCEPGP:FillLootFrameScrollPanel()
end

function TBCEPGP:AddPlayerToItem(Roll, Index, GUID)
    local curPlayer = TBCEPGPDataTable.Players[GUID]
    local PR = curPlayer.PR
    local Name = curPlayer.Name
    local players = EPGPActiveLootItems[Index].players[Roll]
    local NameAlreadyInList = false
    for i = 1, #players do
        if players[i].curName == Name then NameAlreadyInList = true end
    end
    if NameAlreadyInList == false then
        players[#players + 1] = {curName = Name, curPR = PR}
        table.sort(players, function(a, b) return a.curPR > b.curPR end)
        EPGPActiveLootItems[Index].players[Roll] = players
        if #players ~= 0 then
            local PlayerString = ""
            for j = 1, #players do
                PlayerString = PlayerString .. players[j].curName .. " - " .. players[j].curPR .. "\n"
            end
            LootItemFrames[Index][Roll]:SetText(PlayerString)
        end
        TBCEPGP:LootItemFrameResize(Index)
    end
end

function TBCEPGP:FillLootFrameScrollPanel()
    for i = 1, #EPGPActiveLootItems do
        local curItemFrame = LootItemFrames[i]
        if curItemFrame == nil then
            curItemFrame = CreateFrame("Frame", nil, LootScrollPanel, "BackdropTemplate")
            curItemFrame:EnableMouse(true)
            curItemFrame:SetBackdrop({
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                edgeSize = 8,
                insets = {left = 2, right = 2, top = 2, bottom = 2},
            })
            curItemFrame:SetBackdropColor(0.25, 0.25, 0.25, 1)
            if i == 1 then
                curItemFrame:SetPoint("TOPLEFT", LootScrollPanel, "TOPLEFT", 5, 0)
            elseif i > 1 then
                curItemFrame:SetPoint("TOP", LootItemFrames[i-1], "BOTTOM", 0, 0)
            end

            curItemFrame.Icon = CreateFrame("FRAME", nil, curItemFrame, "BackdropTemplate")
            curItemFrame.Icon:SetSize(EPGPLootFrame.Header.Icon:GetWidth() - 4, 30)
            curItemFrame.Icon:SetPoint("TOPLEFT", 2, -2)
            curItemFrame.Icon:SetBackdrop({bgFile = EPGPActiveLootItems[i].texture,})
            curItemFrame.Icon:SetBackdropColor(1, 1, 1, 1)

            curItemFrame.Name = curItemFrame:CreateFontString("curPlayercurItemFrameFrame", "ARTWORK", "GameFontNormal")
            curItemFrame.Name:SetSize(EPGPLootFrame.Header.Name:GetWidth(), 20)
            curItemFrame.Name:SetPoint("TOPLEFT", curItemFrame.Icon, "TOPRIGHT", -4, -2)
            curItemFrame.Name:SetTextColor(1, 1, 1, 1)
            curItemFrame.Name:SetText(EPGPActiveLootItems[i].link)

            curItemFrame.curGP = curItemFrame:CreateFontString("curItemFrame", "ARTWORK", "GameFontNormal")
            curItemFrame.curGP:SetSize(EPGPLootFrame.Header.curGP:GetWidth(), 20)
            curItemFrame.curGP:SetPoint("TOPLEFT", curItemFrame.Name, "TOPRIGHT", -4, 0)
            curItemFrame.curGP:SetTextColor(1, 1, 1, 1)
            curItemFrame.curGP:SetText(EPGPActiveLootItems[i].cost)

            curItemFrame.Need = curItemFrame:CreateFontString("curItemFrame", "ARTWORK", "GameFontNormal")
            curItemFrame.Need:SetPoint("TOPLEFT", curItemFrame.curGP, "TOPRIGHT", -4, 0)
            curItemFrame.Need:SetTextColor(1, 1, 1, 1)
            local NeedPlayers = ""
            for j = 1, #EPGPActiveLootItems[i].players.Need do
                NeedPlayers = NeedPlayers .. EPGPActiveLootItems[i].players.Need[j] .. "\n"
            end
            curItemFrame.Need:SetText(NeedPlayers)
            curItemFrame.Need:SetJustifyV("TOP")

            curItemFrame.Greed = curItemFrame:CreateFontString("curItemFrame", "ARTWORK", "GameFontNormal")
            curItemFrame.Greed:SetPoint("TOPLEFT", curItemFrame.Need, "TOPRIGHT", -4, 0)
            curItemFrame.Greed:SetTextColor(1, 1, 1, 1)
            local GreedPlayers = ""
            for j = 1, #EPGPActiveLootItems[i].players.Greed do
                GreedPlayers = GreedPlayers .. EPGPActiveLootItems[i].players.Greed[j] .. "\n"
            end
            curItemFrame.Greed:SetText(GreedPlayers)
            curItemFrame.Greed:SetJustifyV("TOP")

            curItemFrame.needButton = CreateFrame("BUTTON", nil, curItemFrame, "UIPanelButtonTemplate")
            curItemFrame.needButton:SetSize(EPGPLootFrame.Header.buttons:GetWidth() / 2 - 10, 20)
            curItemFrame.needButton:SetPoint("TOPLEFT", curItemFrame.Greed, "TOPRIGHT", 5, 0)
            curItemFrame.needButton:SetScript("OnClick", function() TBCEPGP:LootRollAddOnMsg("Need", i) end)
            curItemFrame.needButton.text = curItemFrame.needButton:CreateFontString("curItemFrame", "ARTWORK", "GameFontNormal")
            curItemFrame.needButton.text:SetText("Need Item")
            curItemFrame.needButton.text:SetPoint("CENTER", 0, 0)

            curItemFrame.greedButton = CreateFrame("BUTTON", nil, curItemFrame, "UIPanelButtonTemplate")
            curItemFrame.greedButton:SetSize(EPGPLootFrame.Header.buttons:GetWidth() / 2 - 10, 20)
            curItemFrame.greedButton:SetPoint("TOPLEFT", curItemFrame.needButton, "TOPRIGHT", 5, 0)
            curItemFrame.greedButton:SetScript("OnClick", function() TBCEPGP:LootRollAddOnMsg("Greed", i) end)
            curItemFrame.greedButton.text = curItemFrame.greedButton:CreateFontString("curItemFrame", "ARTWORK", "GameFontNormal")
            curItemFrame.greedButton.text:SetText("Greed Item")
            curItemFrame.greedButton.text:SetPoint("CENTER", 0, 0)

            local curBFont, curBSize, curBFlags = curItemFrame.needButton.text:GetFont()
            curItemFrame.needButton .text:SetFont(curBFont, curBSize - 2, curBFlags)
            curItemFrame.greedButton.text:SetFont(curBFont, curBSize - 2, curBFlags)

            curItemFrame:Show()

            local curLFont, curLSize, curLFlags = EPGPLootFrame.Header.Name.Text:GetFont()
            curItemFrame.Name :SetFont(curLFont, curLSize, curLFlags)
            curItemFrame.curGP:SetFont(curLFont, curLSize, curLFlags)
            curItemFrame.Need :SetFont(curLFont, curLSize, curLFlags)
            curItemFrame.Greed:SetFont(curLFont, curLSize, curLFlags)

            LootItemFrames[i] = curItemFrame
            TBCEPGP:LootItemFrameResize(i)
        end
    end
end

function TBCEPGP:LootRollAddOnMsg(Roll, Index)
    local prefix = "TBCEPGPRoll"
    local curGUID = UnitGUID("PLAYER")
    local message = "Roll:" .. Roll .. ":" .. Index .. ":" .. curGUID .. ":"
    C_ChatInfo.SendAddonMessage(prefix, message , "RAID", 1)
end

function TBCEPGP:LootItemAddOnMsg(itemName)
    local itemStuff = TBCEPGP:CheckItemInfo(itemName)
    local GPValue = TBCEPGP:CalculateTotalPrice(itemStuff.itemQuality, itemStuff.itemEquipLoc, itemStuff.itemLevel)

    if itemEquipLoc ~= nil and TBCEPGP.InfoTable.Slot[itemEquipLoc] ~= nil then
        local prefix = "TBCEPGPItem"
        --local message = "Item:" .. itemName .. ":" .. itemTexture .. ":" .. GPValue .. ":" .. itemLink .. ":"
        local message = "Item:" .. itemStuff.itemName .. ":" .. itemStuff.itemTexture .. ":" .. GPValue .. ":" .. itemStuff.itemLink .. ":"
        C_ChatInfo.SendAddonMessage(prefix, message , "RAID", 1)
    end
end

function TBCEPGP:LootItemFrameResize(Index)
    local curIFrameHeight = #EPGPActiveLootItems[Index].players.Need
    if #EPGPActiveLootItems[Index].players.Greed >= curIFrameHeight then curIFrameHeight = #EPGPActiveLootItems[Index].players.Greed end
    if curIFrameHeight >= 3 then curIFrameHeight = curIFrameHeight * 10 + 5 else curIFrameHeight = 32 end
    LootItemFrames[Index]:SetSize(LootScrollPanel:GetWidth() - 4, curIFrameHeight)
    LootItemFrames[Index].Need:SetSize(EPGPLootFrame.Header.playersNeed:GetWidth(), LootItemFrames[Index]:GetHeight())
    LootItemFrames[Index].Greed:SetSize(EPGPLootFrame.Header.playersGreed:GetWidth(), LootItemFrames[Index]:GetHeight())
end

TBCEPGP:OnLoad()

TBCEPGP.SlashCommands["roll"] = function(value)
    TBCEPGP:RollItem(value)
end

TBCEPGP.SlashCommands["sync"] = function(value)
    TBCEPGP:SyncRaidersAddOnMsg()
end

TBCEPGP.SlashCommands["add"] = function(value)
    local curGUID = UnitGUID("Target")
    local curName = UnitName("Target")
    local _, _, curClass = UnitClass("Target")
    TBCEPGP:AddPlayerToList(curGUID, curName, curClass)
end

TBCEPGP.SlashCommands["show"] = function(value)
    if TBCEPGPShowAdminView == true then
        EPGPAdminFrame:Show()
    elseif TBCEPGPShowAdminView == false then
        EPGPUserFrame:Show()
    end
end

TBCEPGP.SlashCommands["loot"] = function(value)
    EPGPLootFrame:Show()
end

TBCEPGP.SlashCommands["recalc"] = function(value)
    TBCEPGP:ForceRecalculate()
end

TBCEPGP.SlashCommands["Roll"] = TBCEPGP.SlashCommands["roll"]
TBCEPGP.SlashCommands["ROLL"] = TBCEPGP.SlashCommands["roll"]

TBCEPGP.SlashCommands["Sync"] = TBCEPGP.SlashCommands["sync"]
TBCEPGP.SlashCommands["SYNC"] = TBCEPGP.SlashCommands["sync"]

TBCEPGP.SlashCommands["Add"] = TBCEPGP.SlashCommands["add"]
TBCEPGP.SlashCommands["ADD"] = TBCEPGP.SlashCommands["add"]

TBCEPGP.SlashCommands["Show"] = TBCEPGP.SlashCommands["show"]
TBCEPGP.SlashCommands["SHOW"] = TBCEPGP.SlashCommands["show"]

TBCEPGP.SlashCommands["Loot"] = TBCEPGP.SlashCommands["loot"]
TBCEPGP.SlashCommands["LOOT"] = TBCEPGP.SlashCommands["loot"]

TBCEPGP.SlashCommands["ReCalc"] = TBCEPGP.SlashCommands["recalc"]
TBCEPGP.SlashCommands["RECALC"] = TBCEPGP.SlashCommands["recalc"]