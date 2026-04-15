local addonName = ...
PenanceTicksDB = PenanceTicksDB or {}

---------------------------------------------------------
-- DEFAULTS
---------------------------------------------------------
local defaults = {
    tickCount = 3,
    castBarEnabled = true,
    barX = 0,
    barY = -160,
    barWidth = 240,
    barHeight = 18,
}

local function LoadDefaults()
    for k, v in pairs(defaults) do
        if PenanceTicksDB[k] == nil then
            PenanceTicksDB[k] = v
        end
    end
end

---------------------------------------------------------
-- CONFIG
---------------------------------------------------------
local SPELL_NAME    = "Penance"
local BASE_DURATION = 2.0

local sounds = {
    "Interface\\AddOns\\PenanceTicks\\Media\\Sounds\\1.ogg",
    "Interface\\AddOns\\PenanceTicks\\Media\\Sounds\\2.ogg",
    "Interface\\AddOns\\PenanceTicks\\Media\\Sounds\\3.ogg",
    "Interface\\AddOns\\PenanceTicks\\Media\\Sounds\\4.ogg",
}

---------------------------------------------------------
-- STATE
---------------------------------------------------------
local active = false
local startTime = 0
local duration = 0
local lastTick = 0

local function PlayTick(i)
    local file = sounds[i]
    if file then
        PlaySoundFile(file, "SFX")
    end
end

---------------------------------------------------------
-- CAST BAR (created AFTER defaults load)
---------------------------------------------------------
local bar

local function CreateBar()
    bar = CreateFrame("StatusBar", "PenanceTicksBar", UIParent)
    bar:SetSize(PenanceTicksDB.barWidth, PenanceTicksDB.barHeight)
    bar:SetPoint("CENTER", PenanceTicksDB.barX, PenanceTicksDB.barY)
    bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    bar:SetMinMaxValues(0, 1)
    bar:Hide()

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(0, 0, 0, 0.6)

    bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bar.text:SetPoint("CENTER")

    -- Movable + resizable
    bar:SetMovable(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", bar.StartMoving)
    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local ux, uy = UIParent:GetCenter()
        PenanceTicksDB.barX = x - ux
        PenanceTicksDB.barY = y - uy
    end)

    local resize = CreateFrame("Frame", nil, bar)
    resize:SetSize(16, 16)
    resize:SetPoint("BOTTOMRIGHT")
    resize:EnableMouse(true)
    resize:SetScript("OnMouseDown", function()
        bar:StartSizing("BOTTOMRIGHT")
    end)
    resize:SetScript("OnMouseUp", function()
        bar:StopMovingOrSizing()
        PenanceTicksDB.barWidth = bar:GetWidth()
        PenanceTicksDB.barHeight = bar:GetHeight()
    end)

    -- UPDATE LOOP (moved here so bar is never nil)
    bar:SetScript("OnUpdate", function()
        if not active then return end

        local now = GetTime()
        local elapsed = now - startTime
        if elapsed < 0 then elapsed = 0 end
        if elapsed > duration then elapsed = duration end

        local progress = elapsed / duration
        bar:SetValue(progress)

        local TICK_COUNT = PenanceTicksDB.tickCount
        local tickDuration = duration / TICK_COUNT
        local expectedTick = math.floor(elapsed / tickDuration) + 1

        if expectedTick > TICK_COUNT then expectedTick = TICK_COUNT end

        if expectedTick ~= lastTick then
            lastTick = expectedTick
            PlayTick(expectedTick)
        end

        bar.text:SetText("Tick " .. expectedTick .. "/" .. TICK_COUNT)
    end)
end

---------------------------------------------------------
-- GUI WINDOW
---------------------------------------------------------
local gui

local function CreateGUI()
    if gui then return end

    gui = CreateFrame("Frame", "PenanceTicksGUI", UIParent, "BackdropTemplate")
    gui:SetSize(240, 180)
    gui:SetPoint("CENTER")
    gui:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    gui:EnableMouse(true)
    gui:SetMovable(true)
    gui:RegisterForDrag("LeftButton")
    gui:SetScript("OnDragStart", gui.StartMoving)
    gui:SetScript("OnDragStop", gui.StopMovingOrSizing)
    gui:Hide()

    -- Close button
    local close = CreateFrame("Button", nil, gui, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)

    -- Title
    local title = gui:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("PenanceTicks")

    -- 3 ticks
    local b3 = CreateFrame("Button", nil, gui, "UIPanelButtonTemplate")
    b3:SetSize(70, 24)
    b3:SetPoint("TOPLEFT", 20, -40)
    b3:SetText("3 Ticks")
    b3:SetScript("OnClick", function()
        PenanceTicksDB.tickCount = 3
        print("PenanceTicks: 3 ticks")
    end)

    -- 4 ticks
    local b4 = CreateFrame("Button", nil, gui, "UIPanelButtonTemplate")
    b4:SetSize(70, 24)
    b4:SetPoint("TOPRIGHT", -20, -40)
    b4:SetText("4 Ticks")
    b4:SetScript("OnClick", function()
        PenanceTicksDB.tickCount = 4
        print("PenanceTicks: 4 ticks")
    end)

    -- Enable cast bar
    local cb = CreateFrame("CheckButton", nil, gui, "ChatConfigCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 20, -80)
    cb.Text:SetText("Enable Cast Bar")
    cb:SetChecked(PenanceTicksDB.castBarEnabled)
    cb:SetScript("OnClick", function(self)
        PenanceTicksDB.castBarEnabled = self:GetChecked()
        if gui:IsShown() then
            if self:GetChecked() then bar:Show() else bar:Hide() end
        end
    end)

    -- Preview when GUI opens
    gui:SetScript("OnShow", function()
        if PenanceTicksDB.castBarEnabled then
            bar:SetValue(1)
            bar.text:SetText("Preview")
            bar:Show()
        end
    end)

    gui:SetScript("OnHide", function()
        if not active then
            bar:Hide()
        end
    end)
end

---------------------------------------------------------
-- SLASH COMMAND
---------------------------------------------------------
SLASH_PENANCETICKS1 = "/pt"
SlashCmdList["PENANCETICKS"] = function()
    if not gui then CreateGUI() end
    if gui:IsShown() then gui:Hide() else gui:Show() end
end

---------------------------------------------------------
-- EVENTS: START/STOP PENANCE
---------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")

frame:SetScript("OnEvent", function(_, event, unit)
    if unit ~= "player" then return end

    if event == "UNIT_SPELLCAST_CHANNEL_START" then
        local name = UnitChannelInfo("player")
        if name ~= SPELL_NAME then return end

        local haste = UnitSpellHaste("player") / 100
        duration = BASE_DURATION / (1 + haste)

        active = true
        startTime = GetTime()
        lastTick = 0

        if PenanceTicksDB.castBarEnabled then
            bar:Show()
        end

    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
    active = false

    -- GUI may not exist yet
    if gui and gui:IsShown() then
        -- GUI open → keep preview visible
        return
    end

    -- GUI closed or not created → hide bar
    bar:Hide()
    end
end)

---------------------------------------------------------
-- ADDON LOADED (load defaults THEN create bar)
---------------------------------------------------------
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, name)
    if name ~= addonName then return end
    LoadDefaults()
    CreateBar()
end)
