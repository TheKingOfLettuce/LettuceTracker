local _, LettuceTrackerNS = ...

local ROW_HEIGHT = 32
local TABLE_WIDTH = 300
local TABLE_HEIGHT = 346

LettuceTrackerNS.KillWindow = {}
LettuceTrackerNS.KillWindow.Rows = {}
LettuceTrackerNS.KillWindow.DisplayData = {}

function LettuceTrackerNS.KillWindow:BuildDisplayData()
    wipe(self.DisplayData)

    local statTable
    if LettuceTrackerCharacterDB.SettingsWindow.AccountStats then
        statTable = LettuceTrackerDB
    else
        statTable = LettuceTrackerCharacterDB
    end

    for npcId, killStat in pairs(statTable.Kills.NPCs or {}) do
        table.insert(self.DisplayData, {
            NpcID = npcId,
            Name = killStat.Name,
            Kills = killStat.KillCount,
        })
    end

    table.sort(self.DisplayData, function(a, b)
        return a.Kills > b.Kills
    end)
end

function LettuceTrackerNS.KillWindow:Create()
    local frame = CreateFrame("Frame", "LettuceStatKillsWindow", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(TABLE_WIDTH, TABLE_HEIGHT)
    frame:SetPoint("CENTER")

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetToplevel(true)

    -- Header
    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetHeight(24)

    header.Name = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header.Name:SetPoint("LEFT", 8, 0)
    header.Name:SetText("Enemy")

    header.Kills = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header.Kills:SetPoint("RIGHT", -28, 0)
    header.Kills:SetText("Kills")

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "LettuceTrackerKillsScrollFrame", frame, "HybridScrollFrameTemplate")
    scrollFrame:SetSize(TABLE_WIDTH-24, TABLE_HEIGHT-26)
    scrollFrame:SetPoint("TOPLEFT", 0, -26)
    scrollFrame:SetPoint("BOTTOMRIGHT", -24, 0)

    local scrollBar = CreateFrame("Slider", "LettuceTrackerKillsScrollBar", scrollFrame, "HybridScrollBarTemplate")
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 1, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 1, 16)

    HybridScrollFrame_CreateButtons(scrollFrame, "LettuceTrackerKillFrameButtons", 0, 0, "TOP", "TOP", 0, 0, "TOP", "BOTTOM")

    self.Frame = frame
    self.ScrollFrame = scrollFrame

    scrollFrame.update = function()
        LettuceTrackerNS.KillWindow:Refresh()
    end

    frame:Hide()
end

function LettuceTrackerNS.KillWindow:Toggle()
    if self.Frame:IsShown() then
        self.Frame:Hide()
    else
        self:BuildDisplayData()
        LettuceTrackerNS.KillWindow:Refresh()
        self.Frame:Show()
    end
end

function LettuceTrackerNS.KillWindow:Hide()
    if not self.Frame or not self.Frame:IsShown() then
        return
    end

    self.Frame:Hide()
end

function LettuceTrackerNS.KillWindow:RefreshTable()
    if not self.Frame or not self.Frame:IsShown() then
        return
    end

    self:BuildDisplayData()
    self:Refresh()
end

function LettuceTrackerNS.KillWindow:Refresh()
    local scrollFrame = self.ScrollFrame
    local buttons = scrollFrame.buttons
    local offset = HybridScrollFrame_GetOffset(scrollFrame)
    local data = self.DisplayData

    for i = 1, #buttons do
        local button = buttons[i]
        local dataIndex = offset + i
        local item = data[dataIndex]

        if item then
            button.NameText:SetText(item.Name)
            button.KillsText:SetText(item.Kills)
            button:Show()
        else
            button:Hide()
        end
    end

    local totalHeight = #data * ROW_HEIGHT

    HybridScrollFrame_Update(scrollFrame, totalHeight, scrollFrame:GetHeight())
end