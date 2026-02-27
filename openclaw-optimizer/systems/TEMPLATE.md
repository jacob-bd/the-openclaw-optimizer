# System Profile: [DEPLOYMENT_NAME]

**Deployment ID:** `[unique-slug]`
**Topology:** [gateway-only | hub-spoke | multi-gateway | mesh]
**Created:** YYYY-MM-DD
**Last updated:** YYYY-MM-DD

---

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
- **OS:** macOS X.X / Linux distro
- **Key paths:**
  - Config: ~/.openclaw/openclaw.json
  - Workspace: ~/.openclaw/workspace/
  - Skills: ~/.openclaw/workspace/skills/
  - Logs: ~/.openclaw/logs/

### Node: [hostname]
- **Role:** node | operator | ui-client
- **SSH:** user@ip
- **Local IP:** x.x.x.x
- **Tailscale IP:** x.x.x.x
- **Connect method:** tailscale-direct | ssh-tunnel | lan-direct
- **Transport:** direct | ssh
- **Client type:** openclaw-macos | cli | webchat
- **Gateway URL:** wss://...
- **OS:** macOS X.X / Linux distro

<!-- Repeat for each node -->

---

## Network

- **Tailnet:** tailnet-name.ts.net
- **Tailscale Serve:** https://hostname.tailnet.ts.net/ → http://127.0.0.1:PORT
- **Auth mode:** token
- **Gateway token:** [first 12 chars]...

---

## Providers (active)

| Provider | Slug | Primary Use | Notes |
|---|---|---|---|
| | | | |

---

## Model Routing

| Tier | Model | Use Case |
|---|---|---|
| T1 Cheap | | |
| T2 Mid | | |
| T3 Smart | | |
| T4 Premium | | |

---

## Channels

| Channel | Status | Notes |
|---|---|---|
| | | |

---

## Issue Log

<!-- Append new issues at the top (newest first) -->

### YYYY-MM-DD: [Short title]
- **Symptom:**
- **Root cause:**
- **Fix applied:**
- **Rollback:**
- **Lesson:**

---

## Lessons Learned

<!-- Accumulated patterns and gotchas specific to this deployment -->

1.
