local _, LettuceTrackerNS = ...

LettuceTrackerNS.DB = {}

local DEFAULT_TABLE = {
    Gold = {
        Total = 0,
        Looted = 0,
        Sold = 0,
        Auctioned = 0,
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

    character.Gold.Total = (character.Gold.Total or 0) + amount
    character.Gold[source] =
        (character.Gold[source] or 0) + amount

    print(
        "Added gold:",
        source,
        C_CurrencyInfo.GetCoinTextureString(amount)
    )
end

function LettuceTrackerNS.DB:AddKill(npcID)
    if not npcID then
        return
    end

    local character = self:GetCharacter()

    character.Kills.Total =
        character.Kills.Total + 1

    character.Kills.NPCs[npcID] =
        (character.Kills.NPCs[npcID] or 0) + 1

    print(
        "Killed NPC:",
        npcID
    )
end

function LettuceTrackerNS.DB:AddLoot(itemID, quantity)
    if not itemID then
        return
    end

    quantity = quantity or 1

    local character = self:GetCharacter()

    character.Loot.Total =
        character.Loot.Total + quantity

    character.Loot.Items[itemID] =
        (character.Loot.Items[itemID] or 0) + quantity

    print(
        "Looted item:",
        itemID,
        "x" .. quantity
    )
end