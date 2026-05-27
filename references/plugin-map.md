# Codex Browser and Chrome Plugin Map

## Components

### Codex Desktop plugin UI

Shows whether bundled plugins such as Browser and Chrome are installed/enabled. This does not prove the active conversation can use the plugin.

### Browser plugin

Controls the in-app browser. It is mainly for local development pages, local files, and pages shown inside Codex.

Typical use:

- Localhost testing
- In-app browser screenshots
- Local file or local web app inspection

### Chrome plugin

Controls the user's installed Google Chrome through the Codex Chrome Extension and native messaging host.

Typical use:

- Logged-in websites
- Existing Chrome tabs
- The user's Chrome profile, cookies, and extensions
- Remote authenticated sites

### Codex Chrome Extension

Chrome Web Store extension ID observed in this case:

```text
hehggadaopoacecdllhhajmbjkdcmajg
```

The extension popup can show Connected while Codex still cannot use `@chrome`. Connected means the Chrome side can talk to its local host, not that the current Codex app-server has loaded the browser-control MCP entry.

### Native host manifest

Expected Windows path:

```text
%LOCALAPPDATA%\OpenAI\extension\com.openai.codexextension.json
```

Expected registry key:

```text
HKCU\Software\Google\Chrome\NativeMessagingHosts\com.openai.codexextension
```

The manifest should allow:

```text
chrome-extension://hehggadaopoacecdllhhajmbjkdcmajg/
```

If this layer is missing or invalid, ask the user to reinstall the Chrome plugin from the Codex plugin UI.

### node_repl MCP server

This is the bridge that lets a Codex conversation run the browser-client setup code. Without it, a thread can have the Chrome plugin installed and still say there is no available Chrome plugin control entry.

Expected command:

```text
%LOCALAPPDATA%\OpenAI\Codex\bin\node_repl.exe
```

Expected environment:

```text
NODE_REPL_NODE_PATH=%LOCALAPPDATA%\OpenAI\Codex\bin\node.exe
NODE_REPL_TRUSTED_BROWSER_CLIENT_SHA256S=<sha256>
```

### browser-client trust

The Chrome plugin's browser-client script needs to be trusted by hash. If the hash is absent, the failure can look like:

```text
privileged native pipe bridge is not available; browser-client is not trusted
```

Compute the hash from the exact bundled file:

```text
%USERPROFILE%\.codex\plugins\cache\openai-bundled\chrome\<version>\scripts\browser-client.mjs
```

### app-server reload

Codex Desktop starts an app-server process. Existing app-server instances do not necessarily reload `config.toml` after repair. A repair can be correct on disk but invisible to an already-running Desktop window until the app-server is restarted or a new Codex Desktop window/thread is created after restart.

## Success Criteria

The reliable success signal is not the UI saying Installed or Connected. The reliable signal is a successful browser-client call that lists current Chrome tabs through:

```javascript
await setupBrowserRuntime({ globals: globalThis });
const browser = await agent.browsers.get("extension");
const tabs = await browser.user.openTabs();
```
