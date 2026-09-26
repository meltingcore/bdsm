local _, addon = ...

local function GetWarningFrame()
    if addon.warningFrame then return addon.warningFrame end

    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(370, 94)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -130)
    frame:SetFrameStrata("HIGH")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.04, 0.04, 0.05, 0.82)
    frame:SetBackdropBorderColor(0.7, 0.55, 0.3, 0.65)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -12)
    frame.title:SetWidth(320)
    frame.title:SetJustifyH("LEFT")
    frame.body = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.body:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -6)
    frame.body:SetWidth(335)
    frame.body:SetJustifyH("LEFT")

    frame.close = CreateFrame("Button", nil, frame)
    frame.close:SetSize(22, 22)
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -7, -6)
    frame.close.text = frame.close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
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
    local message = step.tip
    if roleTip then message = message .. "\n" .. role .. ": " .. roleTip end

    local frame = GetWarningFrame()
    frame.title:SetText(step.number .. ". " .. step.title)
    frame.body:SetText(message)
    frame:SetHeight(roleTip and 122 or 94)
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
    local dungeon = self:GetDungeon()
    local step = dungeon and dungeon.steps[number]
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
