# CLAUDE.md

This file is the single copy of the project conventions; AGENTS.md only points here.

# Repository Guidelines

## Project Structure & Module Organization
- `project.godot` defines the Godot 4.5 project settings.
- `main.tscn` is the primary scene; `main.gd` holds the core gameplay logic.
- `sounds/` contains optional audio assets and a `README.md` describing required filenames.
- `.godot/` is editor-generated cache data; do not edit manually.

## Build, Test, and Development Commands
- Godot Editor: open `project.godot`, then press `F5` (Run Project) to play locally.
- CLI (if Godot is on PATH): `godot --path . --verbose` to launch the project from the repo.
- Export: in the editor, use Project > Export to create an HTML5 build.

## Coding Style & Naming Conventions
- Language: GDScript.
- Indentation: tabs; keep blank lines between logical sections.
- Naming: `snake_case` for variables and functions, `UPPER_SNAKE_CASE` for constants.
- Scene nodes are referenced via `$NodePath` and `@onready` for cached lookups.

## Testing Guidelines
- Headless tests: `GODOT=<godot 4.5 exe> bash tests/run_all_tests.sh` (`test_keyboard.gd`, `test_smoke.gd`).
- Manual testing checklist: run Level 1 and Level 2, confirm food collection, enemy patrols, glucose/fat rules, and death/level reset behavior.

## Commit & Pull Request Guidelines
- No Git history is available in this repo, so no commit message conventions are enforced yet.
- Use clear, imperative commit messages (e.g., "Add fat conversion sound").
- PRs should include: summary, manual test steps, and screenshots or short clips for gameplay or UI changes.

## Configuration & Assets
- Sound effects are optional; place files in `sounds/` using the names in `sounds/README.md`.
- Keep constants for tuning gameplay at the top of `main.gd`.

## Site readiness (sims.mr-miner.com)
- Keyboard code (Tab order, Escape, `sims:leave-game`, arrow/WASD moves) is in `main.gd`: `handle_key()` and `tab_controls()`. Tab stops are the open panel's button, then the Music switch.
- Web export uses the **2D** template (rebuilt 2026-10-10 with Ogg Vorbis; the earlier 2D zip failed to load every `.ogg` in Chrome). Music is silent until the first click/key (`start_audio()`); no autoplay.
- Export: preset "Web" -> `../exports/bug-metabolism/index.html`; browser test copy lives in the supervising session's scratchpad (`webtest-bug`).
