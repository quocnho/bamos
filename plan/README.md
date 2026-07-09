# 🧭 Project Plan — Navigation Hub

> **Last Updated:** 2026-07-09
> **Project Phase:** 🟢 Execution — Sprint 6 Active
> **Current Sprint:** [Sprint 6: Unified Calamares Installer](05-sprints/sprint-06-unified-installer/)

---

## Status Overview

| Section | Purpose | Status |
|---------|---------|--------|
| [01 — Lean Canvas](01-lean-canvas/) | 9 building blocks of the business model | 🟢 Complete |
| [02 — Mission & Scope](02-mission-scope/) | Mission statement and project boundaries | 🟢 Complete |
| [03 — Roadmap](03-roadmap/) | Technical roadmap (7 phases) and milestones | 🟢 Complete |
| [04 — Backlog](04-backlog/) | Epics (8), user stories (24), ICE scoring | 🟢 Complete |
| [05 — Sprints](05-sprints/) | [📊 Sprint Dashboard](05-sprints/README.md) — all sprints at a glance | 🔄 Sprint 6 Active |
| [06 — Tech Refs](06-tech-refs/) | Technology stack assessment + pending research | 🟡 Draft |
| [07 — Increment](07-increment/) | Release notes and delivered increments | 🟡 Draft |

---

## Quick Navigation

1. **Start here** → [01 — Lean Canvas](01-lean-canvas/) — Hiểu problem, solution, market
2. **Big picture** → [02 — Mission & Scope](02-mission-scope/) — Mission + MVP definition
3. **Journey** → [03 — Roadmap](03-roadmap/) — 7 phases với milestones chi tiết
4. **Now** → [05 — Sprint Dashboard](05-sprints/README.md) — 🔥 Tất cả sprints trong một glance
5. **Today** → [Sprint 1 Daily Scrum](05-sprints/sprint-01-iso-gnome-standard/daily-scrum/) — Việc cần làm hôm nay
6. **Details** → [04 — Backlog](04-backlog/) — 24 user stories đã được ICE-scored
7. **Stack** → [06 — Tech Refs](06-tech-refs/) — Technology rationale & key decisions
8. **Releases** → [07 — Increment](07-increment/) — Release notes

---

## Current Sprint at a Glance

**Sprint 6: Unified Calamares Installer** (2026-07-07 → TBD)
- 🎯 Goal: Unified installer với edition + machine type selector
- 📊 Status: 🟡 Active
- 📋 [Full plan](05-sprints/sprint-06-unified-installer/sprint-plan.md)

**Sprint 5: Auto-Detect Hardware + Theming** — ✅ Complete!

---

## Sprint Roadmap

| Sprint | Goal | Dates | SP | Status |
|--------|------|-------|-----|--------|
| [Sprint 1](05-sprints/sprint-01-iso-gnome-standard/) | ISO GNOME Standard bootable | 07-03 → 07-03 | 34/37 | 🟢 Done |
| [Sprint 2](05-sprints/sprint-02-kde-standard-apps/) | KDE Plasma + Standard apps | 07-04 → 07-04 | 30 | 🟢 Done |
| [Sprint 3](05-sprints/sprint-03-developers-gaming/) | Developers + Gaming editions | 07-05 → 07-05 | 35 | 🟢 Done |
| [Sprint 4](05-sprints/sprint-04-cosmic-studio/) | COSMIC + Studio edition | 07-06 → 07-06 | 35 | 🟢 Done |
| [Sprint 5](05-sprints/sprint-05-auto-detect-theming/) | Auto-Detect + RakuOS Theming | 07-06 → TBD | — | 🟢 Done |
| [Sprint 6](05-sprints/sprint-06-unified-installer/) | Unified Calamares Installer | 07-07 → TBD | — | 🟡 Active |

---

## Status Legend
- 🔄 Active — đang thực hiện
- 🔴 Planned — đã scoped, chưa bắt đầu
- ⚫ Idea — chưa scoped
- 🟢 Done — hoàn thành
- 🟡 Draft — đang viết
- ❌ Cancelled

---

## For Team Members (1 dev + AI)

| Role | Maintain | Daily Task |
|------|----------|------------|
| **Product Owner** | `02-mission-scope/`, `04-backlog/` | Prioritize stories, update ICE scores |
| **Scrum Master** | `05-sprints/README.md` (dashboard) | Track velocity, facilitate reviews |
| **Developer + AI** | `05-sprints/sprint-NN/` | Code stories, update daily scrum |
| **Architect** | `03-roadmap/`, `06-tech-refs/` | Validate architecture decisions |

## Git Workflow

```bash
# Start sprint → branch
git checkout -b sprint/01/iso-gnome-standard master

# Daily commits → map to stories
git commit -m "feat(US-003-01): add nixos-generators ISO config"

# End sprint → merge + tag
git checkout master
git merge sprint/01/iso-gnome-standard
git tag v0.1.0
```
