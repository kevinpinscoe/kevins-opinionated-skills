#!/bin/bash
# Installs get-hwo-wx by creating ~/ai/fedora/wx-get-mrx-hwo/ as a real
# directory with individual file symlinks back to this repo, then wires up
# the systemd units and wrapper script.
#
# Safe to re-run: converts a legacy directory symlink if present, and -sf
# overwrites any existing file symlinks.

set -euo pipefail

REPO_DIR=~/Projects/public/kevins-opinionated-skills/get-hwo-wx
FEDORA_DIR=~/ai/fedora/wx-get-mrx-hwo
SYSTEMD_DIR=~/.config/systemd/user
BIN_DIR=~/.local/bin

# If the old layout left a directory symlink here, remove it so we can
# replace it with a real directory.
if [ -L "$FEDORA_DIR" ]; then
  rm "$FEDORA_DIR"
fi

mkdir -p "$FEDORA_DIR"

ln -sf "$REPO_DIR/SKILL.md"                      "$FEDORA_DIR/SKILL.md"
ln -sf "$REPO_DIR/get-hwo-wx-wrapper.sh"         "$FEDORA_DIR/get-hwo-wx-wrapper.sh"
ln -sf "$REPO_DIR/get-hwo-wx.service"            "$FEDORA_DIR/get-hwo-wx.service"
ln -sf "$REPO_DIR/get-hwo-wx.timer"              "$FEDORA_DIR/get-hwo-wx.timer"
ln -sf "$REPO_DIR/RUNBOOK.md"                    "$FEDORA_DIR/RUNBOOK.md"

mkdir -p "$SYSTEMD_DIR"
ln -sf "$FEDORA_DIR/get-hwo-wx.service"          "$SYSTEMD_DIR/get-hwo-wx.service"
ln -sf "$FEDORA_DIR/get-hwo-wx.timer"            "$SYSTEMD_DIR/get-hwo-wx.timer"

chmod +x "$REPO_DIR/get-hwo-wx-wrapper.sh"
ln -sf "$REPO_DIR/get-hwo-wx-wrapper.sh"         "$BIN_DIR/get-hwo-wx-wrapper.sh"

systemctl --user daemon-reload

echo "get-hwo-wx installed."
echo "Enable the timer with: systemctl --user enable --now get-hwo-wx.timer"
