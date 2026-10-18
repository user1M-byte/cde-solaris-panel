/* fp-grid - a grid of small (switch-size) Front Panel buttons, embedded by dtwm as a TYPE client
 * control (CLIENT_NAME = the name given with -n). Part of cde-solaris-panel.
 *   fp-grid -n NAME [-c COLUMNS] [-s SIZE] ITEM...
 *   ITEM = "Label|IconBase|StateFile|Command", or "-" for an empty cell.
 *   Items fill the grid column by column (top to bottom, then the next column to the right).
 *   IconBase.<SIZE>.pm is looked up in ~/.dt/icons, /etc/dt/appconfig/icons/C and
 *   /usr/dt/appconfig/icons/C (SIZE s = 24 px, the switch icon size).
 *   StateFile "-" = static icon; else <IconBase>Off while the file is empty/missing and
 *   <IconBase>On while it is non-empty (dtwm's MONITOR_TYPE file rule).
 *   Command: run with /bin/sh -c in its own session on click (press + release on the button).
 * Window background is ParentRelative, so the icons sit on the Front Panel's own background
 * exactly like dtwm's switch icons. Read-only otherwise: stats the state files every 2 s.  */
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/xpm.h>
#include <sys/stat.h>
#include <sys/select.h>
#include <sys/wait.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#define MAXI 16
typedef struct { char *label,*base,*state,*cmd; Pixmap pm[2],mk[2]; int w[2],h[2],lit,empty; } Item;
static Item it[MAXI]; static int n=0,cols=1,rows=1; static Display *d; static Window win; static GC gc;
static int W=30,H=80,pressed=-1; static char size[4]="s"; static char *home;
static int lit(const char *f){ struct stat st; if(!f||!strcmp(f,"-")) return 0; return stat(f,&st)==0&&st.st_size>0; }
static void load(Item *t,int k,const char *suffix){
  const char *dirs[3]={NULL,"/etc/dt/appconfig/icons/C","/usr/dt/appconfig/icons/C"}; char hd[900];
  snprintf(hd,sizeof hd,"%s/.dt/icons",home); dirs[0]=hd;
  t->pm[k]=t->mk[k]=None; t->w[k]=t->h[k]=0;
  for(int i=0;i<3;i++){ char p[1024]; XpmAttributes a; a.valuemask=0;
    snprintf(p,sizeof p,"%s/%s%s.%s.pm",dirs[i],t->base,suffix,size);
    if(access(p,R_OK)==0&&XpmReadFileToPixmap(d,win,p,&t->pm[k],&t->mk[k],&a)==XpmSuccess){t->w[k]=a.width;t->h[k]=a.height;return;} }
  fprintf(stderr,"fp-grid: no icon %s%s.%s.pm\n",t->base,suffix,size);
}
static void cell(int i,int *x,int *y,int *w,int *h){ int c=i/rows,r=i%rows;
  *x=W*c/cols; *w=W*(c+1)/cols-*x; *y=H*r/rows; *h=H*(r+1)/rows-*y; }
static int hit(int px,int py){ if(px<0||py<0||px>=W||py>=H) return -1;
  int c=px*cols/W, r=py*rows/H, i=c*rows+r; return (i<n&&!it[i].empty)?i:-1; }
static void draw(void){
  XClearWindow(d,win);
  for(int i=0;i<n;i++){ if(it[i].empty) continue;
    int k=it[i].lit?1:0,cx,cy,cw,chh; cell(i,&cx,&cy,&cw,&chh);
    if(it[i].pm[k]==None) continue;
    int o=(pressed==i), x=cx+(cw-it[i].w[k])/2+o, y=cy+(chh-it[i].h[k])/2+o;
    XSetClipMask(d,gc,it[i].mk[k]); XSetClipOrigin(d,gc,x,y);
    XCopyArea(d,it[i].pm[k],win,gc,0,0,it[i].w[k],it[i].h[k],x,y); }
  XSetClipMask(d,gc,None); XFlush(d);
}
static void run(const char *c){
  pid_t p=fork();
  if(p==0){ setsid(); for(int f=3;f<1024;f++) close(f); if(fork()==0){ execl("/bin/sh","sh","-c",c,(char*)0); _exit(127);} _exit(0); }
  if(p>0) while(waitpid(p,0,0)<0); }
int main(int argc,char **argv){
  char *name="fpGrid"; int o;
  while((o=getopt(argc,argv,"n:s:c:"))!=-1){ if(o=='n') name=optarg; else if(o=='c') cols=atoi(optarg); else if(o=='s') snprintf(size,sizeof size,"%s",optarg); }
  if(cols<1) cols=1;
  home=getenv("HOME"); if(!home) home="/";
  for(int i=optind;i<argc&&n<MAXI;i++){ Item *t=&it[n];
    if(!strcmp(argv[i],"-")){ t->empty=1; n++; continue; }
    char *s=strdup(argv[i]); t->label=strsep(&s,"|"); t->base=strsep(&s,"|"); t->state=strsep(&s,"|"); t->cmd=s;
    if(!t->base||!t->state||!t->cmd){ fprintf(stderr,"fp-grid: bad item %s\n",argv[i]); return 2; }
    n++; }
  if(!n){ fprintf(stderr,"usage: fp-grid -n NAME [-c COLS] [-s s|t] 'Label|IconBase|StateFile|Command'|- ...\n"); return 2; }
  rows=(n+cols-1)/cols;
  if(!(d=XOpenDisplay(NULL))) return 1;
  XSetWindowAttributes wa; wa.background_pixmap=ParentRelative;
  wa.event_mask=ExposureMask|ButtonPressMask|ButtonReleaseMask|StructureNotifyMask|LeaveWindowMask;
  win=XCreateWindow(d,DefaultRootWindow(d),0,0,W,H,0,CopyFromParent,InputOutput,CopyFromParent,CWBackPixmap|CWEventMask,&wa);
  XClassHint ch={name,"FpGrid"}; XSetClassHint(d,win,&ch); XStoreName(d,win,name);
  XSizeHints sh; sh.flags=PSize; sh.width=W; sh.height=H; XSetWMNormalHints(d,win,&sh);
  gc=XCreateGC(d,win,0,0); XSetGraphicsExposures(d,gc,False);
  for(int i=0;i<n;i++){ Item *t=&it[i]; if(t->empty) continue;
    if(!strcmp(t->state,"-")){ load(t,0,""); t->pm[1]=t->pm[0]; t->mk[1]=t->mk[0]; t->w[1]=t->w[0]; t->h[1]=t->h[0]; }
    else { load(t,0,"Off"); load(t,1,"On"); }
    t->lit=lit(t->state); }
  XMapWindow(d,win); XFlush(d);
  int fd=ConnectionNumber(d);
  for(;;){
    while(XPending(d)){ XEvent e; XNextEvent(d,&e);
      switch(e.type){
        case Expose: if(e.xexpose.count==0) draw(); break;
        case ConfigureNotify: if(e.xconfigure.width!=W||e.xconfigure.height!=H){W=e.xconfigure.width;H=e.xconfigure.height;draw();} break;
        case ButtonPress: if(e.xbutton.button==1){ pressed=hit(e.xbutton.x,e.xbutton.y); draw(); } break;
        case ButtonRelease: if(e.xbutton.button==1&&pressed>=0){ if(hit(e.xbutton.x,e.xbutton.y)==pressed) run(it[pressed].cmd);
            pressed=-1; draw(); } break;
        case LeaveNotify: if(pressed>=0){ pressed=-1; draw(); } break;
        case DestroyNotify: return 0;
      } }
    fd_set r; FD_ZERO(&r); FD_SET(fd,&r); struct timeval tv={2,0};
    if(select(fd+1,&r,0,0,&tv)==0){ int c2=0; for(int i=0;i<n;i++){ if(it[i].empty) continue; int l=lit(it[i].state); if(l!=it[i].lit){it[i].lit=l;c2=1;} } if(c2) draw(); }
  }
}
