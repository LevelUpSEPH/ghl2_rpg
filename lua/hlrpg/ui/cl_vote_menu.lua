-- hlrpg/ui/cl_vote_menu.lua
-- Vote page of the TAB menu. Starts Lambda's votes through its own console commands; everyone then votes
-- on the running poll with the number keys (handled by Lambda).

local menuFrame

local function AddVoteButton(list, label, desc, onClick)
    local btn = list:Add("DButton")
    btn:SetText("")
    btn:Dock(TOP)
    btn:DockMargin(10, 10, 10, 0)
    btn:SetTall(46)

    btn.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and Color(255, 150, 0, 200) or Color(50, 50, 50, 220))
        draw.SimpleText(label, "HLRPG_HUD_Bold", 12, 8, color_white)
        draw.SimpleText(desc, "DermaDefault", 12, 26, Color(210, 210, 210))
    end

    btn.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        onClick()
    end
end

-- A dropdown of choices; picking one starts the vote with the choice's data
local function OpenChoiceMenu(choices, startVote)
    local menu = DermaMenu()
    if #choices == 0 then
        menu:AddOption("(nothing to choose)"):SetEnabled(false)
    end
    for _, choice in ipairs(choices) do
        menu:AddOption(choice.label, function()
            startVote(choice.data)
            if IsValid(menuFrame) then menuFrame:Close() end
        end)
    end
    menu:Open()
end

local function GetMapChoices()
    local choices = {}
    for _, map in ipairs(GAMEMODE:GetMapList() or {}) do
        if not map:iequals(game.GetMap()) then
            choices[#choices + 1] = { label = map, data = map }
        end
    end
    return choices
end

local function GetKickChoices()
    local choices = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply ~= LocalPlayer() then
            choices[#choices + 1] = { label = ply:Nick(), data = tostring(ply:UserID()) }
        end
    end
    return choices
end

local function StartVote(command, arg)
    if arg then RunConsoleCommand(command, arg) else RunConsoleCommand(command) end
    if IsValid(menuFrame) then menuFrame:Close() end
end

function HLRPG.OpenVoteMenu()
    if IsValid(menuFrame) then menuFrame:Remove() end

    local frame = vgui.Create("DFrame")
    menuFrame = frame
    frame:SetSize(340, 330)
    frame:SetTitle("START A VOTE")
    frame:Center()
    frame:MakePopup()
    frame.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 240))
        draw.RoundedBox(0, 0, 0, w, 25, Color(255, 150, 0, 150))
    end

    if not GAMEMODE.GetMapList then
        local label = vgui.Create("DLabel", frame)
        label:Dock(FILL)
        label:SetContentAlignment(5)
        label:SetText("Voting needs the Lambda gamemode.")
        return
    end

    local footer = vgui.Create("DLabel", frame)
    footer:Dock(BOTTOM)
    footer:SetTall(30)
    footer:SetContentAlignment(5)
    footer:SetTextColor(Color(180, 180, 180))
    footer:SetText("Everyone votes on a running poll with the number keys.")

    local list = vgui.Create("DScrollPanel", frame)
    list:Dock(FILL)

    AddVoteButton(list, "RESTART MAP", "Start this map over from the beginning", function()
        StartVote("lambda_voterestart")
    end)
    AddVoteButton(list, "SKIP MAP", "Move on to the next map", function()
        StartVote("lambda_voteskip")
    end)
    AddVoteButton(list, "CHANGE MAP", "Pick any map in the campaign", function()
        OpenChoiceMenu(GetMapChoices(), function(map) StartVote("lambda_votemap", map) end)
    end)
    AddVoteButton(list, "KICK PLAYER", "Vote to remove a player from the server", function()
        OpenChoiceMenu(GetKickChoices(), function(userID) StartVote("lambda_votekick", userID) end)
    end)
end
