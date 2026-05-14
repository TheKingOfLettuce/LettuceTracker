local _, LettuceTrackerNS = ...

LettuceTrackerNS.Gold = {}

local LOOTED_SOURCE = "LOOTED"
local QUEST_SOURCE = "QUEST"
local MAIL_SOURCE = "MAIL"
local VENDOR_SOURCE = "VENDOR"
local OTHER_SOURCE = "OTHER"

local _startingMoney = 0
local _lastMoney = 0
local _goldSource = OTHER_SOURCE


function LettuceTrackerNS.Gold:Initialize()
    _startingMoney = GetMoney()
    _lastMoney = _startingMoney

    LettuceTrackerNS:RegisterEvent("PLAYER_MONEY", LettuceTrackerNS.Gold, LettuceTrackerNS.Gold.OnPlayerMoney)

    LettuceTrackerNS:RegisterEvent("MERCHANT_SHOW", LettuceTrackerNS.Gold, LettuceTrackerNS.Gold.OnMerchantShow)
    LettuceTrackerNS:RegisterEvent("MERCHANT_CLOSED", LettuceTrackerNS.Gold, LettuceTrackerNS.Gold.OnMerchantClosed)

    LettuceTrackerNS:RegisterEvent("MAIL_SHOW", LettuceTrackerNS.Gold, LettuceTrackerNS.Gold.OnMailShow)
    LettuceTrackerNS:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", LettuceTrackerNS.Gold, LettuceTrackerNS.Gold.OnMailHide)

    LettuceTrackerNS:RegisterEvent("QUEST_TURNED_IN", LettuceTrackerNS.Gold, LettuceTrackerNS.Gold.QuestTurnIn)

    LettuceTrackerNS:RegisterEvent("LOOT_OPENED", LettuceTrackerNS.Gold, LettuceTrackerNS.Gold.OnLootOpen)
    LettuceTrackerNS:RegisterEvent("LOOT_CLOSED", LettuceTrackerNS.Gold, LettuceTrackerNS.Gold.OnLootClosed)
end

function LettuceTrackerNS.Gold:ClearGoldSourceAfterDelay(source, delay)
    if self.ClearSourceTimer then
        self.ClearSourceTimer:Cancel()
        self.ClearSourceTimer = nil
    end

    self.ClearSourceTimer = C_Timer.NewTimer(delay or 3, function()
        if _goldSource == source then
            self:SetGoldSource(OTHER_SOURCE)
        end

        self.ClearSourceTimer = nil
    end)
end

function LettuceTrackerNS.Gold:SetGoldSource(source)
    _goldSource = source
    if self.ClearSourceTimer then
        self.ClearSourceTimer:Cancel()
        self.ClearSourceTimer = nil
    end
end 

function LettuceTrackerNS.Gold:OnMerchantShow()
    self:SetGoldSource(VENDOR_SOURCE)
end

function LettuceTrackerNS.Gold:OnMerchantClosed()
    if _goldSource == VENDOR_SOURCE then
        self:ClearGoldSourceAfterDelay(VENDOR_SOURCE)
    end
end

function LettuceTrackerNS.Gold:OnPlayerMoney()
    if not LettuceTrackerCharacterDB.SettingsWindow.TrackGold then
        return
    end
    
    local currentMoney = GetMoney()
    local difference = currentMoney - _lastMoney

    if difference > 0 then
        if _goldSource == MAIL_SOURCE then
            LettuceTrackerNS.DB:AddGold("Mail", difference)
        elseif _goldSource == VENDOR_SOURCE then
            LettuceTrackerNS.DB:AddGold("Sold", difference)
        elseif _goldSource == LOOTED_SOURCE then
            LettuceTrackerNS.DB:AddGold("Looted", difference)
        elseif _goldSource == QUEST_SOURCE then
            LettuceTrackerNS.DB:AddGold("Quests", difference)
        else
            LettuceTrackerNS.DB:AddGold("Other", difference)
        end
    end

    _lastMoney = currentMoney
end

function LettuceTrackerNS.Gold:OnMailShow()
    self:SetGoldSource(MAIL_SOURCE)
end

function LettuceTrackerNS.Gold:OnMailHide(windowType)
    if windowType ~= Enum.PlayerInteractionType.MailInfo then
        return
    end

    if _goldSource == MAIL_SOURCE then
        self:ClearGoldSourceAfterDelay(MAIL_SOURCE)
    end
end

function LettuceTrackerNS.Gold:QuestTurnIn(_,_,money)
	if money == 0 then
        return
    end

    self:SetGoldSource(QUEST_SOURCE)
    self:ClearGoldSourceAfterDelay(QUEST_SOURCE)
end

function LettuceTrackerNS.Gold:OnLootOpen(_, _)
    self:SetGoldSource(LOOTED_SOURCE)
end

function LettuceTrackerNS.Gold:OnLootClosed()
    if _goldSource == LOOTED_SOURCE then
        self:ClearGoldSourceAfterDelay(LOOTED_SOURCE)
    end
end