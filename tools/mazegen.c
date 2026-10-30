// mazegen.c -- maze and labyrinth generator for the repo's terminal
// graphics (docs/assets). Three constructions, all solved by BFS so
// every emitted maze carries its true shortest path:
//
//   backtracker <cw> <ch> <seed>   perfect maze (recursive backtracker)
//   rule30      <w>  <h>  <seed>   walls from two Rule 30 spacetimes
//                                  (random initial rows, Zero boundary,
//                                  as in the kernel) OR'd together,
//                                  framed with two gates, and repaired
//                                  until every open cell is one
//                                  connected region
//   rings       <w>  <h>           concentric square labyrinth; each
//                                  ring's gap steps by the golden
//                                  constant 0x9E3779B9 around the ring
//
// Output: "W H", the grid (# wall, . open, S start, E end), then
// "PATH n" and n lines of "x y" -- the solution, start to end.
// z3-og -- Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team
// HoloTwinKitty. Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
// LICENSE v1.0 -- see LICENSE at the repository root.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static unsigned rng_state;
static unsigned rnd(void){ rng_state = rng_state*1664525u + 1013904223u; return rng_state >> 8; }

static int W, H; static char *G; /* '#' wall, '.' open */
#define AT(x,y) G[(y)*W+(x)]
static int GATE1X=-1, GATE1Y=-1, GATE2X=-1, GATE2Y=-1;
static int is_gate(int x,int y){ return (x==GATE1X&&y==GATE1Y)||(x==GATE2X&&y==GATE2Y); }
static int is_border(int x,int y){ return x==0||y==0||x==W-1||y==H-1; }


/* BFS shortest path over open cells; writes path into px,py; returns len or 0 */
static int bfs(int sx,int sy,int ex,int ey,int *px,int *py){
    int n=W*H, *prev=malloc(sizeof(int)*n), *q=malloc(sizeof(int)*n);
    for(int i=0;i<n;i++) prev[i]=-2;
    int qh=0, qt=0; q[qt++]=sy*W+sx; prev[sy*W+sx]=-1;
    const int dx[4]={1,-1,0,0}, dy[4]={0,0,1,-1};
    while(qh<qt){ int c=q[qh++], cx=c%W, cy=c/W;
        if(cx==ex&&cy==ey) break;
        for(int d=0;d<4;d++){ int nx=cx+dx[d], ny=cy+dy[d];
            if(nx<0||ny<0||nx>=W||ny>=H) continue;
            int ni=ny*W+nx;
            if(AT(nx,ny)!='#' && prev[ni]==-2){ prev[ni]=c; q[qt++]=ni; } } }
    int ei=ey*W+ex; if(prev[ei]==-2){ free(prev); free(q); return 0; }
    int len=0; for(int c=ei;c!=-1;c=prev[c]) len++;
    int i=len-1; for(int c=ei;c!=-1;c=prev[c]){ px[i]=c%W; py[i]=c/W; i--; }
    free(prev); free(q); return len;
}

static void emit(int sx,int sy,int ex,int ey){
    int *px=malloc(sizeof(int)*W*H), *py=malloc(sizeof(int)*W*H);
    int n=bfs(sx,sy,ex,ey,px,py); if(!n){ fprintf(stderr,"no path\n"); exit(1); }
    AT(sx,sy)='S'; AT(ex,ey)='E';
    printf("%d %d\n",W,H);
    for(int y=0;y<H;y++){ for(int x=0;x<W;x++) putchar(AT(x,y)); putchar('\n'); }
    printf("PATH %d\n",n); for(int i=0;i<n;i++) printf("%d %d\n",px[i],py[i]);
    free(px); free(py);
}

static void gen_backtracker(int cw,int ch,unsigned seed){
    rng_state=seed; W=cw*2+1; H=ch*2+1; G=malloc(W*H); memset(G,'#',W*H);
    int *st=malloc(sizeof(int)*cw*ch), sp=0;
    int sx=0, sy=0; AT(1,1)='.'; st[sp++]=0;
    const int dx[4]={1,-1,0,0}, dy[4]={0,0,1,-1};
    char *vis=calloc(cw*ch,1); vis[0]=1;
    while(sp){ int c=st[sp-1], cx=c%cw, cy=c/cw, opts[4], no=0;
        for(int d=0;d<4;d++){ int nx=cx+dx[d], ny=cy+dy[d];
            if(nx>=0&&ny>=0&&nx<cw&&ny<ch&&!vis[ny*cw+nx]) opts[no++]=d; }
        if(!no){ sp--; continue; }
        int d=opts[rnd()%no], nx=cx+dx[d], ny=cy+dy[d];
        AT(1+cx*2+dx[d], 1+cy*2+dy[d])='.'; AT(1+nx*2, 1+ny*2)='.';
        vis[ny*cw+nx]=1; st[sp++]=ny*cw+nx; }
    free(st); free(vis); (void)sx; (void)sy;
    emit(1,1,W-2,H-2);
}

static void fill_rule30(unsigned char *dst, int w, int h, unsigned seed){
    unsigned char *row=calloc((size_t)w,1), *nx=calloc((size_t)w,1);
    unsigned st = seed*2654435761u + 1u;
    for(int x=0;x<w;x++){ st = st*1664525u + 1013904223u; row[x]=(unsigned char)((st>>8)&1u); }
    for(int y=0;y<h;y++){
        for(int x=0;x<w;x++) dst[y*w+x]=row[x];
        for(int x=0;x<w;x++){ int l=x?row[x-1]:0, c=row[x], r=(x<w-1)?row[x+1]:0;
            nx[x]=(unsigned char)(l ^ (c | r)); }
        memcpy(row,nx,(size_t)w); }
    free(row); free(nx);
}

static void gen_rule30(int w,int h,unsigned seed){
    W=w; H=h; G=malloc((size_t)W*H);
    unsigned char *A=malloc((size_t)W*H), *B=malloc((size_t)W*H);
    fill_rule30(A,W,H,seed); fill_rule30(B,W,H,seed^0x5bd1e995u);
    for(int i=0;i<W*H;i++) AT(i%W,i/W) = (A[i]||B[i]) ? '#' : '.';
    free(A); free(B);
    /* frame the spacetime: solid border, gates at the left and
       right edges, attached to the open cells nearest the one-third
       and two-thirds heights -- the path must cross the whole field */
    for(int x=0;x<W;x++){ AT(x,0)='#'; AT(x,H-1)='#'; }
    for(int y=0;y<H;y++){ AT(0,y)='#'; AT(W-1,y)='#'; }
    int sx=1, sy=1, best=1<<30;
    for(int y=1;y<H-1;y++) for(int x=1;x<W-1;x++){ if(AT(x,y)=='#') continue;
        int d=(x-1)*4+abs(y-H/3); if(d<best){ best=d; sx=x; sy=y; } }
    int ex=W-2, ey=H-2; best=1<<30;
    for(int y=1;y<H-1;y++) for(int x=1;x<W-1;x++){ if(AT(x,y)=='#') continue;
        int d=((W-2)-x)*4+abs(y-(2*H)/3); if(d<best){ best=d; ex=x; ey=y; } }
    (void)sx; (void)ex; /* attachment cells chosen; gates open beside them */
    GATE1X=0; GATE1Y=sy; GATE2X=W-1; GATE2Y=ey;
    AT(0,sy)='.'; AT(W-1,ey)='.';
    /* repair: label open regions; repeatedly carve the cheapest
       wall route (0-1 BFS, never through non-gate border cells)
       from region 0 into the nearest other region until every
       open cell is one connected region */
    int n=W*H, *reg=malloc(sizeof(int)*n), *par=malloc(sizeof(int)*n),
        *dist=malloc(sizeof(int)*n), *dq=malloc(sizeof(int)*(2*n+16)),
        *stack=malloc(sizeof(int)*n);
    for(int iter=0; iter<512; iter++){
        for(int i=0;i<n;i++) reg[i]= (AT(i%W,i/W)=='#') ? -1 : -2;
        int nreg=0;
        for(int i=0;i<n;i++){ if(reg[i]!=-2) continue;
            int sp=0; stack[sp++]=i; reg[i]=nreg;
            while(sp){ int c=stack[--sp], cx=c%W, cy=c/W;
                const int dx[4]={1,-1,0,0}, dy[4]={0,0,1,-1};
                for(int d=0;d<4;d++){ int ax=cx+dx[d], ay=cy+dy[d];
                    if(ax<0||ay<0||ax>=W||ay>=H) continue;
                    int ai=ay*W+ax;
                    if(reg[ai]==-2){ reg[ai]=nreg; stack[sp++]=ai; } } }
            nreg++; }
        if(nreg<=1) break;
        for(int i=0;i<n;i++){ dist[i]=1<<29; par[i]=-1; }
        int dh=n+8, dt=n+8;
        for(int i=0;i<n;i++) if(reg[i]==0){ dist[i]=0; dq[dt++]=i; }
        int target=-1;
        const int dx[4]={1,-1,0,0}, dy[4]={0,0,1,-1};
        while(dh<dt && target<0){ int c=dq[dh++], cx=c%W, cy=c/W;
            for(int d=0;d<4;d++){ int ax=cx+dx[d], ay=cy+dy[d];
                if(ax<0||ay<0||ax>=W||ay>=H) continue;
                if(is_border(ax,ay) && !is_gate(ax,ay)) continue;
                int ai=ay*W+ax;
                int cost = (AT(ax,ay)=='#') ? 1 : 0;
                if(dist[c]+cost < dist[ai]){ dist[ai]=dist[c]+cost; par[ai]=c;
                    if(cost) dq[dt++]=ai; else dq[--dh]=ai;
                    if(reg[ai]>0){ target=ai; } } } }
        if(target<0) break;
        for(int c=target;c!=-1;c=par[c]) if(AT(c%W,c/W)=='#') AT(c%W,c/W)='.';
    }
    free(reg); free(par); free(dist); free(dq); free(stack);
    emit(0,GATE1Y,W-1,GATE2Y);
}

static void gen_rings(int w,int h){
    W=w; H=h; G=malloc(W*H); memset(G,'.',W*H);
    int cx=W/2, cy=H/2; int maxd = cx<cy?cx:cy;
    unsigned step=0x9E3779B9u;
    for(int r=2;r<=maxd;r+=2){
        int x0=cx-r, x1=cx+r, y0=cy-r, y1=cy+r; if(x0<0||y0<0||x1>=W||y1>=H) break;
        for(int x=x0;x<=x1;x++){ AT(x,y0)='#'; AT(x,y1)='#'; }
        for(int y=y0;y<=y1;y++){ AT(x0,y)='#'; AT(x1,y)='#'; }
        int per=8*r; unsigned g=step % (unsigned)per; step = step*2654435761u + 1u;
        int gx, gy; unsigned k=g;
        if(k < (unsigned)(2*r)){ gx=x0+(int)k; gy=y0; } else if((k-=2*r) < (unsigned)(2*r)){ gx=x1; gy=y0+(int)k; }
        else if((k-=2*r) < (unsigned)(2*r)){ gx=x1-(int)k; gy=y1; } else { k-=2*r; gx=x0; gy=y1-(int)k; }
        AT(gx,gy)='.';
    }
    emit(0,0,cx,cy);
}

int main(int argc,char**argv){
    if(argc<2){ fprintf(stderr,"usage: mazegen backtracker|rule30|rings ...\n"); return 1; }
    if(!strcmp(argv[1],"backtracker")) gen_backtracker(atoi(argv[2]),atoi(argv[3]),(unsigned)atoi(argv[4]));
    else if(!strcmp(argv[1],"rule30")) gen_rule30(atoi(argv[2]),atoi(argv[3]),(unsigned)atoi(argv[4]));
    else if(!strcmp(argv[1],"rings")) gen_rings(atoi(argv[2]),atoi(argv[3]));
    else { fprintf(stderr,"unknown mode\n"); return 1; }
    return 0;
}
