local _, addon = ...

function addon:InitializeOptions()
    local category = Settings.RegisterVerticalLayoutCategory("Brann's Dungeon Survival Manual")
    Settings.RegisterAddOnCategory(category)
    self.optionsCategory = category

    local choices = {
        { "showMap", "Show numbered world map tips", "Display tips on the current dungeon floor." },
        { "showMinimap", "Show minimap step card", "Use the arrows to browse tips while inside the dungeon." },
        { "showRoute", "Draw route lines", "Connect consecutive tips on the same floor." },
        { "showRoleTip", "Show my role's tip", "Add a tank, healer, or damage tip in marker tooltips when available." },
    }
    for _, choice in ipairs(choices) do
        local key, label, description = unpack(choice)
        local setting = Settings.RegisterAddOnSetting(category, "BDSM_" .. key,
            key, self.db, type(self.defaults[key]), label, self.defaults[key])
        Settings.CreateCheckbox(category, setting, description)
        setting:SetValueChangedCallback(function() addon:Refresh() end)
    end
end

SLASH_BDSM1 = "/bdsm"
SlashCmdList.BDSM = function()
    if addon.optionsCategory then
        Settings.OpenToCategory(addon.optionsCategory:GetID())
    end
end
