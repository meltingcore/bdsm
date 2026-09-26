local _, addon = ...

-- Positions are normalized Blizzard UiMap coordinates. Boss anchors use
-- Adventure Guide map coordinates. Other anchors are projected from published
-- NPC spawn positions and per-floor map bounds (see README). No walkable route
-- polyline is shipped until its bends can be verified from source data.
addon.dungeons = {
    [2521] = {
        name = "Ruby Life Pools",
        guide = "https://www.wowhead.com/guide/midnight/ruby-life-pools-dungeon-overview-mythic-plus",
        route = "https://www.method.gg/guides/dungeons/ruby-life-pools",
        warningTriggers = {
            -- Eggs may not expose nameplates; nearby Infused Whelps are a fallback.
            npc = { [189903] = 1, [189595] = 1, [187894] = 1,
                    [187897] = 2, [190034] = 5,
                    [197982] = 7, [197535] = 7 },
            encounterStart = { [2488] = 3, [2485] = 6, [2503] = 8 },
            encounterSuccess = { [2488] = 4 },
        },
        steps = {
            { number = 1, mapID = 2095, x = 0.363, y = 0.506, title = "Egg room",
              tip = "Keep to the clear path. Stepping on eggs wakes extra whelps.",
              roles = { TANK = "Keep enemies out of the egg clutches.", HEALER = "Dispel Cold Claws if whelps are woken." } },
            { number = 2, mapID = 2095, x = 0.479, y = 0.222, title = "Defier Draghar",
              tip = "Defeat Draghar to open the way. Dodge Blazing Rush.",
              roles = { TANK = "Use mitigation for Steel Barrage." } },
            { number = 3, mapID = 2095, x = 0.614, y = 0.389,
              labelX = 0.658, labelY = 0.350, title = "Melidrussa Chillworn",
              tip = "Interrupt Frigid Shard. Break Frost Overload's shield and dodge Hailburst.",
              roles = { TANK = "Gather the spawned whelps under the boss.",
                        HEALER = "Dispel Cold Claws and prepare for Chillstorm damage.",
                        DPS = "Focus the Frost Overload shield before returning to the boss." } },
            { number = 4, mapID = 2095, x = 0.612, y = 0.412,
              labelX = 0.687, labelY = 0.428, title = "Fly upstairs",
              tip = "Use a dragon at the exit to fly to the Ruby Overlook." },
            { number = 5, mapID = 2094, x = 0.409, y = 0.673, title = "Clear the overlook ring",
              tip = "Defeat the four Blazebound Destroyers around the ring to unlock Kokia.",
              roles = { DPS = "Interrupt Fiery Blast and help stop Blaze Volley." } },
            { number = 6, mapID = 2094, x = 0.400, y = 0.427,
              labelX = 0.437, labelY = 0.427, title = "Kokia Blazehoof",
              tip = "Dodge Molten Boulder. Kill the summoned firestorm and interrupt Blaze Volley.",
              roles = { TANK = "Use a defensive for Searing Blows; keep boulders aimed at a wall.",
                        HEALER = "Prepare group healing while the firestorm is active.",
                        DPS = "Prioritize the summoned firestorm." } },
            { number = 7, mapID = 2094, x = 0.275, y = 0.283, title = "Final approach",
              tip = "Interrupt Flashfire and leave room to dodge storm effects." },
            { number = 8, mapID = 2094, x = 0.208, y = 0.181,
              labelX = 0.249, labelY = 0.181, title = "Kyrakka & Erkhart",
              tip = "Dodge firebreath and fire pools. Stop casting for Cloudburst; focus Kyrakka when possible.",
              roles = { TANK = "Plan a defensive for Stormslam and keep an escape route.",
                        HEALER = "Dispel Stormslam and watch Inferno Spit targets.",
                        DPS = "Hit Kyrakka when in range and use a defensive for Inferno Spit." } },
        },
    },
}
