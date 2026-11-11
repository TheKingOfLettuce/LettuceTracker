local _, LettuceTrackerNS = ...

LettuceTrackerNS.DB = {}

-- Bump this and add a step to MIGRATIONS whenever the saved table format changes
local CURRENT_VERSION = 1

local UNKNOWN_NAME = "Unknown"
local UNKNOWN_LOCATION = "???"

local DEFAULT_TABLE = {
    Version = CURRENT_VERSION,

    Gold = {
        Total = 0,
        Looted = 0,
        Sold = 0,
        Mail = 0,
        Quests = 0,
        Other = 0
    },

    Kills = {
        Total = 0,
        NPCs = {
            -- [ID] = {KillCount}
        }
    },

    Loot = {
        Total = 0,
        Items = {
            -- [ID] = {ItemCount}
        }
    }
}

local DEFAULT_GLOBAL_STATIC_DATA = {
    EnemyInformation = {
        -- [ID] = {LocationName, Name}
    }
}


function LettuceTrackerNS.DB:Initialize()
    LettuceTrackerDB = LettuceTrackerDB or {}
    LettuceTrackerCharacterDB = LettuceTrackerCharacterDB or {}
    LettuceTrackerStaticDB = LettuceTrackerStaticDB or {}
    self.SessionDB = {}

    -- Migrations write enemy information, so the static table has to be ready first
    self:ApplyDefaults(LettuceTrackerStaticDB, DEFAULT_GLOBAL_STATIC_DATA)

    self:CheckForMigrations(LettuceTrackerDB)
    self:CheckForMigrations(LettuceTrackerCharacterDB)

    self:ApplyDefaults(LettuceTrackerDB, DEFAULT_TABLE)
    self:ApplyDefaults(LettuceTrackerCharacterDB, DEFAULT_TABLE)
    self:ApplyDefaults(self.SessionDB, DEFAULT_TABLE)
end

-- [version the table is at] = function that moves it up one version.
-- Steps run before defaults are applied, so they can't assume any key exists,
-- and each one must be safe to run again on a table it has already migrated.
local MIGRATIONS = {
    [0] = function(db, statTable) db:MigrateV0ToV1(statTable) end,
}

function LettuceTrackerNS.DB:CheckForMigrations(statTable)
    -- A brand new table has nothing to migrate, defaults stamp it with the current version
    if next(statTable) == nil then
        return
    end

    -- no version means anything <= Addon v1.1.0
    local version = statTable.Version or 0

    if version > CURRENT_VERSION then
        print("LettuceTracker | Saved data is from a newer version of the addon, stats may not display correctly")
        return
    end

    while version < CURRENT_VERSION do
        print("LettuceTracker | Migrating data to the new V" .. (version + 1) .. " table")
        MIGRATIONS[version](self, statTable)
        version = version + 1
        statTable.Version = version
    end

    self:RemoveStrayKillCopies(statTable)
end

function LettuceTrackerNS.DB:ApplyDefaults(target, source)
    for key, value in pairs(source) do

        if target[key] == nil then

            if type(value) == "table" then
                target[key] = {}

                self:ApplyDefaults(
                    target[key],
                    value
                )
            else
                target[key] = value
            end

        elseif type(value) == "table"
            and type(target[key]) == "table" then

            self:ApplyDefaults(
                target[key],
                value
            )
        end
    end
end

-- V0 -> V1: enemy names moved out of the kill records into the static table,
-- item counts changed from a plain number to {ItemCount}
function LettuceTrackerNS.DB:MigrateV0ToV1(statTable)
    local enemyInformation = LettuceTrackerStaticDB.EnemyInformation

    local npcs = type(statTable.Kills) == "table" and statTable.Kills.NPCs
    if type(npcs) == "table" then
        for npcId, killStat in pairs(npcs) do
            if type(killStat) == "table" then
                -- Every kill record needs enemy information, but never replace
                -- a name or location that is already known with a worse one
                local enemyRecord = enemyInformation[npcId] or {}
                enemyRecord.Name = killStat.Name or enemyRecord.Name or UNKNOWN_NAME
                enemyRecord.LocationName = enemyRecord.LocationName or UNKNOWN_LOCATION
                enemyInformation[npcId] = enemyRecord

                killStat.Name = nil
            end
        end
    end

    local items = type(statTable.Loot) == "table" and statTable.Loot.Items
    if type(items) == "table" then
        for itemID, lootStat in pairs(items) do
            if type(lootStat) == "number" then
                items[itemID] = { ItemCount = lootStat }
            end
        end
    end
end

-- Not a format change, so not a versioned migration: the V0 -> V1 migration shipped
-- in Addon v1.2.0 also copied every kill record directly into Kills, next to Total
-- and NPCs. This removes those stray copies from tables it already touched.
function LettuceTrackerNS.DB:RemoveStrayKillCopies(statTable)
    local kills = statTable.Kills
    if type(kills) ~= "table" then
        return
    end

    local strayKeys = {}
    for key in pairs(kills) do
        if type(key) == "number" then
            table.insert(strayKeys, key)
        end
    end

    for _, key in ipairs(strayKeys) do
        kills[key] = nil
    end
end

function LettuceTrackerNS.DB:ResetSessionDB()
    self.SessionDB = {}
    self:ApplyDefaults(self.SessionDB, DEFAULT_TABLE)
end


function LettuceTrackerNS.DB:AddGold(source, amount)
    if amount <= 0 then
        return
    end

    self:AddGoldToTable(LettuceTrackerCharacterDB, source, amount)
    self:AddGoldToTable(LettuceTrackerDB, source, amount)
    self:AddGoldToTable(self.SessionDB, source, amount)

    LettuceTrackerNS.MainWindow:RefreshTotalGold()
    LettuceTrackerNS.GoldWindow:RefreshTotalGold()
    LettuceTrackerNS.GoldWindow:RefreshSource(source)
end

function LettuceTrackerNS.DB:AddGoldToTable(statTable, source, amount)
    statTable.Gold.Total = (statTable.Gold.Total or 0) + amount
    statTable.Gold[source] = (statTable.Gold[source] or 0) + amount
end

function LettuceTrackerNS.DB:AddKill(npcID, npcName, locationName)
    if not npcID then
        return
    end

    self:AddKillToTable(LettuceTrackerCharacterDB, npcID)
    self:AddKillToTable(LettuceTrackerDB, npcID)
    self:AddKillToTable(self.SessionDB, npcID)

    self:AddEnemyInfoStaticData(npcID, npcName, locationName)

    LettuceTrackerNS.MainWindow:RefreshTotalKills()
end

function LettuceTrackerNS.DB:AddKillToTable(statTable, npcID)
    statTable.Kills.Total = statTable.Kills.Total + 1
    local killRecord = statTable.Kills.NPCs[npcID]
    if not killRecord then
        statTable.Kills.NPCs[npcID] = {}
        statTable.Kills.NPCs[npcID].KillCount = 0
    end
    statTable.Kills.NPCs[npcID].KillCount = statTable.Kills.NPCs[npcID].KillCount + 1
end

function LettuceTrackerNS.DB:AddEnemyInfoStaticData(npcID, npcName, locationName)
    local enemyRecord = LettuceTrackerStaticDB.EnemyInformation[npcID]
    if not enemyRecord then
        LettuceTrackerStaticDB.EnemyInformation[npcID] = {}
    end
    LettuceTrackerStaticDB.EnemyInformation[npcID].Name = npcName
    LettuceTrackerStaticDB.EnemyInformation[npcID].LocationName = locationName
end

function LettuceTrackerNS.DB:AddLoot(itemID, quantity)
    if not itemID then
        return
    end

    self:AddLootToTable(LettuceTrackerCharacterDB, itemID, quantity)
    self:AddLootToTable(LettuceTrackerDB, itemID, quantity)
    self:AddLootToTable(self.SessionDB, itemID, quantity)

    LettuceTrackerNS.MainWindow:RefreshTotalItems()
end

function LettuceTrackerNS.DB:AddLootToTable(statTable, itemID, quantity)
    statTable.Loot.Total = statTable.Loot.Total + quantity
    local itemRecord = statTable.Loot.Items[itemID]
    if not itemRecord then
        statTable.Loot.Items[itemID] = {}
        statTable.Loot.Items[itemID].ItemCount = 0
    end
    statTable.Loot.Items[itemID].ItemCount = statTable.Loot.Items[itemID].ItemCount + quantity
end