local _, addon = ...

local function AddButton(parent, label, point, x)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(23, 23)
    button:SetPoint(point, parent, point, x, 0)
    button:SetText(label)
    return button
end

function addon:InitializeMinimap()
    local card = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
    card:SetSize(210, 52)
    card:SetPoint("TOP", Minimap, "BOTTOM", 0, -7)
    card:SetFrameStrata("MEDIUM")
    card:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    card:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 11,
        insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    card:SetBackdropColor(0.07, 0.10, 0.15, 0.94)
    card:SetBackdropBorderColor(0.8, 0.57, 0.22, 1)
    card:EnableMouse(true)
    card.title = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    card.title:SetPoint("TOP", 0, -7)
    card.title:SetWidth(150)
    card.text = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.text:SetPoint("TOP", card.title, "BOTTOM", 0, -3)
    card.text:SetWidth(164)
    card.text:SetMaxLines(2)
    local previous = AddButton(card, "<", "LEFT", 2)
    local next = AddButton(card, ">", "RIGHT", -2)
    previous:SetScript("OnClick", function() addon:SetStep(addon.currentStep - 1) end)
    next:SetScript("OnClick", function() addon:SetStep(addon.currentStep + 1) end)
    card:SetScript("OnEnter", function(self)
        local step = addon:GetStep(addon.currentStep)
        if step then addon:ShowTip(self, step) end
    end)
    card:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.minimapCard = card
    self:RefreshMinimap()
end

function addon:RefreshMinimap()
    local card = self.minimapCard
    if not card then return end
    local dungeon = self:GetDungeon()
    if not dungeon or not self.db.showMinimap then card:Hide(); return end
    local step = dungeon.steps[self.currentStep] or dungeon.steps[1]
    card.title:SetText(step.number .. "/" .. #dungeon.steps .. "  " .. step.title)
    card.text:SetText(step.tip)
    card:Show()
end
