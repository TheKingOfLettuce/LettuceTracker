local _, LettuceTrackerNS = ...

LettuceTrackerNS.Tooltip = {}

function LettuceTrackerNS.Tooltip:Initialize()
    if not GameTooltip:HasScript("OnTooltipSetUnit") then
        -- Retail-based clients (WoW Forever) replaced the tooltip scripts with data processors
        self:InitializeDataProcessors()
        return
    end

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

function LettuceTrackerNS.Tooltip:InitializeDataProcessors()
    if not TooltipDataProcessor or not Enum.TooltipDataType then
        return
    end

    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
        if tooltip ~= GameTooltip then
            return
        end

        if not LettuceTrackerCharacterDB.SettingsWindow.TrackKills then
            return
        end

        if not LettuceTrackerCharacterDB.SettingsWindow.KillsTooltip then
            return
        end

        local npcId = LettuceTrackerNS.GetNpcIdFromGuid(data and data.guid)
        if npcId then
            self:AddKillsLine(tooltip, npcId)
        end
    end)

    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then
            return
        end

        if not LettuceTrackerCharacterDB.SettingsWindow.TrackLoot then
            return
        end

        if not LettuceTrackerCharacterDB.SettingsWindow.LootTooltip then
            return
        end

        local itemId = data and data.id
        if itemId and not LettuceTrackerNS.IsSecret(itemId) then
            self:AddLootLine(tooltip, itemId)
        end
    end)
end

function LettuceTrackerNS.Tooltip:AddKillsLine(tooltip, npcId)
    local characterCount, accountCount = LettuceTrackerNS.Tooltip:GetKillCounts(npcId)

    tooltip:AddLine("Kills: " .. characterCount .. " | " .. accountCount, 0.4, 1, 0.4)
end

function LettuceTrackerNS.Tooltip:AddLootLine(tooltip, itemId)
    local characterCount, accountCount = LettuceTrackerNS.Tooltip:GetItemCounts(itemId)

    tooltip:AddLine("Looted: " .. characterCount .. " | " .. accountCount, 0.4, 1, 0.4)
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

    self:AddKillsLine(tooltip, npcId)
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

    self:AddLootLine(tooltip, itemId)
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
    local characterStat = LettuceTrackerCharacterDB.Loot.Items[itemID]
    local accountStat = LettuceTrackerDB.Loot.Items[itemID]

    local characterCount = 0
    if characterStat then
        characterCount = characterStat.ItemCount
    end
    local accountCount = 0
    if accountStat then
        accountCount = accountStat.ItemCount
    end

    return characterCount, accountCount
end