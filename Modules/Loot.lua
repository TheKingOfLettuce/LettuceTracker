local _, LettuceTrackerNS = ...

LettuceTrackerNS.Loot = {}

function LettuceTrackerNS.Loot:Initialize()
    LettuceTrackerNS:RegisterEvent("CHAT_MSG_LOOT", LettuceTrackerNS.Loot, LettuceTrackerNS.Loot.OnChatLoot)
end

local LootPatterns = {
    LOOT_ITEM_SELF_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)"),
    LOOT_ITEM_PUSHED_SELF_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)"),
    LOOT_ITEM_SELF:gsub("%%s", "(.+)"),
    LOOT_ITEM_PUSHED_SELF:gsub("%%s", "(.+)"),
}
local function GetItemInfoFromMsg(message)
    for _, pattern in ipairs(LootPatterns) do
        local itemLink, quantity = message:match(pattern)
        if itemLink then
            return itemLink, tonumber(quantity) or 1
        end
    end
end

local function ParseLootMessage(message)
    local itemLink, quantity = GetItemInfoFromMsg(message)

    if not itemLink then
        return nil
    end

    local itemID = C_Item.GetItemInfoInstant(itemLink)

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

