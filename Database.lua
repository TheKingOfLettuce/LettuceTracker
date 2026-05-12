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
            -- [ID] = KillCount
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

    LettuceTrackerDB.Characters = LettuceTrackerDB.Characters or {}
    LettuceTrackerDB.Account = LettuceTrackerDB.Account or {}
    self:ApplyDefaults(LettuceTrackerDB.Account, DEFAULT_TABLE)

    local characterKey = self:GetCharacterKey()

    if not LettuceTrackerDB.Characters[characterKey] then
        LettuceTrackerDB.Characters[characterKey] = {}
    end

    self:ApplyDefaults(
        LettuceTrackerDB.Characters[characterKey],
        DEFAULT_TABLE
    )
    print("LettuceTrackerDB Initialized")
end

function LettuceTrackerNS.DB:GetCharacterKey()
    local realm = GetRealmName()
    local character = UnitName("player")

    return realm .. "-" .. character
end

function LettuceTrackerNS.DB:GetCharacter()
    local characterKey = self:GetCharacterKey()

    return LettuceTrackerDB.Characters[characterKey]
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

    local character = self:GetCharacter()
    self:AddGoldToTable(character, source, amount)
    self:AddGoldToTable(LettuceTrackerDB.Account, source, amount)

    print(
        "Added gold:",
        source,
        C_CurrencyInfo.GetCoinTextureString(amount)
    )
    LettuceTrackerNS.UI:RefreshTotalGold()
end

function LettuceTrackerNS.DB:AddGoldToTable(statTable, source, amount)
    statTable.Gold.Total = (statTable.Gold.Total or 0) + amount
    statTable.Gold[source] = (statTable.Gold[source] or 0) + amount
end

function LettuceTrackerNS.DB:AddKill(npcID)
    if not npcID then
        return
    end

    local character = self:GetCharacter()
    self:AddKillToTable(character, npcID)
    self:AddKillToTable(LettuceTrackerDB.Account, npcID)

    print(
        "Killed NPC:",
        npcID
    )
    LettuceTrackerNS.UI:RefreshTotalKills()
end

function LettuceTrackerNS.DB:AddKillToTable(statTable, npcID)
    statTable.Kills.Total = statTable.Kills.Total + 1
    statTable.Kills.NPCs[npcID] = (statTable.Kills.NPCs[npcID] or 0) + 1
end

function LettuceTrackerNS.DB:AddLoot(itemID, quantity)
    if not itemID then
        return
    end

    local character = self:GetCharacter()
    self:AddLootToTable(character, itemID, quantity)
    self:AddLootToTable(LettuceTrackerDB.Account, itemID, quantity)

    print(
        "Looted item:",
        itemID,
        "x" .. quantity
    )
    LettuceTrackerNS.UI:RefreshTotalItems()
end

function LettuceTrackerNS.DB:AddLootToTable(statTable, itemID, quantity)
    statTable.Loot.Total = statTable.Loot.Total + quantity
    statTable.Loot.Items[itemID] = (statTable.Loot.Items[itemID] or 0) + quantity
end