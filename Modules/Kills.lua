local _, LettuceTrackerNS = ...

LettuceTrackerNS.Kills = {}

function LettuceTrackerNS.Kills:Initialize()
    LettuceTrackerNS:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", LettuceTrackerNS.Kills, LettuceTrackerNS.Kills.OnCombatLogEvent)
end

function LettuceTrackerNS.GetNpcIdFromGuid(guid)
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
    if not LettuceTrackerCharacterDB.SettingsWindow.TrackKills then
        return
    end

    local _, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _ =
        CombatLogGetCurrentEventInfo()

    if subevent ~= "PARTY_KILL" then
        return
    end

    if not LettuceTrackerCharacterDB.SettingsWindow.PartyKills then
        local playerGUID = LettuceTrackerNS.PlayerGUID
        local petGUID = UnitGUID("pet")
        if sourceGUID ~= playerGUID and sourceGUID ~= petGUID then
            return
        end
    end

    local npcID = LettuceTrackerNS.GetNpcIdFromGuid(destGUID)
    if not npcID then
        return
    end
    local zoneName = GetZoneText()
    local areaName = GetSubZoneText()
    local location = zoneName
    if areaName ~= "" then
        location = location .. ", " .. areaName
    end

    LettuceTrackerNS.DB:AddKill(npcID, destName, location)
end