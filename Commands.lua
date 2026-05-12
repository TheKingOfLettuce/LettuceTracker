local _, LettuceTrackerNS = ...

LettuceTrackerNS.Commands = {}

local _coammnds = {}

SLASH_LETTUCESTATS1 = "/lettucestats"
SLASH_LETTUCESTATS2 = "/ls"

SlashCmdList["LETTUCESTATS"] = function(msg)
    local command, args = msg:match("^(%S*)%s*(.-)$")

    command = command:lower()

    if command == "" then
        LettuceTrackerNS.UI:Toggle()
        return
    end

    local handler = _coammnds[command]

    if handler then
        handler(args)
    else
        print("Unknown command")
    end
end