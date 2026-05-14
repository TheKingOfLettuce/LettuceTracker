local _, LettuceTrackerNS = ...

LettuceTrackerNS.EventFrame = CreateFrame("Frame")
LettuceTrackerNS.Events = {}
LettuceTrackerNS.RegisteredEvents = {}

function LettuceTrackerNS:RegisterEvent(event, module, handler)
    self.Events[event] = self.Events[event] or {}
    table.insert(self.Events[event], {
        module = module,
        func = handler
    })

    if not self.RegisteredEvents[event] then
        self.EventFrame:RegisterEvent(event)
        self.RegisteredEvents[event] = true
    end
end

function LettuceTrackerNS:HandleLogin()
    LettuceTrackerNS.DB:Initialize()

    if LettuceTrackerNS.Gold then
        LettuceTrackerNS.Gold:Initialize()
    end

    if LettuceTrackerNS.Loot then
        LettuceTrackerNS.Loot:Initialize()
    end

    if LettuceTrackerNS.Kills then
        LettuceTrackerNS.Kills:Initialize()
    end

    if LettuceTrackerNS.Tooltip then
        LettuceTrackerNS.Tooltip:Initialize()
    end

    if LettuceTrackerNS.MainWindow then
        LettuceTrackerNS.MainWindow:Create()
    end

    if LettuceTrackerNS.GoldWindow then
        LettuceTrackerNS.GoldWindow:Create()
    end

    if LettuceTrackerNS.KillWindow then
        LettuceTrackerNS.KillWindow:Create()
    end

    if LettuceTrackerNS.LootWindow then
        LettuceTrackerNS.LootWindow:Create()
    end

    print("Lettuce Tracker Addon Loaded")
end

LettuceTrackerNS.EventFrame:SetScript("OnEvent", function(_, event, ...)
    local handlers = LettuceTrackerNS.Events[event]
    if not handlers then return end

    for _, handler in ipairs(handlers) do
        handler.func(handler.module, ...)
    end
end)

LettuceTrackerNS:RegisterEvent("PLAYER_LOGIN", LettuceTrackerNS, LettuceTrackerNS.HandleLogin)