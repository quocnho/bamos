---
name: zed-power-user
description: >-
  Use this skill when working inside the Zed editor (Zed 1.x, binary `zeditor`):
  agent workflows, tasks, multi-cursor editing, LSP/language setup, keybindings,
  snippets, extensions, context servers (MCP), and settings. Activate whenever
  the user asks about doing something in Zed, or when you need to edit Zed's
  own configuration (settings.json, keymap.json, tasks.json, context servers).
---

# Zed Editor — Power User Workflows

Zed is a high-performance, GPU-accelerated editor. This machine runs **Zed 1.16**
(binary `zeditor`, package `zed-editor`). Config lives in `~/.config/zed/`.

## Config files on this machine

- `~/.config/zed/settings.json` — global settings (merged from `/etc/nixos/assets/zed/settings.json` by the `zed-settings` systemd user service; edit the asset, then `sudo nixos-rebuild switch --flake /etc/nixos#lg` or `systemctl --user restart zed-settings`).
- `~/.config/zed/keymap.json` — keybindings.
- `~/.config/zed/skills/` — global agent skills (synced from `assets/zed/skills/`).
- Project-level overrides: `.zed/settings.json`, `.zed/tasks.json`, `.zed/keymap.json`.

## Agent workflows (Zed agent = the AI assistant)

- Open the agent with **Ctrl+Space** (default) or via the Agent panel; use **agent selection** (Gemini/Claude/other) to switch providers.
- Skills are auto-discovered from `~/.config/zed/skills/<name>/SKILL.md` (global) and `.zed/skills/<name>/SKILL.md` (project) — each has `name` + `description` frontmatter. The agent activates them on demand; keep descriptions precise.
- **Tab completion**: agent can complete code — accept with **Tab**, reject with **Esc**.
- **Inline edits**: select code and ask the agent to modify it; review the diff before accepting.
- Use **/context**-style prompts sparingly; be explicit about files to touch.
- The agent uses the terminal via the built-in terminal panel (Ctrl+`). Prefer running `direnv reload`/`devenv shell` commands there.

## Context servers (MCP in Zed)

Configured under `context_servers` in `~/.config/zed/settings.json` (synced from assets):
- `fs` — filesystem access rooted at `$HOME`.
- `context7` — up-to-date library docs (Laravel, Flutter, React, Node…).
- `memory` — persistent memory across sessions.
- `fetch` — read web URLs.
All use `npx` (Node 24 installed). Verify availability via the context-server status in the agent panel.

## Tasks (build/test/run from within Zed)

Define `.zed/tasks.json` in the project root. Example:

```json
{
  "tasks": [
    {
      "label": "php artisan test",
      "command": "php artisan test",
      "reveal": "always"
    },
    {
      "label": "pnpm dev",
      "command": "pnpm dev",
      "reveal": "always"
    }
  ]
}
```
Run with **Ctrl+Shift+T** (or via the command palette → "Tasks: Spawn").

## Multi-cursor & editing

- **Ctrl+D** — select next occurrence; **Ctrl+Shift+L** — select all occurrences.
- **Alt+Click** — add cursor; **Ctrl+Alt+↑/↓** — add cursor above/below.
- **Alt+Shift+↑/↓** — move line; **Ctrl+Shift+K** — delete line.
- **Ctrl+/** — toggle comment. **Alt+W** — select word.
- Use `editor.column_selecting_mode`/`multiple_cursors` settings if needed.
- **Multi-cursor rename**: place cursors, type once — replaces all.

## LSP & language tooling

- Zed auto-detects language servers. For PHP, Zed's built-in PHP support plus language servers installed via the Extensions panel work; ensure PHP tooling resolves inside the devenv shell.
- Tailwind, ESLint, Prettier integrations are handled by Zed extensions or built-in support.
- For direnv-managed projects, run `direnv reload` in the Zed terminal so LSPs pick up the right toolchains (php/node/flutter from devenv).

## Performance notes (this laptop: 16 GB RAM, battery-conscious)

- Large monorepos: disable unused extensions, keep `project_panel.file_scan_exclusions` tight, and use `buffer_search` sparingly.
- Zed is GPU-accelerated; on battery the dGPU may stay active if the app holds `/dev/nvidia*` — closing heavyweight apps reduces power draw (see NixOS power config).

## Extension marketplace

- Zed extensions are installed via the Extensions panel; settings like `theme` (e.g., "One Dark") and fonts (JetBrainsMono Nerd Font Mono at 17/18) are already set globally.
- If an extension is missing, install once via the UI — it persists in `~/.config/zed/extensions/`.

## References

- Zed settings schema: `zeditor --help` for CLI flags; full docs online at zed.dev/docs.
- Keyboard shortcuts are remappable in `~/.config/zed/keymap.json` — prefer editing that over muscle-memory changes.
