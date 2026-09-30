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
place it on the current floor. Click a marker to edit its route number, title,
main tip, and optional role tips. Enter a route number from 1 through the total
number of tips to move that tip; the others renumber automatically. Save the
changes, then turn the option off or type `/bdsm lock`
to restore normal marker clicks. **Reset step** in the editor removes that
step's saved text and marker position changes; set its route number separately.

To create a tip, click **Add tip** on the dungeon floor's world map. The new
marker starts at the center of that floor; drag it to the right spot after
saving its text. Right-click an existing marker to insert a new tip immediately
after it in the numbered route. You can also enter a different route number
while creating it. Click a custom tip to edit or delete it. New
tips appear on the map only; they do not trigger encounter warnings.

Edits and new tips are saved per dungeon in the account's `BDSMDB` saved
variables. Moving a built-in marker changes its visible position only; its
route point and Blizzard's boss or floor-link icons remain separate. A custom
tip's marker is also its route point. A built-in marker without an available
Blizzard anchor can also be dragged from the map-side
list onto the floor. Changes are saved on UI logout/reload and shared by
characters on this WoW installation.

### Import in-game edits into Git

WoW cannot write into the addon's source folder. After editing in game, run
`/reload` to save your changes, then run this from the addon repository:

```sh
python3 tools/import_saved_variables.py
git status --short
```

The script reads the account-wide `WTF/Account/<account>/SavedVariables/bdsm.lua`
and updates the matching `Data/<Dungeon>.lua` file directly. It folds saved
positions, text, new tips, and route order into that dungeon's `steps` table,
and updates encounter warning step numbers. Display settings stay in WoW's save.
Review the changed dungeon file before committing it. After the next `/reload`,
the addon clears the imported saved edits for that dungeon so tips are not
duplicated; you can then make a new round of edits. Repeating an import of the
same save does not rewrite the file. If WoW has more than one account save,
pass `--source` with the desired `bdsm.lua` path. Use `--dungeon 2515` to
import just The Azure Vault, or `--check` to report
pending edits without changing files.

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
