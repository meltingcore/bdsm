local _, addon = ...

local function Trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function AddField(parent, label, top, height, multiline)
    local caption = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    caption:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, top)
    caption:SetText(label)

    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetSize(500, height)
    box:SetPoint("TOPLEFT", caption, "BOTTOMLEFT", 0, -4)
    box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    box:SetBackdropColor(0.08, 0.08, 0.1, 1)
    box:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.9)

    local edit = CreateFrame("EditBox", nil, box)
    edit:SetPoint("TOPLEFT", box, "TOPLEFT", 8, -6)
    edit:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -8, 6)
    edit:SetFontObject("ChatFontNormal")
    edit:SetAutoFocus(false)
    edit:SetMultiLine(multiline)
    edit:SetMaxLetters(500)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    if not multiline then
        edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    end
    return edit, caption
end

local function GetEditor()
    if addon.stepEditor then return addon.stepEditor end

    local frame = CreateFrame("Frame", "BDSMStepEditor", UIParent, "BackdropTemplate")
    frame:SetSize(548, 538)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    frame:SetBackdropColor(0.04, 0.04, 0.06, 0.97)
    frame:SetBackdropBorderColor(0.8, 0.62, 0.3, 1)
    frame:EnableMouse(true)

    frame.heading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.heading:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -18)
    frame.routeNumber, frame.routeLabel = AddField(frame, "Route number", -54, 32, false)
    frame.routeNumber:SetMaxLetters(4)
    frame.title = AddField(frame, "Title", -113, 32, false)
    frame.tip = AddField(frame, "Main tip", -172, 70, true)
    frame.roles = {
        TANK = AddField(frame, "Tank tip (optional)", -269, 32, false),
        HEALER = AddField(frame, "Healer tip (optional)", -328, 32, false),
        DPS = AddField(frame, "Damage tip (optional)", -387, 32, false),
    }
    frame.error = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.error:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -451)
    frame.error:SetTextColor(1, 0.45, 0.45)

    local function Button(text, x, action)
        local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        button:SetSize(104, 25)
        button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", x, 19)
        button:SetText(text)
        button:SetScript("OnClick", action)
        return button
    end
    Button("Save", 24, function()
        local title, tip = Trim(frame.title:GetText()), Trim(frame.tip:GetText())
        local routeText = Trim(frame.routeNumber:GetText())
        local maxNumber = #addon:GetSteps() + (frame.isNew and 1 or 0)
        local routeNumber = routeText:match("^%d+$") and tonumber(routeText)
        if not routeNumber or routeNumber < 1 or routeNumber > maxNumber then
            frame.error:SetText("Route number must be between 1 and " .. maxNumber .. ".")
            return
        end
        if title == "" or tip == "" then
            frame.error:SetText("Title and main tip are required.")
            return
        end
        local roles = {}
        for role, edit in pairs(frame.roles) do roles[role] = Trim(edit:GetText()) end
        if frame.isNew then
            local step = addon:AddCustomStep(frame.mapID, frame.afterStep,
                { title = title, tip = tip, roles = roles })
            if not step then
                frame.error:SetText("Could not add a tip outside this dungeon.")
                return
            end
            addon:MoveStepToPosition(step, routeNumber)
        else
            addon:SaveStepOverride(frame.sourceStep,
                { title = title, tip = tip, roles = roles })
            addon:MoveStepToPosition(frame.sourceStep, routeNumber)
        end
        frame:Hide()
    end)
    Button("Cancel", 139, function() frame:Hide() end)
    frame.resetButton = Button("Reset step", 254, function()
        if frame.sourceStep.customID then
            addon:DeleteCustomStep(frame.sourceStep)
        else
            addon:ResetStepOverride(frame.sourceStep)
        end
        frame:Hide()
    end)
    frame:Hide()
    tinsert(UISpecialFrames, "BDSMStepEditor")
    addon.stepEditor = frame
    return frame
end

function addon:OpenStepEditor(step)
    if not self.db.editMode or not self:GetDungeon() then return end
    GameTooltip:Hide()
    local frame = GetEditor()
    local edited = self:GetDisplayStep(step)
    if not edited then return end
    frame.isNew = false
    frame.sourceStep = step
    frame.heading:SetText("Step " .. edited.number .. " - " .. self:GetDungeon().name)
    frame.routeLabel:SetText("Route number (1-" .. #self:GetSteps() .. ")")
    frame.routeNumber:SetText(tostring(edited.number))
    frame.title:SetText(edited.title or "")
    frame.tip:SetText(edited.tip or "")
    for role, edit in pairs(frame.roles) do
        edit:SetText(edited.roles and edited.roles[role] or "")
    end
    frame.resetButton:SetText(step.customID and "Delete tip" or "Reset step")
    frame.resetButton:Show()
    frame.error:SetText("")
    frame:Show()
end

function addon:OpenNewStepEditor(mapID, afterStep)
    local dungeon = self:GetDungeon()
    if not self.db.editMode or not dungeon then return end
    local supportedFloor
    for _, step in ipairs(dungeon.steps) do
        if step.mapID == mapID then supportedFloor = true; break end
    end
    if not supportedFloor then return end
    GameTooltip:Hide()
    local frame = GetEditor()
    frame.isNew = true
    frame.sourceStep = nil
    frame.mapID = mapID
    frame.afterStep = afterStep
    frame.heading:SetText("New tip - " .. dungeon.name)
    local afterDisplay = afterStep and self:GetDisplayStep(afterStep)
    local routeNumber = afterDisplay and afterDisplay.number + 1 or #self:GetSteps() + 1
    frame.routeLabel:SetText("Route number (1-" .. (#self:GetSteps() + 1) .. ")")
    frame.routeNumber:SetText(tostring(routeNumber))
    frame.title:SetText("")
    frame.tip:SetText("")
    for _, edit in pairs(frame.roles) do edit:SetText("") end
    frame.resetButton:Hide()
    frame.error:SetText("")
    frame:Show()
    frame.title:SetFocus()
end
