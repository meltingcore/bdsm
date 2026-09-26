local _, addon = ...

-- Positions are normalized Blizzard UiMap coordinates. The two floors must
-- remain separate: a line across the dragon flight would be misleading.
addon.dungeons = {
    [2521] = {
        name = "Ruby Life Pools",
        guide = "https://www.wowhead.com/guide/midnight/ruby-life-pools-dungeon-overview-mythic-plus",
        route = "https://www.method.gg/guides/dungeons/ruby-life-pools",
        steps = {
            { number = 1, mapID = 2095, x = 0.35, y = 0.60, title = "Egg room",
              tip = "Keep to the clear path. Stepping on eggs wakes extra whelps.",
              roles = { TANK = "Keep enemies out of the egg clutches.", HEALER = "Dispel Cold Claws if whelps are woken." } },
            { number = 2, mapID = 2095, x = 0.52, y = 0.48, title = "Defier Draghar",
              tip = "Defeat Draghar to open the way. Dodge Blazing Rush.",
              roles = { TANK = "Use mitigation for Steel Barrage." } },
            { number = 3, mapID = 2095, x = 0.71, y = 0.34, title = "Melidrussa Chillworn",
              tip = "Interrupt Frigid Shard. Break Frost Overload's shield and dodge Hailburst.",
              roles = { TANK = "Gather the spawned whelps under the boss.",
                        HEALER = "Dispel Cold Claws and prepare for Chillstorm damage.",
                        DPS = "Focus the Frost Overload shield before returning to the boss." } },
            { number = 4, mapID = 2095, x = 0.83, y = 0.50, title = "Fly upstairs",
              tip = "Use a dragon at the exit to fly to the Ruby Overlook." },
            { number = 5, mapID = 2094, x = 0.36, y = 0.61, title = "Overlook trash",
              tip = "Watch for rolling boulders. Interrupt dangerous fire casts.",
              roles = { DPS = "Interrupt Fiery Blast and help stop Blaze Volley." } },
            { number = 6, mapID = 2094, x = 0.57, y = 0.65, title = "Kokia Blazehoof",
              tip = "Dodge Molten Boulder. Kill the summoned firestorm and interrupt Blaze Volley.",
              roles = { TANK = "Use a defensive for Searing Blows; keep boulders aimed at a wall.",
                        HEALER = "Prepare group healing while the firestorm is active.",
                        DPS = "Prioritize the summoned firestorm." } },
            { number = 7, mapID = 2094, x = 0.66, y = 0.39, title = "Final approach",
              tip = "Interrupt Flashfire and leave room to dodge storm effects." },
            { number = 8, mapID = 2094, x = 0.78, y = 0.26, title = "Kyrakka & Erkhart",
              tip = "Dodge firebreath and fire pools. Stop casting for Cloudburst; focus Kyrakka when possible.",
              roles = { TANK = "Plan a defensive for Stormslam and keep an escape route.",
                        HEALER = "Dispel Stormslam and watch Inferno Spit targets.",
                        DPS = "Hit Kyrakka when in range and use a defensive for Inferno Spit." } },
        },
    },
}
