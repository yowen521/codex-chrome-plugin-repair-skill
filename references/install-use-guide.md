# Install and Use Guide

## Browser vs Chrome

### Browser plugin

Use the Browser plugin for the Codex in-app browser. It is best for:

- local development pages;
- `localhost` testing;
- files opened inside Codex;
- screenshots or inspection in the in-app browser.

It does not use the user's Chrome profile.

### Chrome plugin

Use the Chrome plugin when the task needs the user's actual Google Chrome. It is best for:

- logged-in websites;
- existing Chrome tabs;
- cookies and account state;
- Chrome extension-dependent pages;
- remote websites where the in-app browser is not enough.

## Installation Lifecycle

### 1. Codex Desktop plugin install

The Codex plugin UI installs `chrome@openai-bundled` and/or `browser@openai-bundled`.

Expected config areas:

```toml
[marketplaces.openai-bundled]
source = 'C:\Users\<user>\.codex\bundled-marketplaces\openai-bundled'

[plugins."chrome@openai-bundled"]
enabled = true

[plugins."browser@openai-bundled"]
enabled = true
```

### 2. Chrome extension install

The Chrome plugin uses the Codex Chrome Extension from Chrome Web Store.

Observed extension ID:

```text
hehggadaopoacecdllhhajmbjkdcmajg
```

Chrome must have the extension installed and enabled in the selected profile.

### 3. Native host install

Chrome talks to a native host manifest under:

```text
%LOCALAPPDATA%\OpenAI\extension\com.openai.codexextension.json
```

Windows also needs:

```text
HKCU\Software\Google\Chrome\NativeMessagingHosts\com.openai.codexextension
```

If these are missing, use the Codex plugin UI reinstall flow instead of hand-installing the native host.

### 4. Codex-side control entry

Codex conversations need `node_repl` in:

```text
%USERPROFILE%\.codex\config.toml
```

This is the layer most likely to be invisible to the user. Chrome can show Connected while this layer is missing.

Required environment:

```text
NODE_REPL_NODE_PATH=<Codex bundled node.exe>
NODE_REPL_TRUSTED_BROWSER_CLIENT_SHA256S=<hash of Chrome browser-client.mjs>
```

### 5. App-server reload

After repair, the current Codex Desktop app-server may still be using old config. Restart the app-server or restart Codex Desktop before judging the repair.

## Use Lifecycle

1. User asks with `@chrome` or explicitly requests Chrome.
2. Codex initializes browser-client through `node_repl`.
3. Codex selects the `extension` backend.
4. Codex lists or claims an existing Chrome tab, or creates a new controlled tab.
5. Codex navigates, reads, clicks, types, screenshots, or uploads through that controlled tab.

## Reliable Success Signal

Do not use these as final proof:

- plugin card says installed;
- Chrome extension popup says Connected;
- Chrome opens a URL from a local shell fallback.

Use this as final proof:

```text
browser.user.openTabs() succeeds from a fresh Codex turn
```

Optional stronger proof:

```text
Codex creates or claims a Chrome tab and the tab appears in openTabs()
```
