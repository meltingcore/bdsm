local name, addon = ...

addon.defaults = { showMap = true, showRoleTip = true, showWarnings = true, editMode = false }
addon.currentStep = 1

function addon:GetStepOverride(step)
    if step.customID then return end
    local dungeon, instanceID = self:GetDungeon()
    local saved = dungeon and self.db and self.db.tipOverrides[instanceID]
    return saved and saved[step.number]
end

function addon:SaveStepOverride(step, changes)
    local dungeon, instanceID = self:GetDungeon()
    if not dungeon then return end
    if step.customID then
        for key, value in pairs(changes) do step[key] = value end
        self:Refresh()
        return
    end
    local byDungeon = self.db.tipOverrides[instanceID]
    if not byDungeon then
        byDungeon = {}
        self.db.tipOverrides[instanceID] = byDungeon
    end
    local saved = byDungeon[step.number] or {}
    for key, value in pairs(changes) do saved[key] = value end
    byDungeon[step.number] = saved
    self:Refresh()
end

function addon:ResetStepOverride(step)
    local dungeon, instanceID = self:GetDungeon()
    local byDungeon = dungeon and self.db.tipOverrides[instanceID]
    if byDungeon then byDungeon[step.number] = nil end
    self:Refresh()
end

function addon:GetStepKey(step)
    return step.customID and "c" .. step.customID or "b" .. step.number
end

function addon:GetCustomSteps()
    local dungeon, instanceID = self:GetDungeon()
    if not dungeon then return end
    local steps = self.db.customSteps[instanceID]
    if not steps then
        steps = {}
        self.db.customSteps[instanceID] = steps
    end
    return steps
end

function addon:AddCustomStep(mapID, afterStep, fields)
    local dungeon, instanceID = self:GetDungeon()
    if not dungeon or not mapID then return end
    local previous = self.db.routeOrder[instanceID] and self:GetSteps()
    local steps = self:GetCustomSteps()
    local nextID = 1
    for _, step in ipairs(steps) do
        nextID = math.max(nextID, (step.customID or 0) + 1)
    end
    local step = {
        customID = nextID, mapID = mapID,
        after = afterStep and self:GetStepKey(afterStep),
        x = 0.5, y = 0.5, labelX = 0.5, labelY = 0.5,
        title = fields.title, tip = fields.tip, roles = fields.roles,
    }
    steps[#steps + 1] = step
    if previous then
        local keys, insertAt = {}, #previous + 1
        for index, item in ipairs(previous) do
            keys[index] = self:GetStepKey(item.sourceStep)
            if afterStep and item.sourceStep == afterStep then insertAt = index + 1 end
        end
        table.insert(keys, insertAt, self:GetStepKey(step))
        self.db.routeOrder[instanceID] = keys
    end
    self:Refresh()
    return step
end

function addon:DeleteCustomStep(step)
    if not step.customID then return end
    local _, instanceID = self:GetDungeon()
    local steps = self:GetCustomSteps()
    if not steps then return end
    local key = self:GetStepKey(step)
    for index, item in ipairs(steps) do
        if item.customID == step.customID then
            for _, child in ipairs(steps) do
                if child.after == key then child.after = item.after end
            end
            table.remove(steps, index)
            local order = self.db.routeOrder[instanceID]
            if order then
                for orderIndex, savedKey in ipairs(order) do
                    if savedKey == key then table.remove(order, orderIndex); break end
                end
            end
            self:Refresh()
            return
        end
    end
end

function addon:GetEditedStep(step)
    local saved = self:GetStepOverride(step)
    local edited = {}
    for key, value in pairs(step) do edited[key] = value end
    if saved then
        for key, value in pairs(saved) do
            if key ~= "roles" then edited[key] = value end
        end
    end
    if saved and saved.roles then
        edited.roles = {}
        for role, value in pairs(step.roles or {}) do edited.roles[role] = value end
        for role, value in pairs(saved.roles) do edited.roles[role] = value end
    end
    return edited
end

function addon:GetSteps()
    local dungeon, instanceID = self:GetDungeon()
    if not dungeon then return {} end
    local custom = self:GetCustomSteps()
    local children, ordered, seen = {}, {}, {}
    for _, step in ipairs(custom) do
        if step.after then
            children[step.after] = children[step.after] or {}
            table.insert(children[step.after], step)
        end
    end
    local function append(step)
        if step.customID and seen[step.customID] then return end
        if step.customID then seen[step.customID] = true end
        local edited = self:GetEditedStep(step)
        edited.sourceStep = step
        edited.number = #ordered + 1
        ordered[#ordered + 1] = edited
        for _, child in ipairs(children[self:GetStepKey(step)] or {}) do append(child) end
    end
    for _, step in ipairs(dungeon.steps) do append(step) end
    for _, step in ipairs(custom) do append(step) end
    local savedOrder = self.db.routeOrder[instanceID]
    if savedOrder then
        local byKey, reordered, added = {}, {}, {}
        for _, step in ipairs(ordered) do
            byKey[self:GetStepKey(step.sourceStep)] = step
        end
        for _, key in ipairs(savedOrder) do
            if byKey[key] and not added[key] then
                reordered[#reordered + 1] = byKey[key]
                added[key] = true
            end
        end
        for _, step in ipairs(ordered) do
            local key = self:GetStepKey(step.sourceStep)
            if not added[key] then reordered[#reordered + 1] = step end
        end
        ordered = reordered
    end
    for index, step in ipairs(ordered) do step.number = index end
    return ordered
end

function addon:MoveStepToPosition(sourceStep, position)
    local _, instanceID = self:GetDungeon()
    if not instanceID then return end
    local steps = self:GetSteps()
    if position < 1 or position > #steps or position % 1 ~= 0 then return end
    local keys, oldPosition = {}, nil
    for index, step in ipairs(steps) do
        keys[index] = self:GetStepKey(step.sourceStep)
        if step.sourceStep == sourceStep then oldPosition = index end
    end
    if not oldPosition or oldPosition == position then return end
    local key = table.remove(keys, oldPosition)
    table.insert(keys, position, key)
    self.db.routeOrder[instanceID] = keys
    self:Refresh()
end

function addon:GetDisplayStep(sourceStep)
    for _, step in ipairs(self:GetSteps()) do
        if step.sourceStep == sourceStep then return step end
    end
end

function addon:GetRole()
    local role = UnitGroupRolesAssigned("player")
    if not role or role == "NONE" then
        local spec = GetSpecialization()
        role = spec and GetSpecializationRole(spec) or "DPS"
    end
    return role == "DAMAGER" and "DPS" or role
end

function addon:GetDungeon()
    local _, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
    if instanceType == "party" then
        return self.dungeons[instanceID], instanceID
    end
end

function addon:GetFloor()
    local mapID = C_Map.GetBestMapForUnit("player")
    local dungeon = self:GetDungeon()
    if dungeon then
        for _, step in ipairs(dungeon.steps) do
            if step.mapID == mapID then return mapID end
        end
    end
end

function addon:GetStep(number)
    local dungeon = self:GetDungeon()
    -- Encounter triggers use the built-in step number, not its editable route number.
    local source = dungeon and dungeon.steps[number]
    return source and self:GetDisplayStep(source)
end

function addon:SetStep(number)
    local dungeon = self:GetDungeon()
    if not dungeon then return end
    self.currentStep = math.max(1, math.min(#self:GetSteps(), number))
end

function addon:ShowTip(owner, step)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:AddLine(step.number .. ". " .. step.title, 1, 0.82, 0.34)
    GameTooltip:AddLine(step.tip, 1, 1, 1, true)
    local roleTip = self.db.showRoleTip and step.roles and step.roles[self:GetRole()]
    if roleTip == "" then roleTip = nil end
    if roleTip then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(self:GetRole() .. ": " .. roleTip, 0.55, 0.85, 1, true)
    end
    GameTooltip:Show()
end

function addon:Refresh()
    if self.RefreshMap then self:RefreshMap() end
end

function addon:SetEditMode(enabled)
    self.db.editMode = enabled and true or false
    if not self.db.editMode and self.stepEditor then self.stepEditor:Hide() end
    self:Refresh()
end

function addon:UpdateLocation(force)
    local dungeon = self:GetDungeon()
    local floor = dungeon and self:GetFloor()
    if dungeon ~= self.lastDungeon then
        if self.stepEditor then self.stepEditor:Hide() end
        self.lastDungeon = dungeon
        self.lastFloor = nil
        self.currentStep = 1
        if self.OnDungeonChanged then self:OnDungeonChanged(dungeon) end
        force = true
    end
    if floor and floor ~= self.lastFloor then
        self.lastFloor = floor
        for _, step in ipairs(self:GetSteps()) do
            if step.mapID == floor then self.currentStep = step.number; break end
        end
        force = true
    end
    if force then self:Refresh() end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:RegisterEvent("ZONE_CHANGED")
events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_WorldMap" and addon.db then
            addon:InitializeMap()
            return
        end
        if arg1 ~= name then return end
        BDSMDB = BDSMDB or {}
        BDSMDB.showRoute = nil
        for key, value in pairs(addon.defaults) do
            if BDSMDB[key] == nil then BDSMDB[key] = value end
        end
        addon.db = BDSMDB
        addon.db.tipOverrides = addon.db.tipOverrides or {}
        addon.db.customSteps = addon.db.customSteps or {}
        addon.db.routeOrder = addon.db.routeOrder or {}
        addon:InitializeMap()
        addon:InitializeOptions()
        C_Timer.NewTicker(2, function() addon:UpdateLocation(false) end)
        addon:UpdateLocation(true)
        return
    end
    addon:UpdateLocation(true)
end)
