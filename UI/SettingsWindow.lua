local _, LettuceTrackerNS = ...

LettuceTrackerNS.SettingsWindow = {}

local _frame
local _goldTrackBox
local _killsTrackBox
local _lootTrackBox
local _killsTooltip
local _lootTooltip
local _trackPartyKills

local function CreateHorizontalCheckboxGroup(parent, labels, anchor)
    local group = CreateFrame("Frame", nil, parent)
    group:SetSize(400, 30)
    group:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -16)

    local previous
    local checkBoxes = {}

    for i, label in ipairs(labels) do
        local cb = CreateFrame("CheckButton", nil, group, "UICheckButtonTemplate")

        if not previous then
            cb:SetPoint("LEFT", 0, 0)
        else
            cb:SetPoint("LEFT", previous.text, "RIGHT", 20, 0)
        end

        cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        cb.text:SetText(label)

        previous = cb
        table.insert(checkBoxes, cb)
    end

    return group, checkBoxes
end

local function CreateCloseButton(parent)
    local button = CreateFrame("Button", nil, parent, "UIPanelCloseButton")

    button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 2, 2)

    return button
end


function LettuceTrackerNS.SettingsWindow:Create()
    if _frame then return _frame end

    LettuceTrackerCharacterDB.SettingsWindow = LettuceTrackerCharacterDB.SettingsWindow or {}

    _frame = CreateFrame("Frame", "LettuceStatsSettingsFrame", UIParent)
    _frame:SetSize(400, 180)
    _frame:SetPoint("CENTER")

    _frame:SetMovable(true)
    _frame:EnableMouse(true)
    _frame:RegisterForDrag("LeftButton")
    _frame:SetScript("OnDragStart", _frame.StartMoving)
    _frame:SetScript("OnDragStop", _frame.StopMovingOrSizing)
    _frame:SetToplevel(true)

    _frame.title = _frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    _frame.title:SetPoint("TOP", 0, -5)
    _frame.title:SetText("Lettuce Stats Settings")
    _frame.bg = _frame:CreateTexture(nil, "BACKGROUND")
    _frame.bg:SetAllPoints()
    _frame.bg:SetColorTexture(0, 0, 0, 0.7)

    local trackGroup = LettuceTrackerNS.SettingsWindow:CreateTrackerSettings(_frame.title)
    trackGroup:SetPoint("TOPLEFT", _frame.title, "BOTTOMLEFT", -125, -16) -- hack, title anchor makes the first group centered
    local tooltipGroup = LettuceTrackerNS.SettingsWindow:CreateTooltipSettings(trackGroup)
    LettuceTrackerNS.SettingsWindow:CreateMiscSettings(tooltipGroup)

    CreateCloseButton(_frame)

    self:Hide()

    return _frame
end

function LettuceTrackerNS.SettingsWindow:CreateTrackerSettings(anchor)
    local group, checkBoxes = CreateHorizontalCheckboxGroup(_frame, {"Track Gold", "Track Kills", "Track Loot"}, anchor)
    _goldTrackBox = checkBoxes[1]
    _killsTrackBox = checkBoxes[2]
    _lootTrackBox = checkBoxes[3]

    if LettuceTrackerCharacterDB.SettingsWindow.TrackGold == nil then
        LettuceTrackerCharacterDB.SettingsWindow.TrackGold = true
    end
    _goldTrackBox:SetChecked(LettuceTrackerCharacterDB.SettingsWindow.TrackGold)
    _goldTrackBox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()

        LettuceTrackerCharacterDB.SettingsWindow.TrackGold = checked
        LettuceTrackerNS.MainWindow:ToggleGoldButton(checked)
    end)

    if LettuceTrackerCharacterDB.SettingsWindow.TrackKills == nil then
        LettuceTrackerCharacterDB.SettingsWindow.TrackKills = true
    end
    _killsTrackBox:SetChecked(LettuceTrackerCharacterDB.SettingsWindow.TrackKills)
    _killsTrackBox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()

        LettuceTrackerCharacterDB.SettingsWindow.TrackKills = checked
        LettuceTrackerNS.MainWindow:ToggleKillsButton(checked)
    end)

    if LettuceTrackerCharacterDB.SettingsWindow.TrackLoot == nil then
        LettuceTrackerCharacterDB.SettingsWindow.TrackLoot = true
    end
    _lootTrackBox:SetChecked(LettuceTrackerCharacterDB.SettingsWindow.TrackLoot)
    _lootTrackBox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()

        LettuceTrackerCharacterDB.SettingsWindow.TrackLoot = checked
        LettuceTrackerNS.MainWindow:ToggleLootButton(checked)
    end)

    return group
end

function LettuceTrackerNS.SettingsWindow:CreateTooltipSettings(anchor)
    local group, checkBoxes = CreateHorizontalCheckboxGroup(_frame, {"Show Kills Tooltip", "Show Loot Tooltip"}, anchor)
    _killsTooltip = checkBoxes[1]
    _lootTooltip = checkBoxes[2]

    if LettuceTrackerCharacterDB.SettingsWindow.KillsTooltip == nil then
        LettuceTrackerCharacterDB.SettingsWindow.KillsTooltip = true
    end
    _killsTooltip:SetChecked(LettuceTrackerCharacterDB.SettingsWindow.KillsTooltip)
    _killsTooltip:SetScript("OnClick", function(self)
        local checked = self:GetChecked()

        LettuceTrackerCharacterDB.SettingsWindow.KillsTooltip = checked
    end)

    if LettuceTrackerCharacterDB.SettingsWindow.LootTooltip == nil then
        LettuceTrackerCharacterDB.SettingsWindow.LootTooltip = true
    end
    _lootTooltip:SetChecked(LettuceTrackerCharacterDB.SettingsWindow.LootTooltip)
    _lootTooltip:SetScript("OnClick", function(self)
        local checked = self:GetChecked()

        LettuceTrackerCharacterDB.SettingsWindow.LootTooltip = checked
    end)

    return group
end

function LettuceTrackerNS.SettingsWindow:CreateMiscSettings(anchor)
    local group, checkBoxes = CreateHorizontalCheckboxGroup(_frame, {"Include Party Kills"}, anchor)
    _trackPartyKills = checkBoxes[1]

    if LettuceTrackerCharacterDB.SettingsWindow.SelectView == nil then
        LettuceTrackerCharacterDB.SettingsWindow.SelectView = "Character"
    end

    if LettuceTrackerCharacterDB.SettingsWindow.PartyKills == nil then
        LettuceTrackerCharacterDB.SettingsWindow.PartyKills = true
    end
    _trackPartyKills:SetChecked(LettuceTrackerCharacterDB.SettingsWindow.PartyKills)
    _trackPartyKills:SetScript("OnClick", function(self)
        local checked = self:GetChecked()

        LettuceTrackerCharacterDB.SettingsWindow.PartyKills = checked
    end)

    return group
end


function LettuceTrackerNS.SettingsWindow:Toggle()
    if _frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function LettuceTrackerNS.SettingsWindow:Show()
    _frame:Show()
end

function LettuceTrackerNS.SettingsWindow.Hide()
    _frame:Hide()
end

