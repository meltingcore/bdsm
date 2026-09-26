# Brann's Dungeon Survival Manual (BDSM)

A small World of Warcraft Retail addon for learning dungeon routes. Numbered
markers appear on the **world map** for the current floor. Hover one for a short
instruction and, where useful, a tip for your tank, healer, or damage role.

## Installation

Copy this repository into `World of Warcraft/_retail_/Interface/AddOns/bdsm/`.
The folder must be named `bdsm` so that WoW finds `bdsm.toc`. Reload the UI
with `/reload` or restart the game.

## Usage

1. Enter Ruby Life Pools as a party instance and open the world map with **M**.
2. Follow numbered markers on the current floor. Hover for tips.
3. Use the small card below the minimap to browse the same tips with `<` and
   `>`; it starts at the first tip on a new floor. Hover the card for the full
   text and any role tip.
4. Run `/bdsm` to opne the options panel.

## Sources

- [Wowhead](https://www.wowhead.com)
- [Method](https://www.method.gg)
- [Warcraft Wiki Dungeon Map IDs](https://warcraft.wiki.gg/wiki/UiMapID)
- [TheWoWDB](https://thewowdb.com)
- [Keystone.guru](https://keystone.guru)

## Adding a dungeon

Add a data file before `Core.lua` in `bdsm.toc`, then add its instance ID to
`addon.dungeons`. Each step needs a unique, sequential `number`, a floor
`mapID`, normalized `x` and `y` positions, `title`, and short `tip`. Optional
`labelX` and `labelY` move the visible number away from an existing map icon
without changing where the route goes. `roles` can contain `TANK`, `HEALER`,
and `DPS` tips. Keep tips short enough to
read quickly and check coordinates in game before calling a route finished.
`warningTriggers` can map floor IDs, NPC IDs, and encounter IDs to step numbers
for contextual on-screen warnings.
Optional `paths[mapID]` arrays contain verified bend coordinates or
`{ step = N }` references for drawing walkable lines between tips.
