#!/bin/sh
# Undo panel/install.sh: stops the 2 grids and 3 watchers it started
# (exact PIDs from their pid files, checked against the command line), removes the files it
# added, restores the files it replaced and sessionetc. Removed files are kept in the backup dir.
# Then: Restart Workspace Manager (or log out and in). Never touches /usr/dt or USB mounts.
# Full ~/.dt snapshot from before the install (without Trash): <backup>/dt.tar.gz
set -u
LINK="$HOME/.dt/backup-fpcolumns-v4"; D=${DISPLAY:-:0}; D=${D%.*}; SE=${FP_SESSIONETC:-$HOME/.dt/$(uname -n)$D/sessionetc}
[ -e "$LINK/installed" ] || { echo "Front Panel v4 is not installed."; exit 0; }
B=$(readlink -f "$LINK"); SAVE="$B/rolled-back-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$SAVE"
for st in fpv4-state/grid-left.pid:bin/fp-grid fpv4-state/grid-right.pid:bin/fp-grid \
          localai-state/watch.pid:bin/fp-localai-watch vpn-state/watch.pid:bin/fp-vpn-watch usb-state/watch.pid:bin/fp-usb-watch usb-state/watch-rw.pid:bin/fp-usb-watch; do
    pf="$HOME/.dt/${st%%:*}"; pat=${st#*:}
    pid=$(cat "$pf" 2>/dev/null) || continue
    if tr '\0' ' ' < /proc/$pid/cmdline 2>/dev/null | grep -q "$HOME/$pat"; then
        case $pat in *watch) for c in $(pgrep -P "$pid"); do kill "$c" 2>/dev/null; done ;; esac
        kill "$pid" && echo "stopped ${pat#bin/} ($pid)"
    fi
done
[ -s "$B/new-files" ] && while read -r f; do [ -e "$f" ] && mv -f "$f" "$SAVE/"; done < "$B/new-files"
for f in "$B"/bin/*;   do [ -e "$f" ] && cp -p "$f" "$HOME/bin/"; done
for f in "$B"/types/*; do [ -e "$f" ] && cp -p "$f" "$HOME/.dt/types/"; done
for f in "$B"/icons/*; do [ -e "$f" ] && cp -p "$f" "$HOME/.dt/icons/"; done
[ -e "$B/sessionetc" ] && cp -p "$SE" "$SAVE/sessionetc.now" && cp -p "$B/sessionetc" "$SE"
rm -f "$B/installed" "$LINK"
echo "Rolled back (removed files kept in $SAVE)."
echo "Now right-click the workspace switch > Restart Workspace Manager (or log out and back in)."
