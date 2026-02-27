# OpenClaw Optimizer — CLI Reference
# Aligned with OpenClaw v2026.2.26 | Source: docs.openclaw.ai/cli

---

## Global Flags
```bash
--dev                   # isolate state under ~/.openclaw-dev
--profile <name>        # isolate state under ~/.openclaw-<name>
--json                  # machine-readable JSON output
--no-color              # disable ANSI colors
--update                # shorthand for openclaw update
-V / --version          # print version and exit
```

---

## Core Commands

```bash
# ── Setup & Config ──────────────────────────────────────────────────────────
openclaw onboard                                    # interactive setup wizard
openclaw configure                                  # alternative interactive config
openclaw config get <key.path>                      # read a config value
openclaw config set <key.path> <value>              # write (JSON5 parsed)
openclaw config unset <key.path>                    # remove a config value

# ── Models ──────────────────────────────────────────────────────────────────
openclaw models list                                # all configured models
openclaw models status                              # primary, fallbacks, auth status
openclaw models status --probe                      # live auth probes
openclaw models status --probe-provider <slug>      # probe one provider
openclaw models set <provider/model>                # change primary model
openclaw models set-image <model>                   # set image generation model
openclaw models fallbacks add <model>               # add a fallback
openclaw models fallbacks remove <model>            # remove a fallback
openclaw models fallbacks clear                     # remove all fallbacks
openclaw models fallbacks list                      # list fallback chain
openclaw models scan                                # discover free OpenRouter models
openclaw models auth login --provider <slug>        # authenticate a provider
openclaw models auth login-github-copilot           # GitHub Copilot device flow
openclaw models aliases add / remove / list         # manage model aliases

# ── Gateway ─────────────────────────────────────────────────────────────────
openclaw gateway start / stop / restart             # service control
openclaw gateway install [--force]                  # (re)install service metadata
openclaw gateway uninstall                          # remove service
openclaw gateway status                             # runtime + RPC probe status
openclaw gateway status --deep                      # thorough probe
openclaw gateway health [--json] [--verbose]        # live health probes
openclaw gateway probe                              # quick reachability check
openclaw gateway call config.apply                  # validate + write config + restart
openclaw gateway call config.patch                  # merge partial config update
openclaw gateway call update.run                    # execute update cycle via RPC
openclaw gateway discover                           # discover gateways on network

# ── Cron ────────────────────────────────────────────────────────────────────
openclaw cron list                                  # all jobs
openclaw cron status                                # scheduler health + next runs
openclaw cron add --cron "0 9 * * *" \
  --name "job-name" \
  --message "prompt text" \
  --agent <agent-id> \
  --channel <platform> \
  --to <recipient> \
  --announce                                        # recurring job with delivery
openclaw cron add --at "2026-03-01T08:00:00" \
  --message "..." --keep-after-run                  # one-shot job
openclaw cron run <job-id>                          # test immediately (--force bypasses not-due)
openclaw cron runs --id <job-id> --limit 20         # view run history
openclaw cron edit <job-id> [flags]                 # edit existing job
openclaw cron enable/disable <job-id>               # toggle job on/off
openclaw cron rm <job-id>                           # delete job

# ── Sessions ────────────────────────────────────────────────────────────────
openclaw sessions [--agent <id>] [--all-agents]     # list sessions
openclaw sessions --active <minutes>                # filter by recent activity
openclaw sessions cleanup --dry-run                 # preview pruning
openclaw sessions cleanup --enforce                 # apply pruning
openclaw sessions cleanup --all-agents              # prune all agents
openclaw sessions restart <session-id>              # restart a stuck session

# ── Updates ─────────────────────────────────────────────────────────────────
openclaw update                                     # update to latest stable
openclaw update --dry-run                           # preview update
openclaw update --channel beta                      # switch to beta channel
openclaw update --channel stable                    # switch back to stable
openclaw update status                              # check available updates
openclaw --update                                   # shorthand

# ── Skills & Plugins ────────────────────────────────────────────────────────
openclaw skills list                                # all skills
openclaw skills list --eligible                     # eligible skills only
openclaw skills info <name>                         # skill detail
openclaw skills check                               # validate requirements
openclaw plugins list                               # all plugins
openclaw plugins install <npm-spec-or-archive>      # install plugin
openclaw plugins enable/disable <id>                # toggle plugin
openclaw plugins update <id> [--dry-run] [--yes]    # update one
openclaw plugins update --all [--yes]               # update all
openclaw plugins uninstall <id>                     # remove plugin
openclaw plugins doctor                             # diagnose plugin issues

# ── Diagnostics ─────────────────────────────────────────────────────────────
openclaw doctor                                     # health check + repair prompts
openclaw doctor --fix / --repair                    # auto-fix config issues
openclaw doctor --deep                              # thorough state + orphan scan
openclaw doctor --non-interactive                   # safe for cron/CI
openclaw health [--json] [--verbose]                # live per-account probes
openclaw status                                     # channel + service state
openclaw status --all                               # full shareable report
openclaw status --deep                              # live channel probes
openclaw logs --follow                              # tail gateway logs (real-time)
openclaw logs --limit 500                           # last 500 log entries
openclaw security audit                             # post-upgrade security check

# ── Channels ────────────────────────────────────────────────────────────────
openclaw channels list                              # all channels
openclaw channels status [--probe]                  # channel health
openclaw channels add [--channel <platform>] [--token <tok>]
openclaw channels remove [--channel <platform>]
openclaw channels login / logout                    # interactive auth (WhatsApp QR, etc.)
openclaw pairing list <channel>                     # pending pairing requests
openclaw pairing approve <channel> <CODE>           # approve a sender

# ── Nodes ───────────────────────────────────────────────────────────────────
openclaw nodes list [--connected]                   # list paired nodes
openclaw nodes status [--node <id|name|ip>]         # node health
openclaw nodes describe --node <id>                 # capabilities + permissions
openclaw nodes approve <requestId>                  # approve a node
openclaw nodes invoke --node <id> --command <cmd>   # run structured command
openclaw nodes run --node <id> --raw <shell>        # run raw shell command
openclaw approvals get [--node <id>]                # view exec approvals
openclaw approvals allowlist add --node <id> "<cmd>"

# ── Browser ─────────────────────────────────────────────────────────────────
openclaw browser start / stop / status              # browser lifecycle
openclaw browser profiles                           # list available profiles
openclaw browser screenshot / snapshot              # capture
openclaw browser navigate <url>                     # navigate to URL

# ── ClawHub CLI ─────────────────────────────────────────────────────────────
npx clawhub install <slug>                          # install skill (one-off)
clawhub install <slug> [--version <ver>]            # install with pinned version
clawhub update <slug>                               # update one skill
clawhub update --all                                # update all skills
clawhub search "query"                              # search registry
clawhub list                                        # locally installed skills
clawhub whoami                                      # check auth status
clawhub login                                       # authenticate

# ── Memory ──────────────────────────────────────────────────────────────────
openclaw memory status                              # backend health
openclaw system heartbeat last                      # last heartbeat info
openclaw system event --text "<msg>" --mode now     # manual heartbeat trigger
```

---

## Key Config Paths (Quick Reference)

```bash
openclaw config set agents.defaults.model.primary anthropic/claude-opus-4-6
openclaw config set agents.defaults.heartbeat.every 30m
openclaw config set agents.defaults.compaction.mode safeguard
openclaw config set agents.defaults.compaction.reserveTokensFloor 32000
openclaw config set cron.sessionRetention 24h
openclaw config set cron.maxConcurrentRuns 1
openclaw config set session.maintenance.mode enforce
openclaw config set session.maintenance.maxDiskBytes 500mb
openclaw config set gateway.bind loopback
openclaw config set gateway.auth.token <your-token>
openclaw config set memory.backend builtin
```

---

## In-Chat Commands

```
/status                        context window fullness + session info
/context list                  injected files with sizes
/context detail                per-file token breakdown
/usage tokens                  show per-reply token usage
/compact [instructions]        manual compaction with optional focus
/new                           fresh session (no history carry-over)
/model list                    pick model interactively
/model <provider/model>        switch model (no restart)
/debug show                    runtime debug overrides (requires commands.debug: true)
/debug set / unset / reset     manage debug overrides
/reasoning on / off            toggle extended thinking
/approve <id> allow-once       approve exec request (from node tool)
/approve <id> allow-always
/approve <id> deny
```
