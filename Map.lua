local _, addon = ...

local function WithLabelOffset(step, x, y, defaultXOffset)
    if not x or not y then return end
    local labelX = step.labelX or math.max(0.04, math.min(0.96,
        x + (step.labelDX or defaultXOffset or 0)))
    local labelY = step.labelY or math.max(0.04, math.min(0.96,
        y + (step.labelDY or 0)))
    return x, y, labelX, labelY
end

local function GetStepPosition(step, encounters, links)
    if step.journalEncounterID then
        for _, encounter in ipairs(encounters or {}) do
            if encounter.encounterID == step.journalEncounterID
                and encounter.mapX and encounter.mapY then
                return WithLabelOffset(step, encounter.mapX, encounter.mapY, 0.045)
            end
        end
    elseif step.linkedMapID or step.entranceLink then
        for _, link in ipairs(links or {}) do
            local isEntrance = step.entranceLink and link.linkedUiMapID
                and (link.linkedUiMapID < 2073 or link.linkedUiMapID > 2077)
            if (link.linkedUiMapID == step.linkedMapID or isEntrance) and link.position then
                return WithLabelOffset(step, link.position.x, link.position.y)
            end
        end
    end
    return step.x, step.y, step.labelX, step.labelY
end

local function UpdateDraggedPin(pin)
    local x, y = WorldMapFrame:GetNormalizedCursorPosition()
    if not x or not y then return end
    x = math.max(0.02, math.min(0.98, x))
    y = math.max(0.02, math.min(0.98, y))
    pin.dragX, pin.dragY = x, y
    local overlay = pin:GetParent()
    local width, height = overlay:GetSize()
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", overlay, "TOPLEFT", x * width, -y * height)
end

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
    pin.fallbackText = pin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pin.fallbackText:SetPoint("LEFT", pin, "RIGHT", 5, 0)
    pin.fallbackText:SetJustifyH("LEFT")
    pin:RegisterForDrag("LeftButton")
    pin:SetScript("OnDragStart", function(self)
        if not addon.db.editMode then return end
        self.dragging = true
        self.dragStep = self.sourceStep
        self.dragMapID = WorldMapFrame:GetMapID()
        self.dragX, self.dragY = nil, nil
        self.fallbackText:Hide()
        GameTooltip:Hide()
        self:SetScript("OnUpdate", UpdateDraggedPin)
        UpdateDraggedPin(self)
    end)
    pin:SetScript("OnDragStop", function(self)
        if not self.dragging then return end
        UpdateDraggedPin(self)
        self.dragging = nil
        self:SetScript("OnUpdate", nil)
        self.suppressClick = true
        C_Timer.After(0, function() self.suppressClick = nil end)
        if addon.db.editMode and self.dragMapID == WorldMapFrame:GetMapID()
            and self.dragX and self.dragY then
            addon:SaveStepOverride(self.dragStep,
                { labelX = self.dragX, labelY = self.dragY })
        end
        self.dragStep = nil
    end)
    pin:SetScript("OnEnter", function(self)
        addon:ShowTip(self, self.step)
        if addon.db.editMode then
            GameTooltip:AddLine("Drag to move. Click to edit text.", 0.55, 0.85, 1)
            GameTooltip:Show()
        end
    end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    pin:SetScript("OnClick", function(self)
        if self.suppressClick then return end
        if addon.db.editMode then
            addon:OpenStepEditor(self.sourceStep)
        else
            addon:SetStep(self.step.number)
        end
    end)
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
    overlay.editHint = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    overlay.editHint:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", -12, -12)
    overlay.editHint:SetText("BDSM edit mode: drag markers or click to edit")
    overlay.editHint:Hide()
    self.mapOverlay = overlay

    overlay:SetScript("OnSizeChanged", function() addon:RefreshMap() end)
    map:HookScript("OnShow", function() addon:RefreshMap() end)
    hooksecurefunc(map, "OnMapChanged", function() addon:RefreshMap() end)
    self:RefreshMap()
end

function addon:RefreshMap()
    local overlay = self.mapOverlay
    if not overlay then return end
    for _, pin in ipairs(overlay.pins) do
        pin.dragging = nil
        pin:SetScript("OnUpdate", nil)
        pin:Hide()
    end
    overlay.editHint:Hide()

    local dungeon = self:GetDungeon()
    local mapID = WorldMapFrame:GetMapID()
    if not dungeon or not self.db.showMap or not mapID then return end
    overlay.editHint:SetShown(self.db.editMode)
    local width, height = overlay:GetSize()
    if width <= 0 or height <= 0 then return end

    local encounters, links
    for _, step in ipairs(dungeon.steps) do
        if step.mapID == mapID then
            if step.journalEncounterID and not encounters then
                encounters = C_EncounterJournal.GetEncountersOnMap(mapID) or {}
            end
            if (step.linkedMapID or step.entranceLink) and not links then
                links = C_Map.GetMapLinksForMap(mapID) or {}
            end
        end
    end

    local pinCount, fallbackCount = 0, 0
    for _, step in ipairs(dungeon.steps) do
        if step.mapID == mapID then
            local edited = self:GetEditedStep(step)
            local x, y, labelX, labelY = GetStepPosition(edited, encounters, links)
            pinCount = pinCount + 1
            local pin = overlay.pins[pinCount]
            if not pin then
                pin = NewPin(overlay, step)
                overlay.pins[pinCount] = pin
            end
            pin.step = edited
            pin.sourceStep = step
            pin.text:SetText(step.number)
            pin:ClearAllPoints()
            if (x and y) or (labelX and labelY) then
                pin.fallbackText:Hide()
                pin:SetPoint("CENTER", overlay, "TOPLEFT",
                    (labelX or x) * width, -(labelY or y) * height)
            else
                -- A map link or journal pin may be unavailable on this client.
                -- Keep the route step visible without inventing a map position.
                fallbackCount = fallbackCount + 1
                pin.fallbackText:SetText(edited.title)
                pin.fallbackText:Show()
                pin:SetPoint("TOPLEFT", overlay, "TOPLEFT", 12,
                    -12 - (fallbackCount - 1) * 32)
            end
            pin:Show()
        end
    end
end
