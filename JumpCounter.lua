------------------------------------------------
-- PER-CHARACTER SAVED DATA
------------------------------------------------
JumpCounterDB = JumpCounterDB or { 
    count = 0,
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

------------------------------------------------
-- TEXT (definiraj ovo PRIJE resize dijela!)
------------------------------------------------
local text = display:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
text:SetPoint("CENTER")

local function UpdateText()
    text:SetText("JumpCounter: " .. JumpCounterDB.count)
    
    -- Prilagodi veličinu fonta prema visini displaya
    local height = display:GetHeight()
    if height < 50 then
        text:SetFontObject("GameFontNormal")
    elseif height < 70 then
        text:SetFontObject("GameFontNormalLarge")
    else
        text:SetFontObject("GameFontNormalHuge")
    end
    
    -- Centriraj tekst
    text:ClearAllPoints()
    text:SetPoint("CENTER")
end

-- Kreiraj poseban "drag handle" na gornjem dijelu
local dragHandle = CreateFrame("Frame", nil, display)
dragHandle:SetHeight(20)
dragHandle:SetPoint("TOPLEFT", 0, 0)
dragHandle:SetPoint("TOPRIGHT", 0, 0)
dragHandle:EnableMouse(true)
dragHandle:RegisterForDrag("LeftButton")

-- Tekst za pokazivanje da se može vući
local dragText = dragHandle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dragText:SetPoint("CENTER")
dragText:SetText("")
dragText:SetTextColor(0.8, 0.8, 0.8, 0.8)

dragHandle:SetScript("OnDragStart", function(self)
    display:StartMoving()
end)

dragHandle:SetScript("OnDragStop", function(self)
    display:StopMovingOrSizing()
    -- Spremi novu poziciju
    local point, _, relativePoint, xOfs, yOfs = display:GetPoint(1)
    JumpCounterDB.point = point
    JumpCounterDB.x = xOfs
    JumpCounterDB.y = yOfs
end)

-- MANUAL RESIZE ZA CLASSIC (bez SetMinResize/SetMaxResize)
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
        display:StartMoving() -- Koristimo StartMoving kao workaround za resize
    end
end)

resizeButton:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and isResizing then
        isResizing = false
        display:StopMovingOrSizing()
        -- Spremi novu veličinu
        JumpCounterDB.width, JumpCounterDB.height = display:GetSize()
        UpdateText() -- Update teksta nakon resize-a
    end
end)

-- Update veličine tijekom resize-a
resizeButton:SetScript("OnUpdate", function(self)
    if isResizing then
        local currentX, currentY = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        
        local deltaX = (currentX - display.startX) / scale
        local deltaY = (display.startY - currentY) / scale  -- Obrnuto za Y os
        
        -- Izračunaj novu veličinu
        local newWidth = display.startWidth + deltaX
        local newHeight = display.startHeight + deltaY
        
        -- Ograniči veličinu
        newWidth = math.max(minWidth, math.min(maxWidth, newWidth))
        newHeight = math.max(minHeight, math.min(maxHeight, newHeight))
        
        -- Postavi novu veličinu
        display:SetSize(newWidth, newHeight)
        
        -- Update teksta (samo centriranje, bez promjene teksta)
        text:ClearAllPoints()
        text:SetPoint("CENTER")
    end
end)

-- Spriječi resize ako klikamo negdje drugdje
display:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not isResizing then
        -- Spriječi da se resize aktivira na cijelom frameu
        return
    end
end)

------------------------------------------------
-- SKOK DETEKCIJA (Classic-safe)
------------------------------------------------
local wasFalling = false

frame:SetScript("OnUpdate", function()
    local isFalling = IsFalling()

    -- trenutak kad započne skok
    if isFalling and not wasFalling then
        JumpCounterDB.count = JumpCounterDB.count + 1
        UpdateText()
    end

    wasFalling = isFalling
end)

------------------------------------------------
-- INIT
------------------------------------------------
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if not JumpCounterDB.count then
            JumpCounterDB.count = 0
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
        UpdateText()
        print("|cff00ff00JumpCounter:|r resetirano.")
    elseif msg == "resetpos" then
        -- Resetiraj poziciju na default
        display:ClearAllPoints()
        display:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
        display:SetSize(200, 40)
        
        -- Update bazu podataka
        JumpCounterDB.point = "CENTER"
        JumpCounterDB.x = 0
        JumpCounterDB.y = 200
        JumpCounterDB.width = 200
        JumpCounterDB.height = 40
        
        UpdateText()
        print("|cff00ff00JumpCounter:|r pozicija resetirana.")
    elseif msg == "lock" then
        -- Zaključaj poziciju
        display:SetMovable(false)
        dragText:Hide()
        print("|cff00ff00JumpCounter:|r zaključano.")
    elseif msg == "unlock" then
        -- Otključaj poziciju
        display:SetMovable(true)
        dragText:Show()
        print("|cff00ff00JumpCounter:|r otključano.")
    else
        print("|cff00ff00JumpCounter:|r " .. JumpCounterDB.count .. " skokova")
        print("Koristi:")
        print("|cffffcc00/jc reset|r - Resetiraj brojač")
        print("|cffffcc00/jc resetpos|r - Resetiraj poziciju prozora")
        print("|cffffcc00/jc lock|r - Zaključaj prozor")
        print("|cffffcc00/jc unlock|r - Otključaj prozor")
    end
end

-- Spremi poziciju pri izlazu iz igre
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGOUT" then
        -- Spremi trenutnu poziciju
        local point, _, relativePoint, xOfs, yOfs = display:GetPoint(1)
        JumpCounterDB.point = point
        JumpCounterDB.x = xOfs
        JumpCounterDB.y = yOfs
        JumpCounterDB.width, JumpCounterDB.height = display:GetSize()
    end
end)