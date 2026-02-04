# Necropixel Tactics — MVP Checklist

This checklist is the step-by-step path to a playable MVP: start game → manage gang → launch tutorial mission → end mission → post-mission loop.

Each section ends with a required test.

---

## Phase 0 — Repo Baseline
- [x] Godot project opens cleanly
- [x] Autoloads configured (DataLoader, SaveGame)
- [x] Data folder structure exists

**Test**
- Run `res://scenes/debug/DataDebug.tscn`
- DataLoader loads without errors

---

## Phase 1 — Data + Generation
- [x] DataLoader loads:
  - factions
  - fighter archetypes
  - weapons
  - armour
- [x] GangGenerator can create a starter gang
- [x] SaveGame holds current state in memory
- [x] SaveGame can save/load to `user://savegame.json`

**Test**
- Run DataDebug
- Confirm output includes:
  - faction loaded
  - fighter count > 0
  - save_to_disk true
  - load_from_disk true

---

## Phase 2 — Boot Flow + Menu
- [x] App scene routes:
  - if save exists → HideoutHub
  - else → MainMenu
- [x] MainMenu supports:
  - New Game
  - Continue (only if save exists)

**Test**
- Delete `user://savegame.json` and run:
  - Should land on MainMenu
- Create New Game:
  - Should save then go to HideoutHub
- Restart:
  - Should go straight to HideoutHub

---

## Phase 3 — HideoutHub (Home Base)
### 3.1 Basic hub
- [ ] HideoutHub shows:
  - faction
  - credits
- [ ] Roster list displays fighters
- [ ] Clicking a fighter shows details
- [ ] Tabs:
  - Roster
  - Stash
- [ ] Dev controls:
  - Save
  - Reload

**Test**
- Boot into HideoutHub
- Click fighters, switch tabs
- Save then Reload
- Confirm no errors in debugger

### 3.2 Stash placeholders
- [ ] Stash displays “empty” state when no items
- [ ] (Optional) show equipped items by name

**Test**
- Ensure stash tab shows consistent output
- No null-instance errors

---

## Phase 4 — Missions (Tutorial Stub)
- [ ] News / Missions screen in HideoutHub
- [ ] One tutorial mission available:
  - “Intro Skirmish”
- [ ] “Launch Mission” button enters TacticalScene

**Test**
- From HideoutHub → open missions → launch
- TacticalScene loads

---

## Phase 5 — Tactical Scene (Minimum Play Loop)
- [ ] Tactical scene loads a generated map (simple grid)
- [ ] Spawn fighters (player roster only for now)
- [ ] Basic camera controls:
  - pan
  - zoom
  - rotate (optional)
- [ ] “End Mission” button returns to HideoutHub

**Test**
- Launch mission
- See grid + units
- End mission returns to HideoutHub

---

## Phase 6 — Post-mission Loop (Stub)
- [ ] After mission, apply a simple result:
  - +credits OR +xp
  - mark mission as completed
- [ ] Save updated state

**Test**
- Run mission → end
- Verify credits/xp changed
- Save → restart → values persist

---

## Phase 7 — MVP Definition Complete
MVP is considered complete when:
- Player can:
  1) Start/Continue
  2) View roster/stash
  3) Launch tutorial mission
  4) See units on a grid
  5) End mission
  6) Return to hideout
  7) Persist progression

---

## Standard Test Habit (Do after every build chunk)
After any Codex build:
1. Run the game from `res://scenes/app/App.tscn`
2. Click through:
   - Menu → Hideout → Save → Reload → Back → Menu
3. Confirm no debugger errors
4. If errors occur:
   - capture first error line
   - screenshot scene tree
   - share both before further changes
