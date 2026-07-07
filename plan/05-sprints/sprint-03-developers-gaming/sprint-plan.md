# AI Sprint 3: Developers + Gaming Editions

**Status:** 🔴 Planned
**Dates:** TBD (after Sprint 2)
**Git Branch:** `sprint/03/developers-gaming`
**Target Release:** v0.3.0
**Capacity:** ~35 SP (AI-augmented)

---

## Sprint Goal (SMART)
**Hoàn thiện Developers Edition (devenv + Podman) và Gaming Edition (Steam + Proton + GameScope) — ISO GNOME Dev + GNOME Gaming.**

---

## Sprint Backlog

| ID | Story | AI? | SP | Status |
|----|-------|-----|-----|--------|
| US-005-03 | Developers Edition (devenv + Podman + dev tools) | ✅ | 8 | 🔴 Planned |
| US-005-07 | Distrobox container management | ✅ | 3 | 🔴 Planned |
| US-005-04 | Gaming Edition (Steam + Proton + GameScope) | ✅ | 8 | 🔴 Planned |
| US-005-06 | Gaming stream tools (MangoHud + OBS + Discord) | ✅ | 5 | 🔴 Planned |
| US-005-08 | VN input method in Dev + Gaming profiles | ✅ | 2 | 🔴 Planned |
| — | Build ISO GNOME Developers | ✅ | 5 | 🔴 Planned |
| — | Build ISO GNOME Gaming | ✅ | 5 | 🔴 Planned |
| — | Test both ISOs in QEMU | ✅ | 3 | 🔴 Planned |

**Total:** ~39 SP (may split to Sprint 3a + 3b)

---

## Dependencies
- 🔄 Sprint 2 must be complete (`mkEdition` helper, KDE infrastructure)
- 🔄 Sprint 1 ISO pipeline must be stable

## Day-by-Day (Draft)
| Day | Focus |
|-----|-------|
| 1 | Developers Edition: devenv config, Podman module |
| 2 | Developers Edition: dev tools (editor, terminal, git), Distrobox |
| 3 | Gaming Edition: Steam + Proton + ProtonGE overlay |
| 4 | Gaming Edition: GameScope + MangoHud + OBS + Discord |
| 5 | Build + test both ISOs, release v0.3.0 |
