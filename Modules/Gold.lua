local _, LettuceTrackerNS = ...

LettuceTrackerNS.Gold = {}

local _startingMoney = 0
local _lastMoney = 0
local _atMerchant = false
local _atMail = false
local _pendingAuctions = {}
local _recentlyClaimedAuctionGold = {}

local GOLD_KEY = gsub(GOLD_AMOUNT, "%%d", "(%%d+)")
local SILVER_KEY = gsub(SILVER_AMOUNT, "%%d", "(%%d+)")
local COPPER_Key = gsub(COPPER_AMOUNT, "%%d", "(%%d+)")
local function _ParseLootString(message)
    local gold = tonumber(message:match(GOLD_KEY)) or 0
    local silver = tonumber(message:match(SILVER_KEY)) or 0
    local copper = tonumber(message:match(COPPER_Key)) or 0
    return gold*10000 + silver*100 + copper
end

function LettuceTrackerNS.Gold:Initialize()
    _startingMoney = GetMoney()
    _lastMoney = _startingMoney

    LettuceTrackerNS:RegisterEvent("PLAYER_MONEY", LettuceTrackerNS.Gold, LettuceTrackerNS.Gold.OnPlayerMoney)
    LettuceTrackerNS:RegisterEvent("CHAT_MSG_MONEY", LettuceTrackerNS.Gold, LettuceTrackerNS.Gold.OnChatMsgMoney)

    LettuceTrackerNS:RegisterEvent("MERCHANT_SHOW", LettuceTrackerNS.Gold, LettuceTrackerNS.Gold.OnMerchantShow)
    LettuceTrackerNS:RegisterEvent("MERCHANT_CLOSED", LettuceTrackerNS.Gold, LettuceTrackerNS.Gold.OnMerchantClosed)

    LettuceTrackerNS:RegisterEvent("MAIL_SHOW", LettuceTrackerNS.Gold, LettuceTrackerNS.Gold.OnMailShow)
    LettuceTrackerNS:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", LettuceTrackerNS.Gold, LettuceTrackerNS.Gold.OnMailHide)
    LettuceTrackerNS:RegisterEvent("MAIL_INBOX_UPDATE", LettuceTrackerNS.Gold, LettuceTrackerNS.Gold.ScanInboxForAuctionGold)

    LettuceTrackerNS:RegisterEvent("QUEST_TURNED_IN", LettuceTrackerNS.Gold, LettuceTrackerNS.Gold.QuestTurnIn)

    print("Gold Module Initialized")
end

function LettuceTrackerNS.Gold:OnMerchantShow()
    _atMerchant = true
    _lastMoney = GetMoney()
    print("Merchant Start: ", _atMerchant)
end

function LettuceTrackerNS.Gold:OnMerchantClosed()
    _atMerchant = false
    _lastMoney = GetMoney()
    print("Merchant Stop: ", _atMerchant)
end

function LettuceTrackerNS.Gold:OnPlayerMoney()
    local currentMoney = GetMoney()
    local difference = currentMoney - _lastMoney

    if difference > 0 then
        if _atMail then
            if self:ResolvePendingAuctionGold(difference) then
                LettuceTrackerNS.DB:AddGold("Auctioned", difference)
            else
                LettuceTrackerNS.DB:AddGold("Other", difference)
            end

        elseif _atMerchant then
            LettuceTrackerNS.DB:AddGold("Sold", difference)
        end
    end

    _lastMoney = currentMoney
end

function LettuceTrackerNS.Gold:OnChatMsgMoney(message)
    local looted_money = _ParseLootString(message)
    if looted_money <= 0 then
        return
    end

    LettuceTrackerNS.DB:AddGold("Looted", looted_money)
end

function LettuceTrackerNS.Gold:OnMailShow()
    _atMail = true
    print("Mail Start: ", _atMail)
end

function LettuceTrackerNS.Gold:OnMailHide(windowType)
    if windowType ~= Enum.PlayerInteractionType.MailInfo then
        return
    end

    _atMail = false
    print("Mail End: ", _atMail)
end

function LettuceTrackerNS.Gold:ScanInboxForAuctionGold()
    local newPending = {}

    -- Get All Current Auction Gold
    for i = 1, GetInboxNumItems() do
        local _, _, _, _, money = GetInboxHeaderInfo(i)
        local invoiceType = GetInboxInvoiceInfo(i)

        if invoiceType == "seller" and money and money > 0 then
            newPending[money] = (newPending[money] or 0) + 1
        end
    end

    -- Go Through any previous gold auctions and see if some are missing
    -- if missing, player most likely claimed for gold
    for amount, oldCount in pairs(_pendingAuctions) do
        local newCount = newPending[amount] or 0
        local removedCount = oldCount - newCount

        for _ = 1, removedCount do
            _recentlyClaimedAuctionGold[amount] = (_recentlyClaimedAuctionGold[amount] or 0) + 1
        end
    end

    -- Update the now existing auction gold mail
    wipe(_pendingAuctions)
    for amount, count in pairs(newPending) do
        _pendingAuctions[amount] = count
    end
end

function LettuceTrackerNS.Gold:ResolvePendingAuctionGold(amount)
    local count = _recentlyClaimedAuctionGold[amount]

    if not count or count <= 0 then
        return false
    end

    if count == 1 then
        _recentlyClaimedAuctionGold[amount] = nil
    else
        _recentlyClaimedAuctionGold[amount] = count - 1
    end

    return true
end

function LettuceTrackerNS.Gold:QuestTurnIn(_,_,money)
	if money == 0 then
        return
    end

    LettuceTrackerNS.DB:AddGold("Quests", money)
end