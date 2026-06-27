# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A collection of reusable Claude Code skill definitions — each skill is an instruction file (`SKILL.md`) plus supporting deployment files (wrapper script, systemd units, runbook).

## Path conventions

Always use `~` (tilde) for home-relative paths — never hardcode `/home/kinscoe`. This applies to shell scripts and `SKILL.md` files.

**Exception — systemd unit files:** `~` does not expand in systemd. Use `%h` (home directory specifier) for `WorkingDirectory=` and `ExecStart=` lines in `.service` files.

Examples:
- Shell scripts: `~/Projects/...` not `/home/kinscoe/Projects/...`
- Systemd service: `WorkingDirectory=%h/Journal/personal-journal`

## Skill directory layout

Each skill lives in its own subdirectory named after the skill:

```
<skill-name>/
  SKILL.md                    # The instruction file Claude reads and executes
  <skill-name>-wrapper.sh     # Shell script: invokes claude -p with the SKILL.md path
  <skill-name>.service        # Systemd oneshot service unit
  <skill-name>.timer          # Systemd timer unit
  RUNBOOK.md                  # How to install, run, and troubleshoot the timer
  .claude/settings.local.json # Per-skill Claude tool permissions (gitignored)
  resume.sh                   # Session resume shortcut (gitignored)
```

## Wrapper script pattern

```bash
#!/bin/bash
SKILL_PATH=~/Projects/public/kevins-opinionated-skills/<skill-name>/SKILL.md
CLAUDE=~/.local/bin/claude

exec "$CLAUDE" --dangerously-skip-permissions -p \
  "Read and execute the skill file at $SKILL_PATH"
```

The wrapper is deployed to `~/.local/bin/<skill-name>-wrapper.sh` and invoked by the systemd service.

## Systemd deployment

User-level units (not system-wide). All `systemctl` commands use `--user`:

```bash
cp <skill>.service ~/.config/systemd/user/
cp <skill>.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable <skill>.timer
systemctl --user start <skill>.timer
```

Run on demand without waiting for the schedule:
```bash
systemctl --user start <skill>.service
```

View logs:
```bash
journalctl --user -u <skill>.service -n 50
journalctl --user -u <skill>.service -f   # follow in real time
```

## SKILL.md authoring notes

- Skills invoked by the timer run fully unattended — never include prompts for confirmation or approval.
- Use `WebFetch` for all remote data retrieval; do not rely on MCP tools that require interactive auth.
- On step failure, log to stdout and continue; do not stop the skill.
- `WorkingDirectory` in the service unit sets the CWD when the skill runs — output files with relative paths resolve there.

## Gitignored files

`resume.sh`, `resume.txt`, and `.claude/` directories are gitignored repo-wide. Do not commit session IDs or local Claude permission overrides.
