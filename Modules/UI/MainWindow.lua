local _, LettuceTrackerNS = ...

LettuceTrackerNS.UI = {}

local _frame

function ns.UI:Create()
    if _frame then return _frame end

    _frame = CreateFrame("Frame", "LettueStatsFrame", UIParent, "BasicFrameTemplateWithInset")
    _frame:SetSize(300, 400)
    _frame:SetPoint("CENTER")

    _frame:SetMovable(true)
    _frame:EnableMouse(true)
    _frame:RegisterForDrag("LeftButton")
    _frame:SetScript("OnDragStart", _frame.StartMoving)
    _frame:SetScript("OnDragStop", _frame.StopMovingOrSizing)

    _frame.title = _frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    _frame.title:SetPoint("TOP", 0, -5)
    _frame.title:SetText("Lettuce Stats")

    _frame.rows = {}

    

    _frame:Hide()

    return _frame
end

function LettuceTrackerNS.UI:CreateRow(index)
    local row = _frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")

    row:SetPoint("TOPLEFT", _frame, "TOPLEFT", 16, -40 - ((index - 1) * 18))
    row:SetJustifyH("LEFT")
    row:SetWidth(260)

    row:Hide()

    _frame.rows[index] = row
end

function ns.UI:Toggle()
    local f = self:Create()

    if f:IsShown() then
        f:Hide()
    else
        self:Refresh()
        f:Show()
    end
end