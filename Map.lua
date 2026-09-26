local _, addon = ...

local function NewPin(parent, step)
    local pin = CreateFrame("Button", nil, parent, "BackdropTemplate")
    pin.step = step
    pin:SetSize(25, 25)
    pin:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
    pin:SetBackdropColor(0.13, 0.19, 0.26, 0.94)
    pin:SetBackdropBorderColor(1, 0.72, 0.24, 1)
    pin:SetFrameLevel(parent:GetFrameLevel() + 2)
    pin.text = pin:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pin.text:SetPoint("CENTER")
    pin.text:SetText(step.number)
    pin:SetScript("OnEnter", function(self) addon:ShowTip(self, self.step) end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    pin:SetScript("OnClick", function(self) addon:SetStep(self.step.number) end)
    return pin
end

function addon:InitializeMap()
    if self.mapOverlay then return end
    local map = WorldMapFrame
    if not map then return end
    local canvas = map:GetCanvas()
    local overlay = CreateFrame("Frame", nil, canvas)
    overlay:SetAllPoints(canvas)
    overlay:SetFrameLevel(canvas:GetFrameLevel() + 5)
    overlay:EnableMouse(false)
    overlay.pins = {}
    self.mapOverlay = overlay

    overlay:SetScript("OnSizeChanged", function() addon:RefreshMap() end)
    map:HookScript("OnShow", function() addon:RefreshMap() end)
    hooksecurefunc(map, "OnMapChanged", function() addon:RefreshMap() end)
    self:RefreshMap()
end

function addon:RefreshMap()
    local overlay = self.mapOverlay
    if not overlay then return end
    for _, pin in ipairs(overlay.pins) do pin:Hide() end

    local dungeon = self:GetDungeon()
    local mapID = WorldMapFrame:GetMapID()
    if not dungeon or not self.db.showMap or not mapID then return end
    local width, height = overlay:GetSize()
    if width <= 0 or height <= 0 then return end

    local pinCount = 0
    for _, step in ipairs(dungeon.steps) do
        if step.mapID == mapID then
            pinCount = pinCount + 1
            local pin = overlay.pins[pinCount]
            if not pin then
                pin = NewPin(overlay, step)
                overlay.pins[pinCount] = pin
            end
            pin.step = step
            pin.text:SetText(step.number)
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", overlay, "TOPLEFT",
                (step.labelX or step.x) * width, -(step.labelY or step.y) * height)
            pin:Show()
        end
    end
end
