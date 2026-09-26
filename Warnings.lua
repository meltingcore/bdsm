local _, addon = ...

local function GetWarningFrame()
    if addon.warningFrame then return addon.warningFrame end

    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(370, 88)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -120)
    frame:SetFrameStrata("MEDIUM")
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
    frame.close:SetNormalFontObject("GameFontNormalSmall")
    frame.close:SetHighlightFontObject("GameFontHighlightSmall")
    frame.close:SetText("X")
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

function addon:OnDungeonChanged()
    self.warningSeen = {}
    self.warningProgress = 0
    self.warningSerial = (self.warningSerial or 0) + 1
    if self.warningFrame then self.warningFrame:Hide() end
end

function addon:WarnStep(number)
    if not self.db or not self.db.showWarnings then return end
    local dungeon = self:GetDungeon()
    local step = dungeon and dungeon.steps[number]
    if not step or not self.warningSeen or self.warningSeen[number]
        or number < (self.warningProgress or 0) then return end

    self.warningSeen[number] = true
    self.warningProgress = number
    self:SetStep(number)
    local message = step.tip
    local roleTip = self.db.showRoleTip and step.roles and step.roles[self:GetRole()]
    if roleTip then message = message .. "\n" .. self:GetRole() .. ": " .. roleTip end

    local frame = GetWarningFrame()
    frame.title:SetText(number .. ". " .. step.title)
    frame.body:SetText(message)
    frame:SetHeight(math.max(76, 40 + frame.body:GetStringHeight() + 15))
    frame:Show()
    self.warningSerial = (self.warningSerial or 0) + 1
    local serial = self.warningSerial
    C_Timer.After(20, function()
        if addon.warningSerial == serial then frame:Hide() end
    end)
end

function addon:OnFloorChanged(floor)
    local dungeon = self:GetDungeon()
    self.warningProgress = math.max(self.warningProgress or 0, self.currentStep)
    local triggers = dungeon and dungeon.warningTriggers
    local number = triggers and triggers.floor and triggers.floor[floor]
    if not number then return end
    -- Wait for loading screens and floor transitions to settle before showing a tip.
    C_Timer.After(2, function()
        if addon:GetDungeon() == dungeon and addon:GetFloor() == floor then
            addon:WarnStep(number)
        end
    end)
end

local function WarnForUnit(unit)
    local dungeon = addon:GetDungeon()
    if not dungeon or not dungeon.warningTriggers then return end
    local guid = UnitGUID(unit)
    if not guid or (issecretvalue and issecretvalue(guid)) then return end
    local npcID = tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)"))
    local number = npcID and dungeon.warningTriggers.npc[npcID]
    if number and addon:GetFloor() == dungeon.steps[number].mapID then addon:WarnStep(number) end
end

local events = CreateFrame("Frame")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
events:RegisterEvent("ENCOUNTER_START")
events:RegisterEvent("ENCOUNTER_END")
events:SetScript("OnEvent", function(_, event, arg1, _, _, _, arg5)
    if event == "NAME_PLATE_UNIT_ADDED" then
        WarnForUnit(arg1)
    elseif event == "PLAYER_TARGET_CHANGED" then
        WarnForUnit("target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        WarnForUnit("mouseover")
    else
        local dungeon = addon:GetDungeon()
        local triggers = dungeon and dungeon.warningTriggers
        if not triggers then return end
        if event == "ENCOUNTER_START" then
            addon:WarnStep(triggers.encounterStart[arg1])
        elseif arg5 == 1 then
            addon:WarnStep(triggers.encounterSuccess[arg1])
        else
            local number = triggers.encounterStart[arg1]
            if number and addon.warningSeen then addon.warningSeen[number] = nil end
        end
    end
end)
