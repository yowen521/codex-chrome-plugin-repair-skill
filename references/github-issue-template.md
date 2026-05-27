# GitHub Issue Template

## Title

Codex Desktop Chrome plugin shows connected, but @chrome lacks a usable Chrome control entry until node_repl/browser-client trust and app-server reload are repaired

## Summary

Codex Desktop can show the Chrome plugin installed, and the Codex Chrome Extension in Chrome can show Connected, while new `@chrome` turns still fail with no available Chrome plugin control entry. In this state, Codex may fall back to opening Chrome locally, but it is not controlling Chrome through the extension.

The root problem appears to be a Codex-side integration/configuration gap: the active app-server does not expose the `node_repl` MCP server needed by the Chrome browser-client, or the browser-client hash is not trusted by `node_repl`. After restoring the MCP entry, adding the trusted browser-client SHA-256, and restarting the app-server, Chrome control works.

## Environment

- OS: Windows
- App: Codex Desktop
- Plugin: `chrome@openai-bundled`
- Chrome extension ID: `hehggadaopoacecdllhhajmbjkdcmajg`
- Extension version observed: `1.1.5`
- Chrome plugin cache path example:
  - `%USERPROFILE%\.codex\plugins\cache\openai-bundled\chrome\26.519.41501`

## Symptoms

1. Codex Desktop plugin UI shows Browser/Chrome installed or installable.
2. Chrome extension popup can show `Connected`.
3. A Codex turn using `@chrome` reports that no Chrome plugin control entry is available.
4. In some attempts, Codex opens Chrome through a local fallback, but does not control the tab through the extension.

Example user-visible failure:

```text
The current session has no available Chrome plugin control entry, so Codex cannot open the page through @chrome.
```

## Expected Behavior

If the Chrome plugin is installed in Codex Desktop and the Chrome extension shows Connected, a new Codex `@chrome` turn should receive the Chrome control surface and should be able to list or claim open Chrome tabs.

## Actual Behavior

The extension-side connection can be healthy while the Codex turn has no usable Chrome control tool. The UI state is therefore misleading: Connected does not mean the current Codex app-server can route Chrome commands.

## Diagnostics That Identified the Gap

Chrome side was healthy:

```text
check-extension-installed.js --json => installed: true, enabled: true
check-native-host-manifest.js --json => correct: true
chrome-is-running.js --json => running: true
```

Codex side was broken:

```text
codex mcp get node_repl => Error: No MCP server named 'node_repl' found.
```

In another partial state, `node_repl` existed but browser-client failed because it was not trusted:

```text
privileged native pipe bridge is not available; browser-client is not trusted
```

## Workaround / Repair

Restore the Codex-side `node_repl` MCP server and trust the exact bundled Chrome browser-client hash:

```powershell
$codex = "$env:LOCALAPPDATA\OpenAI\Codex\bin\codex.exe"
$nodeRepl = "$env:LOCALAPPDATA\OpenAI\Codex\bin\node_repl.exe"
$node = "$env:LOCALAPPDATA\OpenAI\Codex\bin\node.exe"
$browserClient = "$env:USERPROFILE\.codex\plugins\cache\openai-bundled\chrome\26.519.41501\scripts\browser-client.mjs"
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $browserClient).Hash.ToLowerInvariant()

& $codex mcp remove node_repl 2>$null | Out-Null
& $codex mcp add node_repl --env "NODE_REPL_NODE_PATH=$node" --env "NODE_REPL_TRUSTED_BROWSER_CLIENT_SHA256S=$hash" -- $nodeRepl
& $codex mcp get node_repl
```

Then restart the Codex Desktop app-server or restart Codex Desktop so new turns reload the config.

## Verification After Repair

Using `node_repl`, Chrome browser-client could initialize the extension backend and list tabs:

```javascript
const { setupBrowserRuntime } = await import("file:///C:/Users/<user>/.codex/plugins/cache/openai-bundled/chrome/26.519.41501/scripts/browser-client.mjs");
await setupBrowserRuntime({ globals: globalThis });
globalThis.browser = await agent.browsers.get("extension");
const tabs = await browser.user.openTabs();
nodeRepl.write("CHROME_OK tabs=" + tabs.length);
```

Observed success:

```text
CHROME_OK tabs=1
```

## Suggested Product Fixes

1. Make the Chrome plugin install/enable flow ensure `node_repl` is configured.
2. Automatically add or refresh the trusted browser-client SHA-256 when the bundled Chrome plugin updates.
3. Detect stale app-server state after plugin install/repair and prompt for reload/restart.
4. In the plugin UI, distinguish:
   - extension connected,
   - native host connected,
   - Codex app-server can expose Chrome control to new turns.
5. Improve `@chrome` failure messaging so it points to the missing `node_repl` or browser-client trust state instead of only saying no control entry is available.
