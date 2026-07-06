---
title: RUNBOOK.md — Kevin's Opinionated Skills
tags: [runbook, operations]
vault_link: runbooks/home-kinscoe-projects-public-kevins-opinionated-skills.md
source_path: /home/kinscoe/Projects/public/kevins-opinionated-skills/RUNBOOK.md
---

> 📓 Indexed in the PKM knowledge vault at `runbooks/home-kinscoe-projects-public-kevins-opinionated-skills.md` (symlink → this file).
# RUNBOOK.md — Kevin's Opinionated Skills

## Metadata

| Field | Value |
|---|---|
| **Owner** | Kevin Inscoe |
| **Last Updated** | 2026-05-29 |
| **Last Tested** | 2026-05-29 |
| **Expected Duration** | N/A — collection of automated skills |
| **Risk Level** | Low |
| **Repo** | https://github.com/kevinpinscoe/kevins-opinionated-skills |

---

## Purpose

This runbook covers the `kevins-opinionated-skills` repository — a collection of reusable Claude Code skill definitions, each with supporting systemd units and wrapper scripts. Each skill runs Claude Code non-interactively (`claude -p --dangerously-skip-permissions`) via a systemd user timer.

The canonical source for all skill files is this repo. Skills are deployed through a symlink structure rooted in `~/ai/fedora/` — see below.

---

## When to Use This Runbook

- **Use when:** Getting oriented in this repo; installing all skills on a new or restored machine; understanding the `~/ai/fedora/` symlink structure.
- **Do NOT use when:** Operating a specific skill — go to that skill's own `RUNBOOK.md`.

---

## Repository Layout

```
kevins-opinionated-skills/
  RUNBOOK.md                     ← this file
  README.md
  CLAUDE.md
  get-weekly-wx/
    SKILL.md
    get-weekly-wx-wrapper.sh
    get-weekly-wx.service
    get-weekly-wx.timer
    RUNBOOK.md                   ← skill-level runbook
    install.sh                   ← creates ~/ai/fedora entry and all symlinks
  get-hwo-wx/
    SKILL.md
    get-hwo-wx-wrapper.sh
    get-hwo-wx.service
    get-hwo-wx.timer
    RUNBOOK.md                   ← skill-level runbook
    install.sh                   ← creates ~/ai/fedora entry and all symlinks
```

---

## ~/ai/fedora Symlink Structure

Each skill's `install.sh` creates a **real directory** under `~/ai/fedora/` containing individual file symlinks that point back into this repo. The `~/ai` repo tracks these symlinks. Systemd unit symlinks in `~/.config/systemd/user/` chain through `~/ai/fedora/` to the repo.

```
~/ai/fedora/get-weekly-wx/               ← real directory
  *.service / *.timer / SKILL.md  →  this repo / get-weekly-wx/

~/ai/fedora/wx-get-mrx-hwo/             ← real directory (legacy name preserved)
  *.service / *.timer / SKILL.md  →  this repo / get-hwo-wx/

~/.config/systemd/user/get-weekly-wx.*  →  ~/ai/fedora/get-weekly-wx/
~/.config/systemd/user/get-hwo-wx.*     →  ~/ai/fedora/wx-get-mrx-hwo/
~/.local/bin/*-wrapper.sh               →  this repo / {skill}/
```

**The canonical files live in this repo.** Never edit files in `~/ai/fedora/` directly — they are symlinks and changes will appear to stick but point at the repo copy.

---

## Skill Index

| Skill | Directory | Runbook | Schedule | Description |
|---|---|---|---|---|
| get-weekly-wx | [get-weekly-wx/](get-weekly-wx/) | [RUNBOOK.md](get-weekly-wx/RUNBOOK.md) | Sundays 07:00 | Fetches WEATHERAmerica Sunday forecast posts and writes WX files to the Obsidian vault |
| get-hwo-wx | [get-hwo-wx/](get-hwo-wx/) | [RUNBOOK.md](get-hwo-wx/RUNBOOK.md) | Every 4 hours | Fetches NWS Hazardous Weather Outlook (MRX office) and writes WX-HAZARD.md |

---

## Prerequisites

- [ ] `~/.local/bin/claude` installed (Claude Code CLI)
- [ ] Linger enabled for user `kinscoe`:
  ```bash
  loginctl show-user kinscoe | grep Linger
  # If "Linger=no":
  sudo loginctl enable-linger kinscoe
  ```
- [ ] Obsidian vault at `~/Journal/personal-journal/WX/` exists

---

## Installing All Skills

Run each skill's `install.sh`, then enable its timer:

```bash
bash ~/Projects/public/kevins-opinionated-skills/get-weekly-wx/install.sh
systemctl --user enable --now get-weekly-wx.timer

bash ~/Projects/public/kevins-opinionated-skills/get-hwo-wx/install.sh
systemctl --user enable --now get-hwo-wx.timer
```

Each `install.sh` is idempotent — safe to re-run to repair broken symlinks.

---

## Logs (all skills at a glance)

```bash
journalctl --user -u get-weekly-wx.service -n 20
journalctl --user -u get-hwo-wx.service -n 20
```

---

## Troubleshooting

| Symptom | Likely Cause | Resolution |
|---|---|---|
| Timer not firing after reboot | Linger not enabled | `sudo loginctl enable-linger kinscoe` |
| Claude CLI not found | `~/.local/bin` not in PATH in non-interactive shell | Verify wrapper script PATH; confirm `~/.local/bin/claude` exists |
| Systemd unit shows "Failed to load" | Symlink chain broken | Re-run the skill's `install.sh` |

---

## Related Runbooks

- [get-weekly-wx/RUNBOOK.md](get-weekly-wx/RUNBOOK.md) — Sunday weather forecast skill
- [get-hwo-wx/RUNBOOK.md](get-hwo-wx/RUNBOOK.md) — Hazardous weather outlook skill
- `~/ai/fedora/RUNBOOK.md` — Fedora workstation automation overview

---

## Maintenance Notes

- **Last game-day test:** 2026-05-29
- **Next scheduled review:** When a new skill is added to this collection
- **Known drift risks:** If `~/ai/fedora/` entries are removed or become real files, systemd units will break. Re-run `install.sh` for each affected skill to restore the chain.
