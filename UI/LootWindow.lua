local _, LettuceTrackerNS = ...

local ROW_HEIGHT = 32
local TABLE_WIDTH = 340
local TABLE_HEIGHT = 346

LettuceTrackerNS.LootWindow = {}
LettuceTrackerNS.LootWindow.Rows = {}
LettuceTrackerNS.LootWindow.DisplayData = {}

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

function LettuceTrackerNS.LootWindow:BuildDisplayData()
    wipe(self.DisplayData)

    local statTable = GetSelectedViewTable()

    for itemID, lootStat in pairs(statTable.Loot.Items or {}) do
        local itemName, _, quality, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemID)
        if itemName then
            table.insert(self.DisplayData, {
                ItemID = itemID,
                Name = itemName,
                Count = lootStat,
                Quality = quality,
                ItemIcon = itemTexture
            })
        end
    end

    table.sort(self.DisplayData, function(a, b)
        if a.Quality ~= b.Quality then
            return a.Quality > b.Quality
        end

        if a.Count ~= b.Count then
            return a.Count > b.Count
        end

        return a.Name < b.Name
    end)
end

function LettuceTrackerNS.LootWindow:Create()
    local frame = CreateFrame("Frame", "LettuceStatLootWindow", UIParent, "BasicFrameTemplateWithInset")
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
    header.Name:SetText("Item")

    header.Kills = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header.Kills:SetPoint("RIGHT", -28, 0)
    header.Kills:SetText("Count")

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "LettuceTrackerLootScrollFrame", frame, "HybridScrollFrameTemplate")
    scrollFrame:SetSize(TABLE_WIDTH-24, TABLE_HEIGHT-26)
    scrollFrame:SetPoint("TOPLEFT", 0, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -24, 8)

    local scrollBar = CreateFrame("Slider", "LettuceTrackerLootScrollBar", scrollFrame, "HybridScrollBarTemplate")
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 1, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 1, 16)

    HybridScrollFrame_CreateButtons(scrollFrame, "LettuceTrackerLootFrameButtons", 0, 0, "TOP", "TOP", 0, 0, "TOP", "BOTTOM")

    self.Frame = frame
    self.ScrollFrame = scrollFrame

    scrollFrame.update = function()
        LettuceTrackerNS.LootWindow:Refresh()
    end

    frame:Hide()
end

function LettuceTrackerNS.LootWindow:Toggle()
    if self.Frame:IsShown() then
        self.Frame:Hide()
    else
        self:BuildDisplayData()
        LettuceTrackerNS.LootWindow:Refresh()
        self.Frame:Show()
    end
end

function LettuceTrackerNS.LootWindow:Hide()
    if not self.Frame or not self.Frame:IsShown() then
        return
    end

    self.Frame:Hide()
end

function LettuceTrackerNS.LootWindow:RefreshTable()
    if not self.Frame or not self.Frame:IsShown() then
        return
    end

    self:BuildDisplayData()
    self:Refresh()
end

function LettuceTrackerNS.LootWindow:Refresh()
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
            local color = ITEM_QUALITY_COLORS[item.Quality or 1]
            button.NameText:SetTextColor(color.r, color.g, color.b)
            button.CountText:SetText(item.Count)
            button.Icon:SetTexture(item.ItemIcon)
            button:Show()
        else
            button:Hide()
        end
    end

    local totalHeight = #data * ROW_HEIGHT

    HybridScrollFrame_Update(scrollFrame, totalHeight, scrollFrame:GetHeight())
end