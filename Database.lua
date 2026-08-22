local _, LettuceTrackerNS = ...

LettuceTrackerNS.DB = {}

local DEFAULT_TABLE = {
    Version = 1,

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

    self:CheckForMigrations(LettuceTrackerDB)
    self:CheckForMigrations(LettuceTrackerCharacterDB)

    self:ApplyDefaults(LettuceTrackerDB, DEFAULT_TABLE)
    self:ApplyDefaults(LettuceTrackerCharacterDB, DEFAULT_TABLE)
    self:ApplyDefaults(self.SessionDB, DEFAULT_TABLE)
    self:ApplyDefaults(LettuceTrackerStaticDB, DEFAULT_GLOBAL_STATIC_DATA)
end

function LettuceTrackerNS.DB:CheckForMigrations(statTable)
    -- no version means anything <= Addon v1.1.0
    if next(statTable) ~= nil and statTable.Version == nil then
        print("LettuceTracker | Migrating data to the new V1 table")
        self:MigrateV0ToV1(statTable)
    end
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

function LettuceTrackerNS.DB:MigrateV0ToV1(statTable)
    -- Need to init the new static data to migrate enemy information
    self:ApplyDefaults(LettuceTrackerStaticDB, DEFAULT_GLOBAL_STATIC_DATA)

    -- Apply Enemy migrations to static table
    for npcId, killStat in pairs(statTable.Kills.NPCs or {}) do
        self:AddEnemyInfoStaticData(npcId, killStat.Name, "???")
        killStat.Name = nil
        statTable.Kills[npcId] = killStat
    end

    -- Apply Item migrations to new table format
    for itemID, lootStat in pairs(statTable.Loot.Items or {}) do
        local itemData = {}
        itemData.ItemCount = lootStat
        statTable.Loot.Items[itemID] = itemData
    end

    statTable.Version = 1
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