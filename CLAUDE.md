# CLAUDE.md — kevins-opinionated-skills

## Path conventions

Always use `~` (tilde) for home-relative paths — never hardcode `/home/kinscoe`. This applies to all scripts, skill files, systemd units, and any other files in this repo.

Examples:
- `~/Projects/...` not `/home/kinscoe/Projects/...`
- `~/.local/bin/claude` not `/home/kinscoe/.local/bin/claude`
- `~/.config/systemd/user/` not `/home/kinscoe/.config/systemd/user/`
