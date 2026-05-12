local _, LettuceTrackerNS = ...

LettuceTrackerNS.UI = {}

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
    LettuceTrackerDB.UI = LettuceTrackerDB.UI or {}

    LettuceTrackerDB.UI.Shown = frame:IsShown()
    LettuceTrackerDB.UI.Width = frame:GetWidth()
    LettuceTrackerDB.UI.Height = frame:GetHeight()

    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()

    LettuceTrackerDB.UI.Point = point
    LettuceTrackerDB.UI.RelativePoint = relativePoint
    LettuceTrackerDB.UI.X = xOfs
    LettuceTrackerDB.UI.Y = yOfs
end

local function RestoreWindowState(frame)
    local ui = LettuceTrackerDB.UI
    frame:ClearAllPoints()
    frame:SetSize(ui.Width or 300, ui.Height or 400)
    frame:SetPoint(ui.Point or "CENTER", UIParent, ui.RelativePoint or ui.Point or "CENTER", ui.X or 0, ui.Y or 0)
end

function LettuceTrackerNS.UI:Create()
    if _frame then return _frame end

    _frame = CreateFrame("Frame", "LettueStatsFrame", UIParent)
    if LettuceTrackerDB.UI then
        RestoreWindowState(_frame)
    else
        _frame:SetSize(200, 120)
        _frame:SetPoint("CENTER")
    end

    _frame:SetResizable(true)
    _frame:SetResizeBounds(200, 120, 600, 800)

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

    _frame.rows = {}

    _totalGoldRow = CreateStatRow(_frame, nil)
    _totalKillsRow = CreateStatRow(_frame, _totalGoldRow)
    _totalItemsRow = CreateStatRow(_frame, _totalKillsRow)

    if LettuceTrackerDB.UI then
        if LettuceTrackerDB.UI.Shown then
            self:Show()
        else
            self:Hide()
        end
    else
        self:Hide()
    end

    return _frame
end

function LettuceTrackerNS.UI:CreateResizeButton()
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

function LettuceTrackerNS.UI:CreateRow(index)
    local row = _frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")

    row:SetPoint("LEFT", _frame, "LEFT", 12, 0)
    row:SetPoint("RIGHT", _frame, "RIGHT", -12, 0)
    row:SetJustifyH("LEFT")
    row:SetWidth(260)

    row:Hide()

    _frame.rows[index] = row
end


function LettuceTrackerNS.UI:Toggle()
    if _frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function LettuceTrackerNS.UI:Show()
    self:RefreshTotalGold()
    self:RefreshTotalKills()
    self:RefreshTotalItems()
    _frame:Show()
    SaveWindowState(_frame)
end

function LettuceTrackerNS.UI.Hide()
    _frame:Hide()
    SaveWindowState(_frame)
end

function LettuceTrackerNS.UI:RefreshTotalGold()
    if not _frame then
        return
    end

    local table = LettuceTrackerNS.DB:GetCharacter()

    _totalGoldRow.Label:SetText("Total Gold:")
    _totalGoldRow.Value:SetText(C_CurrencyInfo.GetCoinTextureString(table.Gold.Total))
end

function LettuceTrackerNS.UI:RefreshTotalKills()
    if not _frame then
        return
    end

    local table = LettuceTrackerNS.DB:GetCharacter()

    _totalKillsRow.Label:SetText("Total Kills:")
    _totalKillsRow.Value:SetText(table.Kills.Total)
end

function LettuceTrackerNS.UI:RefreshTotalItems()
    if not _frame then
        return
    end

    local table = LettuceTrackerNS.DB:GetCharacter()

    _totalItemsRow.Label:SetText("Total Items:")
    _totalItemsRow.Value:SetText(table.Loot.Total)
end
