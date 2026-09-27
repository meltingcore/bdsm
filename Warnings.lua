local _, addon = ...

local ROLE_COLORS = {
    TANK = { 0.4, 0.7, 1 },
    HEALER = { 0.4, 1, 0.5 },
    DPS = { 1, 0.45, 0.45 },
}

local function GetWarningFrame()
    if addon.warningFrame then return addon.warningFrame end

    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(560, 120)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -130)
    frame:SetFrameStrata("HIGH")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.04, 0.04, 0.05, 0.94)
    frame:SetBackdropBorderColor(0.7, 0.55, 0.3, 0.65)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetFont(STANDARD_TEXT_FONT, 22, "OUTLINE")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -16)
    frame.title:SetWidth(490)
    frame.title:SetJustifyH("LEFT")
    frame.body = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.body:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
    frame.body:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -10)
    frame.body:SetWidth(524)
    frame.body:SetJustifyH("LEFT")
    frame.role = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.role:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
    frame.role:SetPoint("TOPLEFT", frame.body, "BOTTOMLEFT", 0, -10)
    frame.role:SetWidth(524)
    frame.role:SetJustifyH("LEFT")

    frame.close = CreateFrame("Button", nil, frame)
    frame.close:SetSize(30, 30)
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -7, -6)
    frame.close.text = frame.close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.close.text:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
    frame.close.text:SetPoint("CENTER")
    frame.close.text:SetText("X")
    frame.close:SetScript("OnClick", function()
        addon.warningSerial = (addon.warningSerial or 0) + 1
        frame:Hide()
    end)
    frame.close:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText("Dismiss tip")
        GameTooltip:Show()
    end)
    frame.close:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame:Hide()
    addon.warningFrame = frame
    return frame
end

function addon:DisplayWarning(step)
    local role = self:GetRole()
    local roleTip = self.db.showRoleTip and step.roles and step.roles[role]
    if roleTip == "" then roleTip = nil end
    local frame = GetWarningFrame()
    frame.title:SetText(step.number .. ". " .. step.title)
    frame.body:SetText(step.tip)
    if roleTip then
        local color = ROLE_COLORS[role] or { 1, 1, 1 }
        frame.role:SetTextColor(color[1], color[2], color[3])
        frame.role:SetText(role .. ": " .. roleTip)
        frame.role:Show()
    else
        frame.role:Hide()
    end
    frame:SetHeight(16 + frame.title:GetStringHeight() + 10 + frame.body:GetStringHeight()
        + (roleTip and (10 + frame.role:GetStringHeight()) or 0) + 18)
    frame:Show()
    self.warningSerial = (self.warningSerial or 0) + 1
    local serial = self.warningSerial
    C_Timer.After(10, function()
        if addon.warningSerial == serial then frame:Hide() end
    end)
end

function addon:OnDungeonChanged()
    self.warningSeen = {}
    self.warningSerial = (self.warningSerial or 0) + 1
    if self.warningFrame then self.warningFrame:Hide() end
end

function addon:WarnStep(number)
    if not self.db or not self.db.showWarnings then return end
    local step = self:GetStep(number)
    if step and not self.warningSeen then self:OnDungeonChanged() end
    if not step or not self.warningSeen or self.warningSeen[number] then return end

    self:DisplayWarning(step)
    self.warningSeen[number] = true
    self:SetStep(number)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ENCOUNTER_START")
events:SetScript("OnEvent", function(_, _, encounterID)
    local dungeon = addon:GetDungeon()
    local triggers = dungeon and dungeon.warningTriggers
    if triggers and triggers.encounterStart then
        addon:WarnStep(triggers.encounterStart[encounterID])
    end
end)
