#!/bin/bash
# Purple lock screen for CDE with a slowly drifting logo. Usage: install.sh [--dry-run]
# Adds: ~/bin/sunlock-saver, ~/.dt/sunlock/*.pm (symlinks to your system logo),
# ~/.dt/types/sunlock.dt and a marked block in ~/.Xdefaults. Takes effect at next CDE login.
# No logo art is shipped with this project. The logo is taken from your own system:
#   $SUNLOCK_LOGO, else /etc/dt/appconfig/icons/C/SolarisLogo.pm, else
#   /usr/dt/appconfig/icons/C/SolarisLogo.pm. With none found you get a plain purple screen.
# Never writes to /usr/dt or /etc.
set -euo pipefail
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
SRC="$(cd "$(dirname "$0")" && pwd)"
STAMP=$(date +%Y-%m-%d-%H%M%S)
BK="$HOME/.dt/backup-$STAMP-lockscreen-sun"
XD="$HOME/.Xdefaults"
run(){ if [ $DRY = 1 ]; then echo "DRY: $*"; else eval "$@"; fi; }
grep -q '>>> lockscreen-sun' "$XD" 2>/dev/null && { echo "Already installed (block found in $XD). Run rollback.sh first."; exit 1; }
if [ ! -x "$SRC/sunlock-saver" ]; then
  if [ $DRY = 1 ]; then echo "DRY: make -C '$SRC'"; else make -C "$SRC" || { echo "could not build sunlock-saver (needs CDE dev headers, libXt, libXpm)"; exit 1; }; fi
fi
LOGO=""
for c in "${SUNLOCK_LOGO:-}" /etc/dt/appconfig/icons/C/SolarisLogo.pm /usr/dt/appconfig/icons/C/SolarisLogo.pm; do
  [ -n "$c" ] && [ -r "$c" ] && { LOGO=$c; break; }
done
[ -n "$LOGO" ] && echo "Logo: $LOGO" || echo "No logo found - the lock screen will be plain purple (set SUNLOCK_LOGO=/path/to/logo.pm to use one)."
echo "Backup dir: $BK"
run "mkdir -p '$BK'"
for t in "$XD" "$HOME/bin/sunlock-saver" "$HOME/.dt/types/sunlock.dt" "$HOME/.dt/sunlock"; do
  if [ -e "$t" ]; then run "cp -a '$t' '$BK/'"; run "echo 'existed $t' >> '$BK/MANIFEST'"
  else run "echo 'new $t' >> '$BK/MANIFEST'"; fi
done
run "mkdir -p '$HOME/bin' '$HOME/.dt/sunlock' '$HOME/.dt/types'"
run "install -m 755 '$SRC/sunlock-saver' '$HOME/bin/sunlock-saver'"
[ -n "$LOGO" ] && run "ln -sf '$LOGO' '$HOME/.dt/sunlock/sunlock-large.pm'"
run "sed 's#@HOME@#$HOME#' '$SRC/sunlock.dt.tmpl' > '$HOME/.dt/types/sunlock.dt'"
BLOCK="! >>> lockscreen-sun (added $STAMP; remove with lockscreen-sun/rollback.sh)"
[ -n "$LOGO" ] && BLOCK="$BLOCK
dtsession*lockLabelPixmap.imageName: $LOGO"
BLOCK="$BLOCK
dtsession*drawArea.background: #5F5997
dtsession*saverList: StartSunLock
! <<< lockscreen-sun"
if [ $DRY = 1 ]; then echo "DRY: append to $XD:"; echo "$BLOCK" | sed 's/^/    /'
else [ -e "$XD" ] || touch "$XD"; printf '\n%s\n' "$BLOCK" >> "$XD"; echo "$BK" > "$HOME/.dt/sunlock/.last-backup"; fi
echo "Done. Takes effect after you log out of CDE and log back in."
[ $DRY = 1 ] && echo "(dry run: nothing was changed)"
exit 0
