local _, LettuceTrackerNS = ...

LettuceTrackerNS.DB = {}

local DEFAULT_TABLE = {
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
            -- [ID] = {Name, KillCount}
        }
    },

    Loot = {
        Total = 0,
        Items = {
            -- [ID] = ItemCount
        }
    }
}


function LettuceTrackerNS.DB:Initialize()
    LettuceTrackerDB = LettuceTrackerDB or {}
    LettuceTrackerCharacterDB = LettuceTrackerCharacterDB or {}

    self:ApplyDefaults(LettuceTrackerDB, DEFAULT_TABLE)
    self:ApplyDefaults(LettuceTrackerCharacterDB, DEFAULT_TABLE)
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


function LettuceTrackerNS.DB:AddGold(source, amount)
    if amount <= 0 then
        return
    end

    self:AddGoldToTable(LettuceTrackerCharacterDB, source, amount)
    self:AddGoldToTable(LettuceTrackerDB, source, amount)

    LettuceTrackerNS.MainWindow:RefreshTotalGold()
    LettuceTrackerNS.GoldWindow:RefreshTotalGold()
    LettuceTrackerNS.GoldWindow:RefreshSource(source)
end

function LettuceTrackerNS.DB:AddGoldToTable(statTable, source, amount)
    statTable.Gold.Total = (statTable.Gold.Total or 0) + amount
    statTable.Gold[source] = (statTable.Gold[source] or 0) + amount
end

function LettuceTrackerNS.DB:AddKill(npcID, npcName)
    if not npcID then
        return
    end

    self:AddKillToTable(LettuceTrackerCharacterDB, npcID, npcName)
    self:AddKillToTable(LettuceTrackerDB, npcID, npcName)

    LettuceTrackerNS.MainWindow:RefreshTotalKills()
end

function LettuceTrackerNS.DB:AddKillToTable(statTable, npcID, npcName)
    statTable.Kills.Total = statTable.Kills.Total + 1
    local killRecord = statTable.Kills.NPCs[npcID]
    if not killRecord then
        statTable.Kills.NPCs[npcID] = {}
        statTable.Kills.NPCs[npcID].KillCount = 0
    end
    statTable.Kills.NPCs[npcID].KillCount = statTable.Kills.NPCs[npcID].KillCount + 1
    statTable.Kills.NPCs[npcID].Name = npcName
end

function LettuceTrackerNS.DB:AddLoot(itemID, quantity)
    if not itemID then
        return
    end

    self:AddLootToTable(LettuceTrackerCharacterDB, itemID, quantity)
    self:AddLootToTable(LettuceTrackerDB, itemID, quantity)

    LettuceTrackerNS.MainWindow:RefreshTotalItems()
end

function LettuceTrackerNS.DB:AddLootToTable(statTable, itemID, quantity)
    statTable.Loot.Total = statTable.Loot.Total + quantity
    statTable.Loot.Items[itemID] = (statTable.Loot.Items[itemID] or 0) + quantity
end