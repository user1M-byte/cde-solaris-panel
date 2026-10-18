#!/bin/bash
# Undo login-purple. Usage: rollback.sh [--dry-run]
# Restores the newest .bak-login-purple-* if the file is otherwise unchanged since
# install; otherwise removes only the marked block. Does not restart dtlogin.
set -euo pipefail
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
F=/etc/dt/config/C/Xresources
BAK=$(ls -1 "$F".bak-login-purple-* 2>/dev/null | sort | tail -1 || true)
grep -q '>>> login-purple' "$F" || { echo "login-purple block not present in $F; nothing to undo"; exit 0; }
STRIPPED=$(mktemp); trap 'rm -f "$STRIPPED"' EXIT
sed '/^!! >>> login-purple/,/^!! <<< login-purple/d' "$F" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' > "$STRIPPED"
SAFE="$F.before-rollback-$(date +%Y-%m-%d-%H%M%S)"
if [ -n "$BAK" ] && cmp -s "$STRIPPED" "$BAK"; then ACTION="restore $BAK"; else ACTION="remove marked block only"; fi
if [ $DRY = 1 ]; then echo "DRY: sudo cp -a $F $SAFE"; echo "DRY: $ACTION"; echo "(dry run: nothing changed)"; exit 0; fi
sudo cp -a "$F" "$SAFE"
if [ "$ACTION" = "remove marked block only" ]; then sudo cp "$STRIPPED" "$F"; else sudo cp -a "$BAK" "$F"; fi
echo "Done ($ACTION). Previous file kept at $SAFE. Takes effect at the next login screen."
