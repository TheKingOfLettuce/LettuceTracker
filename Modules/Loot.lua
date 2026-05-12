local _, LettuceTrackerNS = ...

LettuceTrackerNS.Loot = {}

function LettuceTrackerNS.Loot:Initialize()
    LettuceTrackerNS:RegisterEvent("CHAT_MSG_LOOT", LettuceTrackerNS.Loot, LettuceTrackerNS.Loot.OnChatLoot)

    print("Loot Module Initialized")
end

local function ParseLootMessage(message)
    local itemLink = message:match("|Hitem:.-|h%[.-%]|h")

    if not itemLink then
        return nil
    end

    local itemID = C_Item.GetItemInfoInstant(itemLink)

    -- Usually loot messages end like "x3." or "x12."
    local quantity = tonumber(message:match("x(%d+)")) or 1

    return {
        itemID = itemID,
        itemLink = itemLink,
        quantity = quantity,
        message = message,
    }
end

function LettuceTrackerNS.Loot:OnChatLoot(message)
    local loot = ParseLootMessage(message)

    if not loot then
        return
    end

    LettuceTrackerNS.DB:AddLoot(loot.itemID, loot.quantity)
end

