local _, LettuceTrackerNS = ...

LettuceTrackerNS.GoldWindow = {}

local _frame
local _totalGoldRow
local _lootedGoldRow
local _soldGoldRow
local _mailGoldRow
local _questGoldRow
local _otherGoldRow

local function CreateStatRow(parent, previousRow)
    local row = CreateFrame("Frame", nil, parent)

    row:SetSize(200, 18)

    if previousRow then
        row:SetPoint("TOPLEFT", previousRow, "BOTTOMLEFT", 0, -4)
    else
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -40)
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


local function SaveWindowState(frame)
    LettuceTrackerCharacterDB.GoldWindow = LettuceTrackerCharacterDB.GoldWindow or {}

    LettuceTrackerCharacterDB.GoldWindow.Shown = frame:IsShown()
    LettuceTrackerCharacterDB.GoldWindow.Width = frame:GetWidth()
    LettuceTrackerCharacterDB.GoldWindow.Height = frame:GetHeight()

    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()

    LettuceTrackerCharacterDB.GoldWindow.Point = point
    LettuceTrackerCharacterDB.GoldWindow.RelativePoint = relativePoint
    LettuceTrackerCharacterDB.GoldWindow.X = xOfs
    LettuceTrackerCharacterDB.GoldWindow.Y = yOfs
end

local function RestoreWindowState(frame)
    local ui = LettuceTrackerCharacterDB.GoldWindow
    frame:ClearAllPoints()
    frame:SetSize(ui.Width or 300, ui.Height or 400)
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

function LettuceTrackerNS.GoldWindow:Create()
    if _frame then return _frame end

    _frame = CreateFrame("Frame", "LettuceGoldStatsFrame", UIParent)
    if LettuceTrackerCharacterDB.GoldWindow then
        RestoreWindowState(_frame)
    else
        _frame:SetSize(200, 180)
        _frame:SetPoint("CENTER")
    end

    _frame:SetResizable(true)
    _frame:SetResizeBounds(200, 180, 600, 180)

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
    _frame.title:SetText("Lettuce Gold Stats")
    _frame.bg = _frame:CreateTexture(nil, "BACKGROUND")
    _frame.bg:SetAllPoints()
    _frame.bg:SetColorTexture(0, 0, 0, 0.4)

    self:CreateResizeButton()
    CreateCloseButton(_frame)

    _lootedGoldRow = CreateStatRow(_frame, nil)
    _soldGoldRow = CreateStatRow(_frame, _lootedGoldRow)
    _mailGoldRow = CreateStatRow(_frame, _soldGoldRow)
    _questGoldRow = CreateStatRow(_frame, _mailGoldRow)
    _otherGoldRow = CreateStatRow(_frame, _questGoldRow)
    _totalGoldRow = CreateStatRow(_frame, _otherGoldRow)

    if LettuceTrackerCharacterDB.GoldWindow then
        if LettuceTrackerCharacterDB.GoldWindow.Shown then
            self:Show()
        else
            self:Hide()
        end
    else
        self:Hide()
    end

    return _frame
end

function LettuceTrackerNS.GoldWindow:CreateResizeButton()
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

function LettuceTrackerNS.GoldWindow:Toggle()
    if _frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function LettuceTrackerNS.GoldWindow:Show()
    self:RefreshLootedGold()
    self:RefreshSoldGold()
    self:RefreshMailGold()
    self:RefreshQuestGold()
    self:RefreshOtherGold()
    _frame:Show()
    self:RefreshTotalGold() -- purposefully after show, so that we can bypass our optimization
    SaveWindowState(_frame)
end

function LettuceTrackerNS.GoldWindow.Hide()
    if not _frame then
        return
    end

    _frame:Hide()
    SaveWindowState(_frame)
end

function LettuceTrackerNS.GoldWindow:RefreshEverything()
    if not _frame:IsShown() then
        return
    end

    self:RefreshLootedGold()
    self:RefreshSoldGold()
    self:RefreshMailGold()
    self:RefreshQuestGold()
    self:RefreshOtherGold()
    self:RefreshTotalGold()
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

function LettuceTrackerNS.GoldWindow:RefreshTotalGold()
    if not _frame or not _frame:IsShown() then
        return
    end

    local table = GetSelectedViewTable()

    _totalGoldRow.Label:SetText("Total Gold:")
    _totalGoldRow.Value:SetText(C_CurrencyInfo.GetCoinTextureString(table.Gold.Total))
end

function LettuceTrackerNS.GoldWindow:RefreshLootedGold()
    if not _frame then
        return
    end

    local table = GetSelectedViewTable()

    _lootedGoldRow.Label:SetText("Looted Gold:")
    _lootedGoldRow.Value:SetText(C_CurrencyInfo.GetCoinTextureString(table.Gold.Looted))
end

function LettuceTrackerNS.GoldWindow:RefreshSoldGold()
    if not _frame then
        return
    end

    local table = GetSelectedViewTable()

    _soldGoldRow.Label:SetText("Vendor Gold:")
    _soldGoldRow.Value:SetText(C_CurrencyInfo.GetCoinTextureString(table.Gold.Sold))
end

function LettuceTrackerNS.GoldWindow:RefreshMailGold()
    if not _frame then
        return
    end

    local table = GetSelectedViewTable()

    _mailGoldRow.Label:SetText("Mail Gold:")
    _mailGoldRow.Value:SetText(C_CurrencyInfo.GetCoinTextureString(table.Gold.Mail))
end

function LettuceTrackerNS.GoldWindow:RefreshQuestGold()
    if not _frame then
        return
    end

    local table = GetSelectedViewTable()

    _questGoldRow.Label:SetText("Quest Gold:")
    _questGoldRow.Value:SetText(C_CurrencyInfo.GetCoinTextureString(table.Gold.Quests))
end

function LettuceTrackerNS.GoldWindow:RefreshOtherGold()
    if not _frame then
        return
    end

    local table = GetSelectedViewTable()

    _otherGoldRow.Label:SetText("Other Gold:")
    _otherGoldRow.Value:SetText(C_CurrencyInfo.GetCoinTextureString(table.Gold.Other))
end

local _sourceRowMap = {
    Looted = LettuceTrackerNS.GoldWindow.RefreshLootedGold,
    Sold = LettuceTrackerNS.GoldWindow.RefreshSoldGold,
    Mail = LettuceTrackerNS.GoldWindow.RefreshMailGold,
    Quests = LettuceTrackerNS.GoldWindow.RefreshQuestGold,
    Other = LettuceTrackerNS.GoldWindow.RefreshOtherGold
}

function LettuceTrackerNS.GoldWindow:RefreshSource(source)
    if not _frame or not _frame:IsShown() then
        return
    end

    local rowRefresh = _sourceRowMap[source]
    if not rowRefresh then
        return
    end

    rowRefresh(LettuceTrackerNS.GoldWindow)
end