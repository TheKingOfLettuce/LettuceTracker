local _, LettuceTrackerNS = ...

LettuceTrackerNS.Kills = {}

function LettuceTrackerNS.Kills:Initialize()
    LettuceTrackerNS:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", LettuceTrackerNS.Kills, LettuceTrackerNS.Kills.OnCombatLogEvent)
end

local function GetNpcIdFromGuid(guid)
    if not guid then
        return nil
    end

    local unitType, _, _, _, _, npcId = strsplit("-", guid)

    if unitType ~= "Creature" and unitType ~= "Vehicle" then
        return nil
    end

    return tonumber(npcId)
end

function LettuceTrackerNS.Kills:OnCombatLogEvent()
    local _, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _ =
        CombatLogGetCurrentEventInfo()

    if subevent ~= "PARTY_KILL" then
        return
    end

    -- TODO PartyKills option
    -- if sourceGUID ~= UnitGUID("player") then
    --     return
    -- end

    local npcID = GetNpcIdFromGuid(destGUID)
    if not npcID then
        return
    end

    LettuceTrackerNS.DB:AddKill(npcID)
end