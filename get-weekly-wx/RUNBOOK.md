# RUNBOOK: get-weekly-wx

## Metadata

| Field | Value |
|---|---|
| **Owner** | Kevin Inscoe |
| **Last Updated** | 2026-05-29 |
| **Last Tested** | 2026-05-29 |
| **Expected Duration** | ~2 min per run |
| **Risk Level** | Low |
| **Repo** | https://github.com/kevinpinscoe/kevins-opinionated-skills |

---

## Purpose

Runs the `get-weekly-wx` Claude Code skill every Sunday at 7:00 AM and 7:00 PM local time. The skill fetches WEATHERAmerica forecast posts from the public Google Groups page and writes three WX forecast Markdown files to the `WX/` subdirectory of the Personal Journal Obsidian vault. Each output file includes a source attribution footer linking back to the WEATHERAmerica Google Group.

The timer fires twice because WEATHERAmerica posts have been arriving later and later on Sundays — sometimes not until mid-day. The 7am run captures early posts; the 7pm run picks up anything that came in after the morning window.

---

## When to Use This Runbook

- **Use when:** Installing or reinstalling the skill; debugging a missed Sunday run; triggering a manual run; reading logs.
- **Do NOT use when:** The vault WX files are stale but the timer ran fine — the upstream newsletter may not have been sent that week.

---

## File Layout

Canonical files live in the repo:

```
~/Projects/public/kevins-opinionated-skills/get-weekly-wx/
  SKILL.md                     ← Claude Code skill instructions
  get-weekly-wx-wrapper.sh     ← shell script that invokes claude -p
  get-weekly-wx.service        ← systemd oneshot service unit
  get-weekly-wx.timer          ← systemd timer unit
  RUNBOOK.md                   ← this file
  install.sh                   ← one-command install script
```

**Deployed symlink structure:**

```
~/ai/fedora/get-weekly-wx/                        ← real directory (not a symlink)
  SKILL.md              →  repo/get-weekly-wx/SKILL.md
  get-weekly-wx-wrapper.sh  →  repo/get-weekly-wx/get-weekly-wx-wrapper.sh
  get-weekly-wx.service →  repo/get-weekly-wx/get-weekly-wx.service
  get-weekly-wx.timer   →  repo/get-weekly-wx/get-weekly-wx.timer
  RUNBOOK.md            →  repo/get-weekly-wx/RUNBOOK.md

~/.config/systemd/user/get-weekly-wx.service  →  ~/ai/fedora/get-weekly-wx/get-weekly-wx.service
~/.config/systemd/user/get-weekly-wx.timer    →  ~/ai/fedora/get-weekly-wx/get-weekly-wx.timer
~/.local/bin/get-weekly-wx-wrapper.sh         →  repo/get-weekly-wx/get-weekly-wx-wrapper.sh
```

`~/ai/fedora/get-weekly-wx/` is a **real directory** containing individual file symlinks. The `~/ai` repo tracks these symlinks. The canonical files live in this repo — edit them here, not in `~/ai/fedora/`.

---

## Prerequisites

- [ ] `~/.local/bin/claude` installed (Claude Code CLI)
- [ ] Linger enabled: `loginctl show-user kinscoe | grep Linger` — if `Linger=no`: `sudo loginctl enable-linger kinscoe`
- [ ] Obsidian vault at `~/Journal/Personal Journal/WX/` exists

---

## Stack

| Component | Details |
|---|---|
| **Runtime** | `claude --dangerously-skip-permissions -p` |
| **Systemd mode** | User unit (`systemctl --user`) — runs as `kinscoe` |
| **Data source** | WEATHERAmerica Google Groups public page (WebFetch) |
| **Output** | `~/Journal/Personal Journal/WX/` |

---

## Installation

Run the install script from this skill's directory:

```bash
bash ~/Projects/public/kevins-opinionated-skills/get-weekly-wx/install.sh
```

The script:
1. Converts any legacy `~/ai/fedora/get-weekly-wx` directory symlink to a real directory
2. Creates individual file symlinks inside it pointing back to this repo
3. Symlinks the systemd units into `~/.config/systemd/user/`
4. Symlinks the wrapper script into `~/.local/bin/`
5. Runs `systemctl --user daemon-reload`

Then enable the timer:

```bash
systemctl --user enable --now get-weekly-wx.timer
```

---

## Enable / Disable

| Action | Command |
|---|---|
| Enable timer (survives reboot) | `systemctl --user enable get-weekly-wx.timer` |
| Disable timer | `systemctl --user disable get-weekly-wx.timer` |
| Stop and disable in one step | `systemctl --user disable --now get-weekly-wx.timer` |

---

## Start / Stop

| Action | Command |
|---|---|
| Start timer | `systemctl --user start get-weekly-wx.timer` |
| Stop timer | `systemctl --user stop get-weekly-wx.timer` |
| Run job immediately (one-shot) | `systemctl --user start get-weekly-wx.service` |

---

## Next Scheduled Trigger

```bash
systemctl --user list-timers get-weekly-wx.timer
```

---

## Health Check

```bash
systemctl --user status get-weekly-wx.timer
systemctl --user status get-weekly-wx.service
```

A successful one-shot run exits with code `0` and shows `inactive (dead)` — that is normal for `Type=oneshot`.

---

## Logs

```bash
# Most recent run
journalctl --user -u get-weekly-wx.service -n 50

# Follow live output during a manual run
journalctl --user -u get-weekly-wx.service -f &
systemctl --user start get-weekly-wx.service

# All historical runs
journalctl --user -u get-weekly-wx.service --no-pager

# Specific date range
journalctl --user -u get-weekly-wx.service --since "2026-04-13" --until "2026-04-14"
```

---

## Verification

```bash
systemctl --user list-timers get-weekly-wx.timer
```

**Success criteria:** Timer listed with a NEXT trigger time. A completed one-shot exits with code `0`.

---

## Troubleshooting

| Symptom | Likely Cause | Resolution |
|---|---|---|
| WX files contain "No forecast guidance" | No WEATHERAmerica posts within the last 7 days | Normal if no newsletter was sent; check `https://groups.google.com/g/weatheramerica` manually |
| Timer not firing | Machine was off at 7:00 AM Sunday | `Persistent=true` fires once on next login; check with `list-timers` |
| Claude CLI not found | Path issue in non-interactive shell | Confirm `~/.local/bin/claude` exists |
| Systemd unit shows "Failed to load" | Symlink chain broken | Re-run `install.sh`; verify all links (see File Layout above) |
| Linger not enabled | Timer stops when session ends | `sudo loginctl enable-linger kinscoe` |

---

## Related Runbooks

- [`../RUNBOOK.md`](../RUNBOOK.md) — root runbook for this skills collection
- `~/ai/fedora/RUNBOOK.md` — Fedora workstation automation overview

---

## Maintenance Notes

- **Last game-day test:** 2026-05-29
- **Next scheduled review:** When WEATHERAmerica Google Groups URL changes
- **Known drift risks:** All three links in the chain (`~/.config/systemd/user/` → `~/ai/fedora/get-weekly-wx/` → repo) must exist. Re-run `install.sh` to restore any broken link.
