# Repository Guidelines

## Project Structure & Module Organization

This repository is a Godot 4.6 project for a 2D cognitive-reframing game. Core gameplay scenes and scripts live in `game/`, including the card battle flow in `game/card_game/`. Global singletons live in `autoloads/` (`GameManager`, `EventBus`, audio managers). Reusable node logic belongs in `components/`, service integrations such as Gemini and voice features live in `services/`, and static gameplay data is stored in `data/`. UI scenes and controllers are under `ui/`. Third-party editor and MCP plugins are vendored in `addons/`. Imported media should stay under `assets/`.

## Build, Test, and Development Commands

Use the Godot editor for regular development:

- `godot4 --path .` opens the project locally.
- `godot4 --path . --editor` opens the editor explicitly for scene and asset work.
- `godot4 --path . --headless --quit` performs a quick project load check for script and resource errors.
- `start_godot_mcp.bat` starts the local MCP bridge used by AI tooling.

Run commands from the repository root, `F:\Projects\game_new`.

## Coding Style & Naming Conventions

Follow `.editorconfig`: UTF-8, LF endings, final newline, and tabs with width 4 for `*.gd`. Use Godot 4 typed GDScript where practical, prefer `@export` for inspector fields, and use signal `.connect()` syntax. Name scenes and files in `snake_case` (`main_menu.tscn`, `voice_service.gd`), classes in `PascalCase`, and autoload singletons with clear noun names.

## Testing Guidelines

There is no dedicated automated test suite yet. Until one is added, contributors should:

- run `godot4 --path . --headless --quit` before submitting changes;
- smoke-test the affected scene in the editor;
- verify input mappings, autoload behavior, and asset references after renames or moves.

If you add tests later, place them in a top-level `tests/` directory and mirror the source naming, for example `tests/game/test_game_controller.gd`.

## Commit & Pull Request Guidelines

Recent history uses short conventional commits such as `feat: 集成卡牌对战玩法二（godot-card-game-frame）`. Keep that pattern: `feat:`, `fix:`, `refactor:`, `docs:` followed by a concise summary. PRs should explain gameplay impact, list touched scenes/scripts, link related issues, and include screenshots or short clips for visible UI or scene changes.

## Configuration Tips

Do not commit secrets from `.env`. Treat `.godot/` as generated editor state, and avoid manual edits to `project.godot` unless the change cannot be made safely through the editor.
