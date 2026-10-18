# cde-solaris-panel Front Panel (installed by panel/install.sh, undo: panel/rollback.sh).
# This file deletes the stock switch controls (and the Sound/Wi-Fi/Mic switch controls of
# examples/switch-layout.fp, if you use it) and puts four new ones in the switch.
#
#   [ (spacer bar)  |            |  Busy light bar   ]
#   [ Launch  Sound |  One   Two |  (spare)  Weather ]
#   [ Service Wi-Fi |            |  Lock     TaskMgr ]
#   [ VPN     Mic   | Three Four |  Exit     Calc    ]
#
# The two 2x3 grids are TYPE client controls inside the SWITCH (windows of ~/bin/fp-grid-left
# and fp-grid-right, started from sessionetc), so they span the switch's full height with
# identical rows on both sides. dtwm's busy light can only be a dtwm control, so it stays a
# real TYPE busy control, drawn as a thin bar above the right grid; a transparent spacer of the
# same height sits above the left grid so both grids start at the same height.
# No switch control has a monitor file, which avoids dtwm's SwitchCreate() double free.
CONTROL SoundSwitch
{
  TYPE                  icon
  CONTAINER_NAME        Switch
  CONTAINER_TYPE        SWITCH
  DELETE                True
}
CONTROL WifiToggle
{
  TYPE                  icon
  CONTAINER_NAME        Switch
  CONTAINER_TYPE        SWITCH
  DELETE                True
}
CONTROL MicSwitch
{
  TYPE                  icon
  CONTAINER_NAME        Switch
  CONTAINER_TYPE        SWITCH
  DELETE                True
}
CONTROL Lock
{
  TYPE                  icon
  CONTAINER_NAME        Switch
  CONTAINER_TYPE        SWITCH
  DELETE                True
}
CONTROL Exit
{
  TYPE                  icon
  CONTAINER_NAME        Switch
  CONTAINER_TYPE        SWITCH
  DELETE                True
}
CONTROL Busy
{
  TYPE                  busy
  CONTAINER_NAME        Switch
  CONTAINER_TYPE        SWITCH
  DELETE                True
}
CONTROL FpSwitchStripL
{
  TYPE                  blank
  CONTAINER_NAME        Switch
  CONTAINER_TYPE        SWITCH
  POSITION_HINTS        1
  ICON                  FpstripBlank
}
CONTROL FpBusyStrip
{
  TYPE                  busy
  CONTAINER_NAME        Switch
  CONTAINER_TYPE        SWITCH
  POSITION_HINTS        2
  ICON                  FpliteStrip
  ALTERNATE_ICON        FpliteStripY
  LABEL                 Busy
  HELP_TOPIC            FPOnItemBusy
  HELP_VOLUME           FPanel
}
CONTROL FpSwitchGridL
{
  TYPE                  client
  CONTAINER_NAME        Switch
  CONTAINER_TYPE        SWITCH
  POSITION_HINTS        3
  CLIENT_NAME           fpGridLeft
  CLIENT_GEOMETRY       60x80
  LABEL                 Grid
  HELP_STRING           Launcher, Services, VPN | Sound, Wi-Fi, Mic.
}
CONTROL FpSwitchGridR
{
  TYPE                  client
  CONTAINER_NAME        Switch
  CONTAINER_TYPE        SWITCH
  POSITION_HINTS        4
  CLIENT_NAME           fpGridRight
  CLIENT_GEOMETRY       60x80
  LABEL                 Grid
  HELP_STRING           Lock, Exit | Weather, Task Manager, Calculator.
}
CONTROL Blank2
{
  CONTAINER_NAME        Top
  CONTAINER_TYPE        BOX
  DELETE                True
}
CONTROL FpRight1Usb
{
  TYPE                  icon
  CONTAINER_NAME        Top
  CONTAINER_TYPE        BOX
  POSITION_HINTS        8
  ICON                  FpusbGreyOff
  ALTERNATE_ICON        FpusbGreyOn
  MONITOR_TYPE          file
  FILE_NAME             $HOME/.dt/usb-state/mounted
  LABEL                 USB Drive
  PUSH_ACTION           FpUsbOpen
  HELP_STRING           USB drive: lit (green light) while one is mounted. Click to open it; the arrow above has Safe eject.
}
SUBPANEL FpUsbSubpanel
{
  CONTAINER_NAME        FpRight1Usb
  TITLE                 USB Drive
}
CONTROL FpUsbEjectItem
{
  TYPE                  icon
  CONTAINER_NAME        FpUsbSubpanel
  CONTAINER_TYPE        SUBPANEL
  POSITION_HINTS        1
  ICON                  FpejectGrey
  ALTERNATE_ICON        FpejectGrey
  MONITOR_TYPE          file
  FILE_NAME             $HOME/.dt/fpv2-state/.static
  LABEL                 Safe eject
  PUSH_ACTION           FpUsbEject
  HELP_STRING           Sync, unmount and power off the USB drive so it is safe to unplug.
}
CONTROL FpUsbRwItem
{
  TYPE                  icon
  CONTAINER_NAME        FpUsbSubpanel
  CONTAINER_TYPE        SUBPANEL
  POSITION_HINTS        2
  ICON                  FprwGreyOff
  ALTERNATE_ICON        FprwGreyOn
  MONITOR_TYPE          file
  FILE_NAME             $HOME/.dt/usb-state/readonly
  LABEL                 Read/Write
  PUSH_ACTION           FpUsbRw
  HELP_STRING           Shows whether the USB drive is writable (pencil) or read-only (padlock). Click to see why and to make it writable or read-only. Never formats.
}
