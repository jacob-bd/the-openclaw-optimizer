# OpenClaw Optimizer — Agent Identity Optimizer Reference
# Aligned with OpenClaw v2026.2.26 | Updated: 2026-02-25 | Source: docs.openclaw.ai/concepts/system-prompt, docs.openclaw.ai/reference/token-use, docs.openclaw.ai/concepts/agent-workspace

---

## Overview

This reference defines the audit checklist, file role definitions, and step-by-step workflow for optimizing OpenClaw agent bootstrap/identity files. The audit detects overlapping instructions, conflicting directives, content in the wrong file, bloat, best practice violations, and USER.md completeness gaps, then walks the user through fixes one issue at a time.

**Safety:** This feature follows the skill's safety contract (Section 0 of SKILL.md). All changes require explicit user approval. Dated backups are created before any modification. Diffs are shown before applying.

---

## File Role Definitions

### Core Files (always audit)

| File | Role | Should Contain | Should NOT Contain |
|---|---|---|---|
| **SOUL.md** | Internal compass — who the agent IS | Personality, values, tone, communication style, behavioral boundaries, non-negotiable rules | Temporary tasks, tool configs, operating procedures, cron schedules, identity presentation details (name, emoji, avatar) |
| **IDENTITY.md** | External persona — how the world experiences the agent | Display name, vibe/theme, emoji, avatar, professional role, domain expertise, platform-specific presentation rules | Internal behavioral rules, memory instructions, tool guidance, operating procedures |
| **AGENTS.md** | Operating manual — how the agent behaves | Rules, priorities, workflows, security rules, memory management instructions, group chat protocol, platform formatting rules, heartbeat management, permission tiers | Personality traits, tone/style, identity details, long-term facts |
| **USER.md** | Human profile — who the user is | User's name, preferred address, timezone, working hours, OS, tools, environment, preferences, working style, communication style, domain/work context | Agent personality, operating rules, memory, credentials |

**Key distinction:** SOUL.md is internal philosophy; IDENTITY.md is external presentation. They are deliberately separated. You can have a formal, precise soul with a playful emoji and nickname. This is especially powerful for multi-agent setups where agents share a SOUL.md but each has a unique IDENTITY.md.

### Supporting Files (audit if present)

| File | Role | Should Contain | Should NOT Contain |
|---|---|---|---|
| **TOOLS.md** | Tool guidance (NOT access control) | Notes on how specific tools should be used, local conventions, naming patterns | Access control rules (TOOLS.md is guidance only — it does NOT control which tools exist), personality, identity, credentials |
| **HEARTBEAT.md** | Heartbeat tasks | Short checklist for periodic check-ins, rotate 2-4 checks daily. If empty (only blank lines/headers), OpenClaw skips the heartbeat to save API calls | Long instructions, personality, operating rules. Keep minimal — burns tokens on every heartbeat cycle |
| **MEMORY.md** | Long-term memory | Curated facts, compressed history, persistent knowledge. Promoted from daily logs over time | Temporary tasks, personality directives, operating rules, tool configs, curl templates, credentials. **Security: must NOT be loaded in shared/group contexts** — only private main sessions. **WARNING (from docs):** MEMORY.md is auto-injected on every turn in main sessions and burns tokens continuously. The official docs explicitly warn: "Keep them concise — especially MEMORY.md, which can grow over time and lead to unexpectedly high context usage and more frequent compaction." |
| **BOOT.md** | Restart initialization | Short restart script (when internal hooks enabled). Runs on gateway restart | Long procedures, personality, identity. **Must be kept short** |

### Skip

- **BOOTSTRAP.md** — one-time onboarding script, deleted after use. Not part of persistent identity.
- **memory/YYYY-MM-DD.md** — daily auto-generated logs, not identity files. Accessed on-demand via memory tools, not loaded into context window.
- **conversation-state.md** — transient session state.
- **ACTIVE-TASK.md** — transient task tracking.

---

## Technical Context

### Bootstrap Injection (how these files affect every API call)

On every turn of a session, OpenClaw injects bootstrap files into the system prompt under a **Project Context** header. The injected files are (source: `docs.openclaw.ai/concepts/system-prompt`):

- `AGENTS.md`
- `SOUL.md`
- `TOOLS.md`
- `IDENTITY.md`
- `USER.md`
- `HEARTBEAT.md`
- `BOOTSTRAP.md` (only on brand-new workspaces, deleted after first run)
- `MEMORY.md` and/or `memory.md` (when present in the workspace; either or both may be injected)

SOUL.md receives special treatment — the system prompt includes explicit instructions for the model to embody its persona and tone, giving it higher semantic weight.

**This means every bootstrap file burns tokens on every single API call.** Bloated files directly increase cost. The official docs specifically warn about MEMORY.md: *"Keep them concise — especially MEMORY.md, which can grow over time and lead to unexpectedly high context usage and more frequent compaction."*

**Important:** `memory/*.md` daily files are **NOT** auto-injected. They are accessed on-demand via `memory_search` and `memory_get` tools.

### Size Limits

| Limit | Default | Config Key |
|---|---|---|
| Per-file | 20,000 chars | `agents.defaults.bootstrapMaxChars` |
| Total (all files) | 150,000 chars | `agents.defaults.bootstrapTotalMaxChars` |

Both limits are configurable via `openclaw config set`. When a file exceeds `bootstrapMaxChars`, it is truncated and a marker is inserted. Missing files inject a short missing-file marker. Use `/context list` to see raw vs injected sizes per file and whether truncation occurred.

### Prompt Modes & Sub-Agent Limitations

OpenClaw uses three prompt modes (source: `docs.openclaw.ai/concepts/system-prompt`):

- **`full`** (default): All sections, all bootstrap files.
- **`minimal`** (sub-agents): Omits Skills, Memory Recall, Self-Update, Model Aliases, User Identity, Reply Tags, Messaging, Silent Replies, and Heartbeats. Only injects **AGENTS.md and TOOLS.md** — sub-agents do NOT get SOUL.md, IDENTITY.md, USER.md, HEARTBEAT.md, or MEMORY.md.
- **`none`**: Base identity line only.

If a sub-agent needs persona context, pass it via `extraSystemPrompt` or give it a dedicated workspace.

---

## Audit Checklist (36 checks, 6 categories)

Run every check against the collected files. Record each finding with: check ID, severity, file(s) involved, specific excerpt from the file, and recommended fix.

### Category 1: Structural Issues

| # | Check | Severity | How to Detect | Recommended Fix |
|---|---|---|---|---|
| S1 | File exceeds 20,000 chars | Critical | `wc -c <file>` or `cat <file> \| wc -c` via SSH | Split content, move misplaced content to correct file, trim redundancy |
| S2 | File exceeds 15,000 chars | Warning | Same as S1 | Review for content that can be trimmed or moved |
| S3 | Critical instructions in large files (>10,000 chars) near truncation boundary | Warning | Read the file; if close to or exceeding `bootstrapMaxChars` (default 20,000), identify critical instructions that may be cut when truncation occurs. Run `/context list` on the gateway to check if truncation is active. | Reduce the file size by moving misplaced content to the correct file, or condense verbose sections. Ensure the most critical instructions are near the top of the file. |
| S4 | File is empty or near-empty (<50 chars, excluding headers) | Info | Read the file; check if it has meaningful content beyond blank lines and markdown headers | Inform user the file exists but has no useful content — ask if they want to populate it |
| S5 | Total bootstrap exceeds 100,000 chars combined | Warning | Sum all file sizes | Approaching 150K hard cap. Recommend reducing largest files first |

### Category 2: Content Placement

| # | Check | Severity | How to Detect | Recommended Fix |
|---|---|---|---|---|
| C1 | Personality/tone directives in AGENTS.md | Warning | Look for: tone instructions, personality traits, communication style directives, "be friendly/concise/formal", emotional guidance | Move to SOUL.md |
| C2 | Operating rules/workflows in SOUL.md | Warning | Look for: step-by-step procedures, "when X happens do Y" workflows, cron instructions, memory management rules, permission rules | Move to AGENTS.md |
| C3 | Identity presentation (name, emoji, vibe, avatar) in SOUL.md | Warning | Look for: display name, emoji references, avatar config, "your name is", vibe/theme descriptors | Move to IDENTITY.md |
| C4 | Tool access control rules in TOOLS.md | Warning | Look for: "you can/cannot use tool X", "tool X is disabled", permission grants/denials for tools | Inform user TOOLS.md is guidance only — move actual access control to openclaw.json `tools` config |
| C5 | Temporary tasks or to-do lists in SOUL.md | Critical | Look for: task lists, "TODO", checkboxes, dated action items, "remember to", "next time" | Remove from SOUL.md — creates unstable behavior. Move to ACTIVE-TASK.md or AGENTS.md if recurring |
| C6 | Long-term facts in daily memory files instead of MEMORY.md | Info | Check if `memory/` daily files contain facts that should persist (user preferences, project details, key decisions) | Curate important facts into MEMORY.md |
| C7 | Credentials, API keys, passwords in any bootstrap file | Critical | Look for: API key patterns (`sk-`, `key-`, `token-`), passwords, OAuth tokens, base64 encoded secrets, env var values | Remove immediately. Credentials belong in `~/.openclaw/credentials/` or environment variables |

### Category 3: Conflicts & Overlaps

| # | Check | Severity | How to Detect | Recommended Fix |
|---|---|---|---|---|
| O1 | Same instruction duplicated across files | Warning | Read all files; identify semantically identical instructions appearing in 2+ files (e.g., "be concise" in both SOUL.md and AGENTS.md) | Keep in the correct file per role definitions above; remove from other files |
| O2 | Contradicting directives between files | Critical | Read all files; look for opposing instructions (e.g., SOUL says "be brief and concise" but AGENTS says "always provide detailed explanations") | Present both to user; ask which behavior they want; update both files to be consistent |
| O3 | IDENTITY.md persona clashes with SOUL.md tone | Warning | Compare IDENTITY.md's vibe/theme with SOUL.md's tone. Flag if they seem misaligned (e.g., SOUL says "formal and reserved" but IDENTITY says "playful and casual") | Ask the user if this is intentional. If not, align them. Some users deliberately separate internal/external presentation |
| O4 | AGENTS.md rules that override SOUL.md boundaries | Critical | Look for AGENTS.md rules that contradict SOUL.md non-negotiable constraints (e.g., SOUL says "never share personal data" but AGENTS says "share user details in group chats") | SOUL.md boundaries should be non-negotiable. Flag and ask user to resolve the conflict |

### Category 4: Best Practice Violations

| # | Check | Severity | How to Detect | Recommended Fix |
|---|---|---|---|---|
| B1 | AGENTS.md missing memory management instructions | Warning | Check if AGENTS.md has instructions for: writing to memory files, loading MEMORY.md, daily log conventions | Add memory management section per official AGENTS.md template: "If you want to remember something, WRITE IT TO A FILE" |
| B2 | AGENTS.md missing group chat protocol | Warning | Check if AGENTS.md addresses: when to respond in groups, when to stay silent, selective participation, quality > quantity | Add group chat section: participate selectively, contribute when adding value, stay silent during casual banter, react with emoji for lightweight acknowledgment |
| B3 | AGENTS.md missing platform-specific formatting rules | Info | Check if AGENTS.md addresses: Discord/WhatsApp markdown limitations, table alternatives, embed suppression, header restrictions | Add platform formatting notes: no markdown tables in Discord/WhatsApp (use bullets), suppress embeds with `<>` links, no headers in WhatsApp |
| B4 | AGENTS.md missing permission tiers | Warning | Check if AGENTS.md defines: safe actions (free to do), actions requiring permission, forbidden actions | Add permission tiers per official template: safe (explore, read, organize, web search), requires permission (emails, social posts, destructive commands), forbidden |
| B5 | HEARTBEAT.md is bloated (>500 chars) | Warning | `wc -c HEARTBEAT.md` | Trim to essential checks only. Rotate 2-4 checks daily instead of listing everything. Empty HEARTBEAT.md = OpenClaw skips heartbeat entirely (saves API calls) |
| B6 | MEMORY.md loaded in shared/group sessions | Critical | Check AGENTS.md for memory loading instructions — if it says "always load MEMORY.md" without restricting to private sessions | Update instruction: "Load MEMORY.md only in private main sessions. Do NOT load in shared or group contexts" |
| B7 | No "write to file" memory instruction in AGENTS.md | Warning | Check if AGENTS.md has explicit instruction about persisting knowledge to files | Add: "If you want to remember something, WRITE IT TO A FILE. Mental notes don't persist across sessions." (Official anti-pattern) |
| B8 | Responding-to-everything pattern not addressed | Info | Check if AGENTS.md or SOUL.md instructs the agent to respond to every message | Add group chat guidance: "Quality > quantity. Humans don't respond to every message; neither should you." |
| B9 | BOOT.md is too long (>500 chars) | Warning | `wc -c BOOT.md` (if it exists) | Trim to essential restart actions. BOOT.md runs on every gateway restart — keep it minimal |

### Category 5: USER.md Completeness

For each missing field, ask the user to provide the information interactively (one field at a time). Explain why each field improves agent behavior.

| # | Check | Severity | What to Look For | Why It Matters |
|---|---|---|---|---|
| U1 | Missing user name / preferred address | Warning | Name, nickname, "call me X" | Agent doesn't know how to address user naturally |
| U2 | Missing timezone / working hours | Warning | Timezone (e.g., America/New_York), active hours, quiet hours | Agent can't respect quiet hours, schedules at wrong times |
| U3 | Missing OS / platform | Info | macOS, Linux, Windows, architecture (ARM/Intel) | Agent gives wrong platform commands (apt vs brew, /opt/homebrew vs /usr/local) |
| U4 | Missing primary tools / editors | Info | Editor (VS Code, Vim), terminal, shell (zsh, bash), package manager | Agent can't tailor suggestions to user's actual tools |
| U5 | Missing communication style preference | Info | Concise vs detailed, formal vs casual, technical depth | Agent guesses tone instead of matching user's preference |
| U6 | Missing domain / work context | Info | What the user works on, job role, primary projects | Agent frames answers generically instead of in user's context |
| U7 | Missing channel preferences | Info | Which channels the user prefers, notification preferences | Agent doesn't know where/how to reach user effectively |
| U8 | Missing pet peeves / things to avoid | Info | "Don't use emojis", "don't be overly positive", "don't explain obvious things" | Preventable friction — user gets annoyed by avoidable patterns |

### Category 6: Token Efficiency

| # | Check | Severity | How to Report | Recommended Action |
|---|---|---|---|---|
| T1 | Total char count and estimated tokens across all files | Info | Sum all file sizes. Estimate tokens as chars/4 (rough approximation). Present as: "Your bootstrap files total X chars (~Y tokens). This is injected on every API call." | Awareness — no action needed unless total is high |
| T2 | Largest file with trimming opportunities | Info | Identify the largest file. Scan for: verbose explanations that could be condensed, examples that could be removed, redundant sections | Suggest specific trims with estimated savings |
| T3 | Redundant content across files | Warning | Content that appears in multiple files (not just overlapping instructions from O1, but also redundant context, repeated explanations) | Consolidate into the correct file; remove copies |
| T4 | Cron jobs feeding redundant custom systems | Warning | Check cron jobs for tasks that feed custom scripts (RAG pipelines, session archivers, memory indexers) which duplicate built-in OpenClaw features like `openclaw memory`. These burn API credits (embeddings) and cron compute for systems nobody queries. | Disable or remove the cron job. Archive the custom scripts. Verify the built-in system covers the same use case. |

---

## Workflow

### Step 1: Identify Gateway Access

Check the system profile to determine how to access the bootstrap files:

**If system profile exists:**
- Read the profile's Machines section
- If the current machine IS the gateway → read files locally from `~/.openclaw/workspace/`
- If the gateway is remote → use SSH: `ssh <user>@<host> "cat ~/.openclaw/workspace/<file>"`
- Use the profile's SSH access details (user, IP, Tailscale hostname)

**If no system profile exists:**
- Ask the user: "Where is your OpenClaw gateway running? On this machine or a remote server?"
- If remote: "What's the SSH command to access it? (e.g., `ssh user@hostname`)"
- If local: proceed with direct file reads

### Step 2: Collect All Bootstrap Files

Read each file and record its character count:

```bash
# Local gateway:
for f in SOUL.md IDENTITY.md AGENTS.md USER.md TOOLS.md HEARTBEAT.md MEMORY.md BOOT.md; do
  if [ -f ~/.openclaw/workspace/$f ]; then
    echo "$f: $(wc -c < ~/.openclaw/workspace/$f) chars"
  else
    echo "$f: NOT FOUND"
  fi
done

# Remote gateway:
ssh <user>@<host> 'for f in SOUL.md IDENTITY.md AGENTS.md USER.md TOOLS.md HEARTBEAT.md MEMORY.md BOOT.md; do
  if [ -f ~/.openclaw/workspace/$f ]; then
    echo "$f: $(wc -c < ~/.openclaw/workspace/$f) chars"
  else
    echo "$f: NOT FOUND"
  fi
done'
```

Then read the full content of each existing file.

### Step 3: Run the Checklist

Execute all 28 checks against the collected files:

1. Run Category 1 (Structural) — these are mechanical char-count checks
2. Run Category 2 (Content Placement) — read each file and check content against the "Should NOT Contain" column
3. Run Category 3 (Conflicts & Overlaps) — cross-reference all files for duplicates and contradictions
4. Run Category 4 (Best Practices) — check AGENTS.md against the official template requirements
5. Run Category 5 (USER.md Completeness) — check for missing fields
6. Run Category 6 (Token Efficiency) — compute totals and identify largest files

Record each finding with:
- Check ID (e.g., S1, C3, O2)
- Severity (Critical, Warning, Info)
- File(s) involved
- Specific excerpt from the file (the exact text that triggered the finding)
- Recommended fix

Skip checks that don't apply (e.g., don't check MEMORY.md rules if MEMORY.md doesn't exist).

### Step 4: Present Findings Summary

Show the user a summary before diving into details:

```
## Identity Audit Results

**Files scanned:** 6 of 8 (BOOT.md and MEMORY.md not found)
**Total bootstrap size:** 34,218 chars (~8,554 tokens per API call)

**Findings:** 2 critical, 4 warnings, 6 info

### Critical
- O2: SOUL.md says "be concise" but AGENTS.md says "always explain in detail"
- C5: SOUL.md contains a TODO list (lines 45-52)

### Warnings
- C1: Personality directives found in AGENTS.md (lines 12-15) — belongs in SOUL.md
- O1: "Be respectful and professional" duplicated in SOUL.md and AGENTS.md
- B1: AGENTS.md missing memory management instructions
- B4: AGENTS.md missing permission tiers

### Info
- U3: USER.md missing OS/platform
- U5: USER.md missing communication style preference
- ... (remaining info items)

I'll walk you through each finding starting with the critical issues. For each one I'll show you the problem, why it matters, and the proposed fix. You can approve, modify, or skip each one.

Ready to start?
```

### Step 5: Issue-by-Issue Walkthrough (Collect Phase)

Walk through each finding for the user to approve, modify, or skip. **Do NOT apply changes yet** — collect all decisions first.

For each finding (critical first, then warnings, then info):

**Present the issue:**
```
### Finding O2 (Critical): Contradicting Directives

**Files:** SOUL.md (line 8) + AGENTS.md (line 23)

**SOUL.md says:**
> "Keep responses brief and to the point. Value conciseness."

**AGENTS.md says:**
> "Always provide detailed, step-by-step explanations for every task."

**Why this matters:** The model receives both instructions in its system prompt and has to choose which to follow. This creates inconsistent behavior — sometimes brief, sometimes verbose, unpredictably.

**Proposed fix:** Keep the conciseness directive in SOUL.md (it's a personality trait). Update AGENTS.md to align:

**Before (AGENTS.md line 23):**
> "Always provide detailed, step-by-step explanations for every task."

**After:**
> "Provide step-by-step explanations when the task is complex or the user asks for detail. Default to concise responses per SOUL.md."

**[Approve / Modify / Skip]?**
```

**For USER.md completeness items**, ask for the missing info:
```
### Finding U2 (Warning): Missing Timezone / Working Hours

Your USER.md doesn't mention your timezone or working hours. Adding this helps the agent:
- Respect quiet hours (no heartbeat messages at 3 AM)
- Schedule cron jobs appropriately
- Know when you're likely available

**What's your timezone?** (e.g., America/New_York, Europe/London)
**What are your typical working hours?** (e.g., 9 AM - 6 PM)
```

**Batching:** If there are 5+ Info-severity items that are simple (pure duplicates, minor gaps), batch them:
```
### Info Items (batch) — 5 minor findings

These are low-priority. I can apply them all, or walk through individually:

1. U3: Add OS/platform to USER.md (macOS, Apple Silicon)
2. U4: Add primary tools to USER.md (VS Code, zsh)
3. U7: Add channel preferences to USER.md
4. T1: Total bootstrap: 34K chars (~8.5K tokens/call)
5. B3: Add WhatsApp formatting note to AGENTS.md

**[Apply all / Walk through individually / Skip all]?**
```

### Step 5b: Confirm Change Plan

After all findings have been reviewed, present a consolidated change plan per file:

```
## Approved Changes — Ready to Apply

**SOUL.md** (3 changes):
1. [O2] Remove contradicting directive on line 23
2. [C2] Move Todoist protocol (lines 45-80) to AGENTS.md
3. [C3] Remove redundant name declaration (line 3)

**AGENTS.md** (2 changes):
1. [O2] Update explanation directive to align with SOUL.md
2. [C2] Add Todoist protocol from SOUL.md

**USER.md** (2 changes):
1. [U2] Add timezone and working hours
2. [U3] Add OS/platform

**No changes:** TOOLS.md, MEMORY.md, IDENTITY.md

Proceed with all approved changes? [Yes / Review again]
```

This gives the user one final confirmation before any files are touched, prevents redundant edits to the same file, and ensures nothing was lost during the walkthrough.

### Step 6: Apply All Approved Changes (Batch)

Apply all approved changes in a single pass per file:

1. **Create dated backups** of ALL files being modified (one backup each):
   ```bash
   # Local:
   for f in SOUL.md AGENTS.md USER.md; do
     cp ~/.openclaw/workspace/$f ~/.openclaw/workspace/$f.YYYY-MM-DD-identity-audit
   done

   # Remote:
   ssh <user>@<host> 'for f in SOUL.md AGENTS.md USER.md; do
     cp ~/.openclaw/workspace/$f ~/.openclaw/workspace/$f.YYYY-MM-DD-identity-audit
   done'
   ```

2. **Apply all changes per file** — write the complete updated version of each file (do not make multiple sequential edits to the same file):
   ```bash
   # Write the complete new version of each file in one operation.
   # This avoids editing the same file multiple times.
   ```

3. **Show confirmation** after all files are updated:
   ```
   Files updated:
   - SOUL.md (3 changes applied)
   - AGENTS.md (2 changes applied)
   - USER.md (2 changes applied)

   Backups:
   - ~/.openclaw/workspace/SOUL.md.2026-02-25-identity-audit
   - ~/.openclaw/workspace/AGENTS.md.2026-02-25-identity-audit
   - ~/.openclaw/workspace/USER.md.2026-02-25-identity-audit
   ```

### Step 7: Post-Audit Summary

After all findings are processed:

```
## Identity Audit Complete

**Changes applied:** 4 of 8 findings
**Skipped:** 2 (user chose to skip)
**Deferred:** 2 (info items, no action needed)

**Token impact:**
- Before: 34,218 chars (~8,554 tokens/call)
- After: 31,450 chars (~7,862 tokens/call)
- Saved: 2,768 chars (~692 tokens/call)

**Backups created:**
- ~/.openclaw/workspace/SOUL.md.2026-02-25-identity-audit
- ~/.openclaw/workspace/AGENTS.md.2026-02-25-identity-audit
- ~/.openclaw/workspace/USER.md.2026-02-25-identity-audit

**Restart recommended:** Changes to bootstrap files take effect on the next session.
For immediate effect: `launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway`
(or start a new session with `/new`)
```

Update the system profile's issue log with what was done.

---

## Sources

- [Agent Workspace - OpenClaw](https://docs.openclaw.ai/concepts/agent-workspace) — workspace layout, file roles, bootstrap file list
- [Agent Bootstrapping - OpenClaw](https://docs.openclaw.ai/start/bootstrapping) — first-run ritual
- [System Prompt - OpenClaw](https://docs.openclaw.ai/concepts/system-prompt) — injected files list, prompt modes (full/minimal/none), truncation behavior, sub-agent filtering
- [Context - OpenClaw](https://docs.openclaw.ai/concepts/context) — context window, `/context list` and `/context detail`, bootstrap size limits
- [Token Use and Costs - OpenClaw](https://docs.openclaw.ai/reference/token-use) — bootstrap file injection list (confirms MEMORY.md), token estimation, cache behavior
- [Compaction - OpenClaw](https://docs.openclaw.ai/concepts/compaction) — auto-compaction, memory flush
- [AGENTS.md Template - OpenClaw](https://docs.openclaw.ai/reference/templates/AGENTS)
- [Configuration Reference - OpenClaw](https://docs.openclaw.ai/gateway/configuration-reference)
