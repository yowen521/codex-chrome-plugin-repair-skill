# Failure Modes

## Plugin install failed in Codex Desktop

Symptoms:

- Codex Desktop toast says plugin install failed.
- Browser or Chrome plugin card exists but install button fails.

Likely causes:

- Bundled marketplace path is missing or malformed.
- Plugin cache is incomplete.
- Config file encoding or marketplace source path is invalid.

Checks:

- `config.toml` has `[marketplaces.openai-bundled]`.
- `config.toml` has `[plugins."browser@openai-bundled"]` and `[plugins."chrome@openai-bundled"]`.
- Plugin cache exists under `%USERPROFILE%\.codex\plugins\cache\openai-bundled`.

## Chrome extension shows Disconnected

Symptoms:

- Chrome extension popup says Disconnected.
- Popup says "Use the Chrome plugin in Codex to connect."

Likely causes:

- Codex Chrome plugin has not been activated in Codex Desktop.
- Chrome was opened before the native host was installed.
- Native host manifest is missing or wrong.

Checks:

- Chrome is running.
- Extension is installed and enabled in the selected Chrome profile.
- Native host manifest and registry key are correct.

If extension/native host is missing or invalid, ask the user to reinstall the Chrome plugin from Codex Desktop plugin UI.

## Chrome extension shows Connected, but Codex cannot use @chrome

Symptoms:

- Chrome popup says Connected.
- Codex says current session has no Chrome plugin control entry.
- Codex opens Chrome using a fallback instead of controlling the extension.

Likely causes:

- `mcp_servers.node_repl` is missing from `%USERPROFILE%\.codex\config.toml`.
- `NODE_REPL_TRUSTED_BROWSER_CLIENT_SHA256S` is missing.
- Codex app-server was already running before the config was repaired.

Repair:

1. Add or replace `node_repl` MCP entry.
2. Set `NODE_REPL_NODE_PATH`.
3. Set `NODE_REPL_TRUSTED_BROWSER_CLIENT_SHA256S` to the SHA-256 of the bundled Chrome `browser-client.mjs`.
4. Restart the Codex app-server or open a fresh Codex Desktop session.

## browser-client is not trusted

Symptom:

```text
privileged native pipe bridge is not available; browser-client is not trusted
```

Cause:

The browser-client script loaded from the Chrome plugin cache does not match a trusted hash in the node_repl environment.

Repair:

Compute the exact SHA-256 of:

```text
%USERPROFILE%\.codex\plugins\cache\openai-bundled\chrome\<version>\scripts\browser-client.mjs
```

Then set it as:

```text
NODE_REPL_TRUSTED_BROWSER_CLIENT_SHA256S=<sha256>
```

## Repair succeeds in command test but fails in Codex UI

Symptoms:

- `codex mcp get node_repl` is correct.
- A standalone test can list Chrome tabs.
- Current Codex Desktop conversation still says no Chrome control entry.

Likely cause:

The active app-server was started before the fixed config was written.

Repair:

Restart the app-server. If needed, restart the Codex Desktop app. Start a new `@chrome` turn after restart.

## Chrome is not running

Symptoms:

- Chrome extension cannot be reached.
- `chrome-is-running.js` reports false.

Handling:

Ask the user before launching Chrome. Do not silently open Chrome when using the Chrome skill.

## Native host or extension missing

Symptoms:

- `check-extension-installed.js` reports missing or disabled.
- `check-native-host-manifest.js` reports missing, invalid, or mismatched.

Handling:

Do not hand-install the native host as the default repair. Ask the user to reinstall the Chrome plugin from Codex Desktop plugin UI, then re-run checks.
