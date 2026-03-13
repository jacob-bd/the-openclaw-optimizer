# Changelog

All notable changes to the OpenClaw Optimizer skill are documented here.

## 1.20.0 — 2026-03-12

- **Aligned with OpenClaw v2026.3.11** (covers v2026.3.9 through v2026.3.11)
- GHSA-5wcw-8jjv-m286: WebSocket origin validation enforced for all browser-originated connections in trusted-proxy mode
- v2026.3.11 BREAKING: Cron jobs can no longer notify via ad hoc agent sends; run `openclaw doctor --fix` to migrate
- New providers: OpenCode Go (shares key with Zen)
- Memory search: `gemini-embedding-2-preview` with multimodal image/audio indexing and configurable output dimensions
- First-class Ollama onboarding via `openclaw onboard` (Local or Cloud+Local, curated model suggestions)
- ACP `sessions_spawn` supports `resumeSessionId` for runtime `"acp"` (resume existing conversations)
- Discord `autoArchiveDuration` for auto-created threads
- Improved failover: expired cooldown resets, Gemini MALFORMED_RESPONSE retryable, Poe/Venice 402 triggers fallback, HTTP 499 transient, billing recovery probe for single-provider cooldowns
- New env var: `OPENCLAW_CLI` auto-set in child commands
- 20+ bug fixes: session reset metadata cleanup, context pruning for image-only results, Kimi Coding native Anthropic tools, Discord reply chunking, Telegram delivery fixes, macOS LaunchAgent fixes
- Updated all 4 reference files to v2026.3.11

## 1.19.0 — 2026-03-09

- **Aligned with OpenClaw v2026.3.8** (covers v2026.3.1 through v2026.3.8)
- v2026.3.8: `openclaw backup create/verify` commands, ACP provenance control, cron restart staggering
- v2026.3.8: GPT-5.4 via Codex (1,050,000-token context, 128K max tokens)
- v2026.3.8: `OPENCLAW_THEME`, `browser.relayBindHost`, `talk.silenceTimeoutMs`, Brave LLM Context search
- v2026.3.8: Security hardening (skill download validation, SSRF redirect hop blocking, MS Teams auth)
- v2026.3.8: macOS launchd restart fix, gateway config restart guard, Podman SELinux auto-detection
- Provider ban warnings: Google (AntiGravity + Gemini CLI), Anthropic (Claude Code tokens); Claude Code via ACP is OK
- Community insights: single-agent-with-skills pattern, heartbeat cost optimization, bootstrap tier loading
- Expanded provider table: 40+ providers (added Kimi Coding, Together AI, Cerebras, Hugging Face, MiniMax VL-01)
- New optimization levers: light bootstrap, adaptive thinking, session pruning, cheaper compaction model, backup commands
- New in-chat commands: /steer, /kill, /usage cost, /export-session, /session idle, /session max-age, /check-updates
- New env vars: OPENCLAW_THEME (v2026.3.8), OPENCLAW_LOG_LEVEL, OPENCLAW_DIAGNOSTICS, OPENCLAW_SHELL
- New troubleshooting entries: config file wipe (#40410), silent tool failure (#40069), compaction freeze (#38233), Ollama stuck typing (#40434)
- CVE-2026-25253 (ClawJacked) security reference with mitigation guidance
- Updated all 4 reference files to v2026.3.8

## 1.18.0 — 2026-03-09

- **Aligned with OpenClaw v2026.3.7** (covers v2026.3.1, v2026.3.2, v2026.3.7)
- New providers: Google Gemini 3.1 Flash-Lite, MiniMax-VL-01, OpenAI gpt-5.4 default alias
- Updated defaults: Venice → kimi-k2-5, MiniMax → M2.5-highspeed (M2.5-Lightning removed)
- Ollama memory embeddings (`memorySearch.provider = "ollama"`)
- ContextEngine plugin interface: `plugins.slots.contextEngine` and `lossless-claw` docs
- Compaction model override, `recentTurnsPreserve`, `postCompactionSections` config keys
- Bootstrap truncation warning: `bootstrapPromptTruncationWarning` config
- Light bootstrap: `lightContext` for heartbeat and `--light-context` for cron
- Cron defer-while-active: `cron.deferWhileActive.quietMs` skips main-session jobs when user is active
- Adaptive thinking for Claude 4.6 (default `adaptive` level)
- PDF tool config keys: `pdfModel`, `pdfMaxBytesMb`, `pdfMaxPages`
- Sub-agent inline file attachments: `tools.sessions_spawn.attachments`
- Breaking: `gateway.auth.mode` required when both token and password are set (v2026.3.7)
- Breaking: `tools.profile` defaults to `messaging` for new installs (v2026.3.2)
- Breaking: ACP dispatch defaults to enabled (v2026.3.2)
- ClawJacked CVE-2026-25253 security reference
- 10+ new known bugs: #40069, #38233, #40433, #32533, #39611, #40410, #40434 and more
- New CLI: `config file`, `config validate`, `gateway run --log-level`, `--password-file`
- New in-chat: `/session idle`, `/session max-age`, `/usage cost`, `/export-session`, `/steer`, `/kill`
- New env vars: `OPENCLAW_LOG_LEVEL`, `OPENCLAW_DIAGNOSTICS`, `OPENCLAW_SHELL`
- Container health endpoints: `/health`, `/healthz`, `/ready`, `/readyz`
- Config fail-closed behavior (no more silent fallback to permissive defaults)
- Node.js v22.12+ enforced
- Updated all 4 reference files to v2026.3.7

## 1.16.0 — 2026-02-28

- **Directory-based system profiles**: Split monolith profiles into topic files with on-demand loading
- New profile format: `INDEX.md` (~1K tokens) loads at session start; `topology.md`, `providers.md`, `routing.md`, `channels.md`, `cron.md`, `lessons.md`, and `issues/YYYY-MM.md` load only when needed
- 90%+ reduction in session-start context cost for mature deployments
- Legacy single-file format fully supported (backwards compatible)
- Issue lifecycle: monthly issue files, 14-day archive compression, permanent lessons
- Updated TEMPLATE.md with directory-based structure and templates for all topic files
- Session workflow updated: directory-first detection with single-file fallback
- On-demand loading guidance: which file to read for each type of task

## 1.9.0 — 2026-02-25

- **Agent Identity Optimizer** (Section 13): 36-check audit for SOUL.md, IDENTITY.md, AGENTS.md, USER.md and supporting bootstrap files
- Detects conflicts, overlaps, bloat, misplaced content, best practice violations, and USER.md completeness gaps
- Interactive issue-by-issue walkthrough with diffs and dated backups
- New reference file: `references/identity-optimizer.md`

## 1.8.0 — 2026-02-25

- OpenAI Codex OAuth provider documentation
- Cron model override added to mandatory system assessment checklist

## 1.7.0 — 2026-02-25

- Aligned with OpenClaw v2026.2.24
- Provider removal checklist (6-location cleanup)
- Gemini CLI OAuth crackdown warning
- `launchctl setenv` persistence docs

## 1.6.0 — 2026-02-25

- Centralized system profiles (`~/.openclaw-optimizer/systems/`)
- First-run bootstrap flow
- Mandatory system assessment checklist
- Event loop overload diagnosis (Section 10b)
- Delivery queue and stale node fixes
- Cron `edit` CLI docs
- Dated backup rule

## 1.5.0 — 2026-02-24

- System profiles for persistent deployment knowledge
- Continuous improvement workflow
- Version tracking

## 1.4.0 — 2026-02-25

- Remote Ollama macOS fix (Section 10a)
- Ollama model trimming

## 1.3.0 — 2026-02-25

- Skill versioning
- Safe `launchctl` gateway restart

## 1.2.0 — 2026-02-25

- System learning mechanism
- Deployment profiles with topology types

## 1.1.0 — 2026-02-25

- Skills filesystem path fix
- KiloCode provider setup

## 1.0.0 — 2026-02-24

- Initial release aligned with OpenClaw v2026.2.23
