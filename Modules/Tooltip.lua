local _, LettuceTrackerNS = ...

LettuceTrackerNS.Tooltip = {}

function LettuceTrackerNS.Tooltip:Initialize()
    GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
        self:OnTooltipSetUnit(tooltip)
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