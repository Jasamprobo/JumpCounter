------------------------------------------------
-- PER-CHARACTER SAVED DATA
------------------------------------------------
JumpCounterDB = JumpCounterDB or { 
    count = 0,
    sessionCount = 0,
    lastJumpTime = nil,
    point = "CENTER",
    x = 0,
    y = 200,
    width = 200,
    height = 40
}

------------------------------------------------
-- FRAME
------------------------------------------------
local frame = CreateFrame("Frame")

------------------------------------------------
-- GUI
------------------------------------------------
local display = CreateFrame("Frame", "JumpCounterDisplay", UIParent, "BackdropTemplate")

-- Postavi veličinu iz baze podataka
display:SetSize(JumpCounterDB.width, JumpCounterDB.height)
display:SetPoint(JumpCounterDB.point, UIParent, JumpCounterDB.point, JumpCounterDB.x, JumpCounterDB.y)

display:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
display:SetBackdropColor(0, 0, 0, 0.7)

-- Omogući pomicanje
display:EnableMouse(true)
display:SetMovable(true)

-- Omogući pomicanje cijelog prozora
display:RegisterForDrag("LeftButton")
display:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

display:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Spremi novu poziciju
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint(1)
    JumpCounterDB.point = point
    JumpCounterDB.x = xOfs
    JumpCounterDB.y = yOfs
end)

-- Tooltip za pomicanje
display:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("JumpCounter")
    GameTooltip:AddLine("Lijevi klik i vuci za pomicanje", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Donji desni kut za resize", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

display:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

------------------------------------------------
-- TEXT
------------------------------------------------
local text = display:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
text:SetPoint("CENTER")

local function UpdateText()
    local total = JumpCounterDB.count
    local session = JumpCounterDB.sessionCount or 0
    
    -- Izračunaj rate samo ako ima session podataka
    local rateText = ""
    if session > 10 then  -- Bar 10 skokova za precizniji rate
        rateText = "Rate: " .. math.floor(session / 5) .. "/min"
    end
    
    -- Prilagodi tekst prema veličini prozora
    local width, height = display:GetSize()
    
    if height < 50 then
        -- Mala visina - samo total
        text:SetFontObject("GameFontNormal")
        text:SetText("Jumps: " .. total)
    elseif height < 70 then
        -- Srednja visina - total + session
        text:SetFontObject("GameFontNormalLarge")
        text:SetText(string.format("Total: %d\nSess: %d", total, session))
    else
        -- Velika visina - sve informacije
        text:SetFontObject("GameFontNormalHuge")
        if rateText ~= "" then
            text:SetText(string.format("Total: %d\nSession: %d\n%s", 
                total, session, rateText))
        else
            text:SetText(string.format("Total: %d\nSession: %d", total, session))
        end
    end
    
    -- Centriraj tekst
    text:ClearAllPoints()
    text:SetPoint("CENTER")
end

-- MANUAL RESIZE ZA CLASSIC
local isResizing = false
local minWidth, minHeight = 100, 30
local maxWidth, maxHeight = 400, 100

local resizeButton = CreateFrame("Button", nil, display)
resizeButton:SetSize(16, 16)
resizeButton:SetPoint("BOTTOMRIGHT", -2, 2)
resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeButton:SetFrameLevel(display:GetFrameLevel() + 10)

resizeButton:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        isResizing = true
        display.startWidth, display.startHeight = display:GetSize()
        display.startX, display.startY = GetCursorPosition()
    end
end)

resizeButton:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and isResizing then
        isResizing = false
        -- Spremi novu veličinu
        JumpCounterDB.width, JumpCounterDB.height = display:GetSize()
        UpdateText()
    end
end)

-- Update veličine tijekom resize-a
resizeButton:SetScript("OnUpdate", function(self)
    if isResizing then
        local currentX, currentY = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        
        local deltaX = (currentX - display.startX) / scale
        local deltaY = (display.startY - currentY) / scale
        
        local newWidth = display.startWidth + deltaX
        local newHeight = display.startHeight + deltaY
        
        -- Ograniči veličinu
        newWidth = math.max(minWidth, math.min(maxWidth, newWidth))
        newHeight = math.max(minHeight, math.min(maxHeight, newHeight))
        
        display:SetSize(newWidth, newHeight)
        text:ClearAllPoints()
        text:SetPoint("CENTER")
    end
end)

------------------------------------------------
-- SKOK DETEKCIJA I SESSION TRACKING
------------------------------------------------
local wasFalling = false
local SESSION_TIMEOUT = 300 -- 5 minuta bez skokova = nova session

frame:SetScript("OnUpdate", function()
    local isFalling = IsFalling()

    if isFalling and not wasFalling then
        local now = GetTime()
        
        -- Provjeri treba li nova session
        if not JumpCounterDB.lastJumpTime or 
           (now - JumpCounterDB.lastJumpTime) > SESSION_TIMEOUT then
            -- Resetiraj session count
            JumpCounterDB.sessionCount = 1
        else
            -- Povećaj session count
            JumpCounterDB.sessionCount = (JumpCounterDB.sessionCount or 0) + 1
        end
        
        -- Povećaj total count
        JumpCounterDB.count = JumpCounterDB.count + 1
        JumpCounterDB.lastJumpTime = now
        
        UpdateText()
    end

    wasFalling = isFalling
end)

------------------------------------------------
-- INIT
------------------------------------------------
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        -- Inicijaliziraj ako ne postoje
        if not JumpCounterDB.count then JumpCounterDB.count = 0 end
        if not JumpCounterDB.sessionCount then JumpCounterDB.sessionCount = 0 end
        
        -- Provjeri je li prošlo previše vremena od zadnjeg skoka
        local now = GetTime()
        if JumpCounterDB.lastJumpTime and 
           (now - JumpCounterDB.lastJumpTime) > SESSION_TIMEOUT then
            -- Resetiraj session
            JumpCounterDB.sessionCount = 0
        end
        
        UpdateText()
    end
end)

------------------------------------------------
-- SLASH COMMANDS
------------------------------------------------
SLASH_JUMPCOUNTER1 = "/jc"
SLASH_JUMPCOUNTER2 = "/jumpcount"

SlashCmdList["JUMPCOUNTER"] = function(msg)
    msg = msg:lower()

    if msg == "reset" then
        JumpCounterDB.count = 0
        JumpCounterDB.sessionCount = 0
        UpdateText()
        print("|cff00ff00JumpCounter:|r resetirano.")
    elseif msg == "resetsession" then
        JumpCounterDB.sessionCount = 0
        UpdateText()
        print("|cff00ff00JumpCounter:|r session resetirana.")
    elseif msg == "resetpos" then
        display:ClearAllPoints()
        display:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
        display:SetSize(200, 40)
        
        JumpCounterDB.point = "CENTER"
        JumpCounterDB.x = 0
        JumpCounterDB.y = 200
        JumpCounterDB.width = 200
        JumpCounterDB.height = 40
        
        UpdateText()
        print("|cff00ff00JumpCounter:|r pozicija resetirana.")
    elseif msg == "stats" or msg == "" then
        local rate = "N/A"
        if JumpCounterDB.sessionCount > 10 then
            rate = math.floor(JumpCounterDB.sessionCount / 5) .. "/min"
        end
        
        print("|cff00ff00=== JumpCounter Stats ===")
        print("|cffffcc00Total Jumps:|r " .. JumpCounterDB.count)
        print("|cffffcc00Session Jumps:|r " .. JumpCounterDB.sessionCount)
        print("|cffffcc00Jump Rate:|r " .. rate)
        print("|cffffcc00Last Jump:|r " .. 
              (JumpCounterDB.lastJumpTime and "Recently" or "Never"))
    elseif msg == "help" then
        print("|cff00ff00JumpCounter Commands:")
        print("|cffffcc00/jc|r - Show stats")
        print("|cffffcc00/jc reset|r - Reset total counter")
        print("|cffffcc00/jc resetsession|r - Reset session only")
        print("|cffffcc00/jc resetpos|r - Reset window position")
        print("|cffffcc00/jc stats|r - Detailed statistics")
    else
        print("|cff00ff00JumpCounter:|r Unknown command. Type /jc help for commands.")
    end
end

-- Spremi poziciju pri izlazu
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGOUT" then
        local point, _, relativePoint, xOfs, yOfs = display:GetPoint(1)
        JumpCounterDB.point = point
        JumpCounterDB.x = xOfs
        JumpCounterDB.y = yOfs
        JumpCounterDB.width, JumpCounterDB.height = display:GetSize()
    end
end)

-- Force save periodically (svakih 30 sekundi)
local saveTimer = 0
frame:SetScript("OnUpdate", function(self, elapsed)
    -- Poziv originalnog OnUpdate za jump detekciju
    local isFalling = IsFalling()
    if isFalling and not wasFalling then
        local now = GetTime()
        
        if not JumpCounterDB.lastJumpTime or 
           (now - JumpCounterDB.lastJumpTime) > SESSION_TIMEOUT then
            JumpCounterDB.sessionCount = 1
        else
            JumpCounterDB.sessionCount = (JumpCounterDB.sessionCount or 0) + 1
        end
        
        JumpCounterDB.count = JumpCounterDB.count + 1
        JumpCounterDB.lastJumpTime = now
        
        UpdateText()
    end
    wasFalling = isFalling
    
    -- Periodicno spremanje
    saveTimer = saveTimer + elapsed
    if saveTimer > 30 then  -- Svakih 30 sekundi
        saveTimer = 0
        -- Force garbage collection može potaknuti spremanje
        collectgarbage("collect")
    end
end)

print("|cff00ff00JumpCounter|r loaded. Type |cffffcc00/jc|r for commands.")