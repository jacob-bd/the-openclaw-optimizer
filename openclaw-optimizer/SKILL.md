---
name: openclaw-optimizer
slug: openclaw-optimizer
version: 2026.3.8
description: |
  Use when: you want to optimize an OpenClaw setup (v2026.2.23+) — cost reduction, model routing,
  provider configuration, context management, cron automation, sub-agent architecture, skills,
  or agent personality/identity optimization (SOUL.md, IDENTITY.md, AGENTS.md, USER.md audit).
  Also use when troubleshooting any OpenClaw error, startup failure, channel issue, or provider problem.
  CLI-first. Advisory by default — audit first, propose exact changes, apply only on approval.
  Output: prioritized plan + exact CLI commands + config patches + rollback.
triggers:
  - optimize agent
  - optimizing agent
  - improve OpenClaw setup
  - agent best practices
  - OpenClaw optimization
  - model routing
  - add provider
  - configure provider
  - custom provider
  - cron job
  - context bloat
  - reduce costs
  - sub-agent
  - skills openclaw
  - troubleshoot
  - not working
  - error
  - gateway
  - no response
  - channel not working
  - personality audit
  - identity audit
  - bootstrap audit
  - agent personality
  - agent identity
  - optimize personality
  - SOUL.md
  - IDENTITY.md
  - USER.md
metadata:
  openclaw:
    emoji: "🧰"
---

# OpenClaw Optimizer

**Aligned with: OpenClaw v2026.3.8** | Skill v1.19.0 | Updated: 2026-03-09 | CLI-first advisor

Optimize and troubleshoot OpenClaw workspaces: cost-aware routing, provider configuration, context discipline, lean automation, multi-agent architectures, and error resolution.

**Reference files (load when needed):**
- `references/providers.md` — all 40+ providers, custom provider schema, failover config
- `references/troubleshooting.md` — full error reference, 7 failure categories, GitHub issue workarounds
- `references/cli-reference.md` — complete CLI command reference
- `references/identity-optimizer.md` — agent identity/personality audit checklist, file roles, walkthrough workflow

---

## Version Awareness

This skill tracks OpenClaw releases via two mechanisms:

1. **GitHub Actions** — daily workflow checks for new releases, opens an issue on drift, auto-closes when resolved
2. **Runtime check** — lightweight cached version comparison at session start

### Runtime Check (once per session)

```bash
python3 ~/.claude/skills/openclaw-optimizer/scripts/version-check.py --status
```

- **`CURRENT`** → note the version and proceed.
- **`STALE`** → inform the user: "OpenClaw v`<new>` is available (skill is at v`<current>`). Run `update-skill.sh` to review what changed."
- **`UNCHECKED`** → note "Version check unavailable (offline)" and proceed.

### Update Workflow (user-initiated, never automatic)

```bash
# Show drift report, changelog, and affected sections
bash ~/.claude/skills/openclaw-optimizer/scripts/update-skill.sh

# After updating content in SKILL.md and references/:
bash ~/.claude/skills/openclaw-optimizer/scripts/update-skill.sh --apply    # bump versions
bash ~/.claude/skills/openclaw-optimizer/scripts/update-skill.sh --commit   # bump + commit + push
```

Updates are deliberate — this skill never auto-modifies its own content or pushes to git without explicit user action.

---

## Quick Start (copy/paste prompts)

**Full audit (safe, no changes):**
> Audit my OpenClaw setup for cost, reliability, and context bloat. Prioritized plan with rollback. Do NOT apply changes.

**Troubleshoot a specific problem:**
> [Describe your symptom or paste the error message]. Diagnose it and give me the exact fix.

**Add or configure a provider:**
> Add [provider name] as a model provider. Walk me through the CLI steps and show me the exact config before applying.

**Model routing optimization:**
> Propose a tiered routing plan: cheap for heartbeats/cron, mid for daily tasks, premium for coding/reasoning. Exact config + rollback. Do NOT apply.

**Silent cron job:**
> Create a cron job that runs [task] every [interval]. Isolated session, NO_REPLY on nothing-to-do. Show me the command first.

**Audit agent personality & identity:**
> Audit my agent's personality and identity files. Check for conflicts, bloat, and bad practices. Walk me through improvements.

---

## Safety Contract (non-negotiable)

- This skill is **advisory by default** — not an autonomous control-plane.
- **Never** mutate config (`config.apply`, `config.patch`), cron jobs, or persistent settings without explicit user approval.
- Before any approved change: show (1) exact CLI command or config patch, (2) expected impact, (3) rollback command.
- If an optimization reduces monitoring coverage, present Options A/B/C and require the user to choose.

---

## Backup Strategy

Four backup layers exist — don't stack manual backups on top unnecessarily:

| Layer | What | Retention | When It's Enough |
|---|---|---|---|
| **CLI rolling `.bak`** | Auto-created on every `config set`, `models set`, `cron edit` | Rolling (overwritten each write) | Single-command undo |
| **Nightly GitHub backup** | Full config committed by cron job (3 AM) | Git history (unlimited) | Any rollback to a previous day's state |
| **`openclaw backup create`** | Local state archive with manifest verification (v2026.3.8+) | Until manually deleted | Pre-upgrade safety net; use `openclaw backup verify` to validate |
| **Manual dated backup** | `cp <file> <file>.YYYY-MM-DD-<reason>` | Until next nightly covers it, then delete | Major upgrades, multi-file restructuring, direct JSON edits |

**Rule:** For routine CLI changes (model swaps, cron edits, config sets), do NOT create manual backups. The CLI `.bak` + nightly GitHub backup are sufficient. Only create a manual backup when: (1) upgrading OpenClaw versions, (2) editing multiple config files simultaneously (identity audits), or (3) editing JSON directly without the CLI. For upgrades, prefer `openclaw backup create` over manual copies.

---

## 1. Model Providers

40+ providers supported. For full docs (auth commands, config schemas, all model names, custom provider setup): **read `references/providers.md`**

**Quick lookup — slug, auth env, primary model format:**

| Provider | Slug | Auth Env | Model Format |
|---|---|---|---|
| Anthropic | `anthropic` | `ANTHROPIC_API_KEY` | `anthropic/claude-opus-4-6` |
| OpenAI (API key) | `openai` | `OPENAI_API_KEY` | `openai/gpt-5.4` |
| **OpenAI Codex (subscription)** | `openai-codex` | **ChatGPT OAuth** | `openai-codex/gpt-5.4` |
| Google Gemini | `google` | `GEMINI_API_KEY` | `google/gemini-3.1-pro-preview` |

> **WARNING — Provider Bans (Mar 2026):**
>
> **Google:** Actively cracking down on Gemini CLI OAuth and AntiGravity access through third-party tools. Accounts are being banned or rate-limited without warning or refunds. Use API key auth (`google` provider) instead of OAuth (`google-gemini-cli` / `google-antigravity`). Production API keys: 150-300 RPM, no ban risk. See GitHub Issue #14203.
>
> **Anthropic:** Has banned users linking flat-rate Claude Code subscription tokens to OpenClaw. Using Claude Code OAuth tokens directly in OpenClaw may trigger account suspension. However, using Claude Code through the **Agent SDK / ACP dispatch** (where OpenClaw spawns Claude Code as a sub-agent via the ACP protocol) is the supported pattern and should not cause issues — this is how OpenClaw's built-in `acp` integration works.
>
> **General:** Always prefer pay-per-token API keys over subscription OAuth for third-party tool integrations. Subscription-based OAuth through third-party tools violates most providers' ToS except OpenAI, which explicitly permits Codex OAuth in third-party tools.

| Mistral | `mistral` | `MISTRAL_API_KEY` | `mistral/mistral-large-latest` |
| Groq | `groq` | `GROQ_API_KEY` | `groq/<model-id>` |
| xAI | `xai` | `XAI_API_KEY` | `xai/grok-code-fast-1` |
| OpenRouter | `openrouter` | `OPENROUTER_API_KEY` | `openrouter/anthropic/claude-sonnet-4-5` |
| Bedrock | `amazon-bedrock` | AWS env chain | `amazon-bedrock/us.anthropic.claude-opus-4-6-v1:0` |
| **Kilo Gateway** | `kilocode` | `KILOCODE_API_KEY` | `kilocode/anthropic/claude-opus-4.6` |
| Moonshot/Kimi | `moonshot` | `MOONSHOT_API_KEY` | `moonshot/kimi-k2.5` |
| Kimi Coding | `kimi-coding` | `KIMI_API_KEY` | `kimi-coding/k2p5` |
| Z.AI / GLM | `zai` | `ZAI_API_KEY` | `zai/glm-5` |
| MiniMax | `minimax` | `MINIMAX_API_KEY` | `minimax/MiniMax-M2.5-highspeed` |
| MiniMax VL-01 | `minimax-portal` | `MINIMAX_API_KEY` | `minimax-portal/MiniMax-VL-01` |
| Venice AI | `venice` | `VENICE_API_KEY` | `venice/kimi-k2-5` |
| Hugging Face | `huggingface` | `HF_TOKEN` | `huggingface/deepseek-ai/DeepSeek-R1` |
| Synthetic | `synthetic` | `SYNTHETIC_API_KEY` | `synthetic/hf:MiniMaxAI/MiniMax-M2.1` |
| Together AI | `together` | `TOGETHER_API_KEY` | `together/moonshotai/Kimi-K2.5` |
| Cerebras | `cerebras` | `CEREBRAS_API_KEY` | `cerebras/zai-glm-4.7` |
| Ollama (local) | `ollama` | `OLLAMA_API_KEY` (any) | `ollama/llama3.3` |
| vLLM (local) | `vllm` | `VLLM_API_KEY` (any) | `vllm/<model-id>` |

**Add a provider (API key):**
```bash
openclaw onboard --auth-choice <provider>-api-key
openclaw models auth login --provider <slug>
openclaw models set <provider/model>
```

**Add a provider (OAuth / subscription):**
```bash
openclaw onboard --auth-choice openai-codex    # ChatGPT subscription
openclaw models auth login --provider openai-codex
openclaw models set openai-codex/gpt-5.4
```

### OAuth Providers (Subscription-Based Access)

Some providers offer OAuth authentication tied to a consumer subscription (e.g., ChatGPT Plus/Pro) instead of — or in addition to — a pay-per-token API key. OpenClaw supports these via device-flow OAuth.

**Currently supported OAuth providers:**

| Provider | Slug | Subscription Required | Top Models |
|---|---|---|---|
| **OpenAI Codex** | `openai-codex` | ChatGPT Plus ($20/mo) or Pro ($200/mo) | `gpt-5.4`, `gpt-5.3-codex`, `codex-mini-latest` |
| GitHub Copilot | `github-copilot` | Copilot subscription | `github-copilot/gpt-4o` |

**OpenAI Codex setup (full walkthrough):**

```bash
# 1. Authenticate (opens browser for ChatGPT sign-in)
openclaw models auth login --provider openai-codex
# → Prints a URL. Open it in a browser, sign in to ChatGPT, paste redirect URL back.

# 3. Verify auth
openclaw models status --probe --probe-provider openai-codex

# 4. Set as primary OR add to fallback chain
openclaw models set openai-codex/gpt-5.4                # as primary
openclaw models fallbacks add openai-codex/gpt-5.4      # or as fallback

# 5. Restart gateway
launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway  # macOS LaunchAgent
```

**Headless / SSH gateway:** The OAuth flow prints a URL. Open it in any browser (doesn't need to be on the gateway machine), complete sign-in, then paste the redirect URL back into the SSH terminal. Alternatively, complete OAuth on a machine with a browser and copy `~/.openclaw/credentials/oauth.json` to the gateway.

**Available Codex models:**

| Model | Plan | Notes |
|---|---|---|
| `openai-codex/gpt-5.4` | Plus, Pro, Business | Latest (Mar 2026), 1,050,000-token context, 128K max tokens |
| `openai-codex/gpt-5.3-codex` | Plus, Pro, Business | Previous flagship, most capable coding model |
| `openai-codex/gpt-5.3-codex-spark` | **Pro only** | Research preview, low-latency |
| `openai-codex/gpt-5.2-codex` | Plus, Pro | Previous gen, stable |
| `openai-codex/codex-mini-latest` | Plus, Pro | Lightweight, fast, cheapest |

**Usage limits (per 5-hour window):**
- **Plus ($20/mo):** 30–150 messages
- **Pro ($200/mo):** 300–1,500 messages
- Extra credits purchasable when limits are hit

**Gotchas:**
- **No embeddings.** Codex OAuth does NOT grant access to OpenAI embeddings. You still need a separate `OPENAI_API_KEY` for `text-embedding-3-small` etc.
- **Token refresh is automatic** — active sessions continue without re-login. Credentials stored in `~/.openclaw/credentials/oauth.json`.
- **Don't use both Codex CLI and OpenClaw simultaneously** — some providers invalidate older refresh tokens when a new one is issued. Logging in via one tool can log you out of the other.
- **"Model not supported" errors** — some users report this with `gpt-5.3-codex` on certain accounts. Fall back to `gpt-5.2-codex` if this happens.
- **Dual-config registration required (Issue #13189):** The built-in catalog uses wrong API type (`openai-completions`) for gpt-5.3-codex. Must register manually in **both** `models.json` (API type: `openai-codex-responses`) **AND** `openclaw.json` (API type: `openai-responses` — `openai-codex-responses` is only valid in models.json per schema). v2026.2.26 includes a schema fix — verify with `openclaw models status --probe` after upgrade.
- **Community context (Feb 2026):** After Anthropic and Google updated their ToS to block subscription-based OAuth in third-party tools, the OpenClaw community migrated heavily to `openai-codex`. OpenAI explicitly permits Codex OAuth in third-party tools, though fair-use limits still apply.

### Provider Removal Checklist

Removing a provider requires cleaning **6 locations** — `config unset` alone is not enough:

1. `models.providers.<slug>` in openclaw.json — `openclaw config unset models.providers.<slug>`
2. `auth.profiles.<slug>:*` in openclaw.json — must edit JSON directly (colons in keys break `config unset`)
3. `profiles` dict in `~/.openclaw/agents/main/agent/auth-profiles.json` — edit with python3/jq
4. `agents.defaults.models.<provider/model>` aliases in openclaw.json — `openclaw config unset` each alias
5. `plugins.entries.<slug>-auth` in openclaw.json — `openclaw config unset plugins.entries.<slug>-auth`
6. `lastGood.<slug>` and `usageStats.<slug>:*` in auth-profiles.json — edit directly

For providers with LaunchAgent env vars (Ollama, etc.), also clean:
7. `launchctl unsetenv <KEY>` — session-level env persists independently of plist
8. PlistBuddy delete from `~/Library/LaunchAgents/ai.openclaw.gateway.plist`
9. `launchctl bootout` + `launchctl bootstrap` to pick up the clean plist (kickstart alone doesn't reload env from plist)

**Known CLI limitation:** `openclaw config unset` cannot handle colons in config keys (e.g., `auth.profiles.google-gemini-cli:email@gmail.com`). The parser treats colons as path separators. Edit the JSON file directly for these entries.

**Ollama for memory embeddings (v2026.3.2+):**
```bash
openclaw config set memorySearch.provider ollama
openclaw config set memorySearch.fallback ollama
```
Runs memory search embeddings locally — no external API calls. Honors `models.providers.ollama` settings.

**Custom OpenAI-compatible provider (LM Studio, LiteLLM, etc.):** See `references/providers.md`

---

## 2. Model Routing Strategy

### Tiered Routing (50–95% cost reduction)

| Tier | Models | Use Cases |
|---|---|---|
| **T1 Cheap** | `zai/glm-5`, `google/gemini-3-flash-preview`, `google/gemini-3.1-flash-lite-preview`, `synthetic/hf:deepseek-ai/DeepSeek-V3.2` | Heartbeats, simple checks, greetings, cron |
| **T2 Mid** | `moonshot/kimi-k2.5`, `minimax/MiniMax-M2.5-highspeed` | Daily chat, Q&A, calendar, scheduling |
| **T3 Smart** | `anthropic/claude-sonnet-4-5`, `openai/gpt-5.4`, `openai-codex/gpt-5.4` (subscription) | Code, refactors, research |
| **T4 Premium** | `anthropic/claude-opus-4-6`, `openai/gpt-5.2` | Complex reasoning, orchestration |

**Model preference by task:**

| Task | Model | Why |
|---|---|---|
| Heartbeats / cron | `zai/glm-5` | Cheapest; reliable structured output |
| Calendar / scheduling | `moonshot/kimi-k2.5` | Community #1 for date/time reasoning |
| Coding / refactoring | `anthropic/claude-sonnet-4-5` or `openai-codex/gpt-5.4` | Sonnet: community #1 for code quality; Codex: flat-rate via subscription |
| Agent orchestration | `anthropic/claude-opus-4-6` | Best multi-step reasoning |
| Long-context tasks | `google/gemini-3-flash-preview` or `openai-codex/gpt-5.4` | Gemini: 1M token window; Codex 5.4: 1.05M tokens |
| Subscription-capped coding | `openai-codex/gpt-5.4` | Fixed cost via ChatGPT Plus/Pro; no per-token billing |
| Privacy-sensitive | `venice/kimi-k2-5` or Ollama | Never logged/stored |
| Ultra-cheap batch | `google/gemini-3.1-flash-lite-preview` | Minimal cost; good for lightweight cron/heartbeat |

**Key rules:**
- Never switch models mid-conversation — destroys Anthropic prompt cache
- Use `anthropic` direct (not through proxies) to preserve caching for Opus/Sonnet
- Switch only at session boundaries (`/new`)

### Built-in Model Aliases (v2026.3.7+)

| Alias | Resolves To |
|---|---|
| `opus` | `anthropic/claude-opus-4-6` |
| `sonnet` | `anthropic/claude-sonnet-4-6` |
| `gpt` | `openai/gpt-5.4` |
| `gpt-mini` | `openai/gpt-5-mini` |
| `gemini` | `google/gemini-3.1-pro-preview` |
| `gemini-flash` | `google/gemini-3-flash-preview` |
| `gemini-flash-lite` | `google/gemini-3.1-flash-lite-preview` |

### Thinking Levels (v2026.3.1+)

| Level | Behavior | Best For |
|---|---|---|
| `off` | No extended thinking | Simple queries, heartbeats |
| `minimal` | Light reasoning (~1.1s) | Routine tasks; community tip: set as default to halve latency |
| `low` | Standard reasoning | Default for non-Claude-4.6 reasoning models |
| `medium` / `high` | Deeper reasoning | Complex tasks |
| `xhigh` | "Ultrathink+" | GPT-5.2 + Codex models only |
| `adaptive` | Provider-managed | **Default for Claude 4.6** — auto-scales reasoning to task complexity |

```bash
openclaw config set agents.defaults.thinkingDefault adaptive    # recommended for Claude 4.6
openclaw config set agents.defaults.thinkingDefault minimal     # cost-saver for routine workloads
```

In-chat: `/think low` · `/think adaptive` · `/think off`

### Per-Agent Config

```bash
openclaw models set anthropic/claude-opus-4-6           # set global primary
openclaw config set agents.defaults.model.primary anthropic/claude-opus-4-6
openclaw models fallbacks add openrouter/anthropic/claude-sonnet-4-5
```

```json5
{
  agents: {
    list: [
      { id: "main", model: "anthropic/claude-opus-4-6", heartbeat: { every: "30m" } },
      { id: "ops",  model: { primary: "anthropic/claude-sonnet-4-5", fallbacks: ["zai/glm-5"] },
        tools: { profile: "minimal" } },
    ],
    defaults: {
      model: { primary: "anthropic/claude-opus-4-6", fallbacks: ["minimax/MiniMax-M2.5-highspeed"] },
      thinkingDefault: "adaptive",
      timeoutSeconds: 600,
      contextTokens: 200000,
      maxConcurrent: 3,
      params: { cacheRetention: "long" },
    },
  },
}
```

**In-chat model switch (no restart):** `/model list` → `/model anthropic/claude-sonnet-4-5`

### Session Pruning (v2026.3.1+)

Automatically trims stale tool results from conversation history to preserve cache and reclaim context:

```json5
{
  agents: { defaults: { contextPruning: {
    mode: "cache-ttl",        // "off" (default) | "cache-ttl"
    ttl: "5m",
    keepLastAssistants: 3,
    softTrim: { maxChars: 4000, headChars: 1500, tailChars: 1500 },
    hardClear: { enabled: true },
  } } },
}
```

Anthropic smart defaults auto-enable `cache-ttl` pruning when using API key auth with heartbeat enabled.

---

## 3. Context Management

**What burns tokens:** System prompt (5–10K tokens/call) + bootstrap files + conversation history. Bootstrap files injected on every turn (source: `docs.openclaw.ai/concepts/system-prompt`): `AGENTS.md`, `SOUL.md`, `TOOLS.md`, `IDENTITY.md`, `USER.md`, `HEARTBEAT.md`, `BOOTSTRAP.md` (first-run only), plus `MEMORY.md` and/or `memory.md` **when present**. Daily `memory/*.md` files are NOT auto-injected (on-demand via memory tools). Bootstrap cap: 150K chars total, 20K per file (both configurable).

> **MEMORY.md warning (from docs):** *"Keep them concise — especially MEMORY.md, which can grow over time and lead to unexpectedly high context usage and more frequent compaction."* MEMORY.md is the most common source of bootstrap bloat. Unlike AGENTS.md or SOUL.md which users actively edit, MEMORY.md tends to grow unchecked as the agent appends to it.

**Check context:** `/status` · `/context list` · `/context detail` · `/usage tokens` · `/usage cost`

### Prompt Modes

| Mode | Bootstrap Files Loaded | Use Case |
|---|---|---|
| `full` (default) | All — AGENTS, SOUL, TOOLS, IDENTITY, USER, HEARTBEAT, MEMORY | Main interactive sessions |
| `minimal` (sub-agents) | AGENTS.md + TOOLS.md only | Sub-agent spawns — no SOUL, IDENTITY, USER, HEARTBEAT, MEMORY |
| `none` | Base identity line only | Bare-minimum sessions |

### Light Bootstrap (v2026.3.1+)

Skip all workspace bootstrap files for automated runs:

```bash
openclaw cron add --light-context --cron "*/30 * * * *" --message "Quick check"
```

```json5
{
  agents: { defaults: { heartbeat: {
    lightContext: true,     // only loads HEARTBEAT.md, skips all other bootstrap files
  } } },
}
```

Massive token savings for heartbeats and cron — eliminates 5-10K tokens/call of bootstrap overhead.

### Bootstrap Truncation Warning (v2026.3.7+)

```bash
openclaw config set agents.defaults.bootstrapPromptTruncationWarning once   # off | once | always
```

When a bootstrap file exceeds `bootstrapMaxChars` (default 20K), the agent receives a warning. Set to `always` during identity audits to catch truncated files.

### Compaction Config

```bash
# Manual: /compact [focus instructions]
# Auto: triggers near context limit — count visible in /status

openclaw config set agents.defaults.compaction.mode safeguard
openclaw config set agents.defaults.compaction.reserveTokensFloor 32000
openclaw config set agents.defaults.contextTokens 100000
openclaw config set agents.defaults.compaction.model google/gemini-3-flash-preview   # cheaper compaction (v2026.3.7+)
openclaw config set agents.defaults.compaction.recentTurnsPreserve 4                 # quality-guard (v2026.3.7+)
```

```json5
{
  agents: { defaults: { compaction: {
    mode: "safeguard",
    model: "google/gemini-3-flash-preview",    // route compaction through a cheaper model
    reserveTokensFloor: 32000,
    recentTurnsPreserve: 4,                    // keep last N turns intact during compaction
    postCompactionSections: ["Session Startup", "Red Lines"],  // AGENTS.md sections re-injected after compaction
    memoryFlush: {
      enabled: true,
      prompt: "Write lasting notes to memory/YYYY-MM-DD.md; reply NO_REPLY if nothing to store.",
    },
  }, contextTokens: 100000 } },
}
```

**Known bug — memory flush threshold gap (Issue #25880):** Set `reserveTokensFloor` equal to `reserveTokens` (both `62500`) to fix compaction firing before flush completes.

**Known bug — compaction timeout (Issue #38233):** Both `/compact` and auto compaction can timeout at ~300s with `openai-codex/gpt-5.3-codex`, freezing the session. Fix: override compaction model to `google/gemini-3-flash-preview` with `thinking: "off"`. Tune: `maxHistoryShare: 0.6`, `reserveTokensFloor: 40000`, `maxAttempts: 3`.

### Context Engine Plugin (v2026.3.7+)

Replace the built-in context assembly pipeline with a custom plugin:

```json5
{
  plugins: { slots: { contextEngine: "lossless-claw" } },   // default: "legacy" (built-in)
}
```

Context Engine plugins get full lifecycle hooks: `bootstrap`, `ingest`, `assemble`, `compact`, `afterTurn`, `prepareSubagentSpawn`, `onSubagentEnded`. This enables alternative context management strategies (lossless context, semantic chunking, etc.) without modifying OpenClaw core.

### Bootstrap File Size Targets (optimization recommendations)

These are optimization targets for keeping context lean, not hard limits. All files are subject to `bootstrapMaxChars` (default 20K) and `bootstrapTotalMaxChars` (default 150K).

| File | Target Size | Purpose | Injected? |
|---|---|---|---|
| `SOUL.md` | < 1K tokens (~4K chars) | Personality + absolute constraints | Always (main + full prompt mode) |
| `AGENTS.md` | < 2K tokens (~8K chars) | Workflows, rules, operating procedures | Always (main + sub-agents) |
| `TOOLS.md` | < 2K tokens (~8K chars) | Tool-specific notes, local conventions | Always (main + sub-agents) |
| `IDENTITY.md` | < 500 tokens (~2K chars) | Name, vibe, emoji, presentation | Always (main only) |
| `USER.md` | < 1K tokens (~4K chars) | User profile, preferences, context | Always (main only) |
| `HEARTBEAT.md` | < 200 tokens (~800 chars) | Heartbeat checklist (keep minimal) | Always (main only); skipped with `lightContext` |
| `MEMORY.md` | < 5K tokens (~20K chars) | **Curated long-term facts ONLY** | **Always in main sessions (auto-injected when present)** |

**Critical:** MEMORY.md is auto-injected on every turn in main sessions, NOT loaded on-demand. It burns tokens continuously. Keep it as small as possible with only curated facts. Operational protocols belong in AGENTS.md. Tool notes belong in TOOLS.md.

### Bootstrap Content Placement (What Goes Where)

Users commonly dump all content into SOUL.md because it feels like "who the agent is." This bloats the file (burns tokens every turn) and confuses lighter models that can't prioritize across a noisy instruction set. Place content in the correct file:

| Content Type | Correct File | Common Mistake |
|---|---|---|
| Personality, voice, humor, constraints | SOUL.md | - |
| Protocols, workflows, checklists, operational rules | AGENTS.md | Dumping in SOUL.md |
| User bio, preferences, working hours, communication style | USER.md | Duplicating in SOUL.md |
| Tool configs, API templates, channel IDs, env vars | TOOLS.md | Scattering in AGENTS.md |
| Curated long-term facts (lean) | MEMORY.md | Growing unchecked |
| Proactivity rules, initiative behavior | AGENTS.md | Putting in SOUL.md |

**Cross-file duplication burns tokens silently.** If the same protocol appears in both SOUL.md and AGENTS.md, it's injected twice on every turn. Deduplicate aggressively — pick one canonical location.

**Stale model references are silent saboteurs.** When you change models via CLI (`openclaw models set`), update any AGENTS.md sections that reference specific model names (e.g., Model Selection, Sub-Agent defaults). The agent follows bootstrap instructions and may try to use models that are no longer configured.

**Persistence stack:** `SOUL.md` → `AGENTS.md` → `TOOLS.md` → `IDENTITY.md` → `USER.md` → `MEMORY.md` (all auto-injected in main sessions) → `memory/YYYY-MM-DD.md` (on-demand via memory tools) → `conversation-state.md` → `ACTIVE-TASK.md`

### Session Maintenance

```bash
openclaw config set session.maintenance.mode enforce
openclaw config set session.maintenance.maxDiskBytes 500mb
openclaw sessions cleanup --dry-run      # preview
openclaw sessions cleanup --enforce     # apply
openclaw sessions cleanup --fix-missing # prune store entries whose transcript files are missing (v2026.2.26+)
```

---

## 4. Cron & Automation

### Cron Job Schema (key fields)

```json
{
  "jobId": "daily-brief", "name": "Morning Briefing", "enabled": true,
  "agentId": "main",
  "schedule": { "kind": "cron", "expr": "0 8 * * *", "tz": "America/New_York" },
  "sessionTarget": "isolated",
  "payload": { "kind": "agentTurn", "message": "Morning briefing.", "model": "anthropic/claude-sonnet-4-5", "timeoutSeconds": 300 },
  "delivery": { "mode": "announce", "channel": "telegram", "to": "<user-id>" },
  "lightContext": true
}
```

**sessionTarget:** `"isolated"` (recommended — fresh session) | `"main"` (injects as systemEvent)
**payload.kind:** `"agentTurn"` (isolated) | `"systemEvent"` (main session)
**delivery.mode:** `"announce"` | `"webhook"` | `"none"`
**lightContext:** `true` skips all workspace bootstrap files — massive token savings for automated runs (v2026.3.1+)

### CLI

```bash
openclaw cron add --cron "0 9 * * *" --message "Daily report" --agent main --announce --channel slack --to "channel:CXXX"
openclaw cron add --cron "0 9 * * *" --message "Quick check" --light-context   # skip bootstrap files
openclaw cron add --at "2026-03-01T08:00:00" --message "One-time task" --keep-after-run
openclaw cron add --cron "0 9 * * *" --exact                                   # no stagger jitter
openclaw cron run <job-id>          # test immediately (--force bypasses not-due)
openclaw cron list / status / runs
openclaw cron edit <job-id> [flags] # patch fields: --cron, --message, --model, --name, --tz, etc.
openclaw cron enable/disable <job-id>
openclaw cron rm <job-id>
openclaw config set cron.sessionRetention 24h
openclaw config set cron.maxConcurrentRuns 1   # circuit breaker
```

### Cron Defer-While-Active (v2026.3.7+)

Skip main-session cron jobs when the user is actively chatting:

```bash
openclaw config set cron.deferWhileActive.quietMs 300000   # defer if user active within last 5 minutes
```

Prevents cron jobs from interrupting active conversations. Only affects `sessionTarget: "main"` jobs; isolated jobs always run.

### Cron Restart Staggering (v2026.3.8+)

On gateway startup, missed cron jobs are staggered to prevent gateway starvation. Top-of-hour cron expressions get up to 5 minutes of deterministic stagger. Use `--exact` or `schedule.staggerMs: 0` to disable.

### Silent Patterns

**`NO_REPLY`** — agent outputs this literal string when nothing to report; system suppresses delivery entirely.
**`HEARTBEAT_OK`** — heartbeat token; reply ≤300 chars after stripping it → silently dropped.

```json5
{
  agents: { defaults: { heartbeat: {
    every: "30m",
    target: "last",
    ackMaxChars: 300,
    directPolicy: "allow",
    lightContext: false,        // set true to skip bootstrap files (v2026.3.1+)
    activeHours: { start: "08:00", end: "22:00", timezone: "America/New_York" },
  } } },
}
```

> **v2026.2.25 BREAKING:** The heartbeat DM toggle was replaced with `directPolicy`. Default is now `allow`. If you had DMs blocked in v2026.2.24, explicitly set `agents.defaults.heartbeat.directPolicy: "block"` (or per-agent via `agents.list[].heartbeat.directPolicy`).

**Cost trap:** 5-minute heartbeat loading full MEMORY.md = ~2.9M tokens/day. Keep heartbeat context minimal — use `lightContext: true` or extend intervals.

**Redundant cron jobs:** The built-in `openclaw memory` indexes sessions natively. Custom session archiver cron jobs that convert `.jsonl` to markdown for a separate RAG database are likely redundant. Check whether any cron job feeds a custom system that duplicates built-in functionality before assuming it's needed.

**Known bugs:** Cron current-day skip (Issue #25902) — restart the gateway with `launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway` to recompute (do NOT use `openclaw gateway restart` — it causes duplicate processes; see Section 10). Cron announce → Telegram failure (Issue #25906) — switch to `directMessage` mode.

**v2026.2.25 fixes:** Cron model override failures now auto-recover — if an isolated job's `payload.model` is no longer allowlisted, it gracefully falls back to the default model instead of failing the job. Cron announce duplicate sends are also fixed (duplicate guard tracks attempted vs confirmed delivery). Multi-account cron routing now properly honors `delivery.accountId`.

---

## 5. Skills & Plugins

**`metadata.openclaw.requires`** — gates skill visibility:
```yaml
metadata:
  openclaw:
    requires:
      bins: ["ffmpeg"]          # ALL must exist on PATH
      anyBins: ["gh", "hub"]    # AT LEAST ONE must exist
      env: ["GITHUB_TOKEN"]     # env vars that must be set
      config: ["browser.enabled"]
    os: ["darwin", "linux"]
```

**`disable-model-invocation: true`** — removes skill from model's tool list; user can still invoke manually. Use for high-impact or security-sensitive skills.

**Skills directory:** `~/.openclaw/workspace/skills/` — this is the filesystem path where all skills are stored. Each skill lives in its own subdirectory (e.g., `~/.openclaw/workspace/skills/my-skill/SKILL.md`). When manually installing or copying skills, always use this path — not `~/.openclaw/skills/`.

**ClawHub:**
```bash
npx clawhub install <slug>       # install
clawhub update --all             # update all
openclaw skills list --eligible  # what's loaded
openclaw skills check            # validate requirements
```

**Security:** Before installing any skill, read its `SKILL.md` manually. Community scans found 341+ malicious skills (reverse shells, credential exfiltration, Atomic Stealer, crypto miners). New accounts with popular skills = red flag. The #1 most-downloaded ClawHub skill was confirmed malware.

**Session watcher:** Skills snapshot at session start. If `skills.load.watch` is disabled, start a new session after installing.

### Plugin Slots (v2026.3.7+)

```json5
{
  plugins: {
    slots: {
      contextEngine: "legacy",       // or custom plugin id (e.g., "lossless-claw")
      memory: "memory-core",         // or "none" to disable memory entirely
    },
    entries: {
      "<plugin-id>": {
        enabled: true,
        hooks: { allowPromptInjection: false },   // block plugin from mutating system prompt
      },
    },
  },
}
```

---

## 6. Multi-Agent & Sub-Agent Architecture

```bash
/subagents spawn ops "Audit logs from last 24h"   # via chat
```

```json5
// sessions_spawn tool (programmatic)
{ "task": "Audit logs", "agentId": "ops", "model": "anthropic/claude-sonnet-4-5",
  "thinking": "low", "runTimeoutSeconds": 300, "mode": "minimal",
  "attachments": ["/path/to/file.md"] }   // inline file attachments (v2026.3.2+)
```

```json5
// Nesting config
{ agents: { defaults: { subagents: {
  maxSpawnDepth: 2,    // 0=off; 1=spawn; 2=orchestrator
  maxConcurrency: 8,
  maxChildrenPerAgent: 5,
  model: "anthropic/claude-sonnet-4-5",   // default model for spawned sub-agents
  runTimeoutSeconds: 900,
} } } }
```

**Community pattern:** Orchestrator (`opus-4-6`) → Code sub-agent (`sonnet-4-5`) → Research sub-agent (`kimi-k2.5`) → Cron/monitoring (`zai/glm-5`, isolated)

**Community insight — single agent with skills beats multiple agents for most use cases.** Multiple agent instances multiply context costs (each agent loads its own bootstrap). Use one agent with good skills instead, and only split into multiple agents when you need genuinely different identity/personality/permissions (e.g., a public-facing agent vs an ops agent).

**Sandbox isolation:**
```json5
{ agents: { list: [{ id: "untrusted", sandbox: { mode: "docker" },
  tools: { profile: "minimal", deny: ["exec", "browser"] } }] } }
```

### ACP Dispatch (v2026.3.2+)

Agent Client Protocol enables OpenClaw to spawn external coding harnesses (Claude Code, Codex CLI, Gemini CLI, OpenCode) as sub-agents:

```json5
{
  acp: {
    enabled: true,
    dispatch: { enabled: true },     // default true since v2026.3.2
    defaultAgent: "codex",
    allowedAgents: ["claude", "codex", "opencode", "gemini", "kimi"],
    maxConcurrentSessions: 8,
  },
}
```

In-chat: `/acp spawn` · `/acp status` · `/acp steer <message>` · `/acp close`

---

## 7. High-ROI Optimization Levers

| Lever | Impact | How |
|---|---|---|
| **Tiered model routing** | 50–95% cost reduction | T1 for cron/heartbeat, T4 only for orchestration |
| **Prompt caching** | 60–90% input token reduction | Keep system prompt stable; use `anthropic` direct |
| **Bootstrap file discipline** | 2K–10K tokens/call saved | SOUL.md <1K, AGENTS.md <2K, MEMORY.md <5K |
| **Light bootstrap for cron/heartbeat** | 5-10K tokens/call saved | `lightContext: true` on heartbeat; `--light-context` on cron |
| **Adaptive thinking** | Auto-scales token use | `thinkingDefault: adaptive` for Claude 4.6; `minimal` for routine |
| **Session pruning** | Reclaims stale context | `contextPruning.mode: cache-ttl` with Anthropic |
| **Silent cron (NO_REPLY)** | Eliminates delivery tokens | Instruct: "Reply NO_REPLY if nothing actionable" |
| **Compaction tuning** | Prevents overflow disasters | `safeguard` mode, `reserveTokensFloor: 32000` |
| **Cheaper compaction model** | Reduces compaction cost | Route compaction through `gemini-3-flash-preview` |
| **Session maintenance** | Prevents disk/perf degradation | `mode: enforce`, `maxDiskBytes: 500mb` |
| **Batch heartbeat checks** | 10x fewer API calls | One heartbeat for 10 checks > 10 cron jobs |
| **Isolated cron sessions** | Zero context contamination | `sessionTarget: "isolated"` on all cron jobs |
| **Single agent with skills** | Up to 80% cost reduction | One agent + skills beats multiple agent instances |
| **Gateway security** | Prevents exposure | `gateway.bind: loopback`; Tailscale for remote |
| **Never switch mid-session** | Preserves prompt cache | Only switch model at `/new` boundaries |
| **Backup before upgrades** | Pre-change safety net | `openclaw backup create` before `openclaw update` |

---

## 8. CLI Reference

**Best practice (v2026.2.25+):** Before editing config or asking config-field questions, have the agent call the `config.schema` tool in-chat. This returns the current schema with valid keys, types, and defaults — avoids guessing or using stale field names. Note: this is an agent in-chat tool, NOT a CLI command.

**Most common commands:**
```bash
openclaw doctor --fix               # auto-fix config issues
openclaw gateway status             # check runtime + RPC probe
openclaw models set <provider/model>
openclaw models status --probe
openclaw cron run <job-id>          # test a cron job immediately
openclaw sessions cleanup --dry-run
openclaw sessions cleanup --fix-missing  # prune entries with missing transcripts (v2026.2.26+)
openclaw config validate [--json]        # validate config against schema (v2026.3.2+)
openclaw config file                     # print active config file path (v2026.3.1+)
openclaw backup create [--only-config]   # local state archive (v2026.3.8+)
openclaw backup verify                   # validate backup integrity (v2026.3.8+)
openclaw update
openclaw security audit             # post-upgrade check
openclaw secrets audit              # scan bootstrap files for hardcoded secrets (v2026.2.26+)
openclaw secrets configure          # configure external secrets (v2026.2.26+)
openclaw secrets apply              # apply secrets with strict target-path validation (v2026.2.26+)
openclaw agents bindings            # list account-scoped agent route bindings (v2026.2.26+)
openclaw agents bind                # bind agent to channel account (v2026.2.26+)
openclaw agents unbind              # unbind agent from channel account (v2026.2.26+)
```

> **`openclaw onboard --reset` scope change (v2026.2.26):** Default reset scope is now `config+creds+sessions`. Workspace deletion (bootstrap files, skills, memory) now requires `--reset-scope full`. Do NOT run `openclaw onboard --reset` without specifying `--reset-scope` explicitly — the default no longer wipes the workspace.

### In-Chat Commands (v2026.3.x)

```
/session idle <duration>          manage thread inactivity auto-unfocus
/session max-age <duration>       manage hard max-age for thread bindings
/usage cost                       local cost summary from session logs
/usage tokens                     show per-reply token usage
/export-session [path]            export current session to HTML (/export alias)
/steer <message>                  steer a running sub-agent immediately (/tell alias)
/kill <subagent|all>              abort one or all running sub-agents
/think <level>                    off | minimal | low | medium | high | xhigh | adaptive
/model <provider/model>           switch model without restart
/compact [instructions]           manual compaction with optional focus
/context detail                   per-file, per-tool, per-skill token breakdown
/acp spawn|status|steer|close     ACP session control
/check-updates                    quick update summary
```

### Environment Variables (v2026.3.x)

```bash
OPENCLAW_LOG_LEVEL=<level>         # override log level: silent|fatal|error|warn|info|debug|trace
OPENCLAW_DIAGNOSTICS=<pattern>     # targeted debug logs (e.g., "telegram.*" or "*" for all)
OPENCLAW_SHELL=<runtime>           # set across shell-like runtimes (exec, acp, tui-local)
OPENCLAW_THEME=light|dark          # TUI theme override (v2026.3.8+)
```

**Gateway restart (macOS LaunchAgent):**
```bash
# SAFE restart — single atomic operation, no duplicate processes
launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway

# DO NOT use `openclaw gateway restart` — it races with KeepAlive and spawns
# duplicate processes that loop "Port already in use" every ~10s at 100%+ CPU.

# Recovery if duplicates already exist:
launchctl bootout gui/$(id -u)/ai.openclaw.gateway    # stop launchd service + kill managed process
kill <any-remaining-pids>                              # kill orphans
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist  # re-register + start clean
```

**Full CLI reference (all commands, flags, in-chat commands):** Read `references/cli-reference.md`

---

## 9. Ops Hygiene Checklist

**Daily:**
- `openclaw health --json` via cron (→ HEARTBEAT_OK if clean)
- `clawhub whoami` to verify ClawHub auth
- Token budget check (cost-sensitive providers)

**Weekly:**
- `openclaw update --dry-run` → review → `openclaw update`
- `clawhub update --all --dry-run` → review → `clawhub update --all`
- Curate MEMORY.md — archive old daily logs, promote key insights
- `openclaw sessions cleanup --dry-run` → `openclaw sessions cleanup`
- `openclaw cron status` — check for errors
- Clean stale backup files: `find ~/.openclaw -name "*.bak.*" -mtime +7 -not -name "*.bak" | xargs rm -v` (preserves CLI's rolling `.bak` files, removes old named/dated backups)

**Quarterly:**
- Review custom scripts (`scripts/`) for redundancy with built-in OpenClaw features. Users often build custom solutions (RAG pipelines, session archivers, memory indexers) that become redundant when OpenClaw adds equivalent built-in functionality. Check whether each script and its associated cron job still serves a purpose that the platform doesn't already handle.

**Before/After Updates:**
- Before update: `openclaw backup create` (pre-change safety net — v2026.3.8+)
- After update: `openclaw doctor --fix` (handles config migrations automatically)
- After update: `openclaw config validate --json` (catch fail-closed config errors — v2026.3.2+)
- v2026.2.23 breaking change: `allowPrivateNetwork` → `dangerouslyAllowPrivateNetwork` — auto-fixed by doctor
- Manual backup only needed for major upgrades or multi-file restructuring (see Backup Strategy above)

**v2026.3.x Breaking Changes:**
- **`gateway.auth.mode` required (v2026.3.7):** When both `gateway.auth.token` AND `gateway.auth.password` are configured, you must set `gateway.auth.mode` to `"token"` or `"password"`. Gateway will not start without this.
- **`tools.profile` defaults to `"messaging"` (v2026.3.2):** New installs no longer start with coding/system tools. Existing installs are unaffected.
- **ACP dispatch defaults to enabled (v2026.3.2):** Set `acp.dispatch.enabled: false` to disable.
- **Config fail-closed (v2026.3.2+):** Invalid configs cause gateway startup failure instead of silently falling back to permissive defaults.
- **Node.js v22.12+ enforced:** Attempting to run on Node 18/20 causes immediate failure.

**On Every System Assessment (mandatory data collection):**
- `openclaw cron list` + read `~/.openclaw/cron/jobs.json` — capture full cron inventory: job IDs, names, schedules, **model overrides** (from `payload.model`), status, last run times
- Flag any jobs in `error` state — these are active problems
- Flag jobs with stale last-run times (>24h for daily jobs) — may indicate silent failures
- Check timezone consistency — jobs using `(exact)` instead of named timezones may fire at wrong times
- Record whether jobs use `isolated` or `main` session target
- Map cron schedule to day/night distribution — heavy jobs should cluster overnight
- Document all findings in the system profile's `## Cron Jobs` section before making recommendations
- Without this data, recommendations will duplicate existing automation and waste time

**Security:**
- `openclaw config get gateway.bind` → must be `loopback`
- No public port exposure — use Tailscale for remote
- API keys not in skill files or version control
- Audit ClawHub skills before installing — 341+ malicious skills confirmed
- CVE-2026-25253 (ClawJacked): WebSocket authentication bypass allowing one-click RCE. 42,000+ exposed instances. Patched in v2026.1.29+. Verify you are on v2026.2.26+ minimum.
- `openclaw security audit --deep` for live Gateway probe

---

## 10. Troubleshooting

**Log file paths (macOS):**
- **Error log:** `~/.openclaw/logs/gateway.err.log` — primary source for errors, 502s, plugin failures, tool errors
- **Main log:** `/tmp/openclaw/openclaw-YYYY-MM-DD.log` — verbose debug output (lane events, session activity)

Always check `gateway.err.log` first when troubleshooting — it contains only errors and warnings, making root cause identification much faster than grepping the main log.

**First — always run this triage sequence:**
```bash
openclaw status
openclaw gateway status            # must show "Runtime: running" + "RPC probe: ok"
openclaw doctor
openclaw channels status --probe
openclaw config validate --json    # catch config errors before restart (v2026.3.2+)
tail -50 ~/.openclaw/logs/gateway.err.log | grep -v DEP0040   # skip Node deprecation noise
```

**Quick fix by symptom:**

| Symptom | First Command | Most Likely Fix |
|---|---|---|
| No response from agent | `openclaw gateway status` | Gateway not running or pairing pending |
| Gateway won't start | `openclaw logs --follow` | `EADDRINUSE` or `gateway.mode` not set to `local` |
| "Port already in use" loop | `ps aux \| grep openclaw-gateway` | Duplicate processes from CLI restart vs LaunchAgent `KeepAlive`. Fix: `launchctl bootout` → kill orphans → `launchctl bootstrap` (see Section 8) |
| "Gateway start blocked: set gateway.auth.mode" | `openclaw config get gateway.auth` | Both token and password set but `gateway.auth.mode` missing. Fix: `openclaw config set gateway.auth.mode token` (v2026.3.7 breaking change) |
| "unauthorized" on Control UI | `launchctl getenv OPENCLAW_GATEWAY_TOKEN` | Remove stale launchctl env override |
| Config file wiped on restart | Back up config first | Known bug #40410 — gateway restart can wipe `openclaw.json`. Use `openclaw backup create` before restarts. |
| Cron job never fires | `openclaw cron status` | Cron disabled or timezone mismatch |
| Heartbeat always skipped | `openclaw config get agents.defaults.heartbeat.activeHours` | Wrong timezone, outside active hours, or `directPolicy` set to `block` (v2026.2.25 changed default to `allow`) |
| Cron job fails with "model not allowlisted" | `openclaw cron status` | v2026.2.25+ auto-recovers by falling back to default model. On older versions: update `payload.model` in the job or re-add the model to the allowlist. |
| Channel message dropped | `openclaw logs --follow` | Mention required or sender not paired |
| "RPC probe: failed" | `openclaw gateway status --deep` | Auth token mismatch or port conflict |
| Post-upgrade breakage | `openclaw doctor --fix` | Automatic config migration |
| Provider 401 errors | `openclaw models status --probe` | Token expired or wrong key type |
| Chrome browser won't start (Linux) | `openclaw browser status` | Snap Chromium conflict → install Google Chrome .deb |
| Silent tool execution failure | Check model | Known bug #40069 — agent claims tool use but no calls made. Confirmed with `kimi-coding/k2p5`. Switch model. |
| Compaction freezes session | Override compaction model | Known bug #38233 — `/compact` times out at ~300s with Codex models. Use `compaction.model: google/gemini-3-flash-preview` |
| Ollama stuck "typing" forever | Switch to non-Ollama model | Known bug #40434 — local Ollama models stuck via Telegram |
| Fallback doesn't escalate on outage | Test fallback chain | Known bug #32533 — retries auth profiles instead of escalating to fallback providers |
| ALL providers timeout simultaneously | `grep "delivery-recovery" gateway.err.log` | **Not a provider issue.** Two common causes: (A) **Context bloat** — `contextTokens` unset (unlimited), payload too large for any provider to process within `timeoutSeconds`. Fix: set `contextTokens: 100000`, `timeoutSeconds: 180`, `reserveTokensFloor: 32000`. See Section 10d. (B) **Event loop overload** — stuck delivery-queue, skills-remote probes, Gemini OAuth cycling, too many concurrent sessions. Fix: clear delivery queue, set `cron.maxConcurrentRuns: 1`. See Section 10b. |
| Delivery recovery loop ("21 entries deferred") | `ls ~/.openclaw/delivery-queue/` | Stuck entries (wrong channel, message too long) retry forever on every restart. Move to `~/.openclaw/delivery-queue/failed/` to stop the loop. |
| Ollama "fetch failed" (instant, ~100ms) | Check gateway err log for `Failed to discover Ollama models` | **Known bug:** OpenClaw hardcodes `127.0.0.1:11434` for Ollama discovery (Issue #8663). On macOS, LaunchAgent processes are sandboxed and can't reach private LAN IPs like `192.168.x.x` (Issue #21494). Fix: reverse SSH tunnel from Ollama machine to gateway (`ssh -fN -R 127.0.0.1:11434:127.0.0.1:11434 user@gateway`), set `baseUrl` to `http://127.0.0.1:11434`, add `OLLAMA_HOST` and `OLLAMA_API_KEY` to LaunchAgent env. See Section 10a below. |
| Ollama "Connection error" | Same as above | Same root cause. Switching `api` from `ollama` to `openai-completions` changes the error message but doesn't fix it — the sandbox blocks all LAN connections. |
| Ollama probes spike memory | `curl http://host:11434/api/ps` | Set `OLLAMA_KEEP_ALIVE=0` on the Ollama machine so models unload immediately after probes. No OpenClaw config to disable probes per-provider. |
| Gemini CLI "API rate limit reached" | `openclaw logs \| grep rate` | Google OAuth crackdown (Feb 2026). Switch to API key auth. See Section 1 warning. |
| Provider removal didn't stop probes | Check all 6 locations in Provider Removal Checklist | Stale auth-profiles.json, launchctl env, or plist env vars. See Section 1. |
| `config unset` fails on auth profile keys | Edit JSON directly | Colons in keys break the config path parser. Use python3/jq. |
| `models status --probe` mass timeouts | Test individual providers with `curl` | Probe contention — 16+ simultaneous targets saturate the event loop. Not real failures. |

### 10a. Remote Ollama on macOS (Known Bug Workaround)

**Problem:** OpenClaw on macOS cannot connect to a remote Ollama server on the LAN. `curl` works, but the gateway process fails with "fetch failed" or "Connection error." This affects all API modes (`ollama` and `openai-completions`).

**Root causes (two bugs stacking):**
1. **Hardcoded localhost discovery** (Issue [#8663](https://github.com/openclaw/openclaw/issues/8663)): OpenClaw always probes `127.0.0.1:11434` for Ollama, ignoring `baseUrl`.
2. **macOS LaunchAgent sandbox** (Issue [#21494](https://github.com/openclaw/openclaw/issues/21494)): The gateway process running under launchd gets `EHOSTUNREACH` for private network IPs (`192.168.x.x`, `10.x.x.x`).

**Fix — reverse SSH tunnel:**
```bash
# Run on the Ollama machine (not the gateway):
ssh -fN -R 127.0.0.1:11434:127.0.0.1:11434 user@gateway-host

# On the gateway:
openclaw config set models.providers.<ollama-slug>.baseUrl 'http://127.0.0.1:11434'
openclaw config set models.providers.<ollama-slug>.api ollama
```

Add to the gateway's LaunchAgent plist:
```xml
<key>OLLAMA_HOST</key>
<string>http://127.0.0.1:11434</string>
<key>OLLAMA_API_KEY</key>
<string>ollama</string>
```

**Important:** Kill any local Ollama on the gateway first — it will conflict with the tunnel on port 11434. Make the tunnel persistent with a LaunchAgent on the Ollama machine.

### 10b. Multi-Provider Timeout Storms (Event Loop Overload)

**Symptom:** ALL providers (Kimi, KiloCode, Google, Anthropic, etc.) timeout simultaneously within a 30-90 minute window, even though they are independent services. `FailoverError: LLM request timed out.` on every model in the fallback chain. May cause gateway crash/restart.

**Root cause:** The gateway's Node.js event loop is saturated by a pile-up of concurrent operations. Outbound HTTPS responses arrive, but the process can't process them before its own timeout timer fires. The providers are NOT down — the gateway can't handle the responses.

**Common overload contributors (check all of these):**

1. **Stuck delivery-recovery queue** — Files in `~/.openclaw/delivery-queue/` that will never succeed (wrong channel, message too long) retry on every restart and periodically. Each retry burns event loop time.
   - **Diagnose:** `ls ~/.openclaw/delivery-queue/*.json | wc -l` and `grep "delivery-recovery" gateway.err.log | tail -20`
   - **Fix:** `mv ~/.openclaw/delivery-queue/*.json ~/.openclaw/delivery-queue/failed/`

2. **Skills-remote bin probes to offline nodes** — Gateway probes paired nodes for skill binary requirements. If nodes don't have the node service running, each probe hangs until timeout.
   - **Diagnose:** `grep "skills-remote.*timed out" gateway.err.log | wc -l`
   - **Fix:** Remove offline nodes from paired devices, or ensure nodes have the node service running.

3. **Google Gemini CLI OAuth account cycling** — If the agent switches to Gemini CLI in-session, it cycles through OAuth accounts. Each expired/slow account hangs for 90 seconds. 6 accounts = up to 540s of hung connections.
   - **Diagnose:** `grep "google-gemini-cli.*timed out" gateway.err.log | tail -10`
   - **Fix:** Ensure OAuth tokens are fresh, or use the `google` (API key) provider instead of `google-gemini-cli` for fallbacks.

4. **No cron concurrency limit** — Multiple cron jobs firing simultaneously all compete for the same event loop and hit the same provider chain, creating a thundering herd.
   - **Fix:** `openclaw config set cron.maxConcurrentRuns 1`

5. **Proxy providers as early fallbacks** — KiloCode is a proxy. When it degrades, ALL models through it fail simultaneously (appears as multiple independent failures but is one SPOF). Put direct-API providers (Anthropic, Google API key) before proxies in the fallback chain.

**Recovery:** After fixing underlying causes, restart gateway: `launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway`

### 10c. `launchctl setenv` Persistence (macOS)

**Problem:** Removing an env var from the LaunchAgent plist does NOT remove it from the launchd session environment. The gateway process still sees the old value after a `kickstart -k` restart.

**Root cause:** `launchctl setenv` sets variables at the launchd *domain* level, independent of any plist. These persist until the user logs out or they are explicitly unset. `kickstart -k` re-reads the plist for `ProgramArguments` and `EnvironmentVariables`, but the domain-level env set by `setenv` takes precedence.

**Fix:**
```bash
# 1. Remove from plist
/usr/libexec/PlistBuddy -c 'Delete :EnvironmentVariables:<KEY>' ~/Library/LaunchAgents/ai.openclaw.gateway.plist

# 2. Remove from launchd session
launchctl unsetenv <KEY>

# 3. Full service re-register (not just kickstart)
launchctl bootout gui/$(id -u)/ai.openclaw.gateway
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

**Key lesson:** Always clean both plist AND `launchctl unsetenv` when removing provider env vars. Use `launchctl getenv <KEY>` to verify removal. If the command returns output (even empty), the var is still set. "Not set" means `launchctl getenv` exits with an error.

### 10d. Context Bloat Cascade Timeouts

**Symptom:** ALL providers in the fallback chain timeout simultaneously on the same request. The same `runId` appears across multiple providers in 90-second intervals. Looks like a massive outage but providers are actually fine.

**Pattern in logs:**
```
14:17:24 Profile openai-codex:default timed out. Trying next account...
14:18:54 Profile kimi-coding:default timed out. Trying next account...
14:20:25 [diagnostic] lane task error ... FailoverError: LLM request timed out.
14:21:55 Profile anthropic:manual timed out. Trying next account...
```

**Root cause:** `contextTokens` is unset (defaults to unlimited). The main session accumulates conversation history until the payload is so large that no provider can respond within `timeoutSeconds`. Each provider in the fallback chain gets the same oversized payload, times out, and passes to the next one — creating a cascade that takes `timeoutSeconds × number_of_providers` to fully fail.

**The deadly trio:**
1. **Unlimited `contextTokens`** — payload grows unchecked
2. **Short `timeoutSeconds` (e.g., 90)** — not enough time for large payloads
3. **Long fallback chain (4-5 providers)** — each one gets a full timeout cycle before failing

**Fix — recommended baseline for any mixed-provider fallback chain:**
```bash
openclaw config set agents.defaults.contextTokens 100000
openclaw config set agents.defaults.timeoutSeconds 180
openclaw config set agents.defaults.compaction.reserveTokensFloor 32000
openclaw config set agents.defaults.compaction.mode safeguard
```

**How this works together:**
- `contextTokens: 100000` — caps context so all providers can handle it
- Compaction triggers at ~68K tokens (100K minus 32K reserve)
- Memory flush runs first (if enabled), then compaction compresses history
- `timeoutSeconds: 180` — gives providers 3 minutes per attempt (vs 90s)
- The cap ensures every provider in the chain can respond in time

**Tradeoff:** Models with large context windows (Gemini: 1M, GPT-5.4: 1.05M) are capped at 100K. This is intentional — the cap must match the weakest provider in the fallback chain. For dedicated large-context sessions, temporarily increase `contextTokens`.

**Full troubleshooting reference (7 failure categories, per-channel error tables, node error codes, GitHub issue workarounds):** Read `references/troubleshooting.md`

---

## 11. System Learning

This skill maintains **system profiles** — persistent knowledge files that capture everything learned about specific OpenClaw deployments. Each deployment gets a unique profile that grows over time, turning the skill into an expert on that particular system.

### How It Works

**Directory:** `~/.openclaw-optimizer/systems/` — one Markdown file per deployment, plus `TEMPLATE.md` for new deployments. This is a **centralized location outside the skill directory** so that: (1) system profiles are never accidentally pushed to git, (2) multiple AI tools (Claude Code, OpenClaw, Gemini CLI, etc.) on the same machine can read/write the same profiles without drift. Cross-machine sync is still manual via SCP.

**Deployment ID:** Each deployment has a unique slug (e.g., `my-home-lab`, `prod-cluster-east`, `dev-standalone`). The file is named `systems/<deployment-id>.md`.

**Topology types:**
| Type | Description |
|---|---|
| `gateway-only` | Single gateway, no remote nodes |
| `hub-spoke` | One gateway, one or more client nodes connecting to it |
| `multi-gateway` | Multiple gateways, nodes may connect to different ones |
| `mesh` | Nodes interconnected, multiple gateways with cross-routing |

### Session Workflow

**First-run setup (once per machine):**
1. Check if `~/.openclaw-optimizer/systems/` exists
2. If not: inform the user that this skill stores deployment profiles in `~/.openclaw-optimizer/systems/` (centralized, outside git, shared across AI tools), confirm they're OK with creating it, then: `mkdir -p ~/.openclaw-optimizer/systems/` and copy `TEMPLATE.md` from the skill's `systems/` directory into it
3. If the directory exists but is empty (no TEMPLATE.md): copy `TEMPLATE.md` from the skill's `systems/` directory

**At session start (identify the deployment):**
1. Ask which deployment the user is working on, or identify it from context (SSH target, hostnames, IPs)
2. Check `~/.openclaw-optimizer/systems/` for an existing profile matching the deployment
3. If found: **read the profile** — load topology, access details, past issues, and lessons learned. Use this knowledge throughout the session.
4. If not found: create a new profile from `~/.openclaw-optimizer/systems/TEMPLATE.md` during the session

**On any system assessment or audit (mandatory — run before making recommendations):**
1. `openclaw cron list` — capture full cron inventory: job IDs, names, schedules, status, last run times
2. `openclaw config get agents.defaults.model` — capture model routing (primary + fallbacks)
3. `ls ~/.openclaw/delivery-queue/*.json 2>/dev/null | wc -l` — check for stuck delivery entries
4. `openclaw nodes list` — check paired nodes and connection status
5. Flag any cron jobs in `error` state — these are active problems
6. Flag jobs with stale last-run times (>24h for daily jobs) — may indicate silent failures
7. Check timezone consistency — jobs using `(exact)` instead of named timezones may fire at wrong times
8. Document ALL findings in the system profile before making recommendations
9. **Without this data, recommendations will duplicate existing automation and miss hidden drains.**

**During the session:**
- Reference the profile for SSH access, paths, IPs, and known gotchas
- Check the issue log before diagnosing — the same problem may have been solved before
- Apply lessons learned to avoid repeating mistakes

**At session end (update the profile):**
1. Add any new issues to the **Issue Log** (newest first) with: symptom, root cause, fix, rollback, lesson
2. Update **Lessons Learned** with new patterns discovered
3. Update machine details if anything changed (IPs, versions, config)
4. Update the `Last updated` date
5. Sync the profile to the gateway: `scp ~/.openclaw-optimizer/systems/<deployment-id>.md <user>@<host>:~/.openclaw-optimizer/systems/`
6. Note: system profiles live in `~/.openclaw-optimizer/systems/`, NOT in the skill directory. Do not commit them to git.

### What Gets Captured

| Section | Purpose |
|---|---|
| **Machines** | Every machine in the deployment: role, SSH access, IPs (local + Tailscale), OS, paths, installed software, notable config |
| **Network** | Tailnet, Tailscale Serve config, auth mode, token prefixes, connectivity method |
| **Providers** | Active model providers with slugs and primary use cases |
| **Model Routing** | Current tiered routing setup |
| **Channels** | Messaging channels (Telegram, WhatsApp, etc.) and their status |
| **Paired Devices** | Device entries from the gateway's paired.json — roles, connection status, stale entries |
| **Cron Jobs** | Full inventory: job ID, name, schedule, status, last run, session target, model override. Flag errors and stale runs. |
| **Delivery Queue** | Stuck entries in `~/.openclaw/delivery-queue/` — channel, error, count. These cause infinite retry loops. |
| **Issue Log** | Every problem encountered: symptom → root cause → fix → rollback → lesson |
| **Lessons Learned** | Accumulated patterns and gotchas specific to this deployment |

### Rules

- **Never store full secrets** in profiles — use first 12 chars + `...` for tokens, never store full API keys
- **Always read the profile before troubleshooting** — don't rediscover what's already known
- **Always update the profile after fixes** — future sessions depend on accurate knowledge
- **One profile per gateway** — nodes are documented within the gateway's profile
- **Keep lessons actionable** — not "TLS was broken" but "macOS app rejects `ws://` for remote gateways — always use `wss://`"
- **Rely on built-in backup layers — don't create manual backups for routine changes.** OpenClaw's CLI creates rolling `.bak` files on every config write, and the nightly GitHub backup cron captures the full config in git history. Manual dated backups (`cp <file> <file>.YYYY-MM-DD-<reason>`) are only needed for: (1) major version upgrades, (2) multi-file restructuring (identity audits), (3) direct JSON edits where the CLI isn't used. For routine CLI changes (model swaps, cron edits, config sets), the CLI `.bak` + GitHub nightly are sufficient. Clean up old manual backups after they're covered by the nightly backup.

---

## 12. Continuous Improvement

This skill is a living document. Every troubleshooting session, every CLI interaction, and every failure is an opportunity to make it more accurate. Future sessions must actively update the skill based on real-world experience.

### When to Update SKILL.md

| Trigger | Action |
|---|---|
| A CLI command in the skill doesn't work as documented | Fix the command, add a note about what changed |
| A troubleshooting step is missing or incomplete | Add it to Section 10's symptom table |
| A workaround is discovered that isn't documented | Add it to the relevant section |
| Advice in the skill caused a failure | Correct the advice and add a warning |
| A new `openclaw` flag or subcommand is discovered during use | Update Section 8 (CLI Reference) |
| A new known bug or GitHub issue is found | Add it to the relevant section with issue number |
| A config key is renamed, deprecated, or new | Update the relevant config examples |

### What to Update

**Two targets — always update both when applicable:**

1. **SKILL.md** — general knowledge that applies to ALL deployments (CLI commands, config patterns, troubleshooting steps, known bugs, process workflows)
2. **System profile** (`systems/<deployment-id>.md`) — deployment-specific knowledge (IPs, paths, credentials, topology, issue log, lessons learned)

### How to Update

1. **During the session:** When you discover something new, update the relevant section immediately — don't wait until the end. Corrections to bad advice are urgent.
2. **Be specific:** Don't write "TLS can be tricky." Write "macOS app rejects `ws://` for remote gateways — always use `wss://`. The `ws://` scheme is only valid for loopback connections."
3. **Include the why:** Don't just say "use X instead of Y." Explain what goes wrong when you use Y.
4. **Preserve what works:** Only change what's actually wrong. Don't rewrite sections that are accurate.
5. **Sync to remote:** After updating, sync the skill and system profiles to any remote OpenClaw instances:
   ```bash
   # Sync SKILL.md (skill code — lives in the skill directory)
   scp ~/.claude/skills/openclaw-optimizer/SKILL.md <user>@<host>:~/.openclaw/workspace/skills/openclaw-optimizer/SKILL.md
   # Sync system profiles (deployment data — lives in the centralized directory)
   scp ~/.openclaw-optimizer/systems/<deployment-id>.md <user>@<host>:~/.openclaw-optimizer/systems/
   ```

### Versioning

The skill uses semver (`MAJOR.MINOR.PATCH`) independent of OpenClaw's version:
- **PATCH** (1.3.0 → 1.3.1): Fixing a typo, correcting a command, small clarification
- **MINOR** (1.3.0 → 1.4.0): Adding a new section, new troubleshooting entries, new workflow
- **MAJOR** (1.3.0 → 2.0.0): Restructuring sections, breaking changes to the skill's own workflow

**On every commit that changes SKILL.md:**
1. Bump `version:` in the YAML frontmatter
2. Update the `Updated:` date in the header
3. Update the `Skill v` tag in the header

### Self-Audit Checklist (run mentally at session end)

- Did I discover any CLI behavior that contradicts the skill? → Fix Section 8 or 10
- Did I find a workaround that future sessions would need? → Add to relevant section
- Did I hit an error that's not in the troubleshooting table? → Add to Section 10
- Did I learn something deployment-specific? → Update the system profile
- Did any advice in this skill lead me astray? → Correct it with a warning
- Did I change SKILL.md? → Bump version, update date, commit, push, sync to gateway

---

## 13. Agent Identity Optimizer

Audit and optimize OpenClaw bootstrap/identity files for conflicts, bloat, misplaced content, and best practice violations. Interactive issue-by-issue walkthrough with preview diffs.

**Core files audited:** SOUL.md, IDENTITY.md, AGENTS.md, USER.md
**Supporting files (if present):** TOOLS.md, HEARTBEAT.md, MEMORY.md, BOOT.md

**What it checks (36 items):** Structural issues (truncation risk, bloat), content in the wrong file, conflicting/overlapping directives, best practice violations (official AGENTS.md template), USER.md completeness gaps, token efficiency.

**Workflow:** Collect files (local or SSH) → run checklist → present findings by severity → walk through each issue (approve/modify/skip) → apply changes → report token savings.

**Context-aware (v2026.3.7+):** When auditing, consider `lightContext` and `postCompactionSections` — files used only in `lightContext` mode (HEARTBEAT.md) or re-injected after compaction (`postCompactionSections` headings in AGENTS.md) have different optimization priorities. Ensure critical instructions appear under `postCompactionSections` headings (default: `Session Startup`, `Red Lines`) so they survive compaction.

**Full audit checklist, file role definitions, and detailed workflow:** Read `references/identity-optimizer.md`

---

## Output Shape

- **Executive summary** — what matters most + why
- **Top offenders** — cost drivers, context drivers, reliability risks
- **Options A/B/C** — tradeoffs made explicit
- **Recommended plan** — smallest change first
- **Exact change proposals** — CLI commands or config patches, all with rollback
- **Rollback** — exact command to undo every change

Sources: docs.openclaw.ai, github.com/openclaw/openclaw, r/openclaw, r/myclaw, r/OpenClawUseCases
