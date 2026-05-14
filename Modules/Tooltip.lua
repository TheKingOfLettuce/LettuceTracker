local _, LettuceTrackerNS = ...

LettuceTrackerNS.Tooltip = {}

function LettuceTrackerNS.Tooltip:Initialize()
    GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
        if not LettuceTrackerCharacterDB.SettingsWindow.TrackKills then
            return
        end

        if not LettuceTrackerCharacterDB.SettingsWindow.KillsTooltip then
            return
        end
        self:OnTooltipSetUnit(tooltip)
    end)

    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
        if not LettuceTrackerCharacterDB.SettingsWindow.TrackLoot then
            return
        end

        if not LettuceTrackerCharacterDB.SettingsWindow.LootTooltip then
            return
        end
        self:OnTooltipSetItem(tooltip)
    end)

    ItemRefTooltip:HookScript("OnTooltipSetItem", function(tooltip)
        if not LettuceTrackerCharacterDB.SettingsWindow.TrackLoot then
            return
        end

        if not LettuceTrackerCharacterDB.SettingsWindow.LootTooltip then
            return
        end
        self:OnTooltipSetItem(tooltip)
    end)
end

function LettuceTrackerNS.Tooltip:OnTooltipSetUnit(tooltip)
    local _, unit = tooltip:GetUnit()

    if not unit then
        return
    end

    local npcId = LettuceTrackerNS.GetNpcIdFromGuid(UnitGUID(unit))

    if not npcId then
        return
    end

    local characterCount, accountCount = LettuceTrackerNS.Tooltip:GetKillCounts(npcId)

    tooltip:AddLine("Kills: " .. characterCount .. " | " .. accountCount, 0.4, 1, 0.4)
    tooltip:Show()
end

function LettuceTrackerNS.Tooltip:OnTooltipSetItem(tooltip)
    local _, itemLink = tooltip:GetItem()

    if not itemLink then
        return
    end

    local itemId = C_Item.GetItemInfoInstant(itemLink)

    if not itemId then
        return
    end

    local characterCount, accountCount = LettuceTrackerNS.Tooltip:GetItemCounts(itemId)

    tooltip:AddLine("Looted: " .. characterCount .. " | " .. accountCount, 0.4, 1, 0.4)
    tooltip:Show()
end

function LettuceTrackerNS.Tooltip:GetKillCounts(npcID)
    local characterStat = LettuceTrackerCharacterDB.Kills.NPCs[npcID]
    local accountStat = LettuceTrackerDB.Kills.NPCs[npcID]

    local characterCount = 0
    if characterStat then
        characterCount = characterStat.KillCount
    end
    local accountCount = 0
    if accountStat then
        accountCount = accountStat.KillCount
    end

    return characterCount, accountCount
end

function LettuceTrackerNS.Tooltip:GetItemCounts(itemID)
    local characterCount = LettuceTrackerCharacterDB.Loot.Items[itemID] or 0
    local accountCount = LettuceTrackerDB.Loot.Items[itemID] or 0

    return characterCount, accountCount
end