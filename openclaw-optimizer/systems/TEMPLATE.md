# System Profile Template — Directory Format

When creating a new deployment profile, create the following directory structure:

```
~/.openclaw-optimizer/systems/<deployment-id>/
  INDEX.md          # Always loaded at session start (~1-4K tokens)
  topology.md       # Machines, Network, Paired Devices
  providers.md      # Active and removed providers
  routing.md        # Model routing tiers, fallbacks, heartbeat
  channels.md       # Telegram, WhatsApp, Delivery Queue
  cron.md           # Full cron job inventory
  lessons.md        # Permanent lessons learned
  issues/
    YYYY-MM.md      # Monthly issue files (current month)
    archive.md      # One-line summaries of issues older than 14 days
```

---

## INDEX.md Template

```markdown
# System Profile: [DEPLOYMENT_NAME]

**Deployment ID:** `[unique-slug]`
**Topology:** [gateway-only | hub-spoke | multi-gateway | mesh]
**Created:** YYYY-MM-DD
**Last updated:** YYYY-MM-DD

---

## Machines

| Machine | Role | SSH | Local IP | Tailscale IP |
|---|---|---|---|---|
| [hostname] | gateway | user@ip | x.x.x.x | x.x.x.x |
| [hostname] | node | user@ip | x.x.x.x | x.x.x.x |

**Gateway details:**
- Port: XXXXX | Bind: loopback | TLS: tailscale-serve
- OpenClaw: vXXXX.X.XX | Node: vXX.X.X
- Config: ~/.openclaw/openclaw.json
- Safe restart: `launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway`

---

## Providers

| Slug | Primary Use |
|---|---|
| | |

---

## Model Routing

| Role | Model |
|---|---|
| **Primary** | |
| Fallback 1 | |
| Premium | |

---

## Cron Jobs

| Name | Schedule | Model | Status |
|---|---|---|---|
| | | | |

---

## Channels

- **Telegram:** [status]
- **WhatsApp:** [status]

---

## File Manifest

| File | Contents | When to Read |
|---|---|---|
| `topology.md` | Machines, Network, Paired Devices | Connectivity, SSH, paths/IPs |
| `providers.md` | Active/removed providers | Provider config, auth issues |
| `routing.md` | Routing table, fallbacks, heartbeat | Model changes, timeout cascades |
| `channels.md` | Channel mapping, Delivery Queue | Channel issues, group management |
| `cron.md` | Full cron inventory | Cron failures, schedule conflicts |
| `lessons.md` | Permanent lessons | Read FIRST when diagnosing issues |
| `issues/YYYY-MM.md` | Monthly issue detail | Past fixes, rollback commands |
| `issues/archive.md` | Compressed issue summaries | Quick historical scan |
```

---

## topology.md Template

```markdown
# Topology — Machines, Network, Paired Devices

## Machines

### Gateway: [hostname]
- **Role:** gateway
- **SSH:** user@ip
- **Local IP:** x.x.x.x
- **Tailscale IP:** x.x.x.x
- **Tailscale hostname:** hostname.tailnet.ts.net
- **Gateway port:** XXXXX
- **Bind mode:** loopback | lan
- **TLS:** tailscale-serve | mkcert | off
- **OpenClaw version:** XXXX.X.XX
- **OS:** macOS / Linux
- **Key paths:**
  - Config: ~/.openclaw/openclaw.json
  - Workspace: ~/.openclaw/workspace/
  - Skills: ~/.openclaw/workspace/skills/
  - Logs: ~/.openclaw/logs/

### Node: [hostname]
- **Role:** node | operator
- **SSH:** user@ip
- **Local IP:** x.x.x.x
- **Tailscale IP:** x.x.x.x
- **Connect method:** tailscale-direct | ssh-tunnel | lan-direct
- **Client type:** openclaw-macos | cli | webchat
- **Gateway URL:** wss://...

---

## Network

- **Tailnet:** tailnet-name.ts.net
- **Tailscale Serve:** https://hostname.tailnet.ts.net/ → http://127.0.0.1:PORT
- **Auth mode:** token
- **Gateway token:** [first 12 chars]...

---

## Paired Devices (server)

| Device | ID (short) | Roles | IP | Status |
|---|---|---|---|---|
| | | | | |
```

---

## providers.md Template

```markdown
# Providers — Active and Removed

## Providers (active)

| Provider | Slug | Primary Use | Notes |
|---|---|---|---|
| | | | |

## Removed providers

<!-- Document why each provider was removed -->
```

---

## routing.md Template

```markdown
# Model Routing — Tiers, Fallbacks, Heartbeat

## Model Routing

| Tier | Model | Use Case |
|---|---|---|
| T1 Cheap | | |
| T2 Mid | | |
| T3 Smart | | |
| T4 Premium | | |

**Heartbeat:** [cadence], [active hours], [directPolicy]
```

---

## channels.md Template

```markdown
# Channels — Telegram, WhatsApp, Delivery Queue

## Channels

| Channel | Status | Notes |
|---|---|---|
| | | |

## Delivery Queue

No stuck entries.
```

---

## cron.md Template

```markdown
# Cron Jobs — Full Inventory

## Cron Jobs

**Assessed:** YYYY-MM-DD | **Total:** X jobs | **All isolated sessions** | **Agent:** main

| Job ID (short) | Name | Schedule | Model | Status | Notes |
|---|---|---|---|---|---|
| | | | | | |

### Observations

<!-- Model split, session targets, schedule patterns, known issues -->
```

---

## lessons.md Template

```markdown
# Lessons Learned — Permanent Knowledge

<!-- Accumulated patterns and gotchas specific to this deployment -->
<!-- Never archived — this file only grows -->

1.
```

---

## issues/archive.md Template

```markdown
# Issue Archive — Compressed Summaries

Issues older than 14 days are compressed to one-line summaries here.
Full details remain in their monthly files.

<!-- No archived issues yet -->
```

---

## issues/YYYY-MM.md Template

```markdown
# Issues — [Month Year]

### YYYY-MM-DD: [Short title]
- **Symptom:**
- **Root cause:**
- **Fix applied:**
- **Rollback:**
- **Lesson:**
```
