# Necropixel Tactics — Codex Ruleset

This repo uses Codex to generate and modify files. These rules exist to keep the project stable, testable, and predictable.

## Golden Rule
**No silent contract drift.** If a change could break node paths, IDs, JSON schemas, save formats, or public APIs, it must be explicit and testable.

---

## 1) Two Modes of Work

### A) BUILD mode (default)
Used when writing/modifying repo files.

**BUILD output must be either:**
- Full file contents (preferred), or
- A list of new files to add, or
- A single, complete replacement of a file

**Never** output partial snippets that require manual searching or manual merging.

### B) DESIGN mode
Used for ideation/architecture only. No file modifications.

---

## 2) File Safety Levels (What Codex is allowed to change)

### LOCKED (Do not modify without explicit permission)
These files define project “contracts” and are highly coupled.

- Save format + state:
  - `res://scripts/state/save_game.gd`
- Data loading + parsing:
  - `res://scripts/data/data_loader.gd`
- JSON schemas:
  - `res://data/schemas/*.schema.json`
- Core rulesets JSON contracts (IDs/keys must remain stable once used):
  - `res://data/**/*.json`

If a LOCKED file must change:
- Replace the entire file (no line edits)
- Add a test or debug output that proves compatibility

### MUTABLE (Codex can generate freely under constraints)
- UI scenes:
  - `res://scenes/ui/**/*.tscn`
- UI scripts:
  - `res://scenes/ui/**/*.gd`
- Debug scenes/tools:
  - `res://scenes/debug/**/*`
- Prototype tactical scenes:
  - `res://scenes/tactical/**/*`
- Docs:
  - `/*.md`

---

## 3) Scene/UI Contracts (Godot 4.6)

### Unique-name rule
If a script uses `%NodeName` lookups, the referenced nodes **must** have:
- `unique_name_in_owner = true`

### Node-name stability
For any scene referenced by a script:
- Node names are part of the public contract.
- Do not rename nodes or change hierarchy without also updating the script.
- Prefer `%UniqueName` to brittle `$Path/To/Node`.

### Output rule for scenes
When generating a `.tscn`:
- Output the full `.tscn` content.
- Do not include explanations inside the file.
- Keep nodes minimal (no extra UI unless requested).

---

## 4) Data Contracts (JSON)

### IDs are stable
Once an `id` is used (faction, fighter archetype, weapon, armour), it becomes part of the save format and UI assumptions.
- Do not rename IDs.
- Do not remove IDs.
- Prefer adding new entries over changing existing ones.

### Schema compatibility
If adding new JSON structures:
- Update schemas first
- Add debug validation (or DataDebug output) to confirm

---

## 5) GDScript Contracts

### Compatibility
- Godot: **4.6**
- GDScript syntax must be Godot 4.x
- Prefer explicit typing where it prevents Variant inference issues.

### Avoid reserved keywords
Do not name variables:
- `pass`, `class`, etc.

### Signal connections
Prefer:
- `button.pressed.connect(_handler)`
- `item_list.item_selected.connect(_handler)`

---

## 6) Codex Output Format Requirements

When asked to modify files:
- Provide complete file replacements or new files.
- Do not output “diff” instructions requiring manual edits.
- Never ask the user to find line numbers.

When asked to generate:
- Output only the final file contents requested (no prose inside code files).
- Keep changes scoped to requested files only.

---

## 7) Testing Protocol (Must run after any build chunk)

After any build chunk, run:

### Smoke Test
1. Boot the project (Main Scene: `res://scenes/app/App.tscn`)
2. Navigate:
   - MainMenu → New Game → HideoutHub
   - HideoutHub → Back to Menu
3. Validate:
   - No errors in debugger
   - UI responds to clicks

### Persistence Test
From HideoutHub:
- Click Save
- Click Reload
- Roster + credits remain consistent

If anything fails:
- Provide the first error line and a screenshot of the relevant scene tree.

---

## 8) Standard BUILD Task Template (Copy/Paste)

Use this template for future Codex prompts:

BUILD TASK:
- Change type: (Create / Replace)
- Files:
  - <path>
- Context:
  <what this feature does>
- Hard constraints:
  - Godot version: 4.6
  - Node names must EXACTLY match: <list>
  - If using %NodeName, set unique_name_in_owner=true
  - No changes to other files
- Requirements:
  - <bullets>
- Output:
  - Output ONLY final file content
  - No explanations inside files
  - List created/replaced file paths at the end
