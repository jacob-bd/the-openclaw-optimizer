# OpenClaw Optimizer — Workflows & Architecture

Visual reference for how the skill operates. Each diagram maps to a section in `SKILL.md`.

---

## Architecture Overview

How the skill package, centralized data, and AI tools fit together.

```mermaid
graph TB
    subgraph "Skill Package (git-tracked)"
        SKILL["SKILL.md<br/><i>13 sections, main skill logic</i>"]
        REF_PROV["references/providers.md"]
        REF_TROUBL["references/troubleshooting.md"]
        REF_CLI["references/cli-reference.md"]
        REF_IDENT["references/identity-optimizer.md"]
        SCRIPTS["scripts/<br/>version-check.py<br/>update-skill.sh"]
        TEMPLATE["systems/TEMPLATE.md"]
    end

    subgraph "Centralized Data (NOT git-tracked)"
        SYSTEMS["~/.openclaw-optimizer/systems/<br/><i>Deployment profiles</i>"]
        PROFILE["my-home-lab.md<br/>prod-cluster.md<br/>..."]
    end

    subgraph "AI Tools (readers/writers)"
        CC["Claude Code"]
        OC["OpenClaw Gateway"]
        GC["Gemini CLI"]
    end

    SKILL --> CC
    SKILL --> OC
    SKILL --> GC
    CC --> SYSTEMS
    OC --> SYSTEMS
    GC --> SYSTEMS
    TEMPLATE -.->|"first-run copy"| SYSTEMS
    SYSTEMS --> PROFILE
```

The skill package lives in version control. Deployment profiles live in `~/.openclaw-optimizer/systems/` — centralized, outside git, shared across AI tools on the same machine.

---

## First-Run Bootstrap

*SKILL.md Section 11 — System Learning*

The skill is self-bootstrapping. When loaded by any AI tool for the first time on a machine, it sets up the centralized systems directory.

```mermaid
flowchart TD
    A["Skill loaded by AI tool"] --> B{"~/.openclaw-optimizer/systems/<br/>exists?"}
    B -->|Yes| C{"Has TEMPLATE.md?"}
    B -->|No| D["Inform user:<br/>'This skill stores deployment profiles in<br/>~/.openclaw-optimizer/systems/ — centralized,<br/>outside git, shared across AI tools'"]
    D --> E{"User confirms?"}
    E -->|Yes| F["mkdir -p ~/.openclaw-optimizer/systems/"]
    E -->|No| G["Proceed without system profiles"]
    F --> H["Copy TEMPLATE.md from skill's systems/ dir"]
    H --> I["Ready — proceed to Session Start"]
    C -->|Yes| I
    C -->|No| H
```

If the user declines, the skill still works — it just won't persist deployment knowledge between sessions.

---

## Session Lifecycle

*SKILL.md Section 11 — System Learning*

Every session follows this lifecycle: identify the deployment, load knowledge, assess the system, work, then persist what was learned.

```mermaid
flowchart TD
    START["Session Start"] --> ID["Identify deployment<br/><i>From context, SSH target,<br/>hostnames, or ask user</i>"]
    ID --> CHECK{"Profile exists in<br/>~/.openclaw-optimizer/systems/?"}
    CHECK -->|Yes| LOAD["Read profile:<br/>topology, IPs, SSH access,<br/>issue log, lessons learned"]
    CHECK -->|No| CREATE["Create new profile<br/>from TEMPLATE.md"]
    CREATE --> LOAD

    LOAD --> ASSESS{"System assessment<br/>requested?"}
    ASSESS -->|Yes| COLLECT["Mandatory data collection:<br/>1. openclaw cron list<br/>2. config get agents.defaults.model<br/>3. ls delivery-queue/*.json<br/>4. openclaw nodes list<br/>5. Flag errors, stale runs, TZ issues"]
    ASSESS -->|No| WORK

    COLLECT --> DOC["Document findings<br/>in system profile"]
    DOC --> WORK["Work on task<br/><i>Reference profile for access details,<br/>check issue log before diagnosing,<br/>apply lessons learned</i>"]

    WORK --> END["Session End"]
    END --> UPDATE["Update profile:<br/>1. Add issues to Issue Log<br/>2. Update Lessons Learned<br/>3. Update machine details<br/>4. Update last-updated date"]
    UPDATE --> SYNC["Sync to gateway:<br/>scp ~/.openclaw-optimizer/systems/*.md<br/>user@host:~/.openclaw-optimizer/systems/"]
```

The mandatory data collection step prevents the skill from making recommendations that duplicate existing automation or miss hidden drains (stuck delivery queues, stale cron jobs, etc.).

---

## Troubleshooting Flow

*SKILL.md Section 10 — Troubleshooting*

When diagnosing a problem, the skill follows a structured triage before making recommendations.

```mermaid
flowchart TD
    SYMPTOM["User reports symptom<br/>or pastes error"] --> PROFILE["Load system profile<br/><i>Check issue log — same<br/>problem may be solved before</i>"]
    PROFILE --> TRIAGE["Run triage sequence:<br/>1. openclaw status<br/>2. openclaw gateway status<br/>3. openclaw doctor<br/>4. openclaw channels status --probe<br/>5. openclaw logs --follow"]

    TRIAGE --> SINGLE{"Single provider<br/>failure?"}
    SINGLE -->|Yes| PROVIDER["Provider-specific diagnosis:<br/>auth, rate limits, model ID,<br/>base URL, API format"]
    SINGLE -->|No| MULTI{"Multiple providers<br/>failing simultaneously?"}

    MULTI -->|Yes| EVENTLOOP["Suspect event loop overload<br/><i>SKILL.md Section 10b</i>"]
    EVENTLOOP --> DRAINS["Check hidden drains:<br/>1. Stuck delivery queue<br/>2. Skills-remote probe timeouts<br/>3. Gemini CLI OAuth cycling<br/>4. Cron concurrency<br/>5. Proxy SPOF in fallback chain"]

    PROVIDER --> FIX["Propose fix:<br/>1. Exact CLI command<br/>2. Expected impact<br/>3. Rollback command"]
    DRAINS --> FIX

    FIX --> APPROVE{"User approves?"}
    APPROVE -->|Yes| APPLY["Apply fix"]
    APPROVE -->|No| ALT["Propose alternatives<br/>Options A/B/C"]
    APPLY --> LOG["Log in system profile:<br/>symptom → root cause → fix → rollback → lesson"]
    ALT --> FIX
```

Every fix goes through the safety contract: exact command, expected impact, rollback command, user approval. All fixes are logged in the deployment profile for future reference.

---

## Model Failover Chain

*SKILL.md Section 2 — Model Routing Strategy*

How model requests flow through the failover chain and where problems occur.

```mermaid
flowchart LR
    REQ["LLM Request"] --> PRIMARY["Primary Model<br/><i>e.g., moonshot/kimi-k2.5</i>"]
    PRIMARY -->|"timeout / error"| FB1["Fallback 1<br/><i>Direct API preferred<br/>e.g., google/gemini-3-flash</i>"]
    FB1 -->|"timeout / error"| FB2["Fallback 2<br/><i>Direct API<br/>e.g., anthropic/sonnet</i>"]
    FB2 -->|"timeout / error"| FB3["Fallback 3<br/><i>Proxy OK here<br/>e.g., openrouter/glm-5</i>"]
    FB3 -->|"timeout / error"| FAIL["FailoverError:<br/>All models failed"]

    PRIMARY -->|"success"| OK["Response"]
    FB1 -->|"success"| OK
    FB2 -->|"success"| OK
    FB3 -->|"success"| OK

    style PRIMARY fill:#2d5016,color:#fff
    style FB1 fill:#1a4d1a,color:#fff
    style FB2 fill:#1a3d5c,color:#fff
    style FB3 fill:#4a3520,color:#fff
    style FAIL fill:#5c1a1a,color:#fff
```

**Key rule:** Direct-API providers (Anthropic, Google API key) go before proxy providers (KiloCode, OpenRouter) in the fallback chain. Proxies are single points of failure — when the proxy degrades, ALL models through it fail simultaneously.

When all providers timeout at once, the problem is almost never the providers. See the Troubleshooting Flow above and SKILL.md Sections 10b (event loop overload) and 10d (context bloat cascade).

---

## Agent Identity Audit

*SKILL.md Section 13 — Agent Identity Optimizer*

When auditing agent personality and identity files, the skill follows a structured process.

```mermaid
flowchart TD
    START["User requests<br/>identity audit"] --> ACCESS{"Gateway local<br/>or remote?"}
    ACCESS -->|Local| LOCAL["Read files from<br/>~/.openclaw/workspace/"]
    ACCESS -->|Remote| SSH["SSH to gateway<br/><i>Using system profile</i>"]
    LOCAL --> COLLECT
    SSH --> COLLECT

    COLLECT["Collect bootstrap files:<br/>SOUL.md, IDENTITY.md,<br/>AGENTS.md, USER.md,<br/>TOOLS.md, HEARTBEAT.md,<br/>MEMORY.md, BOOT.md"] --> RUN["Run 36-check audit:<br/>1. Structural (size, truncation)<br/>2. Content placement<br/>3. Conflicts & overlaps<br/>4. Best practice violations<br/>5. USER.md completeness<br/>6. Token efficiency"]

    RUN --> SUMMARY["Present findings summary:<br/>X critical, Y warnings, Z info<br/>Total token cost"]

    SUMMARY --> WALK["Issue-by-issue walkthrough<br/><i>Critical → Warning → Info</i>"]
    WALK --> DECIDE{"For each issue:<br/>Approve / Modify / Skip?"}
    DECIDE -->|Approve| BACKUP["Create dated backup<br/>Show diff, apply change"]
    DECIDE -->|Modify| REVISE["User suggests alternative<br/>Revise and re-present"]
    DECIDE -->|Skip| NEXT["Next issue"]
    BACKUP --> NEXT
    REVISE --> DECIDE

    NEXT --> MORE{"More issues?"}
    MORE -->|Yes| WALK
    MORE -->|No| REPORT["Post-audit report:<br/>Changes applied, tokens saved,<br/>backup locations, restart advice"]
```

The full 36-check audit checklist and file role definitions are in `references/identity-optimizer.md`.

---

## System Learning Lifecycle

*SKILL.md Section 11 — System Learning*

How deployment knowledge accumulates and persists across sessions and tools.

```mermaid
flowchart TD
    subgraph "Session N"
        S1["Load profile"] --> S2["Diagnose issue"]
        S2 --> S3["Discover root cause"]
        S3 --> S4["Apply fix"]
        S4 --> S5["Update profile:<br/>Issue Log + Lessons"]
        S5 --> S6["Sync to gateway"]
    end

    subgraph "Session N+1 (same or different tool)"
        T1["Load profile"] --> T2["Read issue log<br/><i>Already knows the fix</i>"]
        T2 --> T3["Apply lesson learned<br/><i>Avoids repeating mistakes</i>"]
    end

    S6 -->|"SCP sync"| T1

    subgraph "Centralized Storage"
        STORE["~/.openclaw-optimizer/systems/<br/>my-home-lab.md"]
    end

    S5 --> STORE
    STORE --> T1
```

Profiles are stored in `~/.openclaw-optimizer/systems/` — outside git, shared across all AI tools on the same machine. Cross-machine sync is manual via SCP after each session.
