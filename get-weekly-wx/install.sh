#!/bin/bash
# Installs get-weekly-wx by creating ~/ai/fedora/get-weekly-wx/ as a real
# directory with individual file symlinks back to this repo, then wires up
# the systemd units and wrapper script.
#
# Safe to re-run: converts a legacy directory symlink if present, and -sf
# overwrites any existing file symlinks.

set -euo pipefail

REPO_DIR=~/Projects/public/kevins-opinionated-skills/get-weekly-wx
FEDORA_DIR=~/ai/fedora/get-weekly-wx
SYSTEMD_DIR=~/.config/systemd/user
BIN_DIR=~/.local/bin

# If the old layout left a directory symlink here, remove it so we can
# replace it with a real directory.
if [ -L "$FEDORA_DIR" ]; then
  rm "$FEDORA_DIR"
fi

mkdir -p "$FEDORA_DIR"

ln -sf "$REPO_DIR/SKILL.md"                      "$FEDORA_DIR/SKILL.md"
ln -sf "$REPO_DIR/get-weekly-wx-wrapper.sh"      "$FEDORA_DIR/get-weekly-wx-wrapper.sh"
ln -sf "$REPO_DIR/get-weekly-wx.service"         "$FEDORA_DIR/get-weekly-wx.service"
ln -sf "$REPO_DIR/get-weekly-wx.timer"           "$FEDORA_DIR/get-weekly-wx.timer"
ln -sf "$REPO_DIR/RUNBOOK.md"                    "$FEDORA_DIR/RUNBOOK.md"

mkdir -p "$SYSTEMD_DIR"
ln -sf "$FEDORA_DIR/get-weekly-wx.service"       "$SYSTEMD_DIR/get-weekly-wx.service"
ln -sf "$FEDORA_DIR/get-weekly-wx.timer"         "$SYSTEMD_DIR/get-weekly-wx.timer"

chmod +x "$REPO_DIR/get-weekly-wx-wrapper.sh"
ln -sf "$REPO_DIR/get-weekly-wx-wrapper.sh"      "$BIN_DIR/get-weekly-wx-wrapper.sh"

systemctl --user daemon-reload

echo "get-weekly-wx installed."
echo "Enable the timer with: systemctl --user enable --now get-weekly-wx.timer"
