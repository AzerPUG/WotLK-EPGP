if WOTLKEPGP == nil then WOTLKEPGP = {} end
WOTLKEPGP.Events = {}
WOTLKEPGP.Version = 42
local AddOnName = "Wrath EPGP"

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
local DecayConfirmWindow = nil
local ReceiveSyncFrame = nil
local NewPlayers = {}
local NumPlayersInSync = 0
local CurrentSyncTicker = nil
local SyncQueue = {}

if WOTLKEPGPShowAdminView == nil then WOTLKEPGPShowAdminView = false end
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

function WOTLKEPGP:OnLoad()
    C_ChatInfo.RegisterAddonMessagePrefix("WOTLKEPGP")
    C_ChatInfo.RegisterAddonMessagePrefix("WOTLKEPGPItem")
    C_ChatInfo.RegisterAddonMessagePrefix("WOTLKEPGPRoll")
    C_ChatInfo.RegisterAddonMessagePrefix("WOTLKEPGPVersion")

    EventFrame = CreateFrame("Frame", nil, UIParent)
    WOTLKEPGP:RegisterEvents("ADDON_LOADED", function(...) WOTLKEPGP.Events:AddonLoaded(...) end)
    WOTLKEPGP:RegisterEvents("VARIABLES_LOADED", function(...) WOTLKEPGP.Events:VariablesLoaded(...) end)
    WOTLKEPGP:RegisterEvents("CHAT_MSG_ADDON", function(...) WOTLKEPGP.Events:ChatMsgAddon(...) end)
    WOTLKEPGP:RegisterEvents("GROUP_ROSTER_UPDATE", function(...) WOTLKEPGP.Events:GroupRosterUpdate(...) end)
    WOTLKEPGP:RegisterEvents("LOOT_OPENED", function(...) WOTLKEPGP.Events:LootOpened(...) end)

    EventFrame:SetScript("OnEvent", function(...) WOTLKEPGP:OnEvent(...) end)

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
    EPGPOptionsPanel.name = "Wrath EPGP"
    InterfaceOptions_AddCategory(EPGPOptionsPanel)

    EPGPOptionsPanel.header = EPGPOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    EPGPOptionsPanel.header:SetPoint("TOP", 0, -10)
    EPGPOptionsPanel.header:SetText("|cFF00FFFFWotLK EPGP Options!|r")

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
    EPGPOptionsPanel.adminsEditBox:SetScript("OnEditFocusLost", function() WOTLKEPGPAdminList = WOTLKEPGP:splitCharacterNames(EPGPOptionsPanel.adminsEditBox:GetText()) end)

    EPGPOptionsPanel.showAdminViewCheckButton = CreateFrame("CheckButton", "ShowAdminViewCheckButton", EPGPOptionsPanel, "ChatConfigCheckButtonTemplate");
    EPGPOptionsPanel.showAdminViewCheckButton:SetPoint("TOP", EPGPOptionsPanel.adminsEditBox, "BOTTOMLEFT", 0, -20);
    EPGPOptionsPanel.showAdminViewCheckButton:SetScript("OnClick", function()
        WOTLKEPGPShowAdminView = EPGPOptionsPanel.showAdminViewCheckButton:GetChecked()
        if WOTLKEPGPShowAdminView == true then
            EPGPUserFrame:Hide()
            EPGPAdminFrame:Show()
        elseif WOTLKEPGPShowAdminView == false then
            EPGPAdminFrame:Hide()
            EPGPUserFrame:Show()
        end
        WOTLKEPGP:FilterPlayers()
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
        WOTLKEPGP:ChangePRCalculations()
        WOTLKEPGP:SavePRCalculations()
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
        WOTLKEPGP:ChangePRCalculations()
        WOTLKEPGP:SavePRCalculations()
    end)

    WOTLKEPGP:ChangePRCalculations()

    EPGPOptionsPanel.EPMinimumText = EPGPOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    EPGPOptionsPanel.EPMinimumText:SetSize(90, 25)
    EPGPOptionsPanel.EPMinimumText:SetJustifyH("LEFT")
    EPGPOptionsPanel.EPMinimumText:SetPoint("LEFT", EPGPOptionsPanel.EPOffSet, "RIGHT", 75, 0)
    EPGPOptionsPanel.EPMinimumText:SetText("EP Minimum:")

    EPGPOptionsPanel.EPMinimum = CreateFrame("EditBox", nil, EPGPOptionsPanel, "InputBoxTemplate")
    EPGPOptionsPanel.EPMinimum:SetSize(50, 25)
    EPGPOptionsPanel.EPMinimum:SetPoint("LEFT", EPGPOptionsPanel.EPMinimumText, "RIGHT", 0, 0)
    EPGPOptionsPanel.EPMinimum:SetAutoFocus(false)
    EPGPOptionsPanel.EPMinimum:SetScript("OnEditFocusLost",
    function()
        WOTLKEPGPMinimums.EP = EPGPOptionsPanel.EPMinimum:GetText()
    end)

    EPGPOptionsPanel.GPMinimumText = EPGPOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    EPGPOptionsPanel.GPMinimumText:SetSize(90, 25)
    EPGPOptionsPanel.GPMinimumText:SetJustifyH("LEFT")
    EPGPOptionsPanel.GPMinimumText:SetPoint("TOPLEFT", EPGPOptionsPanel.EPMinimumText, "BOTTOMLEFT", 0, -10)
    EPGPOptionsPanel.GPMinimumText:SetText("GP Minimum:")

    EPGPOptionsPanel.GPMinimum = CreateFrame("EditBox", nil, EPGPOptionsPanel, "InputBoxTemplate")
    EPGPOptionsPanel.GPMinimum:SetSize(50, 25)
    EPGPOptionsPanel.GPMinimum:SetPoint("LEFT", EPGPOptionsPanel.GPMinimumText, "RIGHT", 0, 0)
    EPGPOptionsPanel.GPMinimum:SetAutoFocus(false)
    EPGPOptionsPanel.GPMinimum:SetScript("OnEditFocusLost",
    function()
        WOTLKEPGPMinimums.GP = EPGPOptionsPanel.GPMinimum:GetText()
    end)

    EPGPOptionsPanel.EPDecayText = EPGPOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    EPGPOptionsPanel.EPDecayText:SetSize(80, 25)
    EPGPOptionsPanel.EPDecayText:SetJustifyH("LEFT")
    EPGPOptionsPanel.EPDecayText:SetPoint("LEFT", EPGPOptionsPanel.EPMinimum, "RIGHT", 75, 0)
    EPGPOptionsPanel.EPDecayText:SetText("EP Decay %:")

    EPGPOptionsPanel.EPDecay = CreateFrame("EditBox", nil, EPGPOptionsPanel, "InputBoxTemplate")
    EPGPOptionsPanel.EPDecay:SetSize(50, 25)
    EPGPOptionsPanel.EPDecay:SetPoint("LEFT", EPGPOptionsPanel.EPDecayText, "RIGHT", 0, 0)
    EPGPOptionsPanel.EPDecay:SetAutoFocus(false)
    EPGPOptionsPanel.EPDecay:SetScript("OnEditFocusLost",
    function()
        WOTLKEPGPDecay.EP = EPGPOptionsPanel.EPDecay:GetText()
        DecayConfirmWindow.WarningText2:SetText(string.format("|cFFFF0000EP Decay: %d%%\nGP Decay: %d%%|r", WOTLKEPGPDecay.EP, WOTLKEPGPDecay.GP))
    end)

    EPGPOptionsPanel.GPDecayText = EPGPOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    EPGPOptionsPanel.GPDecayText:SetSize(80, 25)
    EPGPOptionsPanel.GPDecayText:SetJustifyH("LEFT")
    EPGPOptionsPanel.GPDecayText:SetPoint("TOPLEFT", EPGPOptionsPanel.EPDecayText, "BOTTOMLEFT", 0, -10)
    EPGPOptionsPanel.GPDecayText:SetText("GP Decay %:")

    EPGPOptionsPanel.GPDecay = CreateFrame("EditBox", nil, EPGPOptionsPanel, "InputBoxTemplate")
    EPGPOptionsPanel.GPDecay:SetSize(50, 25)
    EPGPOptionsPanel.GPDecay:SetPoint("LEFT", EPGPOptionsPanel.GPDecayText, "RIGHT", 0, 0)
    EPGPOptionsPanel.GPDecay:SetAutoFocus(false)
    EPGPOptionsPanel.GPDecay:SetScript("OnEditFocusLost",
    function()
        WOTLKEPGPDecay.GP = EPGPOptionsPanel.GPDecay:GetText()
        DecayConfirmWindow.WarningText2:SetText(string.format("|cFFFF0000EP Decay: %d%%\nGP Decay: %d%%|r", WOTLKEPGPDecay.EP, WOTLKEPGPDecay.GP))
    end)

    ReceiveSyncFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    ReceiveSyncFrame:SetPoint("CENTER", 0, 250)
    ReceiveSyncFrame:SetSize(300, 80)
    ReceiveSyncFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    ReceiveSyncFrame:SetBackdropColor(0.25, 0.25, 0.25, 0.80)

    ReceiveSyncFrame.Header = ReceiveSyncFrame:CreateFontString("ReceiveSyncFrame", "ARTWORK", "GameFontNormalHuge")
    ReceiveSyncFrame.Header:SetPoint("TOP", 0, -10)
    ReceiveSyncFrame.Header:SetText("|cFF00FFFF" .. AddOnName .. " receiving sync.|r")
    
    ReceiveSyncFrame.SubHeader = ReceiveSyncFrame:CreateFontString("ReceiveSyncFrame", "ARTWORK", "GameFontNormalLarge")
    ReceiveSyncFrame.SubHeader:SetPoint("TOP", ReceiveSyncFrame.Header, "BOTTOM", 0, -5)
    ReceiveSyncFrame.SubHeader:SetText("|cFF00FFFFAdmin: %s|r")

    ReceiveSyncFrame.Bar = CreateFrame("StatusBar", nil, ReceiveSyncFrame)
    ReceiveSyncFrame.Bar:SetSize(ReceiveSyncFrame:GetWidth() - 20, 18)
    ReceiveSyncFrame.Bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    ReceiveSyncFrame.Bar:SetPoint("TOP", ReceiveSyncFrame.SubHeader, "BOTTOM", 0, -5)
    ReceiveSyncFrame.Bar:SetMinMaxValues(0, 100)
    ReceiveSyncFrame.Bar:SetValue(0)

    ReceiveSyncFrame.Bar.SyncProgress = ReceiveSyncFrame.Bar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ReceiveSyncFrame.Bar.SyncProgress:SetSize(50, 16)
    ReceiveSyncFrame.Bar.SyncProgress:SetPoint("CENTER", 0, -1)
    ReceiveSyncFrame.Bar.SyncProgress:SetText("0/100")

    ReceiveSyncFrame.Bar.BG = ReceiveSyncFrame.Bar:CreateTexture(nil, "BACKGROUND")
    ReceiveSyncFrame.Bar.BG:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    ReceiveSyncFrame.Bar.BG:SetAllPoints(true)
    ReceiveSyncFrame.Bar.BG:SetVertexColor(1, 0, 0)

    ReceiveSyncFrame.Bar:SetStatusBarColor(0, 0.75, 1)

    ReceiveSyncFrame.CloseButton = CreateFrame("Button", nil, ReceiveSyncFrame, "UIPanelCloseButton")
    ReceiveSyncFrame.CloseButton:SetSize(24, 24)
    ReceiveSyncFrame.CloseButton:SetPoint("TOPRIGHT", ReceiveSyncFrame, "TOPRIGHT", -3, -3)
    ReceiveSyncFrame.CloseButton:SetScript("OnClick", function() ReceiveSyncFrame:Hide() end)

    ReceiveSyncFrame:Hide()

    WOTLKEPGP:AddTooltipScript()
    WOTLKEPGP:CreateLootFrame()
    WOTLKEPGP:CreateLogFrame()

    EPGPOptionsPanel:SetScript("OnShow",
    function()
        WOTLKEPGP:ChangePRCalculations()
        local adminsToSet = ""
        if WOTLKEPGPAdminList ~= nil and #WOTLKEPGPAdminList > 0 then
            for i = 1, #WOTLKEPGPAdminList do
                adminsToSet = WOTLKEPGPAdminList[i] .. " "
            end
            EPGPOptionsPanel.adminsEditBox:SetText(adminsToSet)
        end
    end)
    EPGPOptionsPanel:Hide()
end

function WOTLKEPGP:ChangePRCalculations()
    local EPOffSet = EPGPOptionsPanel.EPOffSet:GetNumber()
    local GPOffSet = EPGPOptionsPanel.GPOffSet:GetNumber()
    if EPOffSet > 0 then EPOffSet = string.format("+%d", EPOffSet) elseif EPOffSet == 0 then EPOffSet = "" end
    if GPOffSet > 0 then GPOffSet = string.format("+%d", GPOffSet) elseif GPOffSet == 0 then GPOffSet = "" end
    local CalcString = string.format("|cFF00FFFFPR = (EP%s) / (GP%s)|r", tostring(EPOffSet), tostring(GPOffSet))
    EPGPOptionsPanel.CalculationsLabel:SetText(CalcString)
end

function WOTLKEPGP:SavePRCalculations()
    local EPOffSet = EPGPOptionsPanel.EPOffSet:GetNumber()
    local GPOffSet = EPGPOptionsPanel.GPOffSet:GetNumber()
    WOTLKEPGPPRCalc = {tostring(EPOffSet), tostring(GPOffSet)}
end

function WOTLKEPGP:CreateLogFrame()
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
    EPGPChangeLogFrame.Title.Text:SetText(AddOnName .. " - v" .. WOTLKEPGP.Version)

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

function WOTLKEPGP:CreateLootFrame()
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
    EPGPLootFrame.Title.Text:SetText(AddOnName .. " - v" .. WOTLKEPGP.Version)

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

function WOTLKEPGP:AddTooltipScript()
    GameTooltip:HookScript("OnTooltipSetItem", function(...)
        local _, itemLink = GameTooltip:GetItem()
        if itemLink ~= nil then
            --local itemName, _, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc = GetItemInfo(itemLink)
            local itemStuff = WOTLKEPGP:CheckItemInfo(itemLink)

            --if itemEquipLoc ~= nil and WOTLKEPGP.InfoTable.Slot[itemEquipLoc] ~= nil then
            if itemStuff.itemEquipLoc ~= nil and WOTLKEPGP.InfoTable.Slot[itemStuff.itemEquipLoc] ~= nil then
                --local price = WOTLKEPGP:CalculateTotalPrice(itemQuality, itemEquipLoc, itemLevel)
                local price = WOTLKEPGP:CalculateTotalPrice(itemStuff.itemQuality, itemStuff.itemEquipLoc, itemStuff.itemLevel)
                price = WOTLKEPGP:MathRound(price * 1000) / 1000
                GameTooltip:AddLine("Wrath EPGP: " .. price .. "GP")
            end
        end
    end)
end

function WOTLKEPGP:CheckItemInfo(itemInfoStuff)
    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expacID, setID, isCraftingReagent = GetItemInfo(itemInfoStuff)

    local itemID = tonumber(string.match(itemLink, "[^:]*:([^:]*)"))

    local value = WOTLKEPGP.InfoTable.PreCalculatedItems[itemID]
    if value ~= nil then
        itemLevel = value.itemLevel
        itemQuality = value.itemQuality
        itemEquipLoc = value.itemEquipLoc
    end

    local itemStuff = {itemName = itemName, itemLink = itemLink, itemID = itemID, itemLevel = itemLevel, itemQuality = itemQuality, itemEquipLoc = itemEquipLoc, itemTexture = itemTexture}

    return itemStuff
end

function WOTLKEPGP:splitCharacterNames(input)
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

function WOTLKEPGP:RegisterEvents(event, func)
    local handlers = WOTLKEPGP.RegisteredEvents[event]
    if handlers == nil then
        handlers = {}
        WOTLKEPGP.RegisteredEvents[event] = handlers
        EventFrame:RegisterEvent(event)
    end
    handlers[#handlers + 1] = func
end

function WOTLKEPGP:GetDateTime()
    local DateTimeString = date()
    local year, month, date, day, time = nil, nil, nil, nil, nil
    if string.find(DateTimeString, "  ") then
        day, month, _, date, time, year = strsplit(" ", DateTimeString)
    else
        day, month, date, time, year = strsplit(" ", DateTimeString)
    end
    day = WOTLKEPGP:GetFullDayName(day)
    month = WOTLKEPGP:GetNumericMonth(month)
    date = tonumber(date)
    year = tonumber(year)
    return year, month, date
end

function WOTLKEPGP:GetFullDayName(day)
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

function WOTLKEPGP:GetNumericMonth(month)
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

function WOTLKEPGP:GetQualityMultiplier(quality, iLevel)
    if quality ~= 0 and quality ~= 1 then
        local multiplier = WOTLKEPGP.InfoTable.Quality[quality](iLevel)
        return multiplier
    else
        return 1
    end
end

function WOTLKEPGP:GetSlotMultiplier(slot)    
    if WOTLKEPGP.InfoTable.Slot[slot] ~= nil then
        local multiplier = WOTLKEPGP.InfoTable.Slot[slot]
        return multiplier
    else
        return 1
    end
end

function WOTLKEPGP:CalculateTotalPrice(quality, slot, iLevel)
    local TotalPrice, CalcPrice, QMulty, SMulty = nil, nil, nil, nil
    QMulty = WOTLKEPGP:GetQualityMultiplier(quality, iLevel)
    SMulty = WOTLKEPGP:GetSlotMultiplier(slot)

    CalcPrice = QMulty * QMulty * 0.04 * SMulty
    return CalcPrice
end

function WOTLKEPGP:MathRound(value)
    value = math.floor(value + 0.5)
    return value
end

function WOTLKEPGP:RollItem(inputLink)
    if inputLink == nil then print("No ItemLink provided!")
    else
        local itemStuff = WOTLKEPGP:CheckItemInfo(inputLink)
        if itemStuff.itemEquipLoc == nil or itemStuff.itemEquipLoc == "" then itemStuff.itemEquipLoc = "Not Equipable!" end
        local totalPrice = WOTLKEPGP:CalculateTotalPrice(itemStuff.itemQuality, itemStuff.itemEquipLoc, itemStuff.itemLevel)
        local roundedPrice = WOTLKEPGP:MathRound(totalPrice)
        print("EPGP Rolling Item:", itemStuff.itemLink)
        print("iLevel:", itemStuff.itemLevel, " - Quality:", itemStuff.itemQuality, " - Slot:", itemStuff.itemEquipLoc)
        print("Quality/iLevel Modifier:", WOTLKEPGP:GetQualityMultiplier(itemStuff.itemQuality, itemStuff.itemLevel))
        print("Slot Modifier:", WOTLKEPGP:GetSlotMultiplier(itemStuff.itemEquipLoc))
        print("Total Price:", totalPrice)
        print("Rounded Price:", roundedPrice)
    end
end

function WOTLKEPGP:AddPlayerToList(curGUID, curName, curClass)
    if curGUID:find("Player-") ~= nil then
        local numPlayers = WOTLKEPGP:CountPlayersInList()
        local epoch = time()
        local players = WOTLKEPGP.DataTable.Players
        if players[curGUID] == nil then
            players[curGUID] = {}
            players[curGUID].Name = curName
            players[curGUID].Update = epoch
            players[curGUID].Class = curClass
            players[curGUID].EP = WOTLKEPGPMinimums.EP
            players[curGUID].GP = WOTLKEPGPMinimums.GP
            players[curGUID].PR = players[curGUID].EP / players[curGUID].GP
            local year, month, date = WOTLKEPGP:GetDateTime()
            local dateString = year .. month .. date
            print("Adding Target to DataTable:", curName, "-", curGUID)
            players[curGUID][dateString] = {}
            WOTLKEPGP:FilterPlayers()
        else
            print("Player already in list!")
        end
    else
        print("NPC is not allowed.")
    end
end

function WOTLKEPGP:CountPlayersInList()
    local numPlayers = 0
    local players = WOTLKEPGP.DataTable.Players
    for key, value in pairs(players) do
        numPlayers = numPlayers + 1
    end

    return numPlayers
end

function WOTLKEPGP:SyncRaidersAddOnMsg()
    print("Trying to sync!")
    local players = WOTLKEPGPDataTable.Players
    for playerGUID, playerData in pairs(players) do
        local message = "Player:"
        if playerData.EP == nil then playerData.EP = 1 end
        if playerData.GP == nil then playerData.GP = 1 end
        message = message .. playerGUID .. ":" .. playerData.Name .. ":" .. playerData.Update .. ":" .. playerData.Class .. ":" .. playerData.EP .. ":" .. playerData.GP .. ":"
        table.insert(SyncQueue, message)
    end
    WOTLKEPGP:SendRaidGuildAddonMsg(string.format("StartOfSync:%d", #SyncQueue))
    if CurrentSyncTicker == nil then
        CurrentSyncTicker = C_Timer.NewTicker(1, function() WOTLKEPGP:SendNextSyncBatch() end)
    end
end

function WOTLKEPGP:SendNextSyncBatch()
    if #SyncQueue > 0 then
        local message = table.remove(SyncQueue, 1)
        WOTLKEPGP:SendRaidGuildAddonMsg(message)
    end

    if #SyncQueue == 0 then
        WOTLKEPGP:SendRaidGuildAddonMsg("EndOfSync")
        CurrentSyncTicker:Cancel()
        CurrentSyncTicker = nil
        print("Sync AddOn Messages Send!")
    end
end

function WOTLKEPGP:SendRaidGuildAddonMsg(message)
    if IsInRaid() then
        C_ChatInfo.SendAddonMessage("WOTLKEPGP", message ,"RAID", 1)
    else
        C_ChatInfo.SendAddonMessage("WOTLKEPGP", message ,"GUILD", 1)
    end
end

function WOTLKEPGP:CreateFilterButtons()
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
        WOTLKEPGP:FilterPlayers()
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
                WOTLKEPGP:FilterPlayers(i)
            end)
        end
    end
end

function WOTLKEPGP.Events:GroupRosterUpdate()
    WOTLKEPGP:ShareVersion()
end

function WOTLKEPGP:CollectPlayersInRaid()
    local playerNames = {}
    for i=1,40 do
        local name = UnitGUID("raid" .. i)
        if name ~= nil then
            tinsert(playerNames, name)
        end
    end
    return playerNames
end

function WOTLKEPGP.Events:ChatMsgAddon(prefix, payload, channel, sender)
    local player = UnitName("PLAYER")
    if prefix == "WOTLKEPGPVersion" and sender ~= player then
        local version = WOTLKEPGP:GetSpecificAddonVersion(payload, "WOTLKEPGP")
        if version ~= nil then
            WOTLKEPGP:ReceiveVersion(version)
        end
    elseif prefix == "WOTLKEPGP" then
        local playerName = UnitName("player")
        local subPayload = payload
        local players = WOTLKEPGPDataTable.Players
        local subStringList = {}

        sender = string.match(sender, "(.*)-")
        if WOTLKEPGPAdminList ~= nil and #WOTLKEPGPAdminList > 0 then
            if sender ~= playerName and tContains(WOTLKEPGPAdminList, sender) then
                local command, arguments = string.match(payload, "([^:]*):?(.*)")
                if command == "StartOfSync" then
                    NumPlayersInSync = tonumber(arguments)
                    ReceiveSyncFrame.Bar:SetValue(0)
                    ReceiveSyncFrame.Bar:SetMinMaxValues(0, NumPlayersInSync)
                    ReceiveSyncFrame.SubHeader:SetText(string.format("|cFF00FFFFAdmin: %s|r", sender))
                    ReceiveSyncFrame:Show()
                    ReceiveSyncFrame.Bar.SyncProgress:SetText(string.format("%s/%s", 0, NumPlayersInSync))
                    NewPlayers = {}
                    print('New Sync Started')
                elseif payload == "EndOfSync" then print("Sync Received from", sender) ReceiveSyncFrame:Hide() WOTLKEPGP:MergeNewPlayerInfo(NewPlayers)
                else
                    local curValue = ReceiveSyncFrame.Bar:GetValue()
                    ReceiveSyncFrame.Bar:SetValue(curValue + 1)
                    ReceiveSyncFrame.Bar.SyncProgress:SetText(string.format("%d/%d", curValue + 1, NumPlayersInSync))
                    for i = 1, 6 do
                        if arguments ~= nil then
                            arguments = string.sub(subPayload, string.find(arguments, ":") + 1, #arguments)
                            local stringFind = string.find(arguments, ":", 1)
                            if stringFind ~= nil then
                                subStringList[i] = string.sub(arguments, 0, stringFind - 1)
                            end
                        end
                        subStringList[3] = tonumber(subStringList[3])
                        subStringList[4] = tonumber(subStringList[4])
                        subStringList[5] = tonumber(subStringList[5])
                        subStringList[6] = tonumber(subStringList[6])
                    end

                    local curGUID = subStringList[1]
                    NewPlayers[curGUID] = {}
                    NewPlayers[curGUID].Name = subStringList[2]
                    NewPlayers[curGUID].Update = subStringList[3]
                    NewPlayers[curGUID].Class = subStringList[4]
                    NewPlayers[curGUID].EP = subStringList[5]
                    NewPlayers[curGUID].GP = subStringList[6]
                end
            end
        end
    elseif prefix == "WOTLKEPGPItem" then
        local subPayload = payload
        local itemName, itemTexture, GPValue, itemLink = string.match(payload, "Item:([^:]*):([^:]*):([^:]*):(.*):$")
        WOTLKEPGP:AddItemToLootList(itemName, itemTexture, GPValue, itemLink)
    elseif prefix == "WOTLKEPGPRoll" then
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

        WOTLKEPGP:AddPlayerToItem(subStringList[1], subStringList[2], subStringList[3])
    end
end

function WOTLKEPGP:MergeNewPlayerInfo(newPlayers)
    print("Merging new player info")
    local players = WOTLKEPGPDataTable.Players

    for _, value in pairs(newPlayers) do
        if value.EP == nil then value.EP = 0 end
        if value.GP == nil then value.GP = 0 end
    end

    for curGUID, player in pairs(newPlayers) do
        if players[curGUID] == nil or players[curGUID].Update < player.Update then
            players[curGUID] = {}
            players[curGUID].Name = player.Name
            players[curGUID].Update = player.Update
            players[curGUID].Class = player.Class
            players[curGUID].EP = player.EP
            players[curGUID].GP = player.GP
            WOTLKEPGP:CalculatePriority(curGUID, player.EP, player.GP)
            print("Updated " .. player.Name .. " with new info")
        end
    end
    WOTLKEPGP:FillAdminFrameScrollPanel(players)
    WOTLKEPGP:FillUserFrameScrollPanel(players)
end

function WOTLKEPGP:OnEvent(_, event, ...)
    for _, handler in pairs(WOTLKEPGP.RegisteredEvents[event]) do
        handler(...)
    end
end

function WOTLKEPGP.Events:AddonLoaded(...)
    local addonName = ...
    print("AddOn Name:", addonName)
    if addonName == "WOTLK-EPGP" then
        if variablesLoaded == true then WOTLKEPGP:VarsAndAddonLoaded() else addonLoaded = true end
    end
end

function WOTLKEPGP.Events:VariablesLoaded(...)
    if addonLoaded == true then WOTLKEPGP:VarsAndAddonLoaded() else variablesLoaded = true end
end

function WOTLKEPGP:VarsAndAddonLoaded()
    if WOTLKEPGPDataTable == nil then
        WOTLKEPGPDataTable = WOTLKEPGP.DataTable
    elseif WOTLKEPGPDataTable ~= nil then
        WOTLKEPGP.DataTable = WOTLKEPGPDataTable
    end

    if WOTLKEPGPPRCalc == nil then WOTLKEPGPPRCalc = {0, 0} end
    WOTLKEPGP:ChangePRCalculations()
    EPGPOptionsPanel.EPOffSet:SetText(WOTLKEPGPPRCalc[1])
    EPGPOptionsPanel.GPOffSet:SetText(WOTLKEPGPPRCalc[2])

    WOTLKEPGP:TempDataChanger()

    WOTLKEPGP:CreateAdminFrame()
    WOTLKEPGP:CreateUserFrame()
    WOTLKEPGP:CreateFilterButtons()
    ShowAdminViewCheckButton:SetChecked(WOTLKEPGPShowAdminView)
    WOTLKEPGP:ShareVersion()

    WOTLKEPGP:ForceRecalculate()

    if WOTLKEPGPVersionNumber ~= nil then WOTLKEPGPVersionNumber = nil end
    WOTLKEPGPVersionData = {GUID = UnitGUID("Player"), Name = UnitName("Player"), Version = WOTLKEPGP.Version, ErrorInfo = {}}

    if WOTLKEPGPMinimums == nil then WOTLKEPGPMinimums = {} end
    if WOTLKEPGPMinimums.EP == nil then WOTLKEPGPMinimums.EP = 1 end
    if WOTLKEPGPMinimums.GP == nil then WOTLKEPGPMinimums.GP = 1 end

    if WOTLKEPGPDecay == nil then WOTLKEPGPDecay = {} end
    if WOTLKEPGPDecay.EP == nil then WOTLKEPGPDecay.EP = 15 end
    if WOTLKEPGPDecay.GP == nil then WOTLKEPGPDecay.GP = 15 end

    EPGPOptionsPanel.EPMinimum:SetText(WOTLKEPGPMinimums.EP)
    EPGPOptionsPanel.GPMinimum:SetText(WOTLKEPGPMinimums.GP)

    EPGPOptionsPanel.EPDecay:SetText(WOTLKEPGPDecay.EP)
    EPGPOptionsPanel.GPDecay:SetText(WOTLKEPGPDecay.GP)

    DecayConfirmWindow.WarningText2:SetText(string.format("|cFFFF0000EP Decay: %d%%\nGP Decay: %d%%|r", WOTLKEPGPDecay.EP, WOTLKEPGPDecay.GP))
end

function WOTLKEPGP:ForceRecalculate()
    local Players = WOTLKEPGPDataTable.Players
    for curPlayer, playerData in pairs(Players) do
        Players[curPlayer].PR = WOTLKEPGP:CalculatePriority(curPlayer, playerData.EP, playerData.GP)
    end
    WOTLKEPGP:FilterPlayers()
end

function WOTLKEPGP:DelayedExecution(delayTime, delayedFunction)
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

function WOTLKEPGP:ShareVersion() -- Change DelayedExecution to native WoW Function.
    local versionString = string.format("|WOTLKEPGP:%d|", WOTLKEPGP.Version)
    WOTLKEPGP:DelayedExecution(10, function()
        if UnitInBattleground("player") ~= nil then
            -- BG stuff?
        else
            if IsInGroup() then
                if IsInRaid() then
                    C_ChatInfo.SendAddonMessage("WOTLKEPGPVersion", versionString ,"RAID", 1)
                else
                    C_ChatInfo.SendAddonMessage("WOTLKEPGPVersion", versionString ,"PARTY", 1)
                end
            end
            if IsInGuild() then
                C_ChatInfo.SendAddonMessage("WOTLKEPGPVersion", versionString ,"GUILD", 1)
            end
        end
    end)
end

function WOTLKEPGP:ReceiveVersion(version)
    if version > WOTLKEPGP.Version then
        if (not HaveShowedUpdateNotification) then
            HaveShowedUpdateNotification = true
            UpdateFrame:Show()
            UpdateFrame.text:SetText(
                "Please download the new version through the CurseForge app.\n" ..
                "Or use the CurseForge website to download it manually!\n\n" ..
                "Newer Version: v" .. version .. "\n" ..
                "Your version: v" .. WOTLKEPGP.Version
            )
        end
    end
end

function WOTLKEPGP:GetSpecificAddonVersion(versionString, addonWanted)
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

function WOTLKEPGP:TempDataChanger()
    for key, value in pairs(WOTLKEPGP.DataTable.Players) do
        if WOTLKEPGP.DataTable.Players[key].Class == "Warrior" then WOTLKEPGP.DataTable.Players[key].Class = 1 end
        if WOTLKEPGP.DataTable.Players[key].Class == "Paladin" then WOTLKEPGP.DataTable.Players[key].Class = 2 end
        if WOTLKEPGP.DataTable.Players[key].Class == "Hunter" then WOTLKEPGP.DataTable.Players[key].Class = 3 end
        if WOTLKEPGP.DataTable.Players[key].Class == "Rogue" then WOTLKEPGP.DataTable.Players[key].Class = 4 end
        if WOTLKEPGP.DataTable.Players[key].Class == "Priest" then WOTLKEPGP.DataTable.Players[key].Class = 5 end
        if WOTLKEPGP.DataTable.Players[key].Class == "Shaman" then WOTLKEPGP.DataTable.Players[key].Class = 7 end
        if WOTLKEPGP.DataTable.Players[key].Class == "Mage" then WOTLKEPGP.DataTable.Players[key].Class = 8 end
        if WOTLKEPGP.DataTable.Players[key].Class == "Warlock" then WOTLKEPGP.DataTable.Players[key].Class = 9 end
        if WOTLKEPGP.DataTable.Players[key].Class == "Druid" then WOTLKEPGP.DataTable.Players[key].Class = 11 end
    end
end

function WOTLKEPGP:CreateAdminFrame()
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
    EPGPAdminFrame.Title.Text:SetText(AddOnName .. " - v" .. WOTLKEPGP.Version)

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
    EPGPAdminFrame.Header.curEP.LockUnlockButton:SetScript("OnClick", function() WOTLKEPGP:LockUnlockAdminControls("EP") end)
    EPGPAdminFrame.Header.curEP.LockUnlockButton:SetBackdrop({bgFile = "Interface/Buttons/LockButton-Locked-Up"})

    EPGPAdminFrame.Header.curEP.changeEP = CreateFrame("EditBox", nil, EPGPAdminFrame.Header.curEP, "InputBoxTemplate")
    EPGPAdminFrame.Header.curEP.changeEP:SetSize(50, 25)
    EPGPAdminFrame.Header.curEP.changeEP:SetPoint("BOTTOMLEFT", EPGPAdminFrame.Header.curEP, "BOTTOMRIGHT", -75, 0)
    EPGPAdminFrame.Header.curEP.changeEP:SetAutoFocus(false)
    EPGPAdminFrame.Header.curEP.changeEP:SetFrameStrata("HIGH")
    EPGPAdminFrame.Header.curEP.changeEP:SetText(0)
    EPGPAdminFrame.Header.curEP.changeEP:HookScript("OnEditFocusLost", function() WOTLKEPGP:MassChange("EP") end)
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
    EPGPAdminFrame.Header.curGP.LockUnlockButton:SetScript("OnClick", function() WOTLKEPGP:LockUnlockAdminControls("GP") end)
    EPGPAdminFrame.Header.curGP.LockUnlockButton:SetBackdrop({bgFile = "Interface/Buttons/LockButton-Locked-Up"})

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
    EPGPAdminFrame.Header.curGP.changeGP:HookScript("OnEditFocusLost", function() WOTLKEPGP:MassChange("GP") end)
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

    EPGPAdminFrame.Header.Name .SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "Name"  WOTLKEPGP:FilterPlayers() end)
    EPGPAdminFrame.Header.Class.SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "Class" WOTLKEPGP:FilterPlayers() end)
    EPGPAdminFrame.Header.curEP.SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "EP"    WOTLKEPGP:FilterPlayers() end)
    EPGPAdminFrame.Header.curGP.SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "GP"    WOTLKEPGP:FilterPlayers() end)
    EPGPAdminFrame.Header.curPR.SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "PR"    WOTLKEPGP:FilterPlayers() end)

    EPGPAdminFrame.Header.Name .SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "Name"  WOTLKEPGP:FilterPlayers() end)
    EPGPAdminFrame.Header.Class.SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "Class" WOTLKEPGP:FilterPlayers() end)
    EPGPAdminFrame.Header.curEP.SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "EP"    WOTLKEPGP:FilterPlayers() end)
    EPGPAdminFrame.Header.curGP.SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "GP"    WOTLKEPGP:FilterPlayers() end)
    EPGPAdminFrame.Header.curPR.SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "PR"    WOTLKEPGP:FilterPlayers() end)

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
    PurgeConfirmWindow:SetSize(300, 175)
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
    PurgeConfirmWindow.WarningText:SetText("|cFFFF0000Are you sure you want to purge\nthe data and/or the players?\nThis can not be undone!!|r")

    PurgeConfirmWindow.PurgeDataButton = CreateFrame("Button", nil, PurgeConfirmWindow, "UIPanelButtonTemplate")
    PurgeConfirmWindow.PurgeDataButton:SetSize(100, 25)
    PurgeConfirmWindow.PurgeDataButton:SetPoint("TOP", PurgeConfirmWindow, "BOTTOM", -75, 75)
    PurgeConfirmWindow.PurgeDataButton:SetText("Purge Data")
    PurgeConfirmWindow.PurgeDataButton:SetScript("OnClick", function() WOTLKEPGP:PurgeData() PurgeConfirmWindow:Hide() end)

    PurgeConfirmWindow.PurgePlayersButton = CreateFrame("Button", nil, PurgeConfirmWindow, "UIPanelButtonTemplate")
    PurgeConfirmWindow.PurgePlayersButton:SetSize(100, 25)
    PurgeConfirmWindow.PurgePlayersButton:SetPoint("TOP", PurgeConfirmWindow, "BOTTOM", 75, 75)
    PurgeConfirmWindow.PurgePlayersButton:SetText("Purge Players")
    PurgeConfirmWindow.PurgePlayersButton:SetScript("OnClick", function() WOTLKEPGP:PurgePlayers() PurgeConfirmWindow:Hide() end)

    PurgeConfirmWindow.CancelButton = CreateFrame("Button", nil, PurgeConfirmWindow, "UIPanelButtonTemplate")
    PurgeConfirmWindow.CancelButton:SetSize(100, 25)
    PurgeConfirmWindow.CancelButton:SetPoint("TOP", PurgeConfirmWindow, "BOTTOM", 0, 35)
    PurgeConfirmWindow.CancelButton:SetText("Cancel")
    PurgeConfirmWindow.CancelButton:SetScript("OnClick", function() PurgeConfirmWindow:Hide() end)

    PurgeConfirmWindow:Hide()

    DecayConfirmWindow = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    DecayConfirmWindow:SetSize(300, 200)
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

    DecayConfirmWindow.WarningText2 = DecayConfirmWindow:CreateFontString("DecayConfirmWindow", "ARTWORK", "GameFontNormalLarge")
    DecayConfirmWindow.WarningText2:SetSize(DecayConfirmWindow:GetWidth(), 50)
    DecayConfirmWindow.WarningText2:SetPoint("TOP", DecayConfirmWindow.WarningText, "BOTTOM", 0, -10)

    DecayConfirmWindow.ConfirmButton = CreateFrame("Button", nil, DecayConfirmWindow, "UIPanelButtonTemplate")
    DecayConfirmWindow.ConfirmButton:SetSize(75, 25)
    DecayConfirmWindow.ConfirmButton:SetPoint("TOP", DecayConfirmWindow, "BOTTOM", -50, 35)
    DecayConfirmWindow.ConfirmButton:SetText("Confirm")
    DecayConfirmWindow.ConfirmButton:SetScript("OnClick", function() WOTLKEPGP:DecayDataTable() DecayConfirmWindow:Hide() end)

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
    EPGPAdminFrame.PurgeButton:SetScript("OnClick", function() PurgeConfirmWindow:Show() end)
    EPGPAdminFrame.PurgeButton.text = EPGPAdminFrame.PurgeButton:CreateFontString("PurgeButton", "ARTWORK", "GameFontNormalTiny")
    EPGPAdminFrame.PurgeButton.text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.PurgeButton.text:SetText("Purge")

    EPGPAdminFrame.OptionsButton = CreateFrame("Button", nil, EPGPAdminFrame, "UIPanelButtonTemplate")
    EPGPAdminFrame.OptionsButton:SetSize(75, 20)
    EPGPAdminFrame.OptionsButton:SetPoint("BOTTOMRIGHT", EPGPAdminFrame, "BOTTOMRIGHT", -10, 15)
    EPGPAdminFrame.OptionsButton:SetFrameStrata("HIGH")
    EPGPAdminFrame.OptionsButton:SetScript("OnClick",
    function()
        InterfaceOptionsFrame_OpenToCategory("Wrath EPGP")
        InterfaceOptionsFrame_OpenToCategory("Wrath EPGP")
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
        local players = WOTLKEPGP.DataTable.Players
        local unitGUID = UnitGUID("Target")
        local unitName = UnitName("Target")
        local _, _, unitClass = UnitClass("Target")
        WOTLKEPGP:AddPlayerToList(unitGUID, unitName, unitClass)
        WOTLKEPGP:FillAdminFrameScrollPanel(players)
    end)
    EPGPAdminFrame.AddToDataBaseButton.text = EPGPAdminFrame.AddToDataBaseButton:CreateFontString("AddToDataBaseButton", "ARTWORK", "GameFontNormalTiny")
    EPGPAdminFrame.AddToDataBaseButton.text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.AddToDataBaseButton.text:SetText("Add Target")

    EPGPAdminFrame.DecayButton = CreateFrame("Button", nil, EPGPAdminFrame, "UIPanelButtonTemplate")
    EPGPAdminFrame.DecayButton:SetSize(75, 20)
    EPGPAdminFrame.DecayButton:SetPoint("Right", EPGPAdminFrame.AddToDataBaseButton, "Left", -10, 0)
    EPGPAdminFrame.DecayButton:SetFrameStrata("HIGH")
    EPGPAdminFrame.DecayButton:SetScript("OnClick", function() DecayConfirmWindow:Show() end)
    EPGPAdminFrame.DecayButton.text = EPGPAdminFrame.DecayButton:CreateFontString("DecayButton", "ARTWORK", "GameFontNormalTiny")
    EPGPAdminFrame.DecayButton.text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.DecayButton.text:SetText("Decay")

    EPGPAdminFrame.SyncButton = CreateFrame("Button", nil, EPGPAdminFrame, "UIPanelButtonTemplate")
    EPGPAdminFrame.SyncButton:SetSize(75, 20)
    EPGPAdminFrame.SyncButton:SetPoint("Right", EPGPAdminFrame.DecayButton, "Left", -10, 0)
    EPGPAdminFrame.SyncButton:SetFrameStrata("HIGH")
    EPGPAdminFrame.SyncButton:SetScript("OnClick", function() WOTLKEPGP:SyncRaidersAddOnMsg() end)
    EPGPAdminFrame.SyncButton.text = EPGPAdminFrame.SyncButton:CreateFontString("SyncButton", "ARTWORK", "GameFontNormalTiny")
    EPGPAdminFrame.SyncButton.text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.SyncButton.text:SetText("Sync")

    EPGPAdminFrame.LogsButton = CreateFrame("Button", nil, EPGPAdminFrame, "UIPanelButtonTemplate")
    EPGPAdminFrame.LogsButton:SetSize(75, 20)
    EPGPAdminFrame.LogsButton:SetPoint("Right", EPGPAdminFrame.SyncButton, "Left", -10, 0)
    EPGPAdminFrame.LogsButton:SetFrameStrata("HIGH")
    EPGPAdminFrame.LogsButton:SetScript("OnClick", function() EPGPAdminFrame:Hide() WOTLKEPGP:UpdateLogs() EPGPChangeLogFrame:Show() end)
    EPGPAdminFrame.LogsButton.text = EPGPAdminFrame.LogsButton:CreateFontString("SyncButton", "ARTWORK", "GameFontNormalTiny")
    EPGPAdminFrame.LogsButton.text:SetPoint("CENTER", 0, 0)
    EPGPAdminFrame.LogsButton.text:SetText("Logs")

    local players = WOTLKEPGP.DataTable.Players
    WOTLKEPGP:FillAdminFrameScrollPanel(players)
    scrollFrame:SetScrollChild(AdminScrollPanel)

    EPGPAdminFrame:Hide()
end

function WOTLKEPGP:LockUnlockAdminControls(Points)
    if EPGPAdminFrame[Points .. "Locked"] == true then
        EPGPAdminFrame[Points .. "Locked"] = false
        EPGPAdminFrame.Header["cur" .. Points]["change" .. Points]:Show()
        EPGPAdminFrame.Header["cur" .. Points].LockUnlockButton:SetBackdrop({bgFile = "Interface/Buttons/LockButton-Unlocked-Up"})
    elseif EPGPAdminFrame[Points .. "Locked"] == false then
        EPGPAdminFrame[Points .. "Locked"] = true
        EPGPAdminFrame.Header["cur" .. Points]["change" .. Points]:Hide()
        EPGPAdminFrame.Header["cur" .. Points].LockUnlockButton:SetBackdrop({bgFile = "Interface/Buttons/LockButton-Locked-Up"})
    end
    WOTLKEPGP:FillAdminFrameScrollPanel(filteredPlayers)
end

function WOTLKEPGP:CreateUserFrame()
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
    EPGPUserFrame.Title.Text:SetText(AddOnName .. " - v" .. WOTLKEPGP.Version)

    EPGPUserFrame.Title.Texture = EPGPUserFrame.Title:CreateTexture(nil, "BACKGROUND")
    EPGPUserFrame.Title.Texture:SetAllPoints()
    EPGPUserFrame.Title.Texture:SetTexture("Interface/DialogFrame/UI-DialogBox-Header")

    EPGPUserFrame.ExtraBG = CreateFrame("FRAME", nil, EPGPUserFrame, "BackdropTemplate")
    EPGPUserFrame.ExtraBG:SetSize(EPGPUserFrame:GetWidth() - 25, EPGPUserFrame:GetHeight() - 79)
    EPGPUserFrame.ExtraBG:SetPoint("TOP", 2, -41)
    EPGPUserFrame.ExtraBG:SetFrameStrata("HIGH")
    EPGPUserFrame.ExtraBG:SetBackdrop({bgFile = "Interface/BankFrame/Bank-Background", tile = true, tileSize = 100;})
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

    EPGPUserFrame.Header.Name .SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "Name"  WOTLKEPGP:FilterPlayers() end)
    EPGPUserFrame.Header.Class.SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "Class" WOTLKEPGP:FilterPlayers() end)
    EPGPUserFrame.Header.curEP.SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "EP"    WOTLKEPGP:FilterPlayers() end)
    EPGPUserFrame.Header.curGP.SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "GP"    WOTLKEPGP:FilterPlayers() end)
    EPGPUserFrame.Header.curPR.SortUpButton:SetScript("OnClick", function() sortDir = "Asc" sortCol = "PR"    WOTLKEPGP:FilterPlayers() end)

    EPGPUserFrame.Header.Name .SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "Name"  WOTLKEPGP:FilterPlayers() end)
    EPGPUserFrame.Header.Class.SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "Class" WOTLKEPGP:FilterPlayers() end)
    EPGPUserFrame.Header.curEP.SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "EP"    WOTLKEPGP:FilterPlayers() end)
    EPGPUserFrame.Header.curGP.SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "GP"    WOTLKEPGP:FilterPlayers() end)
    EPGPUserFrame.Header.curPR.SortDownButton:SetScript("OnClick", function() sortDir = "Dsc" sortCol = "PR"    WOTLKEPGP:FilterPlayers() end)

    EPGPUserFrame.PurgeButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelButtonTemplate")
    EPGPUserFrame.PurgeButton:SetSize(75, 20)
    EPGPUserFrame.PurgeButton:SetPoint("BOTTOMLEFT", EPGPUserFrame, "BOTTOMLEFT", 10, 15)
    EPGPUserFrame.PurgeButton:SetFrameStrata("HIGH")
    EPGPUserFrame.PurgeButton:SetScript("OnClick", function() PurgeConfirmWindow:Show() end)
    EPGPUserFrame.PurgeButton.text = EPGPUserFrame.PurgeButton:CreateFontString("PurgeButton", "ARTWORK", "GameFontNormalTiny")
    EPGPUserFrame.PurgeButton.text:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.PurgeButton.text:SetText("Purge")

    EPGPUserFrame.OptionsButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelButtonTemplate")
    EPGPUserFrame.OptionsButton:SetSize(75, 20)
    EPGPUserFrame.OptionsButton:SetPoint("BOTTOMRIGHT", EPGPUserFrame, "BOTTOMRIGHT", -10, 15)
    EPGPUserFrame.OptionsButton:SetFrameStrata("HIGH")
    EPGPUserFrame.OptionsButton:SetScript("OnClick",
    function()
        InterfaceOptionsFrame_OpenToCategory("Wrath EPGP")
        InterfaceOptionsFrame_OpenToCategory("Wrath EPGP")
    end)
    EPGPUserFrame.OptionsButton.text = EPGPUserFrame.OptionsButton:CreateFontString("OptionsButton", "ARTWORK", "GameFontNormalTiny")
    EPGPUserFrame.OptionsButton.text:SetPoint("CENTER", 0, 0)
    EPGPUserFrame.OptionsButton.text:SetText("Options")

    local EPGPUserFrameCloseButton = CreateFrame("Button", nil, EPGPUserFrame, "UIPanelCloseButton, BackDropTemplate")
    EPGPUserFrameCloseButton:SetSize(24, 24)
    EPGPUserFrameCloseButton:SetPoint("TOPRIGHT", EPGPUserFrame, "TOPRIGHT", -3, -3)
    EPGPUserFrameCloseButton:SetScript("OnClick", function() EPGPUserFrame:Hide() end)

    local players = WOTLKEPGP.DataTable.Players
    WOTLKEPGP:FillUserFrameScrollPanel(players)
    scrollFrame:SetScrollChild(UserScrollPanel)

    EPGPUserFrame:Hide()
end

function WOTLKEPGP:UpdateLogs()
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

function WOTLKEPGP:DecayDataTable()
    local players = WOTLKEPGP.DataTable.Players
    local EPDecay, GPDecay = WOTLKEPGPDecay.EP, WOTLKEPGPDecay.GP
    local EPMin, GPMin = tonumber(WOTLKEPGPMinimums.EP), tonumber(WOTLKEPGPMinimums.GP)
    for key, value in pairs(players) do
        value.EP = WOTLKEPGP:MathRound(value.EP * (1000 * (1 - (EPDecay / 100)))) / 1000
        if value.EP < EPMin then value.EP = EPMin end
        value.GP = WOTLKEPGP:MathRound(value.GP * (1000 * (1 - (GPDecay / 100)))) / 1000
        if value.GP < GPMin then value.GP = GPMin end
        value.PR = WOTLKEPGP:CalculatePriority(key, value.EP, value.GP)
    end
    WOTLKEPGP:FilterPlayers()
end

function WOTLKEPGP:PurgeData()
    for curGUID, curPlayerData in pairs(WOTLKEPGP.DataTable.Players) do
        curPlayerData.EP = WOTLKEPGPMinimums.EP
        curPlayerData.GP = WOTLKEPGPMinimums.GP
        curPlayerData.Update = time()
        WOTLKEPGP:CalculatePriority(curGUID, curPlayerData.EP, curPlayerData.GP)

    end
    WOTLKEPGP:FilterPlayers()
end

function WOTLKEPGP:PurgePlayers()
    WOTLKEPGPDataTable.Players = {}
    WOTLKEPGP:FilterPlayers()
end

function WOTLKEPGP:MassChange(Points)
    local PointsChange = tonumber(EPGPAdminFrame.Header["cur" .. Points]["change" .. Points]:GetText())
    if PointsChange ~= nil and PointsChange ~= 0 then
        local players = WOTLKEPGPDataTable.Players
        if filteredPlayers == nil then filteredPlayers = players end
        for key, _ in pairs(filteredPlayers) do
            WOTLKEPGP:ChangePoints(key, Points, PointsChange)
        end
        EPGPAdminFrame.Header["cur" .. Points]["change" .. Points]:SetText(0)
        WOTLKEPGP:FillUserFrameScrollPanel(filteredPlayers)
        WOTLKEPGP:FillAdminFrameScrollPanel(filteredPlayers)
    end
end

function WOTLKEPGP:ChangePoints(curGUID, Points, Amount)
    Amount = WOTLKEPGP:MathRound(Amount * 1000) / 1000
    local curPlayer = WOTLKEPGPDataTable.Players[curGUID]
    curPlayer[Points] = curPlayer[Points] + Amount
    curPlayer.Update = time()
    if curGUID == nil or curPlayer.Update == nil then
        local tempNumber = #WOTLKEPGPVersionData.ErrorInfo + 1
        local y, m, d = WOTLKEPGP:GetDateTime()
        WOTLKEPGPVersionData.ErrorInfo[tempNumber] = {Time = time(), Date = string.format("%s/%s/%s", d, m, y), GUID = UnitGUID("Player"), Name = UnitName("Player"), Version = WOTLKEPGP.Version}
    end
    EPGPChangeLog[string.format("%s-%d", curGUID, curPlayer.Update)] = {Name = curPlayer.Name, Date = date("%m/%d/%y - %H:%M:%S"), Change = Points, Amount = Amount, Admin = UnitName("Player")}
    WOTLKEPGP:CalculatePriority(curGUID, curPlayer.EP, curPlayer.GP)
end

function WOTLKEPGP:FilterPlayers()
    filteredPlayers = {}
    local players = WOTLKEPGPDataTable.Players
    local raidGUIDs = WOTLKEPGP:CollectPlayersInRaid()

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

    WOTLKEPGP:FillUserFrameScrollPanel(filteredPlayers)
    WOTLKEPGP:FillAdminFrameScrollPanel(filteredPlayers)
end

function WOTLKEPGP:FillAdminFrameScrollPanel(inputPlayers)
    local players = inputPlayers
    local filteredPlayerFrames = {}
    local index = 1

    if inputPlayers == nil then players = WOTLKEPGP.DataTable.Players end

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

                WOTLKEPGP:ChangePoints(curPlayerFrame.key, "EP", PointsChange)

                curPlayerFrame.curEP:SetText(players[curPlayerFrame.key].EP)
                curPlayerFrame.changeEP:SetText(0)

                local curPR = WOTLKEPGP:CalculatePriority(curPlayerFrame.key, players[curPlayerFrame.key].EP, players[curPlayerFrame.key].GP)
                curPlayerFrame.curPR:SetText(curPR)
            end)

            curPlayerFrame.changeGP:HookScript("OnEditFocusLost",
            function()
                local PointsChange = tonumber(curPlayerFrame.changeGP:GetText())

                WOTLKEPGP:ChangePoints(curPlayerFrame.key, "GP", PointsChange)

                curPlayerFrame.curGP:SetText(players[curPlayerFrame.key].GP)
                curPlayerFrame.changeGP:SetText(0)

                local curPR = WOTLKEPGP:CalculatePriority(curPlayerFrame.key, players[curPlayerFrame.key].EP, players[curPlayerFrame.key].GP)
                curPlayerFrame.curPR:SetText(curPR)
            end)
        end

        curPlayerFrame.delButton:SetScript("OnClick", function()
            WOTLKEPGPDataTable.Players[key] = nil
            WOTLKEPGP:FilterPlayers()
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
        curPR = WOTLKEPGP:CalculatePriority(key, value.EP, value.GP)

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
            return WOTLKEPGP:ComparePlayers(players, a, b)
        end)
    end

    for i, frame in ipairs(filteredPlayerFrames) do
        frame:SetPoint("TOPLEFT", AdminScrollPanel, "TOPLEFT", 5, -24 * i + 25)
    end
end

function WOTLKEPGP:FillUserFrameScrollPanel(inputPlayers)
    local players = inputPlayers
    local filteredPlayerFrames = {}
    local index = 1

    if inputPlayers == nil then players = WOTLKEPGP.DataTable.Players end

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
        curPR = WOTLKEPGP:CalculatePriority(key, value.EP, value.GP)

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
            return WOTLKEPGP:ComparePlayers(players, a, b)
        end)
    end

    for i, frame in ipairs(filteredPlayerFrames) do
        frame:SetPoint("TOPLEFT", UserScrollPanel, "TOPLEFT", 5, -24 * i + 25)
    end
end

function WOTLKEPGP:ComparePlayers(sortTable, a, b)
    local aSort = sortTable[a.key][sortCol]
    local bSort = sortTable[b.key][sortCol]

    if sortDir == "Asc" then
        return (aSort < bSort)
    elseif sortDir == "Dsc" then
        return (aSort > bSort)
    end
end

function WOTLKEPGP:CalculatePriority(curGUID, curEP, curGP)
    curEP = curEP + WOTLKEPGPPRCalc[1]
    curGP = curGP + WOTLKEPGPPRCalc[2]
    local curPR = nil
    if curEP == 0 or curGP == 0 then curPR = 0 else curPR = WOTLKEPGP:MathRound(curEP/curGP * 1000) / 1000 end
    WOTLKEPGP.DataTable.Players[curGUID].PR = curPR
    return curPR
end

function WOTLKEPGP.Events:LootOpened()
    local lootmethod, _, MLRaidIndex = GetLootMethod()

    if lootmethod == "master" and MLRaidIndex == UnitInRaid("player") then
        for i = 1, GetNumLootItems() do
            local _, lootName, lootQuantity, _, lootQuality, _, isQuestItem, _, isActive = GetLootSlotInfo(i)
            if lootName ~= nil and isQuestItem == false and isActive == nil and lootQuality >= 1 then
                local itemLink = GetLootSlotLink(i)
                WOTLKEPGP:LootItemAddOnMsg(itemLink)
            end
        end
    end
end

function WOTLKEPGP:AddItemToLootList(itemName, itemTexture, GPValue, itemLink)
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
    WOTLKEPGP:FillLootFrameScrollPanel()
end

function WOTLKEPGP:AddPlayerToItem(Roll, Index, GUID)
    local curPlayer = WOTLKEPGPDataTable.Players[GUID]
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
        WOTLKEPGP:LootItemFrameResize(Index)
    end
end

function WOTLKEPGP:FillLootFrameScrollPanel()
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
            curItemFrame.needButton:SetScript("OnClick", function() WOTLKEPGP:LootRollAddOnMsg("Need", i) end)
            curItemFrame.needButton.text = curItemFrame.needButton:CreateFontString("curItemFrame", "ARTWORK", "GameFontNormal")
            curItemFrame.needButton.text:SetText("Need Item")
            curItemFrame.needButton.text:SetPoint("CENTER", 0, 0)

            curItemFrame.greedButton = CreateFrame("BUTTON", nil, curItemFrame, "UIPanelButtonTemplate")
            curItemFrame.greedButton:SetSize(EPGPLootFrame.Header.buttons:GetWidth() / 2 - 10, 20)
            curItemFrame.greedButton:SetPoint("TOPLEFT", curItemFrame.needButton, "TOPRIGHT", 5, 0)
            curItemFrame.greedButton:SetScript("OnClick", function() WOTLKEPGP:LootRollAddOnMsg("Greed", i) end)
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
            WOTLKEPGP:LootItemFrameResize(i)
        end
    end
end

function WOTLKEPGP:LootRollAddOnMsg(Roll, Index)
    local prefix = "WOTLKEPGPRoll"
    local curGUID = UnitGUID("PLAYER")
    local message = "Roll:" .. Roll .. ":" .. Index .. ":" .. curGUID .. ":"
    C_ChatInfo.SendAddonMessage(prefix, message , "RAID", 1)
end

function WOTLKEPGP:LootItemAddOnMsg(itemName)
    local itemStuff = WOTLKEPGP:CheckItemInfo(itemName)
    local GPValue = WOTLKEPGP:CalculateTotalPrice(itemStuff.itemQuality, itemStuff.itemEquipLoc, itemStuff.itemLevel)

    if itemEquipLoc ~= nil and WOTLKEPGP.InfoTable.Slot[itemEquipLoc] ~= nil then
        local prefix = "WOTLKEPGPItem"
        --local message = "Item:" .. itemName .. ":" .. itemTexture .. ":" .. GPValue .. ":" .. itemLink .. ":"
        local message = "Item:" .. itemStuff.itemName .. ":" .. itemStuff.itemTexture .. ":" .. GPValue .. ":" .. itemStuff.itemLink .. ":"
        C_ChatInfo.SendAddonMessage(prefix, message , "RAID", 1)
    end
end

function WOTLKEPGP:LootItemFrameResize(Index)
    local curIFrameHeight = #EPGPActiveLootItems[Index].players.Need
    if #EPGPActiveLootItems[Index].players.Greed >= curIFrameHeight then curIFrameHeight = #EPGPActiveLootItems[Index].players.Greed end
    if curIFrameHeight >= 3 then curIFrameHeight = curIFrameHeight * 10 + 5 else curIFrameHeight = 32 end
    LootItemFrames[Index]:SetSize(LootScrollPanel:GetWidth() - 4, curIFrameHeight)
    LootItemFrames[Index].Need:SetSize(EPGPLootFrame.Header.playersNeed:GetWidth(), LootItemFrames[Index]:GetHeight())
    LootItemFrames[Index].Greed:SetSize(EPGPLootFrame.Header.playersGreed:GetWidth(), LootItemFrames[Index]:GetHeight())
end

WOTLKEPGP:OnLoad()

WOTLKEPGP.SlashCommands["roll"] = function(value)
    WOTLKEPGP:RollItem(value)
end

WOTLKEPGP.SlashCommands["sync"] = function(value)
    WOTLKEPGP:SyncRaidersAddOnMsg()
end

WOTLKEPGP.SlashCommands["add"] = function(value)
    local curGUID = UnitGUID("Target")
    local curName = UnitName("Target")
    local _, _, curClass = UnitClass("Target")
    WOTLKEPGP:AddPlayerToList(curGUID, curName, curClass)
end

WOTLKEPGP.SlashCommands["show"] = function(value)
    if WOTLKEPGPShowAdminView == true then
        EPGPAdminFrame:Show()
    elseif WOTLKEPGPShowAdminView == false then
        EPGPUserFrame:Show()
    end
end

WOTLKEPGP.SlashCommands["loot"] = function(value)
    EPGPLootFrame:Show()
end

WOTLKEPGP.SlashCommands["recalc"] = function(value)
    WOTLKEPGP:ForceRecalculate()
end

WOTLKEPGP.SlashCommands["Roll"] = WOTLKEPGP.SlashCommands["roll"]
WOTLKEPGP.SlashCommands["ROLL"] = WOTLKEPGP.SlashCommands["roll"]

WOTLKEPGP.SlashCommands["Sync"] = WOTLKEPGP.SlashCommands["sync"]
WOTLKEPGP.SlashCommands["SYNC"] = WOTLKEPGP.SlashCommands["sync"]

WOTLKEPGP.SlashCommands["Add"] = WOTLKEPGP.SlashCommands["add"]
WOTLKEPGP.SlashCommands["ADD"] = WOTLKEPGP.SlashCommands["add"]

WOTLKEPGP.SlashCommands["Show"] = WOTLKEPGP.SlashCommands["show"]
WOTLKEPGP.SlashCommands["SHOW"] = WOTLKEPGP.SlashCommands["show"]

WOTLKEPGP.SlashCommands["Loot"] = WOTLKEPGP.SlashCommands["loot"]
WOTLKEPGP.SlashCommands["LOOT"] = WOTLKEPGP.SlashCommands["loot"]

WOTLKEPGP.SlashCommands["ReCalc"] = WOTLKEPGP.SlashCommands["recalc"]
WOTLKEPGP.SlashCommands["RECALC"] = WOTLKEPGP.SlashCommands["recalc"]