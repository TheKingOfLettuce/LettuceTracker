local _, LettuceTrackerNS = ...

LettuceTrackerNS.Kills = {}

local UNKNOWN_NAME = "Unknown"

-- [npcID] = name, only used on clients without the combat log (see OnPartyKill)
local _npcNames = {}

function LettuceTrackerNS.Kills:Initialize()
    if CombatLogGetCurrentEventInfo then
        -- Classic clients: the combat log is readable by addons
        LettuceTrackerNS:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", LettuceTrackerNS.Kills, LettuceTrackerNS.Kills.OnCombatLogEvent)
    else
        -- Retail-based clients (WoW Forever): registering the combat log errors,
        -- PARTY_KILL is a standalone event that only carries GUIDs
        LettuceTrackerNS:RegisterEvent("PARTY_KILL", LettuceTrackerNS.Kills, LettuceTrackerNS.Kills.OnPartyKill)

        -- The event has no names, so remember the names of units we come across
        LettuceTrackerNS:RegisterEvent("PLAYER_TARGET_CHANGED", LettuceTrackerNS.Kills, function(self) self:RememberUnitName("target") end)
        LettuceTrackerNS:RegisterEvent("UPDATE_MOUSEOVER_UNIT", LettuceTrackerNS.Kills, function(self) self:RememberUnitName("mouseover") end)
        LettuceTrackerNS:RegisterEvent("NAME_PLATE_UNIT_ADDED", LettuceTrackerNS.Kills, function(self, unit) self:RememberUnitName(unit) end)
    end
end

function LettuceTrackerNS.GetNpcIdFromGuid(guid)
    if not guid or LettuceTrackerNS.IsSecret(guid) then
        return nil
    end

    local unitType, _, _, _, _, npcId = strsplit("-", guid)

    if unitType ~= "Creature" and unitType ~= "Vehicle" then
        return nil
    end

    return tonumber(npcId)
end

local function GetCurrentLocation()
    local zoneName = GetZoneText()
    local areaName = GetSubZoneText()
    local location = zoneName
    if areaName ~= "" then
        location = location .. ", " .. areaName
    end

    return location
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

    LettuceTrackerNS.DB:AddKill(npcID, destName, GetCurrentLocation())
end

function LettuceTrackerNS.Kills:RememberUnitName(unit)
    if not unit or not UnitExists(unit) then
        return
    end

    local npcID = LettuceTrackerNS.GetNpcIdFromGuid(UnitGUID(unit))
    if not npcID then
        return
    end

    local name = UnitName(unit)
    if not name or LettuceTrackerNS.IsSecret(name) or name == "" then
        return
    end

    _npcNames[npcID] = name
end

local function GetNameFromTooltipData(guid)
    if not C_TooltipInfo or not C_TooltipInfo.GetHyperlink then
        return nil
    end

    local ok, data = pcall(C_TooltipInfo.GetHyperlink, "unit:" .. guid)
    if not ok or not data or not data.lines or not data.lines[1] then
        return nil
    end

    local name = data.lines[1].leftText
    if not name or LettuceTrackerNS.IsSecret(name) or name == "" then
        return nil
    end

    return name
end

local function ResolveNpcName(npcID, guid)
    local name = _npcNames[npcID] or GetNameFromTooltipData(guid)
    if name then
        _npcNames[npcID] = name
        return name
    end

    -- Keep whatever was recorded on a previous kill
    local enemyRecord = LettuceTrackerStaticDB.EnemyInformation[npcID]
    if enemyRecord and enemyRecord.Name then
        return enemyRecord.Name
    end

    return UNKNOWN_NAME
end

function LettuceTrackerNS.Kills:OnPartyKill(attackerGUID, targetGUID)
    if not LettuceTrackerCharacterDB.SettingsWindow.TrackKills then
        return
    end

    -- The client hides the identity of some units; such a kill can't be attributed to an NPC
    if LettuceTrackerNS.IsSecret(targetGUID) then
        return
    end

    if not LettuceTrackerCharacterDB.SettingsWindow.PartyKills then
        if LettuceTrackerNS.IsSecret(attackerGUID) then
            return
        end

        local petGUID = UnitGUID("pet")
        if LettuceTrackerNS.IsSecret(petGUID) then
            petGUID = nil
        end

        if attackerGUID ~= LettuceTrackerNS.PlayerGUID and attackerGUID ~= petGUID then
            return
        end
    end

    local npcID = LettuceTrackerNS.GetNpcIdFromGuid(targetGUID)
    if not npcID then
        return
    end

    LettuceTrackerNS.DB:AddKill(npcID, ResolveNpcName(npcID, targetGUID), GetCurrentLocation())
end
