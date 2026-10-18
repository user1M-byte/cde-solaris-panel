#!/bin/bash
# Undo lockscreen-sun. Usage: rollback.sh [--dry-run]
set -euo pipefail
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
XD="$HOME/.Xdefaults"
run(){ if [ $DRY = 1 ]; then echo "DRY: $*"; else eval "$@"; fi; }
BK=$(cat "$HOME/.dt/sunlock/.last-backup" 2>/dev/null || ls -d "$HOME"/.dt/backup-*-lockscreen-sun 2>/dev/null | tail -1 || true)
[ -n "$BK" ] && [ -d "$BK" ] || { echo "No lockscreen-sun backup found"; exit 1; }
echo "Using backup: $BK"
# 1) remove only our marked block from ~/.Xdefaults (keeps any other edits made since)
if grep -q '>>> lockscreen-sun' "$XD" 2>/dev/null; then
  run "cp -a '$XD' '$BK/Xdefaults.before-rollback'"
  run "sed -i '/^! >>> lockscreen-sun/,/^! <<< lockscreen-sun/d' '$XD'"
  # drop the single blank line install.sh added before the block, if it is now trailing
  run "sed -i -e :a -e '/^\n*\$/{\$d;N;ba' -e '}' '$XD'"
fi
# 2) new files are removed; files that existed before are restored
while read -r kind path; do
  name=$(basename "$path")
  case "$path" in "$XD") continue;; esac
  if [ "$kind" = new ]; then run "rm -rf '$path'"
  else run "rm -rf '$path'"; run "cp -a '$BK/$name' '$path'"; fi
done < "$BK/MANIFEST"
echo "Rolled back. Takes effect after you log out of CDE and log back in."
[ $DRY = 1 ] && echo "(dry run: nothing was changed)"
exit 0
