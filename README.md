# Brann's Dungeon Survival Manual (BDSM)

A small World of Warcraft Retail addon for learning dungeon routes. Numbered
markers appear on the **world map** for the current floor. Hover one for a short
instruction and, where useful, a tip for your tank, healer, or damage role.

## Installation

Copy this repository into `World of Warcraft/_retail_/Interface/AddOns/bdsm/`.
The folder must be named `bdsm` so that WoW finds `bdsm.toc`. Reload the UI
with `/reload` or restart the game.

## Usage

1. Enter dungeon instance and open the map with **M**.
2. Follow numbered markers on the current floor. Hover for tips.
3. A small warning appears when a boss encounter starts and closes after 10 seconds.
4. Run `/bdsm` to open the options panel.

### Adjust tips in game

While inside a supported dungeon, enable **Unlock map tips for editing** in
`/bdsm`, or type `/bdsm edit`. Open the world map and drag a numbered marker to
place it on the current floor. Click a marker to edit its title, main tip, and
optional role tips. Save the text, then turn the option off or type `/bdsm lock`
to restore normal marker clicks. **Reset step** in the editor removes that
step's saved text and position changes.

Edits are saved per dungeon and step in the account's `BDSMDB` saved
variables. Moving a marker changes its visible position only; the route point
and Blizzard's built-in boss or floor-link icons remain separate. A marker
without an available Blizzard anchor can also be dragged from the map-side
list onto the floor. Changes are saved on UI logout/reload and shared by
characters on this WoW installation.

Encounter warnings are fight-time cues and can be missed when joining a fight
after it starts. The Azure Vault trash tips use preceding entrance or floor-link
pins as route checkpoints; they do not mark exact enemy spawn positions. If
Blizzard does not provide a pin position, the tip stays in an ordered list at
the edge of the dungeon map.

## Sources

- [Wowhead](https://www.wowhead.com)
- [Method](https://www.method.gg)
- [Warcraft Wiki](https://warcraft.wiki.gg)
- [TheWoWDB](https://thewowdb.com)
- [Keystone.guru](https://keystone.guru)
- [The Azure Vault route and trash guidance](https://www.method.gg/guides/dungeons/the-azure-vault)
- [Blizzard map and encounter IDs](https://warcraft.wiki.gg/wiki/UiMapID)
