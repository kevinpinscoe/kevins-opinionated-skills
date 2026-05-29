# RUNBOOK: get-hwo-wx

## Purpose

Fetches the **Hazardous Weather Outlook (HWO)** issued by the National Weather
Service office in Morristown TN (MRX) from:

    https://forecast.weather.gov/product.php?site=NWS&issuedby=MRX&product=HWO&format=txt&version=1&glossary=0

The skill parses the plain-text product and writes formatted Markdown to
`WX/WX-HAZARD.md` in the Personal Journal vault. It commits and pushes only
when the content has changed. If the content is unchanged, the file is left
untouched and no commit is made.

Runs every 4 hours (00:00, 04:00, 08:00, 12:00, 16:00, 20:00) via a systemd
user timer.

---

## Underlying Stack

| Component | Notes |
|---|---|
| Runtime | `claude --dangerously-skip-permissions -p` |
| Data fetch | `WebFetch` tool inside the Claude skill |
| Systemd mode | User unit (`systemctl --user`) — runs as `kinscoe` |

No curl, Python, or pip packages required.

---

## File layout

Canonical files live in the repo:

    ~/Projects/public/kevins-opinionated-skills/get-hwo-wx/
      SKILL.md
      get-hwo-wx-wrapper.sh
      get-hwo-wx.service
      get-hwo-wx.timer
      RUNBOOK.md

The legacy path `~/ai/fedora/wx-get-mrx-hwo` is a directory symlink to the
repo directory above.

---

## Installation (one-time setup)

### 1. Install the wrapper script

```bash
cp ~/Projects/public/kevins-opinionated-skills/get-hwo-wx/get-hwo-wx-wrapper.sh \
   ~/.local/bin/get-hwo-wx-wrapper.sh
chmod +x ~/.local/bin/get-hwo-wx-wrapper.sh
```

### 2. Install the systemd unit files

```bash
mkdir -p ~/.config/systemd/user/

ln -sf ~/ai/fedora/wx-get-mrx-hwo/get-hwo-wx.service \
   ~/.config/systemd/user/get-hwo-wx.service

ln -sf ~/ai/fedora/wx-get-mrx-hwo/get-hwo-wx.timer \
   ~/.config/systemd/user/get-hwo-wx.timer

systemctl --user daemon-reload
```

### 3. Enable and start the timer

```bash
systemctl --user enable --now get-hwo-wx.timer
```

### 4. Verify (optional — trigger a manual run)

```bash
systemctl --user start get-hwo-wx.service
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

A successful one-shot run exits with code `0` and shows `inactive (dead)` —
that is normal for `Type=oneshot`.

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

The content matches what was last committed. The NWS may not have issued a new
HWO yet. Check the issuance timestamp in `WX/WX-HAZARD.md`.

### Upstream URL returns no content

```bash
curl -s "https://forecast.weather.gov/product.php?site=NWS&issuedby=MRX&product=HWO&format=txt&version=1&glossary=0" | head -30
```

If empty, the NWS API may be temporarily unavailable. The timer will retry at
the next 4-hour interval.

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
