#!/bin/bash
# Purple (#5F5997) login screen background around the dtlogin box.
# Box and its logo unchanged (the system greeter logo is used as-is; none is shipped here). Usage: install.sh [--dry-run]
# Edits /etc/dt/config/C/Xresources (C.UTF-8 and en_US.UTF-8 are symlinks to C).
# Does NOT touch /usr/dt and does NOT restart dtlogin.
set -euo pipefail
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
F=/etc/dt/config/C/Xresources
BAK="$F.bak-login-purple-$(date +%Y-%m-%d-%H%M%S)"
read -r -d '' BLOCK <<'B' || true
!! >>> login-purple (plain #5F5997 around the login box; box and Sun logo unchanged)
Dtlogin*login_shell.background:  #5F5997
Dtlogin*table.background:        #5F5997
!! <<< login-purple
B
[ -f "$F" ] || { echo "$F not found"; exit 1; }
if grep -q '>>> login-purple' "$F"; then echo "Already installed in $F (run rollback.sh first)"; exit 1; fi
if [ $DRY = 1 ]; then
  echo "DRY: sudo cp -a $F $BAK"
  echo "DRY: append to $F:"; echo "$BLOCK" | sed 's/^/    /'
  echo "(dry run: nothing changed)"; exit 0
fi
sudo cp -a "$F" "$BAK"
printf '\n%s\n' "$BLOCK" | sudo tee -a "$F" >/dev/null
echo "Backed up to $BAK and applied."
echo "Takes effect the next time the login screen appears (log out of CDE). dtlogin was not restarted."
