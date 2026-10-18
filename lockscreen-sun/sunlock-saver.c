/* sunlock-saver: CDE screen saver / lock picture showing a logo (by default the system Solaris logo, if installed)
 * (same art as the dtlogin greeter). Draws into the windows dtsession hands
 * to savers via DtSaverGetWindows(). Use -create to test in a plain window.
 * Part of cde-solaris-panel. Loads $SUNLOCK_DIR (default ~/.dt/sunlock)/sunlock-large.pm,
 * then sunlock-small.pm; with neither it shows a plain purple screen. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <sys/select.h>
#include <X11/Xlib.h>
#include <X11/Intrinsic.h>
#include <X11/xpm.h>
#include <Dt/Saver.h>

#define MAXW 16
typedef struct { Window w; int W,H; Pixmap pix; int pw,ph; GC gc; unsigned long bg; int x,y,dx,dy; } Scr;
static volatile sig_atomic_t done = 0;
static void onsig(int s){ (void)s; done = 1; }

int main(int argc, char **argv){
  const char *dir = getenv("SUNLOCK_DIR");
  char large[1024], small[1024];
  int create = 0, i, n = 0;
  Window *wins = NULL, cw;
  Scr s[MAXW];
  Display *d;
  for (i = 1; i < argc; i++) if (!strcmp(argv[i], "-create")) create = 1;
  if (!dir) { const char *h = getenv("HOME"); static char b[900]; snprintf(b, sizeof b, "%s/.dt/sunlock", h ? h : ""); dir = b; }
  snprintf(large, sizeof large, "%s/sunlock-large.pm", dir);
  snprintf(small, sizeof small, "%s/sunlock-small.pm", dir);
  signal(SIGTERM, onsig); signal(SIGINT, onsig); signal(SIGHUP, onsig);
  if (!(d = XOpenDisplay(NULL))) { fprintf(stderr, "sunlock-saver: cannot open display\n"); return 1; }
  if (!create && DtSaverGetWindows(d, &wins, &n) && n > 0) {
    if (n > MAXW) n = MAXW;
  } else {
    int sc = DefaultScreen(d);
    XSetWindowAttributes a; a.override_redirect = True;
    cw = XCreateWindow(d, RootWindow(d, sc), 0, 0, DisplayWidth(d, sc), DisplayHeight(d, sc), 0,
                       CopyFromParent, InputOutput, CopyFromParent, CWOverrideRedirect, &a);
    XMapRaised(d, cw); wins = &cw; n = 1;
  }
  for (i = 0; i < n; i++) {
    XWindowAttributes wa; XpmAttributes xa; XColor c, e;
    Scr *p = &s[i]; memset(p, 0, sizeof *p); p->w = wins[i];
    XGetWindowAttributes(d, p->w, &wa); p->W = wa.width; p->H = wa.height;
    if (XAllocNamedColor(d, wa.colormap, "#5F5997", &c, &e)) p->bg = c.pixel; else p->bg = BlackPixelOfScreen(wa.screen);
    memset(&xa, 0, sizeof xa); xa.valuemask = XpmCloseness | XpmColormap | XpmVisual | XpmDepth;
    xa.closeness = 40000; xa.colormap = wa.colormap; xa.visual = wa.visual; xa.depth = wa.depth;
    {
      const char *f = (p->W >= 2400 && p->H >= 1300) ? large : small;
      if (XpmReadFileToPixmap(d, p->w, (char *)f, &p->pix, NULL, &xa) != XpmSuccess) {
        if (f == large || XpmReadFileToPixmap(d, p->w, small, &p->pix, NULL, &xa) != XpmSuccess) p->pix = None;
        else { p->pw = xa.width; p->ph = xa.height; }
      } else { p->pw = xa.width; p->ph = xa.height; }
    }
    p->gc = XCreateGC(d, p->w, 0, NULL);
    p->x = (p->W - p->pw) / 2; p->y = (p->H - p->ph) / 2; p->dx = 1; p->dy = 1;
    XSetWindowBackground(d, p->w, p->bg);
    XSelectInput(d, p->w, ExposureMask | StructureNotifyMask);
  }
  {
    int tick = 0;
    while (!done) {
      fd_set fs; struct timeval tv; int fd = ConnectionNumber(d);
      for (i = 0; i < n; i++) {
        Scr *p = &s[i];
        XClearWindow(d, p->w);
        if (p->pix) XCopyArea(d, p->pix, p->w, p->gc, 0, 0, p->pw, p->ph, p->x, p->y);
      }
      XFlush(d);
      FD_ZERO(&fs); FD_SET(fd, &fs); tv.tv_sec = 15; tv.tv_usec = 0;
      if (select(fd + 1, &fs, NULL, NULL, &tv) > 0) {
        while (XPending(d)) { XEvent ev; XNextEvent(d, &ev); if (ev.type == DestroyNotify) done = 1; }
      } else {
        /* slow drift (anti burn-in): move a few pixels every 15 s, bounce inside a margin */
        tick++;
        for (i = 0; i < n; i++) {
          Scr *p = &s[i]; int mx = (p->W - p->pw) / 4, my = (p->H - p->ph) / 4;
          int cx = (p->W - p->pw) / 2, cy = (p->H - p->ph) / 2;
          if (mx < 0) { mx = 0; } if (my < 0) { my = 0; }
          p->x += p->dx * 24; p->y += p->dy * 16;
          if (p->x > cx + mx || p->x < cx - mx) { p->dx = -p->dx; p->x += 2 * p->dx * 24; }
          if (p->y > cy + my || p->y < cy - my) { p->dy = -p->dy; p->y += 2 * p->dy * 16; }
        }
      }
    }
  }
  XCloseDisplay(d);
  return 0;
}
