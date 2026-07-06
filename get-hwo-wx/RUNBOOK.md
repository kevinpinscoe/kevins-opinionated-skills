---
title: RUNBOOK: get-hwo-wx
tags: [runbook, operations]
vault_link: runbooks/home-kinscoe-projects-public-kevins-opinionated-skills-get-hwo-wx.md
source_path: /home/kinscoe/Projects/public/kevins-opinionated-skills/get-hwo-wx/RUNBOOK.md
---

> 📓 Indexed in the PKM knowledge vault at `runbooks/home-kinscoe-projects-public-kevins-opinionated-skills-get-hwo-wx.md` (symlink → this file).
# RUNBOOK: get-hwo-wx

## Metadata

| Field | Value |
|---|---|
| **Owner** | Kevin Inscoe |
| **Last Updated** | 2026-05-29 |
| **Last Tested** | 2026-05-29 |
| **Expected Duration** | ~1 min per run |
| **Risk Level** | Low |
| **Repo** | https://github.com/kevinpinscoe/kevins-opinionated-skills |

---

## Purpose

Fetches the **Hazardous Weather Outlook (HWO)** issued by the National Weather Service office in Morristown TN (MRX) from:

    https://forecast.weather.gov/product.php?site=NWS&issuedby=MRX&product=HWO&format=txt&version=1&glossary=0

The skill parses the plain-text product and writes formatted Markdown to `WX/WX-HAZARD.md` in the personal-journal vault. It commits and pushes only when the content has changed. If the content is unchanged the file is left untouched and no commit is made.

Runs every 4 hours (00:00, 04:00, 08:00, 12:00, 16:00, 20:00) via a systemd user timer.

---

## When to Use This Runbook

- **Use when:** Installing or reinstalling the skill; debugging a missed run; triggering a manual run; reading logs.
- **Do NOT use when:** The HWO content looks stale but the timer ran — the NWS may not have issued a new product yet.

---

## File Layout

Canonical files live in the repo:

```
~/Projects/public/kevins-opinionated-skills/get-hwo-wx/
  SKILL.md                     ← Claude Code skill instructions
  get-hwo-wx-wrapper.sh        ← shell script that invokes claude -p
  get-hwo-wx.service           ← systemd oneshot service unit
  get-hwo-wx.timer             ← systemd timer unit
  RUNBOOK.md                   ← this file
  install.sh                   ← one-command install script
```

**Deployed symlink structure:**

```
~/ai/fedora/wx-get-mrx-hwo/                       ← real directory (not a symlink)
  SKILL.md              →  repo/get-hwo-wx/SKILL.md
  get-hwo-wx-wrapper.sh →  repo/get-hwo-wx/get-hwo-wx-wrapper.sh
  get-hwo-wx.service    →  repo/get-hwo-wx/get-hwo-wx.service
  get-hwo-wx.timer      →  repo/get-hwo-wx/get-hwo-wx.timer
  RUNBOOK.md            →  repo/get-hwo-wx/RUNBOOK.md

~/.config/systemd/user/get-hwo-wx.service  →  ~/ai/fedora/wx-get-mrx-hwo/get-hwo-wx.service
~/.config/systemd/user/get-hwo-wx.timer    →  ~/ai/fedora/wx-get-mrx-hwo/get-hwo-wx.timer
~/.local/bin/get-hwo-wx-wrapper.sh         →  repo/get-hwo-wx/get-hwo-wx-wrapper.sh
```

`~/ai/fedora/wx-get-mrx-hwo/` is a **real directory** containing individual file symlinks. The `~/ai` repo tracks these symlinks. The canonical files live in this repo — edit them here, not in `~/ai/fedora/`.

The `~/ai/fedora/wx-get-mrx-hwo` directory name is preserved from the original skill name (`wx-get-mrx-hwo`) to keep existing systemd symlinks valid.

---

## Prerequisites

- [ ] `~/.local/bin/claude` installed (Claude Code CLI)
- [ ] Linger enabled: `loginctl show-user kinscoe | grep Linger` — if `Linger=no`: `sudo loginctl enable-linger kinscoe`
- [ ] Obsidian vault at `~/Journal/personal-journal/WX/` exists and is a git repo

---

## Stack

| Component | Notes |
|---|---|
| **Runtime** | `claude --dangerously-skip-permissions -p` |
| **Data fetch** | `WebFetch` tool inside the Claude skill |
| **Systemd mode** | User unit (`systemctl --user`) — runs as `kinscoe` |
| **Output** | `~/Journal/personal-journal/WX/WX-HAZARD.md` |

No curl, Python, or pip packages required.

---

## Installation

Run the install script:

```bash
bash ~/Projects/public/kevins-opinionated-skills/get-hwo-wx/install.sh
```

The script:
1. Converts any legacy `~/ai/fedora/wx-get-mrx-hwo` directory symlink to a real directory
2. Creates individual file symlinks inside it pointing back to this repo
3. Symlinks the systemd units into `~/.config/systemd/user/`
4. Symlinks the wrapper script into `~/.local/bin/`
5. Runs `systemctl --user daemon-reload`

Then enable the timer:

```bash
systemctl --user enable --now get-hwo-wx.timer
```

---

## Enable / Disable

| Action | Command |
|---|---|
| Enable timer (survives reboot) | `systemctl --user enable get-hwo-wx.timer` |
| Disable timer | `systemctl --user disable get-hwo-wx.timer` |

---

## Start / Stop

| Action | Command |
|---|---|
| Start timer | `systemctl --user start get-hwo-wx.timer` |
| Stop timer | `systemctl --user stop get-hwo-wx.timer` |
| Run job immediately (one-shot) | `systemctl --user start get-hwo-wx.service` |

---

## Next Scheduled Trigger

```bash
systemctl --user list-timers get-hwo-wx.timer
```

---

## Health Check

```bash
systemctl --user status get-hwo-wx.timer
systemctl --user status get-hwo-wx.service
```

A successful one-shot run exits with code `0` and shows `inactive (dead)` — that is normal for `Type=oneshot`.

---

## Logs

```bash
# Most recent run
journalctl --user -u get-hwo-wx.service -n 50

# Follow live output during a manual run
journalctl --user -u get-hwo-wx.service -f &
systemctl --user start get-hwo-wx.service

# All historical runs (newest first)
journalctl --user -u get-hwo-wx.service --reverse
```

---

## Troubleshooting

### "No change detected" but the HWO looks stale

The content matches what was last committed. The NWS may not have issued a new HWO yet. Check the issuance timestamp in `WX/WX-HAZARD.md`.

### Upstream URL returns no content

```bash
curl -s "https://forecast.weather.gov/product.php?site=NWS&issuedby=MRX&product=HWO&format=txt&version=1&glossary=0" | head -30
```

If empty, the NWS API may be temporarily unavailable. The timer will retry at the next 4-hour interval.

### Timer not firing after a reboot

Ensure linger is enabled:

```bash
loginctl show-user kinscoe | grep Linger
# If "Linger=no":
sudo loginctl enable-linger kinscoe
```

### Unit files updated in the repo but changes not taking effect

```bash
systemctl --user daemon-reload
systemctl --user restart get-hwo-wx.timer
```

### Systemd unit shows "Failed to load"

Verify the full symlink chain (see File Layout above):

```bash
ls -la ~/.config/systemd/user/get-hwo-wx.*
ls -la ~/ai/fedora/wx-get-mrx-hwo/
```

If anything is broken, re-run `install.sh`.

---

## Related Runbooks

- [`../RUNBOOK.md`](../RUNBOOK.md) — root runbook for this skills collection
- `~/ai/fedora/RUNBOOK.md` — Fedora workstation automation overview

---

## Maintenance Notes

- **Last game-day test:** 2026-05-29
- **Next scheduled review:** When NWS product URL changes
- **Known drift risks:** All three links in the chain (`~/.config/systemd/user/` → `~/ai/fedora/wx-get-mrx-hwo/` → repo) must exist. Re-run `install.sh` to restore any broken link.
