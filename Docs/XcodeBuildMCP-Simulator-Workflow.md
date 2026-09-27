# XcodeBuildMCP — Building, Running & Driving the Simulator

**This is the required tooling for anything involving the iOS Simulator.** Do not shell out to
`xcodebuild` or `xcrun simctl` for build/run/interaction work — use the XcodeBuildMCP tools.

## Setup (already done on this machine)

| Piece | Detail |
|-------|--------|
| MCP server | `.mcp.json` at the repo root registers `XcodeBuildMCP` (`npx -y xcodebuildmcp@latest mcp`) |
| UI automation backend | [AXe](https://github.com/cameroncooke/AXe) — `brew tap cameroncooke/axe && brew install axe` |
| Enabled workflows | `simulator`, `simulator-management`, `ui-automation`, `debugging` (LLDB), `device`, `project-discovery`, `session-management`, `swift-package`, `coverage`, `utilities`, `doctor` |
| Xcode MCP bridge | `.mcp.json` also registers `xcode` → `xcrun mcpbridge` (Xcode's own MCP server: previews, per-file diagnostics, String Catalog edits, documentation search) |

Session defaults are baked into `.mcp.json`, so most tools can be called without repeating them:

- Project: `Diameris.xcodeproj`
- Scheme: `Diameris`
- Configuration: `Debug`
- Simulator: `iPhone 17 Pro`, latest OS

Every automation-relevant workflow is enabled. Only `macos` (Diameris is iOS-only),
`project-scaffolding` (irrelevant) and `xcode-ide` (redundant — it proxies `xcrun mcpbridge`, which is
registered directly as the `xcode` server) are left out. `XCODEBUILDMCP_ENABLED_WORKFLOWS` **replaces**
the defaults rather than extending them, so the list must name every workflow in use.

### Xcode MCP bridge (`xcrun mcpbridge`)

Resolves inside the `xcode-select`ed Xcode, so it is unpinned and its tool set tracks the installed
Xcode. It needs either a UI Xcode with the project open and external-agent access approved, or headless
mode (`sudo xcrun mcp-server enable`) with this folder permitted
(`sudo xcrun mcp-server allow-folder <repo path>`). Otherwise it exits with status 1 and no message.
`xcrun mcp-server status` shows permission, permitted agents/folders and open workspaces.

### Xcode skills plugin (`xcode-integration`)

Xcode also packages Apple-authored skills as a Claude Code plugin. `xcrun agent plugin path
--plugin-format claude` materialises it under
`~/Library/Developer/Xcode/CodingAssistant/ExportedPlugins/<xcode-build>/claude`. It isn't vendored in
the repo because it tracks the installed Xcode build. A `claude` shell function in `~/.zshrc` passes
that path to `--plugin-dir` **only when launched inside a folder listed in
`CLAUDE_XCODE_PLUGIN_PROJECTS`** (currently just this repo); everywhere else it runs plain `claude`.

Skills (Xcode 27.0 RC, 27A266a): `swiftui-specialist`, `swiftui-whats-new-27`,
`accessibility-{voiceover,dynamic-type,sufficient-contrast}-specialist`, `translation-coordinator`,
`translation`, `modernize-tests`, `device-interaction`, `app-intents-specialist`,
`app-intents-whats-new-27`, `building-document-based-swiftui-applications`, `uikit-app-modernization`,
`adopt-c-bounds-safety`, `audit-xcode-security-settings`. When each must be used is in `CLAUDE.md`
("Apple Skills & Official Docs").

The plugin bundles its own `xcode` bridge server too, so with it loaded there are two bridge
connections (project `.mcp.json` + plugin). Harmless, just redundant.

Official docs: the bridge's `DocumentationSearch` tool does semantic search over Apple Developer
Documentation (optionally scoped with `frameworks`). Use it before web search.

## Rules

1. **Use MCP tools, not raw shell.** `simulator_build_and_run` instead of an `xcodebuild` incantation;
   `simulator_boot` / `simulator_open` instead of `xcrun simctl boot`. The MCP tools capture runtime
   logs automatically and return the log file path — raw shell does not.
2. **Never tap blind.** Always call `snapshot_ui` (or `wait_for_ui`) first and act on the returned
   `elementRef` values. Screen coordinates are forbidden — they break on every layout change.
3. **Re-snapshot after any UI change.** Navigation, scrolling, a sheet appearing/dismissing, or an
   obvious layout shift invalidates existing `elementRef`s.
4. **Screenshots are for the human, snapshots are for you.** Use `screenshot` to show the user what a
   change looks like; use `snapshot_ui` to decide where to tap.
5. **Verify UI work in the simulator.** After any SwiftUI change, build, run, drive to the affected
   screen, and take a screenshot. A change that only compiles is not a change that works.
6. **Unit tests still run through SPM/`swift test`** where that is faster (see the Build Commands
   section in `CLAUDE.md`). Use `simulator_test` when the test target needs a simulator host.

## Typical loop

```
simulator_build_and_run        # boots the sim if needed, installs, launches, captures logs
snapshot_ui                    # semantic tree with elementRefs + available actions per element
tap { elementRef: "e12" }      # or batch / swipe / type_text / long_press
wait_for_ui { ... }            # poll until the expected state settles, then re-snapshot
screenshot                     # show the user the result
```

## Tool cheat sheet

**Build & run** — `simulator_build_and_run`, `simulator_build`, `simulator_install`,
`simulator_launch_app`, `simulator_stop`, `simulator_clean`, `simulator_test`,
`simulator_get_app_path`, `simulator_get_app_bundle_id`, `simulator_list_schemes`,
`simulator_show_build_settings`

**Simulator management** — `simulator_list`, `simulator_boot`, `simulator_open`, `erase`,
`set_appearance` (light/dark — useful for Liquid Glass checks), `set_location`, `reset_location`,
`statusbar`, `toggle_software_keyboard`, `toggle_connect_hardware_keyboard`

**Interaction** — `snapshot_ui`, `wait_for_ui`, `tap`, `batch`, `touch`, `long_press`, `swipe`
(needs `withinElementRef` + `direction`, optional normalized `distance`), `drag`, `gesture`,
`type_text` (needs `elementRef`), `key_press` / `key_sequence` (HID codes: 40 Return, 42 Backspace,
43 Tab, 44 Space), `button` (hardware buttons), `screenshot`, `record_video`

**Coverage** — `get_coverage_report`, `get_file_coverage`

## Gotchas

- `swipe` takes `withinElementRef`, **not** `elementRef` — it scrolls *within* a scrollable element.
- `batch` takes a `steps` array of objects (`{"action":"tap","elementRef":"e1"}`), never raw strings.
  Don't set `preDelay`/`postDelay` on switch elements — they reject delays.
- `type_text` requires an `elementRef`; calling it with only `text` fails.
- Only `elementRef`s whose snapshot entry lists the action as a target are actionable. Text-only rows
  are not tappable.
- AXe must be on `PATH` for any interaction tool to work. If they start failing, check `which axe`.

## Verifying the setup

```bash
which axe && axe --version                          # expect 1.8.0+
npx -y xcodebuildmcp@latest tools                   # lists every tool
npx -y xcodebuildmcp@latest simulator list          # sanity-check simulator access
```
