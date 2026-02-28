# Changelog

All notable changes to the OpenClaw Optimizer skill are documented here.

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
