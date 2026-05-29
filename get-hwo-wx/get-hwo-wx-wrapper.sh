#!/bin/bash

SKILL_PATH=~/Projects/public/kevins-opinionated-skills/get-hwo-wx/SKILL.md
CLAUDE=~/.local/bin/claude

exec "$CLAUDE" --dangerously-skip-permissions -p \
  "Read and execute the skill file at $SKILL_PATH"
