# Kevin's Opinionated Skills

Reusable Claude Code skill definitions built around Kevin's preferred tools, conventions, and ways of working. Each skill runs Claude Code non-interactively (`claude -p --dangerously-skip-permissions`) on a schedule via a systemd user timer.

## Skills

| Skill | Schedule | Description |
|---|---|---|
| [get-weekly-wx](get-weekly-wx/) | Sundays 07:00 | Fetches WEATHERAmerica Sunday forecast posts and writes WX Markdown files to the Obsidian vault |
| [get-hwo-wx](get-hwo-wx/) | Every 4 hours | Fetches the NWS Hazardous Weather Outlook (Morristown TN / MRX office) and writes `WX-HAZARD.md` |

## Deployment

Skills are deployed through a symlink structure so they can be edited here and take effect immediately without copying files.

Each skill directory contains an `install.sh` that:
1. Creates a real directory under `~/ai/fedora/` (e.g. `~/ai/fedora/get-weekly-wx/`)
2. Populates it with individual file symlinks pointing back into this repo
3. Symlinks the systemd unit files from `~/.config/systemd/user/` through `~/ai/fedora/`
4. Symlinks the wrapper script into `~/.local/bin/`

```
this repo / get-weekly-wx/         ← canonical files (edit here)
       ↑
~/ai/fedora/get-weekly-wx/         ← real directory; files are symlinks to the repo
       ↑
~/.config/systemd/user/get-weekly-wx.*   ← systemd picks up changes automatically
```

The `~/ai/fedora/` directory names are preserved from the original skill names to keep existing systemd unit symlinks valid (`wx-get-mrx-hwo` → `get-hwo-wx`).

### Install all skills

```bash
bash ~/Projects/public/kevins-opinionated-skills/get-weekly-wx/install.sh
systemctl --user enable --now get-weekly-wx.timer

bash ~/Projects/public/kevins-opinionated-skills/get-hwo-wx/install.sh
systemctl --user enable --now get-hwo-wx.timer
```

Each `install.sh` is idempotent — safe to re-run to repair broken symlinks.

See [RUNBOOK.md](RUNBOOK.md) for full operational details.

## License

This project is licensed under the Apache License 2.0. See [LICENCE](LICENCE) for details.

## Contributing & Reporting Issues

Bug reports, feature requests, security disclosures, and contributions are all
welcome. I keep these guidelines in one place for all my projects:

- **How to contribute or report an issue:** https://github.com/kevinpinscoe/how-to-contribute
- **Report a security vulnerability:** do not open a public issue. Use the
  **"Report a vulnerability"** button on this repository's **Security** tab, or
  see the [security policy](https://github.com/kevinpinscoe/how-to-contribute/blob/main/SECURITY.md).
