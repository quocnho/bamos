# Retro — Sprint 1: ISO GNOME Standard Bootable

**Date:** 2026-07-03
**Participants:** 1 dev + AI

---

## 🤖 AI-Human Collaboration Score (1-10)

| Dimension | Score | Notes |
|-----------|-------|-------|
| AI code quality | 8 | Good Nix code, caught GLF-OS patterns well |
| Human review efficiency | 9 | Quick decisions, clear direction |
| Prompt quality | 8 | Specific requirements helped AI execute |

---

## 🌟 What Went Well

### AI Excelled At
- Research: caught nixos-generators deprecated, found GLF-OS patterns
- Nix boilerplate: disko config, flake-parts modules, systemd services
- Audit: systematic gap analysis codebase vs idea.md
- Git workflow: proper branching, conventional commits, merge strategy

### Human Excelled At
- Architecture decisions: LTS kernel for ISO, Zen for installed OS
- Strategic direction: dual-kernel, binary cache, ISO naming
- Quick validation: caught hardcoded hostname issue, directed fixes

### Process
- Refine→Plan→Validate→Execute workflow kept things on track
- Per-sprint directory structure preserved full history
- Daily scrum provided clear context for each session

---

## 📉 What Could Be Improved

### AI Weaknesses
- ISO build iteration took many tries (ZFS kernel issue)
- Calamares module had invalid NixOS options (needs better nixpkgs knowledge)
- ISO file accidentally committed to git twice (3.2GB)

### Human Bottlenecks
- No KVM for QEMU testing (US-003-06 pending)

### Process Gaps
- Cachix setup deferred (need auth token from cachix.org)
- CI/CD not fully tested (needs GitHub push)

---

## 🔧 Actions for Sprint 2

| # | Action | Type | Priority |
|---|--------|------|----------|
| 1 | Test ISO in QEMU (US-003-06) | Tech | High |
| 2 | Create Cachix cache + add token to GitHub Secrets | DevOps | High |
| 3 | Reduce ISO size < 2.5GB | Tech | Medium |
| 4 | Add Vietnamese fonts (Noto Sans VN) | Tech | Medium |
| 5 | KDE Plasma + Standard apps | Feature | High |
| 6 | Calamares custom branding | Feature | Medium |
