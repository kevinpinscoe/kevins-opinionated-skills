#!/usr/bin/env bash
#
# Runs the get-weekly-wx skill via Claude Code, then asserts that this run
# actually rewrote the three forecast files before reporting success.
#
# WHY THE ASSERTION EXISTS
# ------------------------
# `claude -p` exits 0 whether the skill completed its work or gave up partway.
# This wrapper used to `exec` straight into it, so a scheduler running it saw
# "success" for every outcome, including a run that produced nothing at all.
#
# The assertion can be strict here because the skill ALWAYS writes all three
# files: when no WEATHERAmerica posts are found within the lookback window it
# writes each one with a "No forecast guidance for this time period was received"
# message and stops. So a file that did not move is a failed run, never a quiet
# week. That no-data file is only ~145 bytes, which is why MIN_BYTES is low --
# its job is to catch an empty or headings-only stub, while the freshness check
# does the real work.
#
# Exit 0 = all three forecasts rewritten by this run. Exit 1 = at least one was
# not, so what is on disk belongs to an earlier run.

# NOT `set -e`: claude's exit status is handled explicitly below, and a non-zero
# return from it must not skip the assertion that produces the real verdict.
set -uo pipefail

SKILL_PATH="$HOME/Projects/public/kevins-opinionated-skills/get-weekly-wx/SKILL.md"
CLAUDE="$HOME/.local/bin/claude"

# Absolute paths: this typically runs from a systemd timer, whose minimal PATH
# excludes ~/.local/bin and can differ from an interactive shell's.
STAT=/usr/bin/stat
DATE=/usr/bin/date

WX_DIR="${WX_DIR:-$HOME/Journal/personal-journal/WX}"
OUTPUTS=(WX-THE-NEXT-72-HOURS.md WX-THIS-WEEK.md WX-NEXT-30-DAY.md)
MIN_BYTES="${MIN_BYTES:-100}"

log() { echo "[$($DATE '+%Y-%m-%d %H:%M:%S')] $*"; }

# Recorded before the run so each file can be proved to belong to THIS
# invocation. Without it, last week's forecasts satisfy a mere existence check
# and the job looks healthy indefinitely.
START_EPOCH=$($DATE +%s)

"$CLAUDE" --dangerously-skip-permissions -p \
  "Read and execute the skill file at $SKILL_PATH"
claude_rc=$?
log "claude exited ${claude_rc} (advisory only — the files below are the verdict)"

# --- assert the work product -------------------------------------------------
failed=0
for f in "${OUTPUTS[@]}"; do
    path="${WX_DIR}/${f}"

    if [[ ! -f "$path" ]]; then
        log "FAIL: ${f} does not exist at ${path}"
        failed=1
        continue
    fi

    epoch=$($STAT -c %Y "$path" 2>/dev/null || echo 0)
    if (( epoch < START_EPOCH )); then
        log "FAIL: ${f} still dates from $($DATE -d "@${epoch}" '+%Y-%m-%d %H:%M') — this run did not rewrite it."
        failed=1
        continue
    fi

    bytes=$($STAT -c %s "$path" 2>/dev/null || echo 0)
    if (( bytes < MIN_BYTES )); then
        log "FAIL: ${f} is only ${bytes} bytes (floor ${MIN_BYTES}) — the run wrote a stub."
        failed=1
        continue
    fi

    log "ok: ${f} rewritten this run (${bytes} bytes)"
done

if (( failed )); then
    log "One or more forecast files were not produced by this run."
    exit 1
fi

log "OK — all three forecasts rewritten by this run."
exit 0
