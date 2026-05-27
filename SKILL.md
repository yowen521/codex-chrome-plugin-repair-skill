---
name: codex-chrome-plugin-repair
description: Diagnose and repair Codex Desktop Browser and Chrome plugin setup on Windows, especially when plugin installation succeeds or Chrome shows Connected but @chrome still says no Chrome plugin control entry is available, cannot open pages, or falls back to local Chrome launching. Use for Codex Browser/Chrome plugin install, native host, node_repl, browser-client trust, app-server restart, and Chrome extension connection troubleshooting.
---

# Codex Chrome Plugin Repair

Use this skill when the user is trying to install, connect, or use the Codex Browser or Chrome plugin and the behavior does not match the UI state.

## First Distinction

Separate these three layers before repairing anything:

1. **Plugin install state**: Codex Desktop shows Browser or Chrome plugin installed.
2. **Chrome extension state**: Chrome extension popup shows Connected or Disconnected.
3. **Codex tool state**: a new Codex turn can actually use Chrome through `@chrome`.

Do not treat Chrome showing Connected as final proof. It only proves the extension/native-host side is alive. Codex still needs a usable `node_repl` MCP entry and browser-client trust so new turns receive the Chrome control surface.

## Fast Workflow

1. Read `references/install-use-guide.md` for the full install/use lifecycle, then `references/plugin-map.md` for component responsibilities and expected states.
2. Run `scripts/codex-chrome-plugin-health.ps1` without repair first.
3. If `node_repl` is missing or browser-client is not trusted, run the same script with `-Repair`.
4. If the current Codex Desktop window was already open, restart the app-server or tell the user to open a fresh Codex window/thread.
5. Verify with a real browser-client call: set up the runtime, get the `extension` browser, and list open Chrome tabs.

## Windows Checks

Use the bundled Chrome plugin scripts when available:

```powershell
$node = "$env:LOCALAPPDATA\OpenAI\Codex\bin\node.exe"
$root = "$env:USERPROFILE\.codex\plugins\cache\openai-bundled\chrome\26.519.41501"
& $node "$root\scripts\installed-browsers.js" --json
& $node "$root\scripts\chrome-is-running.js" --json
& $node "$root\scripts\check-extension-installed.js" --json
& $node "$root\scripts\check-native-host-manifest.js" --json
```

Check Codex side:

```powershell
$codex = "$env:LOCALAPPDATA\OpenAI\Codex\bin\codex.exe"
& $codex mcp get node_repl
```

Expected Codex side after repair:

```toml
[mcp_servers.node_repl]
command = 'C:\Users\<user>\AppData\Local\OpenAI\Codex\bin\node_repl.exe'

[mcp_servers.node_repl.env]
NODE_REPL_NODE_PATH = 'C:\Users\<user>\AppData\Local\OpenAI\Codex\bin\node.exe'
NODE_REPL_TRUSTED_BROWSER_CLIENT_SHA256S = "<sha256 of chrome scripts/browser-client.mjs>"
```

## Repair Rule

Only repair the Codex-side `node_repl` entry and trust hash automatically. Do not hand-edit or install the Chrome native host manifest as a first response. If the native host or extension is missing, direct the user to reinstall the Chrome plugin from Codex Desktop plugin UI.

Use:

```powershell
.\scripts\codex-chrome-plugin-health.ps1 -Repair
```

Use this only when the current Desktop app-server needs to reload the fixed config:

```powershell
.\scripts\codex-chrome-plugin-health.ps1 -Repair -RestartAppServer
```

## Verification

A repair is complete only when a browser-client call can list real Chrome tabs from a fresh or reloaded Codex context.

Minimum verification code for `node_repl`:

```javascript
const { setupBrowserRuntime } = await import("file:///C:/Users/<user>/.codex/plugins/cache/openai-bundled/chrome/26.519.41501/scripts/browser-client.mjs");
await setupBrowserRuntime({ globals: globalThis });
globalThis.browser = await agent.browsers.get("extension");
const tabs = await browser.user.openTabs();
nodeRepl.write("CHROME_OK tabs=" + tabs.length);
```

If this succeeds, Chrome control is working. If a navigation test times out but `openTabs()` shows the new tab or URL, report that control works and the page load was slow or blocked separately.

## Common Failure Modes

Read `references/failure-modes.md` for exact symptoms and decisions. The most important cases:

- `Chrome popup: Connected`, but Codex says no control entry: usually missing `mcp_servers.node_repl` or stale app-server.
- `browser-client is not trusted`: add `NODE_REPL_TRUSTED_BROWSER_CLIENT_SHA256S` for the exact bundled `browser-client.mjs`.
- Repair works in a one-off test but not Desktop UI: restart the Codex app-server so new turns reload config.
- Chrome is not running: ask before launching Chrome.
- Extension or native host is missing/invalid: ask the user to reinstall the Chrome plugin from Codex plugin UI.

## GitHub Reporting

When asked to report this upstream, use `references/github-issue-template.md`. Include:

- UI states from Codex Desktop and Chrome extension.
- The exact failure text shown in Codex.
- Whether `node_repl` existed in `config.toml`.
- Whether `NODE_REPL_TRUSTED_BROWSER_CLIENT_SHA256S` was present.
- Whether restarting the app-server changed the result.
- A clear expected vs actual section.
