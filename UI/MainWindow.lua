local _, LettuceTrackerNS = ...

LettuceTrackerNS.MainWindow = {}

local _frame
local _totalGoldRow
local _totalKillsRow
local _totalItemsRow
local _sessionTime
local _showGoldWindow
local _showKillsWindow
local _showLootWindow
local _viewDropDown
local _sessionResetButton

local _sessionTicker
local _sessionSeconds = 0

local function CreateSimpleDropdown(parent, width, items, default, onSelect)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")

    UIDropDownMenu_SetWidth(dropdown, width)

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()

        for _, value in ipairs(items) do
            info.text = value
            info.value = value
            info.checked = false
            info.isNotRadio = false
            info.func = function(self)
                UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                UIDropDownMenu_SetText(dropdown, self.value)

                if onSelect then
                    onSelect(self.value)
                end
            end

            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetSelectedValue(dropdown, default)
    UIDropDownMenu_SetText(dropdown, default)

    return dropdown
end

local function CreateStatRow(parent, previousRow)
    local row = CreateFrame("Frame", nil, parent)

    row:SetSize(200, 18)

    if previousRow then
        row:SetPoint("TOPLEFT", previousRow, "BOTTOMLEFT", 0, -4)
    else
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -60)
    end

    row:SetPoint("LEFT", parent, "LEFT", 8, 0)
    row:SetPoint("RIGHT", parent, "RIGHT", -8, 0)

    row.Label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.Label:SetPoint("LEFT", row, "LEFT", -10, 0)
    row.Label:SetJustifyH("LEFT")

    row.Value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.Value:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.Value:SetJustifyH("RIGHT")

    row.Label:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    row.Value:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

    return row
end

local function CreateSettingsButton(parent)
    local button = CreateFrame("Button", nil, parent)

    button:SetSize(18, 18)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -3)

    button.texture = button:CreateTexture(nil, "ARTWORK")
    button.texture:SetAllPoints()
    button.texture:SetTexture("Interface\\Buttons\\UI-OptionsButton")

    button:SetScript("OnEnter", function()
        button.texture:SetVertexColor(1, 0.8, 0.2)
    end)

    button:SetScript("OnLeave", function()
        button.texture:SetVertexColor(1, 1, 1)
    end)

    button:SetScript("OnClick", function()
        LettuceTrackerNS.SettingsWindow:Toggle()
    end)

    return button
end

local function CreateSessionResetButton(parent)
    local button = CreateFrame("Button", nil, parent)

    button:SetSize(16, 16)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -33)

    button.texture = button:CreateTexture(nil, "ARTWORK")
    button.texture:SetAllPoints()
    button.texture:SetTexture("Interface\\Buttons\\UI-RefreshButton")

    button:SetScript("OnEnter", function()
        button.texture:SetVertexColor(1, 0.8, 0.2)
    end)

    button:SetScript("OnLeave", function()
        button.texture:SetVertexColor(1, 1, 1)
    end)

    button:SetScript("OnClick", function()
        LettuceTrackerNS.DB:ResetSessionDB()
        _sessionSeconds = 0
        LettuceTrackerNS.MainWindow:RefreshEverything()
    end)

    return button
end


local function SaveWindowState(frame)
    LettuceTrackerCharacterDB.MainWindow = LettuceTrackerCharacterDB.MainWindow or {}

    LettuceTrackerCharacterDB.MainWindow.Shown = frame:IsShown()
    LettuceTrackerCharacterDB.MainWindow.Width = frame:GetWidth()
    LettuceTrackerCharacterDB.MainWindow.Height = frame:GetHeight()

    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()

    LettuceTrackerCharacterDB.MainWindow.Point = point
    LettuceTrackerCharacterDB.MainWindow.RelativePoint = relativePoint
    LettuceTrackerCharacterDB.MainWindow.X = xOfs
    LettuceTrackerCharacterDB.MainWindow.Y = yOfs
end

local function RestoreWindowState(frame)
    local ui = LettuceTrackerCharacterDB.MainWindow
    frame:ClearAllPoints()
    frame:SetSize(ui.Width or 300, ui.Height or 200)
    frame:SetPoint(ui.Point or "CENTER", UIParent, ui.RelativePoint or ui.Point or "CENTER", ui.X or 0, ui.Y or 0)
end

local function CreateCloseButton(parent)
    local button = CreateFrame("Button", nil, parent, "UIPanelCloseButton")

    button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 2, 2)
    button:SetScript("OnClick", function()
        parent:Hide()
        SaveWindowState(parent)
    end)

    return button
end

function LettuceTrackerNS.MainWindow:Create()
    if _frame then return _frame end

    _frame = CreateFrame("Frame", "LettuceStatsFrame", UIParent)
    if LettuceTrackerCharacterDB.MainWindow then
        RestoreWindowState(_frame)
    else
        _frame:SetSize(200, 180)
        _frame:SetPoint("CENTER")
    end

    _frame:SetResizable(true)
    _frame:SetResizeBounds(200, 180, 600, 200)

    _frame:SetMovable(true)
    _frame:EnableMouse(true)
    _frame:RegisterForDrag("LeftButton")
    _frame:SetScript("OnDragStart", _frame.StartMoving)
    _frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveWindowState(self)
    end)
    _frame:SetToplevel(true)

    _frame.title = _frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    _frame.title:SetPoint("TOP", 0, -5)
    _frame.title:SetText("Lettuce Tracker")
    _frame.bg = _frame:CreateTexture(nil, "BACKGROUND")
    _frame.bg:SetAllPoints()
    _frame.bg:SetColorTexture(0, 0, 0, 0.4)

    self:CreateResizeButton()
    CreateCloseButton(_frame)
    CreateSettingsButton(_frame)
    _sessionResetButton = CreateSessionResetButton(_frame)
    if LettuceTrackerCharacterDB.SettingsWindow.SelectView == "Session" then
        _sessionResetButton:Show()
    else
        _sessionResetButton:Hide()
    end

    _totalGoldRow = CreateStatRow(_frame, nil)
    _totalGoldRow.Label:SetText("Total Gold:")

    _totalKillsRow = CreateStatRow(_frame, _totalGoldRow)
    _totalKillsRow.Label:SetText("Total Kills:")

    _totalItemsRow = CreateStatRow(_frame, _totalKillsRow)
    _totalItemsRow.Label:SetText("Total Items:")

    _sessionTime = CreateStatRow(_frame, _totalItemsRow)
    _sessionTime.Label:SetText("Session Time:")

    _sessionTicker = C_Timer.NewTicker(1, function()
        _sessionSeconds = _sessionSeconds + 1
        self:RefreshSessionTime()
    end)

    self:CreateButtons()
    self:CreateDropdown()

    if LettuceTrackerCharacterDB.MainWindow then
        if LettuceTrackerCharacterDB.MainWindow.Shown then
            self:Show()
        else
            self:Hide()
        end
    else
        self:Hide()
    end

    return _frame
end

function LettuceTrackerNS.MainWindow:CreateResizeButton()
    _frame.resizeButton = CreateFrame("Button", nil, _frame)
    _frame.resizeButton:SetSize(16, 16)
    _frame.resizeButton:SetPoint("BOTTOMRIGHT", _frame, "BOTTOMRIGHT", -2, 2)

    _frame.resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    _frame.resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    _frame.resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    _frame.resizeButton:SetScript("OnMouseDown", function()
        _frame:StartSizing("BOTTOMRIGHT")
    end)

    _frame.resizeButton:SetScript("OnMouseUp", function()
        _frame:StopMovingOrSizing()
        SaveWindowState(_frame)
    end)
end

function LettuceTrackerNS.MainWindow:Toggle()
    if _frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function LettuceTrackerNS.MainWindow:Show()
    self:RefreshTotalGold()
    self:RefreshTotalKills()
    self:RefreshTotalItems()
    self:RefreshSessionTime()
    _frame:Show()
    SaveWindowState(_frame)
end

function LettuceTrackerNS.MainWindow.Hide()
    _frame:Hide()
    SaveWindowState(_frame)
end

function LettuceTrackerNS.MainWindow:RefreshEverything()
    if not _frame:IsShown() then
        return
    end

    self:RefreshTotalGold()
    self:RefreshTotalKills()
    self:RefreshTotalItems()
    self:RefreshSessionTime()
end

local function GetSelectedViewTable()
    local view = LettuceTrackerCharacterDB.SettingsWindow.SelectView
    if view == "Account" then
        return LettuceTrackerDB
    elseif view == "Session" then
        return LettuceTrackerNS.DB.SessionDB
    else
        return LettuceTrackerCharacterDB
    end
end

function LettuceTrackerNS.MainWindow:RefreshTotalGold()
    if not _frame then
        return
    end

    local table = GetSelectedViewTable()
    
    if LettuceTrackerCharacterDB.SettingsWindow.TrackGold then
        _totalGoldRow.Value:SetText(C_CurrencyInfo.GetCoinTextureString(table.Gold.Total))
    else
        _totalGoldRow.Value:SetText("N/A")
    end
    
end

function LettuceTrackerNS.MainWindow:RefreshTotalKills()
    if not _frame then
        return
    end

    local table = GetSelectedViewTable()

    if LettuceTrackerCharacterDB.SettingsWindow.TrackKills then
        _totalKillsRow.Value:SetText(table.Kills.Total)
    else
        _totalKillsRow.Value:SetText("N/A")
    end
end

function LettuceTrackerNS.MainWindow:RefreshTotalItems()
    if not _frame then
        return
    end

    local table = GetSelectedViewTable()

    if LettuceTrackerCharacterDB.SettingsWindow.TrackLoot then
        _totalItemsRow.Value:SetText(table.Loot.Total)
    else
        _totalItemsRow.Value:SetText("N/A")
    end
end

function LettuceTrackerNS.MainWindow:RefreshSessionTime()
    if not _frame then
        return
    end
    if not _frame:IsShown() then
        return
    end

    local h = math.floor(_sessionSeconds / 3600)
    local m = math.floor((_sessionSeconds % 3600) / 60)
    local s = math.floor(_sessionSeconds % 60)

    _sessionTime.Value:SetText(string.format("%02d:%02d:%02d", h, m, s))
end

function LettuceTrackerNS.MainWindow:ToggleGoldButton(state)
    if state then
        _showGoldWindow:Show()
    else
        _showGoldWindow:Hide()
        LettuceTrackerNS.GoldWindow:Hide()
    end

    self:RefreshTotalGold()
end

function LettuceTrackerNS.MainWindow:ToggleKillsButton(state)
    if state then
        _showKillsWindow:Show()
    else
        _showKillsWindow:Hide()
        LettuceTrackerNS.KillWindow:Hide()
    end

    self:RefreshTotalKills()
end

function LettuceTrackerNS.MainWindow:ToggleLootButton(state)
    if state then
        _showLootWindow:Show()
        _totalItemsRow:Show()
    else
        _showLootWindow:Hide()
        LettuceTrackerNS.LootWindow:Hide()
    end

    self:RefreshTotalItems()
end

function LettuceTrackerNS.MainWindow:CreateButtons()
    local buttonContainer = CreateFrame("Frame", nil, _frame)
    buttonContainer:SetHeight(30)
    buttonContainer:SetPoint("BOTTOMLEFT", _frame, "BOTTOMLEFT", 8, 8)
    buttonContainer:SetPoint("BOTTOMRIGHT", _frame, "BOTTOMRIGHT", -8, 8)

    local buttonWidth = 60

    _showGoldWindow = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    _showGoldWindow:SetSize(buttonWidth, 22)
    _showGoldWindow:SetPoint("LEFT", buttonContainer, "LEFT", 0, 0)
    _showGoldWindow:SetText("Gold")

    _showGoldWindow:SetScript("OnClick", function()
        LettuceTrackerNS.GoldWindow:Toggle()
    end)
    self:ToggleGoldButton(LettuceTrackerCharacterDB.SettingsWindow.TrackGold)

    _showKillsWindow = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    _showKillsWindow:SetSize(buttonWidth, 22)
    _showKillsWindow:SetPoint("CENTER", buttonContainer, "CENTER", 0, 0)
    _showKillsWindow:SetText("Kills")

    _showKillsWindow:SetScript("OnClick", function()
        LettuceTrackerNS.KillWindow:Toggle()
    end)
    self:ToggleKillsButton(LettuceTrackerCharacterDB.SettingsWindow.TrackKills)

    _showLootWindow = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    _showLootWindow:SetSize(buttonWidth, 22)
    _showLootWindow:SetPoint("RIGHT", buttonContainer, "RIGHT", 0, 0)
    _showLootWindow:SetText("Loot")

    _showLootWindow:SetScript("OnClick", function()
        LettuceTrackerNS.LootWindow:Toggle()
    end)
    self:ToggleLootButton(LettuceTrackerCharacterDB.SettingsWindow.TrackLoot)
end

function LettuceTrackerNS.MainWindow:CreateDropdown()
    _viewDropDown = CreateSimpleDropdown(_frame, 120, {"Character", "Account", "Session"}, LettuceTrackerCharacterDB.SettingsWindow.SelectView, function(value)
        LettuceTrackerCharacterDB.SettingsWindow.SelectView = value

        if value == "Session" then
            _sessionResetButton:Show()
        else
            _sessionResetButton:Hide()
        end

        LettuceTrackerNS.MainWindow:RefreshEverything()
        LettuceTrackerNS.GoldWindow:RefreshEverything()
        LettuceTrackerNS.KillWindow:RefreshTable()
        LettuceTrackerNS.LootWindow:RefreshTable()
    end) 
    _viewDropDown:SetPoint("TOP", _frame, "TOP", 0, -25)
end