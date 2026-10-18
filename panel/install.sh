#!/bin/sh
# cde-solaris-panel - Front Panel install.
#   [Mail] [Launch Sound | One  Two  | Busy-bar/(spare) Weather ] [USB] [Printer] ...
#          [Svc    Wi-Fi |           | Lock             TaskMgr ]
#          [VPN    Mic   | Three Four| Exit             Calc    ]
# The switch holds only the 4 workspace buttons plus two small-icon 2x3 grids (embedded clients
# ~/bin/fp-grid-left/-right) and dtwm's real Busy light as a thin bar. USB full-size + drawer.
#   install.sh [--dry-run]            fresh install
#   install.sh --update [--dry-run]   already installed: copy in newer files; backs up first,
#                                     starts/stops nothing
# Writes only to ~/.dt, ~/bin and ~/.config. Never touches /usr/dt, never restarts dtwm,
# never logs out.
# 1. backs up ~/.dt (everything except Trash) to ~/.dt/backup-fpcolumns-v4-<time>/dt.tar.gz
# 2. copies scripts to ~/bin, icons to ~/.dt/icons, fpcolumns-v4.fp/.dt to ~/.dt/types,
#    adds watcher + grid lines to your CDE session's sessionetc
# 3. starts the 3 read-only watchers (services, VPN, USB). The grids start at the next login.
# Then: LOG OUT AND BACK IN (or: Restart Workspace Manager, then run ~/bin/fp-grid-start).
# Undo: rollback.sh (next to this file)
set -eu
S=$(cd "$(dirname "$0")" && pwd)
T="$HOME/.dt/types"; IC="$HOME/.dt/icons"; D=${DISPLAY:-:0}; D=${D%.*}
SE=${FP_SESSIONETC:-$HOME/.dt/$(uname -n)$D/sessionetc}
LINK="$HOME/.dt/backup-fpcolumns-v4"
DRY=0; UPD=0; for a in "$@"; do case $a in --dry-run) DRY=1;; --update) UPD=1;; *) echo "usage: install.sh [--update] [--dry-run]"; exit 2;; esac; done
do_() { if [ $DRY = 1 ]; then echo "would: $*"; else "$@"; fi; }
BINS="fp-conf fp-launcher fp-audio-toggle fp-audio-hdmi-on fp-audio-popup fp-wifi-toggle fp-wifi-popup fp-mic-toggle fp-grid fp-grid-left fp-grid-right fp-grid-start fp-column-popup fp-confirm fp-usb-rw fp-usb-rwtool fp-usb-ntfsflags fp-localai-toggle fp-localai-watch fp-vpn-toggle fp-vpn-watch fp-weather fp-taskmgr fp-usb-scan fp-usb-watch fp-usb-open fp-usb-eject"
TYPES="fpcolumns-v4.fp fpcolumns-v4.dt"
if [ ! -x "$S/bin/fp-grid" ]; then
    if [ $DRY = 1 ]; then echo "would: make -C $S (build bin/fp-grid)"
    else make -C "$S" || { echo "could not build bin/fp-grid - install a C compiler and the libX11/libXpm headers"; exit 1; }; fi
fi
if [ $UPD = 1 ]; then
    [ -e "$LINK/installed" ] || { echo "Front Panel v4 is not installed - run install.sh without --update."; exit 1; }
    OB=$(readlink -f "$LINK"); B="$HOME/.dt/backup-fpcolumns-v4-update-$(date +%Y%m%d-%H%M%S)"
    do_ mkdir -p "$B/bin" "$B/types" "$B/icons"
    echo "backing up ~/.dt (without Trash) to $B/dt.tar.gz"
    do_ tar -C "$HOME" --exclude=.dt/Trash --exclude='.dt/backup-fpcolumns-v4*' -czf "$B/dt.tar.gz" .dt
    n=0
    upd() { # upd SRC DEST MODE BACKUPDIR - copy only if different; back up the old one
        cmp -s "$1" "$2" && return
        if [ -e "$2" ]; then do_ cp -p "$2" "$4/"; else [ $DRY = 1 ] || echo "$2" >> "$OB/new-files"; fi
        if [ "$3" = x ]; then do_ install -m 755 "$1" "$2"; else do_ cp -p "$1" "$2"; fi; n=$((n+1)); }
    for f in $BINS; do upd "$S/bin/$f" "$HOME/bin/$f" x "$B/bin"; done
    for f in "$S"/icons/*; do upd "$f" "$IC/$(basename "$f")" - "$B/icons"; done
    for f in $TYPES; do upd "$S/types/$f" "$T/$f" - "$B/types"; done
    [ $DRY = 1 ] && { echo "would update $n file(s) (dry run - nothing changed)"; exit 0; }
    echo "$B" >> "$OB/updates"; date > "$B/updated"
    echo "Updated $n file(s) (previous versions: $B). Nothing was restarted."
    echo "It takes effect at the next login (or after Restart Workspace Manager)."
    echo "rollback.sh still undoes the whole v4 install, including this update."
    exit 0
fi
[ -e "$LINK/installed" ] && { echo "Front Panel v4 is already installed. Run rollback.sh first (or use --update)."; exit 1; }
[ -d "$(dirname "$SE")" ] || { echo "CDE session dir $(dirname "$SE") not found - log in to CDE once, or set FP_SESSIONETC=/path/to/sessionetc"; exit 1; }
B="$HOME/.dt/backup-fpcolumns-v4-$(date +%Y%m%d-%H%M%S)"
do_ mkdir -p "$B/bin" "$B/types" "$B/icons" "$HOME/bin"
echo "backing up ~/.dt (without Trash) to $B/dt.tar.gz"
do_ tar -C "$HOME" --exclude=.dt/Trash --exclude='.dt/backup-fpcolumns-v4*' -czf "$B/dt.tar.gz" .dt
[ -e "$SE" ] && do_ cp -p "$SE" "$B/sessionetc"
for f in $BINS; do [ -e "$HOME/bin/$f" ] && do_ cp -p "$HOME/bin/$f" "$B/bin/"; done
for f in $TYPES; do [ -e "$T/$f" ] && do_ cp -p "$T/$f" "$B/types/"; done
for f in "$S"/icons/*; do [ -e "$IC/$(basename "$f")" ] && do_ cp -p "$IC/$(basename "$f")" "$B/icons/"; done
[ $DRY = 1 ] || : > "$B/new-files"
add() { [ -e "$1" ] || { [ $DRY = 1 ] || echo "$1" >> "$B/new-files"; }; }
for f in $BINS; do add "$HOME/bin/$f"; do_ install -m 755 "$S/bin/$f" "$HOME/bin/$f"; done
for f in "$S"/icons/*; do add "$IC/$(basename "$f")"; do_ cp -p "$f" "$IC/"; done
for f in $TYPES; do add "$T/$f"; do_ cp -p "$S/types/$f" "$T/"; done
for d in usb-state vpn-state localai-state fpv4-state; do add "$HOME/.dt/$d"; do_ mkdir -p "$HOME/.dt/$d"; done
if ! grep -q 'fpcolumns-v4' "$SE" 2>/dev/null; then
    if [ $DRY = 1 ]; then echo "would: append watcher + fp-grid-start lines to $SE"
    else cat >> "$SE" <<'EOT'
# Added by cde-solaris-panel panel/install.sh (fpcolumns-v4): Front Panel small-icon grids
# inside the switch + read-only state watchers (undo: panel/rollback.sh)
[ -x "$HOME/bin/fp-localai-watch" ] && "$HOME/bin/fp-localai-watch" >/dev/null 2>&1 &
[ -x "$HOME/bin/fp-vpn-watch" ] && "$HOME/bin/fp-vpn-watch" >/dev/null 2>&1 &
[ -x "$HOME/bin/fp-usb-watch" ] && "$HOME/bin/fp-usb-watch" >/dev/null 2>&1 &
[ -x "$HOME/bin/fp-grid-start" ] && ( sleep 3; "$HOME/bin/fp-grid-start" ) >/dev/null 2>&1 &
EOT
    fi
fi
C="$HOME/.config/cde-solaris-panel"
[ -e "$C/panel.conf" ] || { add "$C/panel.conf"; do_ mkdir -p "$C"; do_ cp "$S/config/panel.conf.example" "$C/panel.conf"; [ $DRY = 1 ] || echo "created $C/panel.conf - edit it to set your launcher, services and VPN"; }
[ -s "$HOME/.config/fp-weather/location" ] || echo "note: set your weather location in ~/.config/fp-weather/location (format: Name|lat|lon, see config/weather-location.example)."
if [ $DRY = 1 ]; then echo "would: start fp-localai-watch, fp-vpn-watch, fp-usb-watch"; echo "(dry run - nothing changed)"; exit 0; fi
for w in fp-localai-watch fp-vpn-watch fp-usb-watch; do setsid "$HOME/bin/$w" >/dev/null 2>&1 </dev/null & done
rm -f "$LINK"; ln -s "$B" "$LINK"; date > "$B/installed"
echo "Installed (backup: $B)."
echo "Now log out and back in (or: Restart Workspace Manager, then run ~/bin/fp-grid-start)."
