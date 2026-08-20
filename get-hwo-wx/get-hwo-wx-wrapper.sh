#!/usr/bin/env bash
#
# Runs the get-hwo-wx skill via Claude Code, then asserts that this run actually
# rewrote the Hazardous Weather Outlook before reporting success.
#
# WHY THE ASSERTION EXISTS
# ------------------------
# `claude -p` exits 0 whether the skill completed its work or gave up partway.
# This wrapper used to `exec` straight into it, so a scheduler running it saw
# "success" for every outcome, including a run that fetched nothing.
#
# A stale hazardous weather outlook is worse than an absent one, because it reads
# as current. The skill ALWAYS overwrites WX-HAZARD.md -- there is always an
# outlook to fetch, even when it reports no hazards expected -- so a file that did
# not move means the fetch failed, never a quiet forecast period.
#
# Exit 0 = the outlook was rewritten by this run. Exit 1 = it was not, so what is
# on disk predates this run and must not be trusted as current.

# NOT `set -e`: claude's exit status is handled explicitly below, and a non-zero
# return from it must not skip the assertion that produces the real verdict.
set -uo pipefail

SKILL_PATH="$HOME/Projects/public/kevins-opinionated-skills/get-hwo-wx/SKILL.md"
CLAUDE="$HOME/.local/bin/claude"

# Absolute paths: this typically runs from a systemd timer, whose minimal PATH
# excludes ~/.local/bin and can differ from an interactive shell's.
STAT=/usr/bin/stat
DATE=/usr/bin/date

HAZARD="${HAZARD:-$HOME/Journal/personal-journal/personal-journal/WX/WX-HAZARD.md}"
MIN_BYTES="${MIN_BYTES:-300}"

log() { echo "[$($DATE '+%Y-%m-%d %H:%M:%S')] $*"; }

# Recorded before the run so the file can be proved to belong to THIS invocation.
# Without it, an outlook from several hours ago satisfies an existence check while
# the fetch has been failing all day.
START_EPOCH=$($DATE +%s)

"$CLAUDE" --dangerously-skip-permissions -p \
  "Read and execute the skill file at $SKILL_PATH"
claude_rc=$?
log "claude exited ${claude_rc} (advisory only — the file below is the verdict)"

# --- assert the work product -------------------------------------------------
if [[ ! -f "$HAZARD" ]]; then
    log "FAIL: WX-HAZARD.md does not exist at ${HAZARD}"
    exit 1
fi

epoch=$($STAT -c %Y "$HAZARD" 2>/dev/null || echo 0)
if (( epoch < START_EPOCH )); then
    log "FAIL: WX-HAZARD.md still dates from $($DATE -d "@${epoch}" '+%Y-%m-%d %H:%M') — this run did not rewrite it."
    log "      The NWS fetch failed; the outlook on disk is stale and reads as current."
    exit 1
fi

bytes=$($STAT -c %s "$HAZARD" 2>/dev/null || echo 0)
if (( bytes < MIN_BYTES )); then
    log "FAIL: WX-HAZARD.md is only ${bytes} bytes (floor ${MIN_BYTES}) — the run wrote a stub."
    exit 1
fi

log "OK — WX-HAZARD.md rewritten by this run (${bytes} bytes)."
exit 0
