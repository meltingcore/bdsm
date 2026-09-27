local name, addon = ...

addon.defaults = { showMap = true, showRoleTip = true, showWarnings = true, editMode = false }
addon.currentStep = 1

function addon:GetStepOverride(step)
    local dungeon, instanceID = self:GetDungeon()
    local saved = dungeon and self.db and self.db.tipOverrides[instanceID]
    return saved and saved[step.number]
end

function addon:SaveStepOverride(step, changes)
    local dungeon, instanceID = self:GetDungeon()
    if not dungeon then return end
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

function addon:GetEditedStep(step)
    local saved = self:GetStepOverride(step)
    if not saved then return step end
    local edited = {}
    for key, value in pairs(step) do edited[key] = value end
    for key, value in pairs(saved) do
        if key ~= "roles" then edited[key] = value end
    end
    if saved.roles then
        edited.roles = {}
        for role, value in pairs(step.roles or {}) do edited.roles[role] = value end
        for role, value in pairs(saved.roles) do edited.roles[role] = value end
    end
    return edited
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
    local step = dungeon and dungeon.steps[number]
    return step and self:GetEditedStep(step)
end

function addon:SetStep(number)
    local dungeon = self:GetDungeon()
    if not dungeon then return end
    self.currentStep = math.max(1, math.min(#dungeon.steps, number))
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
        for _, step in ipairs(dungeon.steps) do
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
        addon:InitializeMap()
        addon:InitializeOptions()
        C_Timer.NewTicker(2, function() addon:UpdateLocation(false) end)
        addon:UpdateLocation(true)
        return
    end
    addon:UpdateLocation(true)
end)
