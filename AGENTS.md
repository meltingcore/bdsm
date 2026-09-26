# Agent instructions for Brann's Dungeon Survival Manual

This repository is a World of Warcraft **Retail** addon. Work toward a usable
in-game result, keep tips short, and preserve the user's existing changes.

## Project layout

- `bdsm.toc` defines the load order. Load dungeon data before `Core.lua` and
  modules after it.
- `Data/*.lua` contains static dungeon steps and warning trigger IDs.
- `Core.lua` owns saved settings, dungeon and floor selection, role selection,
  and the selected step.
- `Map.lua`, `Warnings.lua`, and `Options.lua` own their named UI.
- Update `CHANGELOG.md` when behavior or supported data changes.

## Current documentation

When a request asks about a library, framework, SDK, API, CLI tool, or cloud
service, check current documentation with Context7 before answering or relying
on API details. Run `npx ctx7@latest library <official name> "<full question>"`,
choose a relevant `/org/project` ID, then run
`npx ctx7@latest docs <libraryId> "<full question>"`. Use at most three Context7
commands per question. If Context7 reports a quota error, say so and suggest
`npx ctx7@latest login` or `CONTEXT7_API_KEY`. This does not apply to ordinary
refactoring, scripts from scratch, business logic, or code review. For WoW API
work, also prefer current Blizzard UI source and other direct source data over
memory; verify version-sensitive claims.

## Map and route data

- Treat each Blizzard `UiMapID` floor separately. 
- Store positions as normalized Blizzard map coordinates. MDT's custom map
  coordinates and world spawn coordinates are different coordinate systems;
  transform them with verified per-floor bounds before use.
- Use published boss, spawn, and route data instead of visual guesses.
  Validate positions in game when possible; do not claim they were validated 
  without doing so.
- Keep a step's route position (`x`, `y`) separate from its visible marker
  position (`labelX`, `labelY`). Offset boss labels beside built-in boss icons
  so both remain visible.
- Numbered steps are the current route guidance.
- Keep tips concise, actionable, and suitable for first-time players. Include
  role-specific `TANK`, `HEALER`, or `DPS` notes where they add value.

## Contextual warnings

- WoW does not provide usable player map or world coordinates inside dungeon
  instances through `C_Map.GetPlayerMapPosition` or `UnitPosition`. Do not build
  room-entry detection or minimap positioning on those APIs.
- Show notification popups only for configured boss or scripted encounter
  starts. Non-boss tips, including trash, travel, and transitions, stay on the
  world map only due to Blizzard API limitations.
- Keep warnings small and dismissible. The current warning stays for 10
  seconds, has a close button, and should avoid repeated spam within a run.
- Include the player's role-specific note in the warning when `showRoleTip` is
  enabled, and respect `showWarnings` immediately when it is turned off.
- Document that encounter-start warnings are fight-time cues and can be missed
  when the player joins an encounter after it starts.
