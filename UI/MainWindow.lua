local _, LettuceTrackerNS = ...

LettuceTrackerNS.MainWindow = {}

local _frame
local _totalGoldRow
local _totalKillsRow
local _totalItemsRow

local function CreateStatRow(parent, previousRow)
    local row = CreateFrame("Frame", nil, parent)

    row:SetSize(200, 18)

    if previousRow then
        row:SetPoint("TOPLEFT", previousRow, "BOTTOMLEFT", 0, -4)
    else
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -40)
    end

    row:SetPoint("LEFT", parent, "LEFT", 12, 0)
    row:SetPoint("RIGHT", parent, "RIGHT", -12, 0)

    row.Label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.Label:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.Label:SetJustifyH("LEFT")

    row.Value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.Value:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.Value:SetJustifyH("RIGHT")

    row.Label:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.Value:SetPoint("RIGHT", row, "RIGHT", 0, 0)

    row.Label:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    row.Value:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

    return row
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
    frame:SetSize(ui.Width or 300, ui.Height or 400)
    frame:SetPoint(ui.Point or "CENTER", UIParent, ui.RelativePoint or ui.Point or "CENTER", ui.X or 0, ui.Y or 0)
end

function LettuceTrackerNS.MainWindow:Create()
    if _frame then return _frame end

    _frame = CreateFrame("Frame", "LettuceStatsFrame", UIParent)
    if LettuceTrackerCharacterDB.MainWindow then
        RestoreWindowState(_frame)
    else
        _frame:SetSize(200, 150)
        _frame:SetPoint("CENTER")
    end

    _frame:SetResizable(true)
    _frame:SetResizeBounds(200, 150, 600, 800)

    _frame:SetMovable(true)
    _frame:EnableMouse(true)
    _frame:RegisterForDrag("LeftButton")
    _frame:SetScript("OnDragStart", _frame.StartMoving)
    _frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveWindowState(self)
    end)

    _frame.title = _frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    _frame.title:SetPoint("TOP", 0, -5)
    _frame.title:SetText("Lettuce Stats")
    _frame.bg = _frame:CreateTexture(nil, "BACKGROUND")
    _frame.bg:SetAllPoints()
    _frame.bg:SetColorTexture(0, 0, 0, 0.4)

    self:CreateResizeButton()
    self:CreateButtons()

    _frame.rows = {}

    _totalGoldRow = CreateStatRow(_frame, nil)
    _totalKillsRow = CreateStatRow(_frame, _totalGoldRow)
    _totalItemsRow = CreateStatRow(_frame, _totalKillsRow)

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
    _frame:Show()
    SaveWindowState(_frame)
end

function LettuceTrackerNS.MainWindow.Hide()
    _frame:Hide()
    SaveWindowState(_frame)
end

function LettuceTrackerNS.MainWindow:RefreshTotalGold()
    if not _frame then
        return
    end

    _totalGoldRow.Label:SetText("Total Gold:")
    _totalGoldRow.Value:SetText(C_CurrencyInfo.GetCoinTextureString(LettuceTrackerCharacterDB.Gold.Total))
end

function LettuceTrackerNS.MainWindow:RefreshTotalKills()
    if not _frame then
        return
    end

    _totalKillsRow.Label:SetText("Total Kills:")
    _totalKillsRow.Value:SetText(LettuceTrackerCharacterDB.Kills.Total)
end

function LettuceTrackerNS.MainWindow:RefreshTotalItems()
    if not _frame then
        return
    end

    _totalItemsRow.Label:SetText("Total Items:")
    _totalItemsRow.Value:SetText(LettuceTrackerCharacterDB.Loot.Total)
end

function LettuceTrackerNS.MainWindow:CreateButtons()
    local buttonContainer = CreateFrame("Frame", nil, _frame)
    buttonContainer:SetHeight(30)
    buttonContainer:SetPoint("BOTTOMLEFT", _frame, "BOTTOMLEFT", 8, 8)
    buttonContainer:SetPoint("BOTTOMRIGHT", _frame, "BOTTOMRIGHT", -8, 8)

    local buttonWidth = 60

    local leftButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    leftButton:SetSize(buttonWidth, 22)
    leftButton:SetPoint("LEFT", buttonContainer, "LEFT", 0, 0)
    leftButton:SetText("Gold")

    leftButton:SetScript("OnClick", function()
        LettuceTrackerNS.GoldWindow:Toggle()
    end)

    local centerButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    centerButton:SetSize(buttonWidth, 22)
    centerButton:SetPoint("CENTER", buttonContainer, "CENTER", 0, 0)
    centerButton:SetText("Kills")

    centerButton:SetScript("OnClick", function()
        LettuceTrackerNS.KillWindow:Toggle()
    end)

    local rightButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    rightButton:SetSize(buttonWidth, 22)
    rightButton:SetPoint("RIGHT", buttonContainer, "RIGHT", 0, 0)
    rightButton:SetText("Loot")

    rightButton:SetScript("OnClick", function()
        
    end)
end
