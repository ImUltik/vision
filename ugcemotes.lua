--credits to 7yd7
local Players   = game:GetService("Players")
local RS        = game:GetService("RunService")
local UIS       = game:GetService("UserInputService")
local TS        = game:GetService("TweenService")
local Http      = game:GetService("HttpService")
local CoreGui   = game:GetService("CoreGui")

local LP   = Players.LocalPlayer
local Char = LP.Character or LP.CharacterAdded:Wait()
local Hum  = Char:WaitForChild("Humanoid")

local C = {
    Accent     = Color3.fromRGB(175, 45, 52),
    AccentDark = Color3.fromRGB(110, 28, 34),
    BG0        = Color3.fromRGB(0, 0, 0),
    BG1        = Color3.fromRGB(6, 6, 6),
    BG2        = Color3.fromRGB(12, 12, 14),
    BG3        = Color3.fromRGB(18, 18, 22),
    Stk        = Color3.fromRGB(30, 30, 35),
    Dim        = Color3.fromRGB(110, 110, 125),
    W          = Color3.new(1, 1, 1),
}

local EMOTE_URL      = "https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/EmoteSniper.json"
local ANIM_URL       = "https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/AnimationSniper.json"
local FAVS_FILE      = "BLEED/emote_favs.json"
local BINDS_FILE     = "BLEED/emote_binds.json"
local ITEMS_PER_PAGE = 12

local St = {
    mode       = "emote",
    favOnly    = false,
    page       = 1,
    totalPages = 1,
    search     = "",
    track      = nil,
    emotes     = {},
    anims      = {},
    favs       = {},
    binds      = {},
    filtered   = {},
    visible    = false,
}

local function ensureFolder()
    pcall(function()
        if not isfolder("BLEED") then makefolder("BLEED") end
    end)
end

local function readJSON(path, fallback)
    local ok, result = pcall(function()
        if isfile(path) then return Http:JSONDecode(readfile(path)) end
    end)
    return (ok and result) or fallback
end

local function writeJSON(path, data)
    ensureFolder()
    pcall(function() writefile(path, Http:JSONEncode(data)) end)
end

do
    local favsList = readJSON(FAVS_FILE, {})
    for _, id in ipairs(favsList) do St.favs[tostring(id)] = true end
    local bindsMap = readJSON(BINDS_FILE, {})
    for id, key in pairs(bindsMap) do St.binds[tostring(id)] = key end
end

local function saveFavs()
    local list = {}
    for id in pairs(St.favs) do list[#list+1] = tonumber(id) or id end
    writeJSON(FAVS_FILE, list)
end

local function saveBinds()
    writeJSON(BINDS_FILE, St.binds)
end

local SG = Instance.new("ScreenGui", gethui and gethui() or CoreGui)
SG.Name           = "BleedEmote"
SG.ResetOnSpawn   = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.DisplayOrder   = 9999999
SG.IgnoreGuiInset = true

local function corner(parent, r)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, r or 8)
    return c
end

local function stroke(parent, col, thick)
    local s = Instance.new("UIStroke", parent)
    s.Color     = col or C.Stk
    s.Thickness = thick or 1
    return s
end

local function label(parent, props)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.TextStrokeTransparency = 1
    l.Font            = props.font  or Enum.Font.Gotham
    l.TextSize        = props.size  or 12
    l.TextColor3      = props.color or C.W
    l.Text            = props.text  or ""
    l.TextXAlignment  = props.align or Enum.TextXAlignment.Left
    l.TextWrapped     = props.wrap  or false
    l.Size            = props.sz    or UDim2.new(1, 0, 1, 0)
    l.Position        = props.pos   or UDim2.new(0, 0, 0, 0)
    l.ZIndex          = props.z     or 1
    return l
end

local function btn(parent, props)
    local b = Instance.new("TextButton", parent)
    b.BackgroundColor3       = props.bg   or C.BG2
    b.BackgroundTransparency = props.bgt  or 0
    b.BorderSizePixel        = 0
    b.Font                   = props.font or Enum.Font.GothamBold
    b.TextSize               = props.size or 12
    b.TextColor3             = props.color or C.W
    b.Text                   = props.text or ""
    b.AutoButtonColor        = false
    b.TextStrokeTransparency = 1
    b.Size                   = props.sz  or UDim2.new(0, 80, 0, 28)
    b.Position               = props.pos or UDim2.new(0, 0, 0, 0)
    b.ZIndex                 = props.z   or 1
    if props.r ~= false then corner(b, props.r or 8) end
    return b
end

local function imgBtn(parent, img, sz, pos, z)
    local b = Instance.new("ImageButton", parent)
    b.Image                  = img
    b.BackgroundTransparency = 1
    b.BorderSizePixel        = 0
    b.AutoButtonColor        = false
    b.Size                   = sz  or UDim2.new(0, 24, 0, 24)
    b.Position               = pos or UDim2.new(0, 0, 0, 0)
    b.ZIndex                 = z   or 1
    return b
end

local function frame(parent, props)
    local f = Instance.new("Frame", parent)
    f.BackgroundColor3       = props.bg  or C.BG1
    f.BackgroundTransparency = props.bgt or 0
    f.BorderSizePixel        = 0
    f.Size                   = props.sz  or UDim2.new(1, 0, 0, 40)
    f.Position               = props.pos or UDim2.new(0, 0, 0, 0)
    f.ClipsDescendants       = props.clip or false
    f.ZIndex                 = props.z   or 1
    return f
end

local function tw(obj, t, props)
    TS:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quint), props):Play()
end

local notify = _G.BleedNotify or (function()
    local notifStack = {}
    local W_N  = 320
    local X_SH = -(320 + 16)
    local X_HI = 10
    local GAP  = 8

    local function reposition()
        local yOff = -12
        for i, entry in ipairs(notifStack) do
            yOff = yOff - entry.frame.AbsoluteSize.Y - GAP
            TS:Create(entry.frame, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {
                Position = UDim2.new(1, X_SH, 1, yOff)
            }):Play()
        end
    end

    return function(title, msg, icon)
        task.spawn(function()
            local descLines = math.max(1, math.min(math.ceil(#(msg or "") / 38), 4))
            local H = 54 + (descLines - 1) * 14

            local nf = Instance.new("Frame", SG)
            nf.Size                   = UDim2.new(0, W_N, 0, H)
            nf.Position               = UDim2.new(1, X_HI, 1, -H - 12)
            nf.BackgroundColor3       = C.BG0
            nf.BackgroundTransparency = 1
            nf.BorderSizePixel        = 0
            nf.ZIndex                 = 200
            nf.ClipsDescendants       = true
            Instance.new("UICorner", nf).CornerRadius = UDim.new(0, 10)

            local nGrad = Instance.new("UIGradient", nf)
            nGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 5, 5)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(6,  3, 3)),
            })
            nGrad.Rotation = 135

            local nStroke = Instance.new("UIStroke", nf)
            nStroke.Color        = C.Stk
            nStroke.Thickness    = 1
            nStroke.Transparency = 1

            local bar = Instance.new("Frame", nf)
            bar.Size                   = UDim2.new(0, 3, 0.7, 0)
            bar.Position               = UDim2.new(0, 0, 0.15, 0)
            bar.BackgroundColor3       = C.Accent
            bar.BackgroundTransparency = 1
            bar.BorderSizePixel        = 0
            Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)

            local iconImg = Instance.new("ImageLabel", nf)
            iconImg.Size                   = UDim2.new(0, 28, 0, 28)
            iconImg.Position               = UDim2.new(0, 14, 0.5, -14)
            iconImg.BackgroundTransparency = 1
            iconImg.ImageTransparency      = 1
            iconImg.ZIndex                 = 201
            iconImg.ScaleType              = Enum.ScaleType.Fit

            if type(icon) == "number" then
                iconImg.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. icon .. "&width=150&height=150&format=png"
                Instance.new("UICorner", iconImg).CornerRadius = UDim.new(1, 0)
            elseif type(icon) == "string" and icon ~= "" then
                iconImg.Image = icon
            else
                iconImg.Image = "rbxassetid://14385986465"
            end

            local titleL = Instance.new("TextLabel", nf)
            titleL.Text                   = title or ""
            titleL.Font                   = Enum.Font.GothamBold
            titleL.TextSize               = 13
            titleL.TextColor3             = C.W
            titleL.Position               = UDim2.new(0, 50, 0, 10)
            titleL.Size                   = UDim2.new(1, -60, 0, 16)
            titleL.BackgroundTransparency = 1
            titleL.TextXAlignment         = Enum.TextXAlignment.Left
            titleL.TextTransparency       = 1
            titleL.TextTruncate           = Enum.TextTruncate.AtEnd
            titleL.ZIndex                 = 201

            local timeL = Instance.new("TextLabel", nf)
            timeL.Text                   = "now"
            timeL.Font                   = Enum.Font.Gotham
            timeL.TextSize               = 9
            timeL.TextColor3             = C.Dim
            timeL.Position               = UDim2.new(1, -38, 0, 12)
            timeL.Size                   = UDim2.new(0, 32, 0, 14)
            timeL.BackgroundTransparency = 1
            timeL.TextXAlignment         = Enum.TextXAlignment.Right
            timeL.TextTransparency       = 1
            timeL.ZIndex                 = 201

            local msgL = Instance.new("TextLabel", nf)
            msgL.Text                   = msg or ""
            msgL.Font                   = Enum.Font.Gotham
            msgL.TextSize               = 11
            msgL.TextColor3             = C.Dim
            msgL.Position               = UDim2.new(0, 50, 0, 29)
            msgL.Size                   = UDim2.new(1, -60, 1, -34)
            msgL.BackgroundTransparency = 1
            msgL.TextXAlignment         = Enum.TextXAlignment.Left
            msgL.TextWrapped            = true
            msgL.TextTransparency       = 1
            msgL.ZIndex                 = 201

            local interact = Instance.new("TextButton", nf)
            interact.Size                   = UDim2.new(1, 0, 1, 0)
            interact.BackgroundTransparency = 1
            interact.Text                   = ""
            interact.ZIndex                 = 202

            local entry = {frame = nf}
            table.insert(notifStack, 1, entry)
            reposition()

            task.spawn(function()
                local snd = Instance.new("Sound")
                snd.SoundId = "rbxassetid://255881176"
                snd.Volume  = 0.65
                snd.Parent  = SG
                snd:Play()
                game:GetService("Debris"):AddItem(snd, 2)
            end)

            TS:Create(nf,      TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.35}):Play()
            TS:Create(nStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0.6}):Play()
            TS:Create(bar,     TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
            task.wait(0.05)
            TS:Create(iconImg, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
            task.wait(0.04)
            TS:Create(titleL,  TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
            task.wait(0.04)
            TS:Create(msgL,    TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0.15}):Play()
            TS:Create(timeL,   TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0.5}):Play()

            local dismissed = false
            local function dismiss()
                if dismissed then return end
                dismissed = true
                local idx = table.find(notifStack, entry)
                if idx then table.remove(notifStack, idx) end
                TS:Create(nf, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
                    {Position = UDim2.new(1, X_HI, nf.Position.Y.Scale, nf.Position.Y.Offset)}):Play()
                TS:Create(nf,      TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
                TS:Create(nStroke, TweenInfo.new(0.25), {Transparency = 1}):Play()
                TS:Create(titleL,  TweenInfo.new(0.2),  {TextTransparency = 1}):Play()
                TS:Create(msgL,    TweenInfo.new(0.2),  {TextTransparency = 1}):Play()
                TS:Create(bar,     TweenInfo.new(0.2),  {BackgroundTransparency = 1}):Play()
                TS:Create(iconImg, TweenInfo.new(0.2),  {ImageTransparency = 1}):Play()
                task.wait(0.65)
                nf:Destroy()
                reposition()
            end

            interact.MouseButton1Click:Connect(dismiss)
            task.delay(math.clamp(#(msg or "") * 0.1 + 2, 2.5, 10), dismiss)
        end)
    end
end)()


local function fetchEmotes()
    local ok, res = pcall(function() return game:HttpGet(EMOTE_URL) end)
    if not ok or not res or res == "" then return {} end
    local parsed = Http:JSONDecode(res)
    local list = {}
    for _, item in ipairs(parsed.data or {}) do
        if tonumber(item.id) and tonumber(item.id) > 0 then
            list[#list+1] = {id = tonumber(item.id), name = item.name or ("Emote_" .. item.id)}
        end
    end
    return list
end

local function fetchAnims()
    local ok, res = pcall(function() return game:HttpGet(ANIM_URL) end)
    if not ok or not res or res == "" then return {} end
    local parsed = Http:JSONDecode(res)
    local list = {}
    for _, item in ipairs(parsed.data or {}) do
        if tonumber(item.id) and tonumber(item.id) > 0 then
            list[#list+1] = {id = tonumber(item.id), name = item.name or ("Anim_" .. item.id), bundledItems = item.bundledItems}
        end
    end
    return list
end

local function stopTrack()
    pcall(function()
        if St.track and St.track.IsPlaying then St.track:Stop() end
    end)
    St.track = nil
end

local function getChar()
    local char = LP.Character
    if not char then return nil, nil, nil end
    local hum      = char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    return char, hum, animator
end

local function playEmote(id)
    stopTrack()
    local _, hum, animator = getChar()
    if not hum or not animator then return end

    local ok, track = pcall(function()
        return hum:PlayEmoteAndGetAnimTrackById(id)
    end)
    if ok and track and typeof(track) == "Instance" and track:IsA("AnimationTrack") then
        St.track = track
        track.Looped = true
            return
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. tostring(id)
    local ok2, track2 = pcall(function() return animator:LoadAnimation(anim) end)
    if not ok2 or not track2 then return end
    track2.Priority = Enum.AnimationPriority.Action
    track2.Looped   = true
    St.track        = track2
    track2:Play()
end

local function playAnim(animData)
    stopTrack()
    if not animData.bundledItems then return end
    local char, _, animator = getChar()
    if not char or not animator then return end
    local animate = char:FindFirstChild("Animate")
    if not animate then return end

    for _, ids in pairs(animData.bundledItems) do
        for _, assetId in ipairs(ids) do
            task.spawn(function()
                local ok, objects = pcall(function()
                    return game:GetObjects("rbxassetid://" .. tostring(assetId))
                end)
                if not ok or not objects then return end
                for _, obj in ipairs(objects) do
                    local function applyAnims(parent, path)
                        for _, child in ipairs(parent:GetChildren()) do
                            if child:IsA("Animation") then
                                local parts = string.split(path .. "." .. child.Name, ".")
                                if #parts >= 2 then
                                    local cat   = parts[#parts - 1]
                                    local name  = parts[#parts]
                                    local catF  = animate:FindFirstChild(cat)
                                    if catF then
                                        local slot = catF:FindFirstChild(name)
                                        if slot and slot:IsA("Animation") then
                                            slot.AnimationId = child.AnimationId
                                            local anim = Instance.new("Animation")
                                            anim.AnimationId = child.AnimationId
                                            local tok, t = pcall(function() return animator:LoadAnimation(anim) end)
                                            if tok and t then
                                                t.Priority = Enum.AnimationPriority.Action
                                                t:Play()
                                                task.wait(0.1)
                                                t:Stop()
                                            end
                                        end
                                    end
                                end
                            elseif #child:GetChildren() > 0 then
                                applyAnims(child, path .. "." .. child.Name)
                            end
                        end
                    end
                    applyAnims(obj, obj.Name)
                    obj.Parent = workspace
                    task.delay(2, function() pcall(function() obj:Destroy() end) end)
                end
            end)
        end
    end
end

local function getSourceList()
    local base = St.mode == "emote" and St.emotes or St.anims
    if St.favOnly then
        local list = {}
        for _, item in ipairs(base) do
            if St.favs[tostring(item.id)] then list[#list+1] = item end
        end
        return list
    end
    return base
end

local function applyFilter()
    local src = getSourceList()
    local q   = St.search:lower()
    if q == "" then
        St.filtered = src
    else
        St.filtered = {}
        for _, item in ipairs(src) do
            if item.name:lower():find(q, 1, true) or tostring(item.id):find(q, 1, true) then
                St.filtered[#St.filtered+1] = item
            end
        end
    end
    St.totalPages = math.max(1, math.ceil(#St.filtered / ITEMS_PER_PAGE))
    St.page       = math.min(St.page, St.totalPages)
end

local function getPage()
    local s = (St.page - 1) * ITEMS_PER_PAGE + 1
    local result = {}
    for i = s, math.min(s + ITEMS_PER_PAGE - 1, #St.filtered) do
        result[#result+1] = St.filtered[i]
    end
    return result
end

local Main = frame(SG, {bg = C.BG0, sz = UDim2.new(0, 580, 0, 460), pos = UDim2.new(0.5, -290, 0.5, -230), clip = true, z = 100})
corner(Main, 12)
stroke(Main, C.Stk)
Main.Visible = false

do
    local g = Instance.new("UIGradient", Main)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 3, 3)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
    })
    g.Rotation = 135
end

local Header     = frame(Main, {bg = C.BG1, sz = UDim2.new(1, 0, 0, 48), z = 101})
corner(Header, 12)
local HeaderClip = frame(Header, {bg = C.BG1, sz = UDim2.new(1, 0, 0, 14), pos = UDim2.new(0, 0, 1, -14), z = 101})

local Div = frame(Main, {bg = C.Stk, sz = UDim2.new(1, -32, 0, 1), pos = UDim2.new(0, 16, 0, 48), z = 101})
do
    local g = Instance.new("UIGradient", Div)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.3, C.Accent),
        ColorSequenceKeypoint.new(0.7, C.Accent),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0, 0, 0)),
    })
end

local IconBg = frame(Header, {bg = C.BG3, sz = UDim2.new(0, 28, 0, 28), pos = UDim2.new(0, 12, 0.5, -14), z = 102})
corner(IconBg, 6)
local IconImg = Instance.new("ImageLabel", IconBg)
IconImg.Image                  = "rbxassetid://137394715816110"
IconImg.Size                   = UDim2.new(0, 18, 0, 18)
IconImg.Position               = UDim2.new(0.5, -9, 0.5, -9)
IconImg.BackgroundTransparency = 1
IconImg.ImageColor3            = C.Accent
IconImg.ZIndex                 = 103

label(Header, {text = "Emotes", font = Enum.Font.GothamBold, size = 14, color = C.W,
    sz = UDim2.new(0.5, 0, 1, 0), pos = UDim2.new(0, 50, 0, 0), z = 102})

local CloseBtn = btn(Header, {bg = C.BG3, text = "X", font = Enum.Font.GothamBold, size = 13, color = C.Dim,
    sz = UDim2.new(0, 28, 0, 28), pos = UDim2.new(1, -40, 0.5, -14), r = 6, z = 102})
CloseBtn.MouseEnter:Connect(function() tw(CloseBtn, 0.15, {BackgroundColor3 = C.AccentDark, TextColor3 = C.W}) end)
CloseBtn.MouseLeave:Connect(function() tw(CloseBtn, 0.15, {BackgroundColor3 = C.BG3,       TextColor3 = C.Dim}) end)
CloseBtn.MouseButton1Click:Connect(function()
    St.visible = false
    Main.Visible = false
end)

local Toolbar = frame(Main, {bg = C.BG0, bgt = 1, sz = UDim2.new(1, -32, 0, 36), pos = UDim2.new(0, 16, 0, 56), z = 101})

local TabBar    = frame(Toolbar, {bg = C.BG2, sz = UDim2.new(0, 160, 0, 28), pos = UDim2.new(0, 0, 0.5, -14), z = 102})
corner(TabBar, 7)
stroke(TabBar, C.Stk)

local TabSlider = frame(TabBar, {bg = C.BG3, sz = UDim2.new(0.5, -4, 1, -6), pos = UDim2.new(0, 3, 0, 3), z = 103})
corner(TabSlider, 5)

local TabEmote = btn(TabBar, {bg = C.BG0, bgt = 1, text = "Emotes", font = Enum.Font.GothamBold, size = 11,
    color = C.Accent, sz = UDim2.new(0.5, 0, 1, 0), r = false, z = 104})
local TabAnim  = btn(TabBar, {bg = C.BG0, bgt = 1, text = "Animations", font = Enum.Font.GothamBold, size = 11,
    color = C.Dim, sz = UDim2.new(0.5, 0, 1, 0), pos = UDim2.new(0.5, 0, 0, 0), r = false, z = 104})

local FavBtn    = btn(Toolbar, {bg = C.BG2, text = "Favourites", font = Enum.Font.GothamBold, size = 11, color = C.Dim,
    sz = UDim2.new(0, 88, 0, 28), pos = UDim2.new(0, 168, 0.5, -14), r = 6, z = 102})

local SearchFrame  = frame(Main, {bg = C.BG2, sz = UDim2.new(1, -32, 0, 30), pos = UDim2.new(0, 16, 0, 100), z = 101})
corner(SearchFrame, 8)
local SearchStroke = stroke(SearchFrame, C.Stk)

local SearchIcon = Instance.new("ImageLabel", SearchFrame)
SearchIcon.Image                  = "rbxassetid://73226807610398"
SearchIcon.Size                   = UDim2.new(0, 16, 0, 16)
SearchIcon.Position               = UDim2.new(0, 8, 0.5, -8)
SearchIcon.BackgroundTransparency = 1
SearchIcon.ImageColor3            = C.Dim
SearchIcon.ZIndex                 = 102

local SearchBox = Instance.new("TextBox", SearchFrame)
SearchBox.Size                   = UDim2.new(1, -36, 1, 0)
SearchBox.Position               = UDim2.new(0, 30, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.BorderSizePixel        = 0
SearchBox.Font                   = Enum.Font.Gotham
SearchBox.TextSize               = 12
SearchBox.TextColor3             = C.W
SearchBox.PlaceholderText        = "Search emotes..."
SearchBox.PlaceholderColor3      = C.Dim
SearchBox.Text                   = ""
SearchBox.ClearTextOnFocus       = false
SearchBox.TextStrokeTransparency = 1
SearchBox.TextXAlignment         = Enum.TextXAlignment.Left
SearchBox.ZIndex                 = 102

SearchBox.Focused:Connect(function()  tw(SearchStroke, 0.2, {Color = C.Accent}) end)
SearchBox.FocusLost:Connect(function() tw(SearchStroke, 0.2, {Color = C.Stk})   end)

local PageInfo = label(Main, {text = "Page 1 / 1", size = 10, color = C.Dim,
    sz = UDim2.new(0, 100, 0, 14), pos = UDim2.new(0.5, -50, 0, 138), align = Enum.TextXAlignment.Center, z = 101})

local function updatePageInfo()
    PageInfo.Text = "Page " .. St.page .. " / " .. St.totalPages .. "  •  " .. #St.filtered .. " results"
end

local PrevBtn = btn(Main, {bg = C.BG2, text = "‹", font = Enum.Font.GothamBold, size = 16, color = C.Dim,
    sz = UDim2.new(0, 28, 0, 18), pos = UDim2.new(0, 16, 0, 133), r = 5, z = 101})
stroke(PrevBtn, C.Stk)
local NextBtn = btn(Main, {bg = C.BG2, text = "›", font = Enum.Font.GothamBold, size = 16, color = C.Dim,
    sz = UDim2.new(0, 28, 0, 18), pos = UDim2.new(1, -44, 0, 133), r = 5, z = 101})
stroke(NextBtn, C.Stk)

local Grid = Instance.new("ScrollingFrame", Main)
Grid.Size                 = UDim2.new(1, -32, 1, -162)
Grid.Position             = UDim2.new(0, 16, 0, 158)
Grid.BackgroundTransparency = 1
Grid.BorderSizePixel      = 0
Grid.ScrollBarThickness   = 2
Grid.ScrollBarImageColor3 = C.Accent
Grid.CanvasSize           = UDim2.new(0, 0, 0, 0)
Grid.AutomaticCanvasSize  = Enum.AutomaticSize.Y
Grid.ClipsDescendants     = true
Grid.ZIndex               = 101

local GridLayout = Instance.new("UIGridLayout", Grid)
GridLayout.CellSize             = UDim2.new(0, 120, 0, 130)
GridLayout.CellPadding          = UDim2.new(0, 8, 0, 8)
GridLayout.SortOrder            = Enum.SortOrder.LayoutOrder
GridLayout.HorizontalAlignment  = Enum.HorizontalAlignment.Center

local GridPad = Instance.new("UIPadding", Grid)
GridPad.PaddingTop    = UDim.new(0, 4)
GridPad.PaddingBottom = UDim.new(0, 12)

local bindOverlay    = nil
local bindActiveItem = nil

local function closeBind()
    if bindOverlay then bindOverlay:Destroy() bindOverlay = nil end
    bindActiveItem = nil
end

local function buildCard(item, refreshFn)
    local card       = frame(Grid, {bg = C.BG1, sz = UDim2.new(0, 120, 0, 130), z = 102})
    corner(card, 8)
    local cardStroke = stroke(card, C.Stk)

    local thumb = Instance.new("ImageLabel", card)
    thumb.Size             = UDim2.new(1, -12, 0, 80)
    thumb.Position         = UDim2.new(0, 6, 0, 6)
    thumb.BackgroundColor3 = C.BG2
    thumb.BorderSizePixel  = 0
    thumb.ScaleType        = Enum.ScaleType.Fit
    thumb.ZIndex           = 103
    corner(thumb, 6)

    if St.mode == "emote" then
        thumb.Image = "rbxthumb://type=Asset&id=" .. item.id .. "&w=420&h=420"
    else
        thumb.Image = "rbxthumb://type=BundleThumbnail&id=" .. item.id .. "&w=420&h=420"
    end

    local nameL = label(card, {text = item.name, size = 10, color = C.Dim, wrap = true,
        sz = UDim2.new(1, -10, 0, 26), pos = UDim2.new(0, 5, 0, 88), z = 103})
    nameL.TextXAlignment = Enum.TextXAlignment.Center

    local isFav  = St.favs[tostring(item.id)]
    local hasBind = St.binds[tostring(item.id)]

    local FavIco = Instance.new("ImageButton", card)
    FavIco.Size                   = UDim2.new(0, 18, 0, 18)
    FavIco.Position               = UDim2.new(0, 5, 1, -22)
    FavIco.BackgroundTransparency = 1
    FavIco.BorderSizePixel        = 0
    FavIco.AutoButtonColor        = false
    FavIco.Image                  = isFav and "rbxassetid://102437792716891" or "rbxassetid://95978656668759"
    FavIco.ImageColor3            = isFav and Color3.fromRGB(255, 200, 50) or C.Dim
    FavIco.ZIndex                 = 104

    local BindIco    = btn(card, {bg = C.BG3, text = hasBind and hasBind:sub(1,3) or "+",
        font = Enum.Font.GothamBold, size = 8, color = hasBind and C.W or C.Dim,
        sz = UDim2.new(0, 26, 0, 18), pos = UDim2.new(1, -31, 1, -22), r = 4, z = 104})
    local BindStroke = stroke(BindIco, C.Stk)

    local PlayArea = btn(card, {bg = C.BG0, bgt = 1, text = "",
        sz = UDim2.new(1, 0, 1, -22), r = false, z = 103})

    PlayArea.MouseEnter:Connect(function()
        tw(card,       0.15, {BackgroundColor3 = C.BG2})
        tw(cardStroke, 0.15, {Color = C.Accent})
    end)
    PlayArea.MouseLeave:Connect(function()
        tw(card,       0.15, {BackgroundColor3 = C.BG1})
        tw(cardStroke, 0.15, {Color = C.Stk})
    end)
    PlayArea.MouseButton1Click:Connect(function()
        if St.mode == "emote" then
            playEmote(item.id)
        else
            playAnim(item)
        end
        notify("Emotes", "Playing: " .. item.name)
    end)

    FavIco.MouseButton1Click:Connect(function()
        local id = tostring(item.id)
        if St.favs[id] then
            St.favs[id]    = nil
            FavIco.Image      = "rbxassetid://95978656668759"
            FavIco.ImageColor3 = C.Dim
            notify("Favourites", "Removed: " .. item.name)
        else
            St.favs[id] = true
            FavIco.Image = "rbxassetid://102437792716891"
            tw(FavIco, 0.15, {ImageColor3 = Color3.fromRGB(255, 200, 50)})
            notify("Favourites", "Added: " .. item.name)
        end
        saveFavs()
        if St.favOnly then refreshFn() end
    end)

    local listening  = false
    local bindKeyConn = nil

    BindIco.MouseButton1Click:Connect(function()
        if bindActiveItem and bindActiveItem ~= BindIco then closeBind() end

        if listening then
            listening = false
            if bindKeyConn then bindKeyConn:Disconnect() bindKeyConn = nil end
            if bindOverlay  then bindOverlay:Destroy()   bindOverlay = nil end
            bindActiveItem = nil
            local hb = St.binds[tostring(item.id)]
            BindIco.Text       = hb and hb:sub(1,3) or "+"
            BindIco.TextColor3 = hb and C.W or C.Dim
            tw(BindStroke, 0.15, {Color = C.Stk})
            return
        end

        listening      = true
        bindActiveItem = BindIco
        BindIco.Text       = "..."
        BindIco.TextColor3 = C.W
        BindStroke.Color   = C.Accent

        bindOverlay = Instance.new("TextButton", SG)
        bindOverlay.Size                   = UDim2.new(1, 0, 1, 0)
        bindOverlay.BackgroundTransparency = 1
        bindOverlay.Text                   = ""
        bindOverlay.ZIndex                 = 10001
        bindOverlay.BorderSizePixel        = 0
        bindOverlay.AutoButtonColor        = false
        BindIco.ZIndex = 10002

        bindOverlay.MouseButton1Click:Connect(function()
            St.binds[tostring(item.id)] = nil
            saveBinds()
            BindIco.Text       = "+"
            BindIco.TextColor3 = C.Dim
            tw(BindStroke, 0.15, {Color = C.Stk})
            listening = false
            if bindKeyConn then bindKeyConn:Disconnect() bindKeyConn = nil end
            if bindOverlay  then bindOverlay:Destroy()   bindOverlay = nil end
            bindActiveItem = nil
            BindIco.ZIndex = 104
        end)

        bindKeyConn = UIS.InputBegan:Connect(function(i, gp)
            if gp then return end
            if i.UserInputType == Enum.UserInputType.Keyboard then
                local keyName = i.KeyCode.Name
                St.binds[tostring(item.id)] = keyName
                saveBinds()
                BindIco.Text       = keyName:sub(1, 3)
                BindIco.TextColor3 = C.W
                tw(BindStroke, 0.15, {Color = C.Stk})
                listening = false
                bindKeyConn:Disconnect()
                bindKeyConn    = nil
                if bindOverlay then bindOverlay:Destroy() bindOverlay = nil end
                bindActiveItem = nil
                BindIco.ZIndex = 104
                notify("Keybind", keyName .. " → " .. item.name)
            end
        end)
    end)

    return card
end

local rendered = {}

local function renderPage()
    Grid.CanvasPosition = Vector2.zero
    for _, c in ipairs(rendered) do c:Destroy() end
    rendered = {}

    local items = getPage()
    if #items == 0 then
        rendered[#rendered+1] = label(Grid, {text = "No results found.", size = 12, color = C.Dim,
            sz = UDim2.new(1, 0, 0, 40), align = Enum.TextXAlignment.Center, z = 102})
        return
    end

    local function refresh() applyFilter() renderPage() updatePageInfo() end
    for _, item in ipairs(items) do
        rendered[#rendered+1] = buildCard(item, refresh)
    end
    updatePageInfo()
end

local function switchMode(mode)
    St.mode   = mode
    St.page   = 1
    St.search = ""
    SearchBox.Text = ""
    applyFilter()
    renderPage()
    updatePageInfo()
    if mode == "emote" then
        tw(TabSlider, 0.2, {Position = UDim2.new(0, 3, 0, 3)})
        TabEmote.TextColor3 = C.Accent
        TabAnim.TextColor3  = C.Dim
        SearchBox.PlaceholderText = "Search emotes..."
    else
        tw(TabSlider, 0.2, {Position = UDim2.new(0.5, 1, 0, 3)})
        TabAnim.TextColor3  = C.Accent
        TabEmote.TextColor3 = C.Dim
        SearchBox.PlaceholderText = "Search animations..."
    end
end

TabEmote.MouseButton1Click:Connect(function() if St.mode ~= "emote" then switchMode("emote") end end)
TabAnim.MouseButton1Click:Connect(function()  if St.mode ~= "anim"  then switchMode("anim")  end end)

FavBtn.MouseButton1Click:Connect(function()
    St.favOnly = not St.favOnly
    if St.favOnly then
        tw(FavBtn, 0.15, {BackgroundColor3 = C.AccentDark, TextColor3 = C.W})
    else
        tw(FavBtn, 0.15, {BackgroundColor3 = C.BG2, TextColor3 = C.Dim})
    end
    St.page = 1
    applyFilter()
    renderPage()
    updatePageInfo()
end)



PrevBtn.MouseButton1Click:Connect(function()
    St.page = St.page <= 1 and St.totalPages or St.page - 1
    renderPage()
    updatePageInfo()
end)

NextBtn.MouseButton1Click:Connect(function()
    St.page = St.page >= St.totalPages and 1 or St.page + 1
    renderPage()
    updatePageInfo()
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    St.search = SearchBox.Text
    St.page   = 1
    applyFilter()
    renderPage()
    updatePageInfo()
end)

UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local keyName = i.KeyCode.Name
    for id, boundKey in pairs(St.binds) do
        if boundKey == keyName then
            local idNum = tonumber(id)
            local list  = St.mode == "emote" and St.emotes or St.anims
            for _, item in ipairs(list) do
                if item.id == idNum then
                    if St.mode == "emote" then playEmote(item.id)
                    else                      playAnim(item) end
                    notify("Keybind", "Playing: " .. item.name)
                    break
                end
            end
        end
    end
end)

do
    local dragStart, startPos
    Header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStart = i.Position
            startPos  = Main.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragStart and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragStart = nil end
    end)
end

UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.P then
        St.visible   = not St.visible
        Main.Visible = St.visible
        if St.visible then
            Main.Size = UDim2.new(0, 540, 0, 420)
            Main.BackgroundTransparency = 0
            TS:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 580, 0, 460),
            }):Play()
        end
    end
end)

LP.CharacterAdded:Connect(function(char)
    Char = char
    Hum  = char:WaitForChild("Humanoid")
    St.track   = nil
end)

notify("Emotes", "Loading... press P to toggle")

task.spawn(function()
    St.emotes = fetchEmotes()
    St.anims  = fetchAnims()
    applyFilter()
    renderPage()
    updatePageInfo()
    notify("Emotes", #St.emotes .. " emotes  •  " .. #St.anims .. " animations")
end)
