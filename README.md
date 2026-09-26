# Brann's Dungeon Survival Manual (BDSM)

A small World of Warcraft Retail addon for learning dungeon routes. Numbered
markers appear on the **world map** for the current floor. Hover one for a short
instruction and, where useful, a tip for your tank, healer, or damage role.
Click a marker to select that step. Optional lines connect consecutive markers
on the same floor.

The first supported dungeon is **Ruby Life Pools**. Its eight tips cover the egg
room, Defier Draghar, Melidrussa, the flight upstairs, Kokia, and the final
encounter. The route is a beginner-friendly sequence of landmarks, not a live
Mythic+ pull or enemy-forces plan. The coordinates are initial map estimates
and still need in-game validation on Retail 12.1.

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
4. Run `/bdsm` to toggle map markers, minimap card, route lines, and role tips.

The card is an ordered tip navigator rather than a position-tracking minimap
marker. WoW's `C_Map.GetPlayerMapPosition` is restricted in instances, so the
addon cannot reliably place a tip at its geographic position on the minimap.
Steps do not advance automatically through combat; use the arrows or click a
world-map marker.

## Sources and route data

- [Wowhead Ruby Life Pools overview (Midnight Season 2)](https://www.wowhead.com/guide/midnight/ruby-life-pools-dungeon-overview-mythic-plus) informs the short, paraphrased mechanic tips.
- [Method Ruby Life Pools guide and MDT route](https://www.method.gg/guides/dungeons/ruby-life-pools) provides a reference route. The addon ships its own static landmark sequence; it does not import a player's MDT route.
- [Warcraft Wiki dungeon map IDs](https://warcraft.wiki.gg/wiki/UiMapID) identifies Ruby Overlook (`2094`) and Infusion Chambers (`2095`).

## Adding a dungeon

Add a data file before `Core.lua` in `bdsm.toc`, then add its instance ID to
`addon.dungeons`. Each step needs a unique, sequential `number`, a floor
`mapID`, normalized `x` and `y` positions, `title`, and short `tip`. Optional
`roles` keys are `TANK`, `HEALER`, and `DPS`. Keep tips short enough to
read quickly and check coordinates in game before calling a route finished.

The addon reads static data only. It neither downloads Wowhead pages during
play nor requires HandyNotes or MDT to be installed.
