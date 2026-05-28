# RUNBOOK: get-weekly-wx Systemd Timer

This service runs the `get-weekly-wx` Claude Code skill every Sunday at 7:00 AM local time. It fetches WEATHERAmerica forecast posts from the public Google Groups page and writes the three WX forecast files into `WX/`.

---

## Installation (one-time setup)

Copy the unit files to your systemd user directory and enable the timer:

```bash
cp get-weekly-wx.service ~/.config/systemd/user/
cp get-weekly-wx.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable get-weekly-wx.timer
systemctl --user start get-weekly-wx.timer
```

To confirm the timer is active:

```bash
systemctl --user status get-weekly-wx.timer
```

---

## Check when the job is next scheduled to run

```bash
systemctl --user list-timers get-weekly-wx.timer
```

This shows the next scheduled fire time, the last time it ran, and how long until the next run.

---

## Start and stop

**Start the timer** (resume scheduling):
```bash
systemctl --user start get-weekly-wx.timer
```

**Stop the timer** (pause scheduling — does not disable at boot):
```bash
systemctl --user stop get-weekly-wx.timer
```

**Run the job immediately on demand** (without waiting for Sunday):
```bash
systemctl --user start get-weekly-wx.service
```

---

## Enable and disable

**Enable** (start timer automatically at login/boot):
```bash
systemctl --user enable get-weekly-wx.timer
```

**Disable** (remove from auto-start; does not stop a currently running timer):
```bash
systemctl --user disable get-weekly-wx.timer
```

To fully stop and disable in one step:
```bash
systemctl --user disable --now get-weekly-wx.timer
```

---

## View logs and journal output

**Most recent run:**
```bash
journalctl --user -u get-weekly-wx.service -n 50
```

**Follow output in real time** (useful when triggering a manual run):
```bash
journalctl --user -u get-weekly-wx.service -f
```

**All historical output:**
```bash
journalctl --user -u get-weekly-wx.service --no-pager
```

**Output from a specific date:**
```bash
journalctl --user -u get-weekly-wx.service --since "2026-04-13" --until "2026-04-14"
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| WX files contain "No forecast guidance" | No WEATHERAmerica posts within the last 7 days | Normal if no newsletter was sent; check `https://groups.google.com/g/weatheramerica` manually |
| Timer not firing | Machine was off; `Persistent=true` catches up on next boot | Run `systemctl --user list-timers get-weekly-wx.timer` |
| Claude CLI not found | Path issue in non-interactive shell | Confirm `~/.local/bin/claude` exists |

## Notes

- This is a **user** systemd unit (not system-wide). All `systemctl` commands require the `--user` flag.
- `Persistent=true` in the timer means if the machine was off at 7:00 AM Sunday, the job will fire once the next time you log in.
- The service runs Claude Code non-interactively (`-p`) with `--dangerously-skip-permissions`. This bypasses tool-use confirmation prompts, which is required for unattended execution. Do not use this flag in interactive sessions.
