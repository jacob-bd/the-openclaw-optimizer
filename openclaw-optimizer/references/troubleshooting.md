# OpenClaw Optimizer — Troubleshooting Reference
# Aligned with OpenClaw v2026.2.26 | Source: docs.openclaw.ai/troubleshooting + GitHub Issues

## 10. Troubleshooting Reference

> Source pages fetched: docs.openclaw.ai/troubleshooting, /gateway/troubleshooting, /help/troubleshooting, /automation/troubleshooting, /channels/troubleshooting, /nodes/troubleshooting, /tools/browser-linux-troubleshooting, /help/debugging, /gateway/doctor, /cli/doctor — last pulled 2026-02-24.

---

### 60-Second Triage — Run These First (Always)

```bash
openclaw status
openclaw status --all
openclaw gateway probe
openclaw gateway status
openclaw doctor
openclaw channels status --probe
openclaw logs --follow
```

**Expected healthy output for each:**
- `openclaw status` — configured channels visible, no auth errors
- `openclaw status --all` — complete shareable report generated
- `openclaw gateway probe` — gateway target reachable
- `openclaw gateway status` — "Runtime: running" AND "RPC probe: ok"
- `openclaw doctor` — no blocking configuration or service errors
- `openclaw channels status --probe` — channels show "connected" or "ready"
- `openclaw logs --follow` — steady activity, no repeating fatal errors

---

### Diagnostic Decision Tree — 7 Primary Failure Categories

1. **No replies** — sender receives no response from the agent
2. **Dashboard / Control UI connectivity** — web interface fails to load or authenticate
3. **Gateway startup** — service will not start or crashes on start
4. **Channel message flow** — channel is connected but messages are blocked
5. **Cron / heartbeat delivery** — scheduled jobs or heartbeats do not fire or deliver
6. **Node tool execution** — camera, canvas, screen, or exec commands fail
7. **Browser tool failures** — browser functionality breaks

---

### Category 1 — No Replies

**Diagnostic commands (run in order):**
```bash
openclaw status
openclaw gateway status
openclaw channels status --probe
openclaw pairing list <channel>
openclaw logs --follow
```

**Success indicators:**
- Runtime status: "running"
- RPC probe: "ok"
- Channel shows "connected" or "ready"
- Sender appears approved, or DM policy is "open" / allowlist includes sender

**Common log patterns and what they mean:**

| Log Signature | Meaning | Fix |
|---|---|---|
| `drop guild message (mention required` | Discord mention gating blocked the message | Disable `requireMention`, or mention the bot explicitly |
| `pairing request` | Sender is unapproved; awaiting DM pairing approval | Run `openclaw pairing list <channel>` → approve sender |
| `blocked` / `allowlist` | Sender, room, or group is filtered by policy rules | Review allowlist; add sender or loosen policy |

**Related docs:** /gateway/troubleshooting#no-replies, /channels/troubleshooting, /channels/pairing

---

### Category 2 — Dashboard / Control UI Connectivity

**Diagnostic commands:**
```bash
openclaw status
openclaw gateway status
openclaw gateway status --json
openclaw logs --follow
openclaw doctor
openclaw channels status --probe
```

**Default Control UI URL:** `http://127.0.0.1:18789/` or `http://localhost:18789/`

**Success indicators:**
- Dashboard URL displayed in `openclaw gateway status` output
- RPC probe: "ok"
- No authentication loops in logs

**Common log patterns and fixes:**

| Log Signature | Meaning | Fix |
|---|---|---|
| `device identity required` | HTTP / non-secure context cannot complete device auth | Use HTTPS via Tailscale Serve; or set emergency toggle `allowInsecureAuth` (break-glass only) |
| `unauthorized` / reconnect loop | Token or password wrong, or auth mode mismatch | Verify `gateway.auth.token` matches what the UI is using |
| `gateway connect failed:` | UI is targeting the wrong URL, port, or the gateway is unreachable | Confirm host/port in browser URL matches `openclaw gateway status` output |

**macOS-specific: launchctl environment variable override issue**

Previous `launchctl setenv` commands for `OPENCLAW_GATEWAY_TOKEN` or `OPENCLAW_GATEWAY_PASSWORD` persist across reboots and silently override config file settings, causing "unauthorized" errors even after fixing the config.

```bash
# Diagnose
launchctl getenv OPENCLAW_GATEWAY_TOKEN
launchctl getenv OPENCLAW_GATEWAY_PASSWORD

# Fix
launchctl unsetenv OPENCLAW_GATEWAY_TOKEN
launchctl unsetenv OPENCLAW_GATEWAY_PASSWORD
```

**Related docs:** /gateway/troubleshooting#dashboard-control-ui-connectivity, /web/control-ui, /gateway/authentication

---

### Category 3 — Gateway Startup / Service Not Running

**Diagnostic commands:**
```bash
openclaw gateway status
openclaw gateway status --deep
openclaw status
openclaw logs --follow
openclaw doctor
openclaw channels status --probe
```

**Success indicators:**
- "Service: ... (loaded)"
- "Runtime: running"
- "RPC probe: ok"

**Common error signatures and exact fixes:**

| Error Message | Root Cause | Fix |
|---|---|---|
| `Gateway start blocked: set gateway.mode=local` | `gateway.mode` is unset or set to "remote" | `openclaw config set gateway.mode local` — For Podman/openclaw user: config location is `~openclaw/.openclaw/openclaw.json` |
| `refusing to bind gateway ... without auth` | Non-loopback bind (`lan`, `tailnet`, `custom`) requires a token or password | Set `gateway.auth.token` before binding to non-loopback |
| `another gateway instance is already listening` / `EADDRINUSE` | Port 18789 (default) is already occupied | Check `openclaw doctor` for port collision detection; kill the conflicting process or change the gateway port |

**Post-upgrade: service config and runtime disagree**

```bash
# Reinstall service metadata
openclaw gateway install --force
openclaw gateway restart
```

**Related docs:** /gateway/troubleshooting#gateway-service-not-running, /gateway/background-process, /gateway/configuration

---

### Category 4 — Channel Connected But Messages Not Flowing

**Diagnostic commands:**
```bash
openclaw channels status --probe
openclaw pairing list <channel>
openclaw status --deep
openclaw logs --follow
openclaw config get channels
```

**Success indicators:**
- Channel transport connected
- Pairing / allowlist checks pass
- Required mentions are detected

**Common log patterns and fixes:**

| Log Signature | Meaning | Fix |
|---|---|---|
| `mention required` | Group mention policy is filtering messages | Disable `requireMention` or mention the bot explicitly |
| `pairing` / `pending` | DM sender not yet approved | `openclaw pairing list <channel>` → approve sender |
| `missing_scope` | Channel API token lacks a required OAuth scope | Re-authenticate the channel with correct scopes |
| `not_in_channel` | Bot is not a member of the target channel | Invite the bot to the channel |
| `Forbidden` / `401` / `403` | Auth token is invalid or revoked | Re-authenticate the channel |

**Per-channel specific troubleshooting:**

**WhatsApp:**
- No DM replies despite connection: `openclaw pairing list whatsapp` → approve senders or adjust DM policy
- Group message silence: Verify `requireMention` and mention patterns; loosen or ensure bot is mentioned
- Disconnect/relogin cycles: `openclaw channels status --probe` + review logs; re-authenticate and check credentials directory integrity

**Telegram:**
- Bot active but no `/start` response: `openclaw pairing list telegram` → approve pairings or modify DM policy
- Group message suppression: Disable bot privacy mode or require mentions as configured
- Network transmission errors: Inspect logs for API failures; resolve DNS/IPv6/proxy routing to `api.telegram.org`
- Post-upgrade allowlist rejection: `openclaw security audit` + `openclaw doctor --fix`, or replace `@username` references with numeric sender IDs

**Discord:**
- Guild silence despite online status: `openclaw channels status --probe`; enable guild/channel allowlisting and verify message content intent
- Group message filtering: Check logs for mention-based drops; disable `requireMention` or mention the bot
- Missing DM responses: `openclaw pairing list discord` → approve DM pairings or adjust DM policy

**Slack:**
- Socket mode active but unresponsive: Verify app token, bot token, and required OAuth scopes via `openclaw channels status --probe`
- DM restrictions: `openclaw pairing list slack` → approve pairings or relax DM policy
- Channel message suppression: Review `groupPolicy` and channel allowlist; switch policy to "open" mode if needed

**iMessage / BlueBubbles:**
- Missing inbound events: Verify webhook/server accessibility and app permissions; fix webhook URL or BlueBubbles server state
- macOS receive failure: Re-grant TCC (Transparency, Consent, and Control) permissions and restart the channel process
- Sender blocking: `openclaw pairing list imessage` or `openclaw pairing list bluebubbles` → approve senders or update allowlist

**Signal:**
- Daemon accessible but bot unresponsive: Confirm `signal-cli` daemon URL/account configuration and receive mode via `openclaw channels status --probe`
- DM rejection: `openclaw pairing list signal` → approve senders or relax DM policy
- Group reply failure: Verify group allowlist and mention pattern settings

**Matrix:**
- Room message suppression: Check `groupPolicy` and room allowlist via `openclaw channels status --probe`
- DM processing failure: `openclaw pairing list matrix` → approve senders or adjust DM policy
- Encrypted room dysfunction: Enable encryption support, verify crypto module, and rejoin/sync affected rooms

**DM policy values:** `"pairing"` (default) | `"allowlist"` | `"open"` | `"disabled"`

**Pairing code specs:**
- 8 uppercase characters (no ambiguous 0, O, 1, I)
- Valid for 1 hour
- Max 3 pending requests per channel; excess requests are discarded

**Related docs:** /gateway/troubleshooting#channel-connected-messages-not-flowing, /channels/troubleshooting

---

### Category 5 — Cron and Heartbeat Delivery

**Diagnostic commands:**
```bash
openclaw cron status
openclaw cron list
openclaw cron runs --id <jobId> --limit 20
openclaw system heartbeat last
openclaw logs --follow
openclaw config get agents.defaults.heartbeat
openclaw channels status --probe
```

**Success indicators:**
- Cron status: enabled with a future `nextWakeAtMs`
- Job enabled with valid schedule and timezone
- Recent runs show "ok" entries
- Heartbeat enabled and within configured `activeHours`

**Cron-specific error signatures:**

| Error Message | Root Cause | Fix |
|---|---|---|
| `cron: scheduler disabled; jobs will not run automatically` | Cron is disabled in configuration or environment | Enable cron in config; check environment overrides |
| `cron: timer tick failed` | Scheduler crashed | Check surrounding log lines for file/runtime errors |
| `reason: not-due` | Manual run invoked without `--force`; job not yet scheduled | Add `--force` flag: `openclaw cron run <job-id> --force` |

**Heartbeat-specific error signatures:**

| Log Signature / Reason | Root Cause | Fix |
|---|---|---|
| `heartbeat skipped` + `reason=quiet-hours` | Outside configured `activeHours` window | Adjust `activeHours.start` / `activeHours.end` or timezone |
| `requests-in-flight` | Main processing queue is busy; heartbeat deferred | Normal behavior under load; reduce heartbeat frequency or check for stuck sessions |
| `empty-heartbeat-file` | Interval heartbeat skipped because `HEARTBEAT.md` contains only blank lines and headers | Add content to `HEARTBEAT.md` or disable the check |
| `alerts-disabled` | Visibility settings suppress messages | Check `showOk`, `showAlerts`, `useIndicator` settings |
| `heartbeat skipped` + `reason=unknown accountId` | Heartbeat delivery target account does not exist | Verify the delivery target account ID in heartbeat config |

**Timezone / activeHours pitfalls:**

- Missing `agents.defaults.userTimezone` → system falls back to host timezone or `activeHours.timezone`
- Cron without `--tz` flag uses gateway host timezone
- ISO timestamps without timezone in `at` schedules are interpreted as UTC
- After host timezone changes, verify wall-clock execution times are still correct
- Heartbeat always suppressed during specific hours if `activeHours.timezone` is wrong

**Manual heartbeat trigger:**
```bash
openclaw system event --text "message" --mode now
```

**Related docs:** /gateway/troubleshooting#cron-and-heartbeat-delivery, /automation/troubleshooting, /automation/cron-jobs, /gateway/heartbeat

---

### Category 6 — Node Paired Tool Failures

**Diagnostic commands:**
```bash
openclaw nodes status
openclaw nodes describe --node <idOrNameOrIp>
openclaw approvals get --node <idOrNameOrIp>
openclaw logs --follow
openclaw status
```

**Success indicators:**
- Node listed as connected and paired for "node" role
- Required capability exists for the invoked command (visible in `nodes describe`)
- Tool permission state is "granted"
- Exec approvals configured with expected mode and allowlist

**Error code reference (exact strings):**

| Error Code | Meaning | Fix |
|---|---|---|
| `NODE_BACKGROUND_UNAVAILABLE` | App is backgrounded; canvas/camera/screen require foreground | Bring the node app to the foreground |
| `CAMERA_DISABLED` | Camera disabled in device settings | Enable camera in device settings |
| `*_PERMISSION_REQUIRED` | Missing OS permission (camera, mic, screen, location) | Grant the permission in OS settings; see platform table below |
| `LOCATION_DISABLED` | Location mode is inactive on device | Enable location services |
| `LOCATION_PERMISSION_REQUIRED` | Requested location mode not granted | Grant the specific location permission level |
| `LOCATION_BACKGROUND_UNAVAILABLE` | Insufficient permission scope for background location | Grant "Always" / background location permission |
| `SYSTEM_RUN_DENIED: approval required` | Exec approval is pending | Approve via Control UI, macOS app, or `/approve <id> allow-once` |
| `SYSTEM_RUN_DENIED: allowlist miss` | Command is blocked by allowlist policy | `openclaw approvals allowlist add --node <id> "<command>"` |

**Platform-specific permission requirements:**

| Capability | iOS | Android | macOS | Error |
|---|---|---|---|---|
| Camera operations | Camera + mic (for clip) | Camera + mic (for clip) | Camera + mic (for clip) | `*_PERMISSION_REQUIRED` |
| Screen recording | Screen Recording ± mic | Screen capture prompt ± mic | Screen Recording | `*_PERMISSION_REQUIRED` |
| Location access | While Using / Always | Foreground / Background (mode-dependent) | Location permission | `LOCATION_PERMISSION_REQUIRED` |
| Shell execution | N/A | N/A | Exec approvals required | `SYSTEM_RUN_DENIED` |

**Critical limitations:**
- iOS, Android, and macOS nodes restrict `canvas.*`, `camera.*`, `screen.*` to foreground operation
- Screen recordings clamped to ≤60 seconds
- Location services disabled by default
- Android SMS requires device permission grant before capability advertisement
- Windows: shell-wrapper forms like `cmd.exe /c` are treated as allowlist misses unless explicitly approved

**Two separate authorization layers (do not confuse):**
- **Device pairing** — gateway connectivity eligibility (`openclaw devices list`, `openclaw devices approve <requestId>`)
- **Exec approvals** — command execution permissions (`openclaw approvals get`, `openclaw approvals allowlist add`)

**Approval chat channel forwarding:**
```
/approve <id> allow-once
/approve <id> allow-always
/approve <id> deny
```

**Exec approvals config location:** `~/.openclaw/exec-approvals.json`

**Exec approval security modes:**
- `deny` — blocks all host exec requests
- `allowlist` — permits only allowlisted commands
- `full` — allows everything (equivalent to elevated)

**Ask modes:**
- `off` — never prompt
- `on-miss` — prompt only when allowlist does not match
- `always` — prompt on every command

**Related docs:** /gateway/troubleshooting#node-paired-tool-fails, /nodes/troubleshooting, /tools/exec-approvals

---

### Category 7 — Browser Tool Failures

**Diagnostic commands:**
```bash
openclaw browser status
openclaw browser start --browser-profile openclaw
openclaw browser profiles
openclaw logs --follow
openclaw doctor
```

**Success indicators:**
- Browser status shows "running: true" with selected browser/profile
- "openclaw" profile starts, or Chrome relay has an attached tab

**Common error signatures and fixes:**

| Error Message | Root Cause | Fix |
|---|---|---|
| `Failed to start Chrome CDP on port 18800` | Local browser launch failed — most common on Linux with snap Chromium | Install Google Chrome `.deb` package; configure `browser.executablePath` to `/usr/bin/google-chrome-stable`; set `noSandbox: true` and `headless: true` |
| `browser.executablePath not found` | Configured binary path is incorrect or does not exist | Run `openclaw browser profiles` to find available profiles; correct `browser.executablePath` |
| `Chrome extension relay is running, but no tab is connected` | Extension is installed but no tab has been attached | Click the OpenClaw extension toolbar button on a tab to attach; badge shows `ON` when attached |
| `Browser attachOnly is enabled ... not reachable` | Attach-only profile is configured but no live CDP target exists | Manually start Chrome with `--remote-debugging-port` flags before OpenClaw tries to attach |

**Linux-specific root cause:** Ubuntu's default `apt install chromium` installs only a snap wrapper stub, not a functional browser. The snap AppArmor profile blocks subprocess spawning that OpenClaw requires.

**Linux fix:**
```bash
# Install Google Chrome .deb (not snap Chromium)
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt-get install -f

# Then update OpenClaw config
openclaw config set browser.executablePath /usr/bin/google-chrome-stable
openclaw config set browser.noSandbox true
openclaw config set browser.headless true
```

**Linux attach-only alternative (for users requiring snap Chromium):**
Start Chrome manually with debug flags, then configure OpenClaw to attach rather than launch:
```json5
{
  browser: {
    attachOnly: true,
    cdpPort: 18800,
  }
}
```

**Linux systemd auto-start option:**
Create a systemd user service that starts Chrome with proper flags at login, eliminating manual startup steps.

**Browser verification commands:**
```bash
# Check CDP endpoint is reachable
curl http://127.0.0.1:18791/json/version
curl http://127.0.0.1:18791/json/list

# Check browser status via OpenClaw
openclaw browser status
```

**Chrome extension port derivation:**
When using a custom gateway port, the extension relay port = gateway port + 3.
Example: gateway on port 19001 → relay on port 19004.

**Extension configuration:**
- Relay port: default `18792`
- Gateway token must match `gateway.auth.token` / `OPENCLAW_GATEWAY_TOKEN`
- Extension badge: `ON` = attached, `...` = connecting, `!` = disconnected

**Two browser profile types:**
- `openclaw` — managed, isolated instance (no extension required; recommended)
- `chrome` — extension relay connecting to your system browser (requires OpenClaw extension installed)

**Security warning:** When the extension is attached, the model can click/type/navigate in that tab and read page content. Use dedicated Chrome profiles, not your daily-driver browser account.

**Related docs:** /gateway/troubleshooting#browser-tool-fails, /tools/browser-linux-troubleshooting, /tools/chrome-extension

---

### Post-Upgrade Breakage

#### Auth and URL Override Behavior Changed

```bash
openclaw gateway status
openclaw config get gateway.mode
openclaw config get gateway.remote.url
openclaw config get gateway.auth.mode
```

| Signature | Meaning | Fix |
|---|---|---|
| `gateway connect failed:` | Wrong URL target after upgrade | Verify `gateway.mode` is "local" not "remote"; correct the URL |
| `unauthorized` | Endpoint reachable but authentication mismatch | Re-check `gateway.auth.token` alignment |

Note: `gateway.mode=remote` routes CLI calls away from the local service. Explicit `--url` flags ignore stored credentials.

#### Bind and Auth Guardrails Stricter (recent change)

```bash
openclaw config get gateway.bind
openclaw config get gateway.auth.token
openclaw gateway status
openclaw logs --follow
```

| Signature | Meaning | Fix |
|---|---|---|
| `refusing to bind gateway ... without auth` | Non-loopback bind lacks auth config | Set `gateway.auth.token` before using `lan`, `tailnet`, or `custom` bind |
| `RPC probe: failed` while runtime is running | Gateway inaccessible with current auth/url | Check auth token and URL are aligned |

**Important:** The old `gateway.token` config key does NOT replace `gateway.auth.token`. You must use the new key.

#### Pairing and Device Identity State Changed

```bash
openclaw devices list
openclaw pairing list <channel>
openclaw logs --follow
openclaw doctor
```

| Signature | Meaning | Fix |
|---|---|---|
| `device identity required` | Device auth not satisfied (HTTP context or missing device auth) | Complete device pairing; or use HTTPS via Tailscale Serve |
| `pairing required` | Sender or device must be approved | Approve via `openclaw pairing approve <channel> <CODE>` or `openclaw devices approve <requestId>` |

**Recovery:** If service config and runtime disagree after upgrade:
```bash
openclaw gateway install --force
openclaw gateway restart
```

---

### `openclaw doctor` — What It Checks (19+ Operations)

```bash
openclaw doctor                    # interactive health check + repair prompts
openclaw doctor --repair           # apply recommended repairs without prompting
openclaw doctor --repair --force   # aggressive repair; overwrites custom supervisor configs
openclaw doctor --yes              # accept default repair prompts (for automation)
openclaw doctor --non-interactive  # safe migrations only; skips actions needing human confirmation
openclaw doctor --deep             # scans system for extra gateway installations
openclaw doctor --generate-gateway-token   # forces token creation in automation
```

**Pre-execution review:**
```bash
cat ~/.openclaw/openclaw.json
```

**What doctor checks (complete list):**
1. Git install updates (interactive mode only)
2. UI protocol freshness (rebuilds Control UI when schema is newer)
3. Health checks and restart prompts
4. Skills status (eligible / missing / blocked summary)
5. Config normalization for legacy values
6. OpenCode Zen provider warnings when `models.providers.opencode` overrides exist
7. Legacy state migration (sessions / agent directories / WhatsApp authentication)
8. State integrity (sessions, transcripts, permissions)
9. Config file permissions validation (chmod 600)
10. Model auth health (OAuth expiry detection and token refresh)
11. Extra workspace detection
12. Sandbox image repair
13. Legacy service migration and gateway detection
14. Gateway runtime checks (service installation and execution status)
15. Channel status warnings (probed from running gateway)
16. Supervisor config audit (launchd / systemd / schtasks)
17. Runtime best-practice checks (Node vs Bun, version-manager paths)
18. Gateway port collision diagnostics (default port: 18789)
19. Security warnings (open DM policies, missing authentication tokens)

**Config migrations doctor handles automatically:**

| Old Key | New Key |
|---|---|
| `routing.allowFrom` | `channels.whatsapp.allowFrom` |
| `routing.groupChat.*` | channel-specific group configuration paths |
| `routing.queue` | `messages.queue` |
| `routing.bindings` | top-level `bindings` |
| `routing.agents` / `routing.defaultAgentId` | `agents.list` structure |
| `agent.*` | `agents.defaults` + tool configurations |
| `browser.ssrfPolicy.allowPrivateNetwork` | `browser.ssrfPolicy.dangerouslyAllowPrivateNetwork` |
| `gateway.token` (old) | `gateway.auth.token` (new) |

**State paths doctor migrates:**
- Sessions: `~/.openclaw/sessions/` → `~/.openclaw/agents/<agentId>/sessions/`
- Agent dirs: `~/.openclaw/agent/` → `~/.openclaw/agents/<agentId>/agent/`
- WhatsApp auth: `~/.openclaw/credentials/*.json` → `~/.openclaw/credentials/whatsapp/<accountId>/`

**Runtime best-practice warning:** Doctor warns when the gateway runs on Bun or version-managed Node paths (`nvm`, `fnm`, `volta`, `asdf`) since WhatsApp and Telegram channels require system Node. Doctor offers migration to system Node installs.

**Port collision:** Doctor reports collisions on port 18789 with likely causes (already-running gateway, SSH tunnel). Check with `openclaw doctor --deep`.

**Backup created by `--fix` flag:** `~/.openclaw/openclaw.json.bak`

---

### Debugging Tools

```bash
# Runtime debug overrides (in-memory only, not persisted to disk)
# Requires: commands.debug: true in config
/debug show        # display current overrides
/debug set         # apply temporary settings
/debug unset       # remove specific overrides
/debug reset       # clear all overrides, restore disk config
```

**Raw stream logging (development use):**
```bash
# Capture unfiltered assistant stream before processing
pnpm gateway:watch --raw-stream
# or:
OPENCLAW_RAW_STREAM=1 pnpm gateway:watch
# Default output: ~/.openclaw/logs/raw-stream.jsonl

# Log raw OpenAI-compatible chunks before parsing
PI_RAW_STREAM=1 pnpm gateway:watch
# Path configurable via PI_RAW_STREAM_PATH
```

**Security note:** Raw stream logs retain full prompts, tool responses, and user data. Keep logs local, remove after debugging, scrub sensitive data before sharing.

**Dev profile (isolated environment):**
```bash
pnpm gateway:dev                   # state stored under ~/.openclaw-dev, port 19001
OPENCLAW_PROFILE=dev openclaw tui  # connect TUI to dev profile
pnpm gateway:dev:reset             # wipe config, credentials, sessions, dev workspace
```

---

### Security Audit Command

```bash
openclaw security audit    # post-upgrade: checks allowlists, policies, and auth
```

Use after upgrades to catch post-upgrade allowlist rejections (e.g., `@username` references replaced by numeric sender IDs in Telegram).

---

### Quick Fixes by Symptom

| Symptom | First Command to Run | Most Likely Fix |
|---|---|---|
| No response from agent | `openclaw gateway status` | Gateway not running or pairing pending |
| Gateway won't start | `openclaw logs --follow` | Check for `EADDRINUSE` or `mode=local` not set |
| Control UI shows "unauthorized" | `launchctl getenv OPENCLAW_GATEWAY_TOKEN` | Remove stale launchctl env override |
| Cron job never fires | `openclaw cron status` | Cron disabled or timezone mismatch |
| Heartbeat always skipped | `openclaw config get agents.defaults.heartbeat.activeHours` | Wrong timezone or outside hours |
| Node tool returns error code | `openclaw nodes describe --node <id>` | Permission not granted or app backgrounded |
| Chrome won't start on Linux | `openclaw browser status` | Snap Chromium conflict; install Google Chrome .deb |
| Channel message dropped | `openclaw logs --follow` | Mention required or sender not paired |
| "RPC probe: failed" | `openclaw gateway status --deep` | Auth token mismatch or port conflict |
| Post-upgrade broken config | `openclaw doctor --fix` | Automatic config migration |

### Known Active Bugs (GitHub Issues — v2026.2.23)

These are confirmed open issues with workarounds. Check GitHub for fix status before applying patches.

**Gateway:**

| Issue | Symptom | Workaround |
|---|---|---|
| #25915 — Avatar loop | Network flapping, 11,000 req/sec to `/avatar/main?meta=1`, WAN cycling | Close browser tab → `openclaw gateway restart` |
| #25918 — `tools.catalog` error | Dashboard loads but chat empty; WebSocket error `"unknown method: tools.catalog"` | `Cmd+Shift+R` hard refresh; test incognito; `npm install -g openclaw@latest && openclaw gateway restart` |

**Auth:**

| Issue | Symptom | Workaround |
|---|---|---|
| #25872 — AntiGravity 401 | `"Invalid Google Cloud Code Assist credentials"` + all `google-antigravity/*` calls fail after v2026.2.23 upgrade | Re-auth: `openclaw models auth logout --provider google-antigravity && openclaw models auth login --provider google-antigravity` |
| #25928 — Chrome relay 401 | Port 18792 rejects all tokens with HTTP 401; port 18789 works fine | Switch to OpenClaw profile browser (port 18800) until fixed |
| #25920 — Chrome extension "Gateway token rejected" | Extension options reject raw gateway token | Derive relay token via HMAC: `echo -n "openclaw-extension-relay-v1:18792" \| openssl dgst -sha256 -hmac "YOUR_GATEWAY_TOKEN"` — paste hex output into extension |

**Models:**

| Issue | Symptom | Workaround |
|---|---|---|
| #25926 — Fallback stops at 2 | `"All models failed (2): provider-a in cooldown \| provider-b in cooldown"` even with 15+ fallbacks | `openclaw models fallbacks list` to verify chain; `openclaw gateway restart` to reset cooldown state |
| #25912 — Empty fallback after failover | Post-failover secondary hits error → hard fail, zero remaining fallbacks | `openclaw sessions restart <session-id>` after provider recovers |
| #25895 — Ollama routing bypassed | Agent shows `openrouter/...` in status despite Ollama config; zero GPU activity | `openclaw config get agents.<name>.model` — verify baseUrl: `openclaw config set agents.<name>.provider.baseUrl "http://localhost:11434"` |
| #25880 — Memory flush threshold gap | Compaction fires before memoryFlush completes with 272K context | Set `reserveTokensFloor` equal to `reserveTokens`: both to `62500` in compaction config |

**Channels:**

| Issue | Symptom | Workaround |
|---|---|---|
| #25921 — Discord blockStreaming drops | First reply works, all subsequent silently dropped; `"DiscordMessageListener timed out after 30000ms"` | `openclaw config set channels.discord.blockStreaming false` |
| #25913 — Slack double-post | Agent `message` tool to originating channel produces both tool output AND suppressed inline text | Avoid using `message` tool to send to the session's own originating channel |
| #25906 — Cron announce → Telegram fails | `"cron announce delivery failed"` — job executes but delivery fails | Switch delivery to `directMessage` mode in job config |

**Memory:**

| Issue | Symptom | Workaround |
|---|---|---|
| #25910 — QMD silent failure | `memory.backend: "qmd"` configured, gateway starts fine, but memory searches return built-in results only | `which qmd` — if missing, `openclaw config set memory.backend builtin` |

**Cron:**

| Issue | Symptom | Workaround |
|---|---|---|
| #25902 — Cron skips current day | Job set for 06:00, gateway starts at 05:01, `nextRunAtMs` schedules for next day | `openclaw gateway restart` after jobs were expected to fire to force recompute |

---