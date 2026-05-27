# Codex Chrome Plugin Repair Skill

This repository contains a Codex skill for diagnosing and repairing Codex Desktop Browser/Chrome plugin setup issues on Windows.

It is especially useful when:

- Codex Desktop shows the Browser or Chrome plugin installed, but usage still fails.
- The Codex Chrome Extension shows `Connected`, but `@chrome` says no Chrome plugin control entry is available.
- Chrome extension/native-host checks pass, but Codex cannot actually list or control Chrome tabs.
- `browser-client.mjs` fails because it is not trusted.
- A repair works on disk, but the current Codex Desktop app-server has not reloaded the fixed config.

## What This Skill Covers

- Browser plugin vs Chrome plugin responsibilities
- Chrome extension installation checks
- Chrome native host manifest checks
- Codex-side `node_repl` MCP checks
- Browser-client trust hash repair
- Codex app-server reload guidance
- Common failure modes
- GitHub issue report template
- Windows health-check and repair script

## Install

Copy the skill folder into your Codex skills directory:

```powershell
Copy-Item -Recurse . "$env:USERPROFILE\.codex\skills\codex-chrome-plugin-repair"
```

Then start a new Codex conversation. The skill should be available as:

```text
codex-chrome-plugin-repair
```

## Quick Health Check

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\codex-chrome-plugin-health.ps1
```

If the Codex-side `node_repl` entry or browser-client trust is missing, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\codex-chrome-plugin-health.ps1 -Repair
```

If the current Codex Desktop app-server needs to reload config:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\codex-chrome-plugin-health.ps1 -Repair -RestartAppServer
```

## Important Note

Chrome showing `Connected` is not enough to prove that `@chrome` works.

The reliable success signal is that a fresh Codex turn can initialize the Chrome browser-client and list current Chrome tabs through:

```javascript
const tabs = await browser.user.openTabs();
```

## Files

- `SKILL.md`: skill entrypoint
- `scripts/codex-chrome-plugin-health.ps1`: Windows health check and Codex-side repair helper
- `references/install-use-guide.md`: install and usage lifecycle
- `references/plugin-map.md`: component map
- `references/failure-modes.md`: common symptoms and fixes
- `references/github-issue-template.md`: issue report template for upstream bugs

## Scope

The repair script only fixes the Codex-side `node_repl` MCP entry and browser-client trust hash.

It does not hand-install the Chrome native host. If the native host or Chrome extension is missing, reinstall the Chrome plugin from Codex Desktop plugin UI.
