pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- pico-8 tunes vol. 1
--  by @gruber_music / @krajzeg

vtop=20

------------------------------
-- utilities
------------------------------

function round(x)
 return flr(x+0.5)
end

function ceil(x)
 return -flr(-x)
end

function lerp(a,b,t)
 return b+(a-b)*(1-t)
end

function lerpp(ob,prop,tgt,t)
 ob[prop]=
  tgt+(ob[prop]-tgt)*(1-t)
 if abs(ob[prop]-tgt)<0.1 then
  ob[prop]=tgt
 end
end

soff={{x=1,y=0},{x=-1,y=0},{x=-1,y=1},{x=0,y=1},{x=1,y=1},{x=0,y=-1}}
function prints(txt,x,y,clr,align)
 sh,align=sh or 0,align or 0
 x-=#txt*4*align
 for o in all(soff) do
  print(txt,x+o.x,y+o.y,0)
 end
 print(txt,x,y,clr)
end

-- copies props to obj
-- if obj is nil, a new
-- object will be created,
-- so set(nil,{...}) copies
-- the object
function set(obj,props)
 obj=obj or {}
 for k,v in pairs(props) do
  obj[k]=v
 end
 return obj
end

function g_add(tab,ind,e)
 tab[ind]=tab[ind] or {}
 add(tab[ind],e)
end

------------------------------
-- class system
------------------------------

-- creates a "class" object
-- with support for basic
-- inheritance/initialization

object={}
 function object:extend(kob)
  kob=kob or {}
  kob.extends=self
  setmetatable(kob,{__index=self})
  kob.new=function(self,ob)
   ob=set(ob,{kind=kob})
   setmetatable(ob,{__index=kob})
   local ko,create_fn=kob
   while ko~=object do
    if ko.create~=create_fn then
     create_fn=ko.create
     create_fn(ob)
    end
    ko=ko.extends
   end
   return ob
  end 
  return kob
 end

-------------------------------
-- vectors & 3d
-------------------------------

vec={}
 function vec.__add(v1,v2)
  return v(v1.x+v2.x,v1.y+v2.y,v1.z+v2.z)
 end
 function vec.__sub(v1,v2)
  return v(v1.x-v2.x,v1.y-v2.y,v1.z-v2.z)
 end
 function vec.__mul(v1,a)
  return v(v1.x*a,v1.y*a,v1.z*a)
 end
 function vec:copy()
  local cpy=set({},self)
  setmetatable(cpy,vec)
  return cpy
 end
 function vec:str()
  return self.x..","..
   self.y..","..
   self.z
 end
vec.__index=vec
function vec:project(cx,cy)
 local dv=1+self.z/49
 return v(cx+self.x/dv,cy+self.y/dv,self.z)
end

function v(x,y,z)
 local nv={x=x,y=y,z=z}
 setmetatable(nv,vec)
 return nv
end

-------------------------------
-- polygons
-------------------------------

dummy_hole={yt=16000}

function fl_color(c)
 return function(x1,x2,y)
  rectfill(x1,y,x2,y,c)
 end
end
function fl_odd(c)
 return function(x1,x2,y)
  if band(y,1)==1 then
   rectfill(x1,y,x2,y,c)
  end
 end
end

function project(pts,cx,cy,...)
 for i,p in pairs(pts) do
  pts[i]=p:project(cx,cy)
 end
 return pts
end

function holed_ngon(pts,ln,hole)
 local xls,xrs,npts={},{},#pts
 for i=1,npts do
  ngon_edge(
   pts[i],pts[i%npts+1],
   xls,xrs
  )
 end
 --
 hole=hole or dummy_hole
 local htop,hbot,hl,hr=
  hole.yt,hole.yb,
  hole.xl,hole.xr
 for y,xl in pairs(xls) do
  local xr=xrs[y]
  if y<htop or y>hbot then
   ln(xl,xr,y)
  else
   local cl,cr=
    min(hl,xr),max(hr,xl)
   if xl<=cl then
    ln(xl,cl,y)
   end
   if cr<=xr then
    ln(cr,xr,y)
   end
  end
 end
end

function ngon_edge(a,b,xls,xrs)
 local ax,ay=a.x,round(a.y)
 local bx,by=b.x,round(b.y)
 if (ay==by) return

 local x,dx,stp=
  ax,(bx-ax)/abs(by-ay),1
 if by<ay then
  --switch direction and tables
  xrs,stp=xls,-1 
 end
 for y=ay,by,stp do
  xrs[y]=x
  x+=dx
 end
end

-------------------------------
-- bg draws
-------------------------------
   
function blank(clr)
 return function()
  rectfill(0,0,127,63,clr)
 end
end

function mapwrap(mx,my,w,h,vx,vy,wx,wy,tx,ty)
 vx=vx or 0
 vy=vy or 0
 tx=tx or 0
 ty=ty or 0
 local wp,hp=w*8,h*8
 local wd,hd=
  wx and 0 or wp,
  wy and 0 or hp
 
 return function(t)
  local dx,dy=
   tx+vx*t%wp,ty+vy*t%hp
  for x=dx-wd,dx+wd,wp do
   for y=dy-hd,dy+hd,hp do
    map(mx,my,x,y,w,h)
   end
  end
 end
end

-------------------------------
-- 0. title
-------------------------------

titletext={
 {"music by          ",15},
 {"     @gruber_music",7},
 {"with stuff by     ",15},
 {"          @krajzeg",7},
 {"",0},
 {"",0},
 {" prev/next   pause/play   ",12},
}
function title(cmul)
 return function(t)  
  for y=1,#titletext do
   local text,clr=
    unpack(titletext[y])
   prints(text,64,5+y*7,clr*cmul,0.5)
  end
 end
end

-------------------------------
-- 1. mario
-------------------------------

plgrass=v(0,2,0)

platform=object:extend()
 function platform:move()
  self.x-=2
 end
 
 function platform:dead()
  local plin=v(0,0,self.d*10)
  local rx=self.x-64+self.w*8
  local br=v(rx,0,self.d*10):project(64,32)
  return br.x<-2
 end
 
 function platform:draw_sides()
 local w,h=self.w,self.h
  local x,y=self.x,64-h*8  
  -- polygons
  local nx,ny=x-64,y-32
  local fl,fr=
   v(nx,ny,0),v(nx+w*8-1,ny,0)
  local plin=v(0,0,self.d*10)
  local bl,br=
   fl+plin,fr+plin
  if fr.x<0 then
	  local grf,grb=
	   fr+plgrass,br+plgrass
	  local side=project({grf,grb,grb,grf},64,32)
	  side[3].y=64
	  side[4].y=64
	  holed_ngon(side,fl_color(1))
	  holed_ngon(
	   project({fr,br,grb,grf},64,32),
	   fl_color(3)
   )	    
  end
  if fl.x>0 then
	  local grf,grb=
	   fl+plgrass,bl+plgrass
	  local side=project({grb,grf,grf,grb},64,32)
	  side[3].y=64
	  side[4].y=64
	  holed_ngon(side,fl_color(1))	   
	  holed_ngon(
	   project({bl,fl,grf,grb},64,32),
	   fl_color(3)
   )	    
  end
 end
 
 function platform:draw_fronts()
  local w,h=self.w,self.h
  local x,y=self.x,64-h*8  
  -- polygons
  local nx,ny=x-64,y-32
  local fl,fr=
   v(nx,ny,0),v(nx+w*8-1,ny,0)
  local plin=v(0,0,self.d*10)
  local bl,br=
   fl+plin,fr+plin
  local pts=project({fl,bl,br,fr},64,32)
  holed_ngon(
			pts,
   fl_color(11)
  )
  -- grass
  local prfl,prbl,prbr,prfr=
   unpack(pts)
  
  local grcnt=
   max(ceil((prfl.y-prbr.y)/3)+1,2)
  local stp=-1/(grcnt-1)
  for t=1,0,stp do
   local pl,pr=
    lerp(prfl,prbl,t),
    lerp(prfr,prbr,t)
   self:grass(pl,pr,1-t*0.2)
  end
  -- tiles
  local r=rnd()
  srand(self.seed)  
  for dx=0,w-1 do
   spr(4+rnd(2),x+dx*8,y)
   for dy=1,flr(h) do
    spr(20+rnd(4),x+dx*8,y+dy*8)
   end
  end
  srand(r)
 end
 
	function platform:grass(p1,p2,scl)
	 local sx=flr(32*scl)
	 local h=8*scl
	 local y=ceil(p1.y-h)
	 for x=p1.x,p2.x,sx do
	  local w=min((p2.x-x)/sx,1)
	  sspr(32,24,32*w,8,x,y,sx*w,h)
	 end
	end
 
jumper_frms={37,38,39,38}
jumper=object:extend()
 function jumper:update() 
  local nxt=self.seq[1]
  if (not nxt) return

  local tgty=64-nxt.h*8
  if self.air then
   self.y+=self.vy
   self.vy+=0.3
   if 40>=nxt.x and self.y>=tgty then
    self.y=tgty
    self.air=false
    del(self.seq,nxt)
   end
  else
   if nxt.x<=80 then
    self.air=true
    self.vy=-sqrt(
     21+self.y-tgty)*0.7
   end
  end 
 end
 function jumper:render(t)
  local frm
  if self.air then
   frm=36
  else
   frm=jumper_frms[flr(t*0.2%4)+1]
  end
  local p=v(-16,self.y-32,7):project(64,32)
  spr(frm,p.x-4,p.y-8)
 end

function platforms()
 local ps={}
 local last=platform:new({
  x=16,w=18,h=2.5,d=2,seed=323
 })
 local seq={}
 ps[rnd()]=last
 
 local jmp=jumper:new({seq=seq,y=44})
 
 return function(t)
  -- draw/update all
  for k,p in pairs(ps) do
   p:draw_sides()
  end
  for k,p in pairs(ps) do
   p:draw_fronts()
   p:move()
   if (p:dead()) ps[k]=nil
  end
  jmp:update()
  jmp:render(t)
  -- generate new platforms
  if last.x+last.w*8<160 then
   last=platform:new({
    x=176+rnd(16),
    w=flr(rnd(12))+4,
    h=mid(last.h+rnd(3)-1.5,0.5,3.5),
    d=1.8+rnd(0.4),seed=rnd()
   })
   ps[rnd()]=last
   add(seq,last)
  end
 end
end

-------------------------------
-- 2. pastoral
-------------------------------

function waterfront()
 rectfill(0,0,128,3,12)
 palt(14,false)
 map(64,0,0,3,16,8)
end

function wave(ys,h)
 local saddr=0x6000+(vtop+ys)*64
 local rf={}
 rf[0]=0
 for y=1,h-1 do
  rf[y]=rf[y-1]+rnd(0.6)-0.3
 end
 return function(t,dx)
  memcpy(0x1800,saddr,0x800)
  if btnp(4) then cstore() end
  for y=0,h-1 do
   local xs,xe=sin(t*0.01+rf[y])*2*y/h
   for i=1,4 do
    xe=i*32+
     sin(t*0.01+rf[y])*2*y/h
    palt(3,false)
    sspr((i-1)*32-dx,96+y,32,1,
     xs,ys+y,xe-xs,1)
    xs=xe
   end
  end
 end
end

function watersurf()
 local ds={}
 local cs={1,1,5,5,13,6,7}
 for i=0,127 do
  add(ds,{x=i,o=rnd()})
 end
 return function(t)
--  rectfill(0,34,127,34,13)
  for d in all(ds) do
   local s=sin(t*0.01+d.o)
   local c=cs[flr(4.5+s*3.49)]
   pset(d.x,35,c)
  end
 end
end

function fisherman()
 local l,d=26,0
 return function()
  if rnd()<0.01 then
   local tl=rnd(30)+6
   d=tl-l
  end
  if d~=0 then
   l+=sgn(d)
   d-=sgn(d)
  end
  spr(42,64,9,2,3)
  rectfill(79,17,79,17+l,6)
 end
end

function fishes(n)
 local fs={}
 for i=1,n do
  add(fs,{
   x=i/n*128+rnd(10)-5,
   y=rnd(),
   vy=0,
   s=56+i%2,
   d=rnd()>0.5 and 1 or -1
  })
 end
 return function()
  for f in all(fs) do
   f.x+=f.d*(0.4+f.y*0.2)
   if (f.x<-8) f.x+=148
   if (f.x>140) f.x-=148
   f.y=mid(f.y+f.vy,0,1)
   f.vy+=rnd(0.002)-0.002*f.y
   spr(f.s,f.x,f.y*12+37,
    1,1,f.d==1)
  end
 end
end

-------------------------------
-- 3. sand
-------------------------------

function unpack(a)
 if (#a==1) return a[1]
 if (#a==2) return a[1],a[2]
 if (#a==3) return a[1],a[2],a[3]
 if (#a==4) return a[1],a[2],a[3],a[4]
 if (#a==5) return a[1],a[2],a[3],a[4],a[5]
 if (#a==6) return a[1],a[2],a[3],a[4],a[5],a[6]
end

function fix(fn,...)
 local args={...}
 return function()
  return fn(unpack(args))
 end
end

function terrain(spd,avgh,rng,v,clr,sprx)
 local h,sp,beg,en,dy={0.5},{0},0,1,0
 local frac=0
 return function()  
  palt(14,false)
  while en~=beg do
   local prv=h[en]

   dy+=(rnd()-dy^1-(prv-0.5)*0.03-0.5)*v
   en=band(en+1,0x7f)
   h[en]=prv+dy*0.5
   sp[en]=(dy>0.05 and 0 or dy<-0.05 and 4 or 2)+flr(rnd(2))
  end
  
  for x=0,127 do
   local hx=band(beg+x,0x7f)
   local ty=63-avgh-h[hx]*rng
   rectfill(x,63,
    x,ty,
    clr)
   sspr(sprx+sp[hx],0,1,8,
    x,ty)
  end

  frac+=spd
  if frac>=1 then
   local d=flr(frac)
   beg=band(beg+d,0x7f)
   frac-=d
  end
 end
end

-------------------------------
-- 4. space
-------------------------------

function stars(n)
 local cols={1,5,13}
 local ss={}
 for i=1,n do
  add(ss,{
   off=rnd(128),
   y=rnd(64),
   c=rnd(3)+1
  })
 end
 
 return function(t)
  for s in all(ss) do
   local x=(s.off+t*s.c)%128
   pset(x,s.y,cols[flr(s.c)])
  end
 end
end

-------------------------------
-- 5. ice
-------------------------------

function ice()
 local upcs={12,6,12}
 local dncs={1,1,1,1,1,1,1,1}
 return function()
  gradrect(0,0,128,32,upcs)
  gradrect(0,32,128,32,dncs)
 end
end

function gradrect(sx,sy,w,h,cs)
 local d,n=h-1,#cs
 local corr=0.0
 for y=0,d do
  local desired=1+y*(n-1)/d
	 local actual=flr(desired+corr+0.5)
	 corr+=desired-actual
  rectfill(sx,sy+y,sx+w-1,sy+y,cs[actual])
 end
end

function floe()
 local animals={
  {68,4,-14,1,2},
  {69,0,-6,2,1},
  {85,4,-6,1,1},
  {0,0,0,0,0}
 }
 local fs={}
 local newf=function(i)
  local tp=flr(rnd(2))
  return {x=rnd(128)+128,
   y=37+i*2.5,o=rnd(),
   a=rnd()<0.6 and 4 or flr(rnd(4))+1,
   sp=102+tp*16}
 end
 for i=1,7 do
  add(fs,newf(i))
  fs[i].x=fs[i].x*2-256
 end

 return function(t)
  for i=1,#fs do
   local f=fs[i]
   local d=(1+sin(t*0.01+f.o))*1.99
   palette(5+flr(d))
   spr(f.sp,f.x,f.y+d,2,1)
   reset_palette()
   local as,ax,ay,aw,ah=unpack(animals[f.a])
   spr(as,f.x+ax,f.y+ay+d,aw,ah)
   f.x-=f.y/128
   if f.x<-20 then
    fs[i]=newf(i)
   end
  end
 end
end

-------------------------------
-- 6. nostalgia
-------------------------------

function nostalgiabg()
 return function()
  gradrect(0,0,128,64,{13,12,12,12,13})
 end
end

function casette()
 local reels={
  {52,-4.5},{76,-4.5}
 }
 local spokes={
  {0.6,-2.6},{1.6,-2.6},
  {2.6,-1.6},{2.6,-0.6}
 }
 local tape={}
 for i=0,30 do
  add(tape,{
   a=rnd(),r=rnd(5)+7
  })
 end
 
 return function(t)
  local td=t*0.005
  local d=sin(td)*8
  local by=34+d
  
  local p=flr(t/10%4)+1
  
  rectfill(38,by-19,89,by+14,0)
  rectfill(37,by-18,90,by+13,0)
  map(66,10,40,by-16,6,4)
  
  for r in all(reels) do
   local rx,ry=unpack(r)
   ry+=by
   local sx,sy=unpack(spokes[p])
   pset(rx+sx,ry+sy,15)
   pset(rx+sy,ry-sx,15)
   pset(rx-sx,ry-sy,15)
   pset(rx-sy,ry+sx,15)
  end
  
  local rx,ry=unpack(reels[1])
  ry+=by
  for tp in all(tape) do
   local a,r=tp.a-t*0.005,tp.r
   local px,py=
    rx+cos(a)*r,ry+sin(a)*r
   if pget(px,py)==5 then
    pset(px,py,1)
   elseif pget(px,py)==1 then
    pset(px,py,0)
   end
  end
 end
end

function rpset(x,y,c)
 pset(flr(x),flr(y),c)
end

-------------------------------
-- 7. dungeon
-------------------------------

function pillar()
 return function(t)
  local td=t*0.016
  local d=(td*4)%8
  for y=1-d,41-d,8 do
   sspr(96+d,56,8,8, 58,y,3,8)
   sspr(96+d,56,10,8, 61,y+1,10,8)
   sspr(98+d,56,8,8, 71,y,2,8)
  end
 end
end

function stairs()
 local hole={xl=54,xr=77,
  yt=0,yb=63}
 return function(t)
  local td=t*0.001%0.0625
  local flp=band(t*0.001/0.0625,1)==1
  local ba=-td
  local bh=80-td*64
  local sp
  for i=1,15 do
   local h,a=
    bh-i*4,
    ba-i*0.0625
   local t,r=stair(h,a)
   local bck=t[1].z>30
   holed_ngon(t,fl_color(1),
    bck and hole or nil)
   line(t[3].x,round(t[3].y),
    t[4].x,round(t[4].y),0)
   if r[1].x<55 then    
    line(r[1].x,round(r[1].y),
     r[4].x,round(r[4].y),1)
   end
   if i==10 then
    sp=(t[1]+t[3])*0.5
   end
  end
  spr(76,sp.x-7,sp.y-21,2,3,flp)  
 end
end

function stair(h,a)
 local pts,ap={},a+0.0625
 local b,d1,d2=
  v(0,h,30),
  v(sin(a),0,cos(a)),
  v(sin(ap),0,cos(ap))
 local hc=v(0,4,0)
 local ln,lf,rf,rn=
  b+d1*50,b+d1*15,
  b+d2*15,b+d2*50  
 local bn,bf=rn+hc,rf+hc
 return 
  project({ln,lf,rf,rn},64,0),
  project({rn,rf,bf,bn},64,0)
end

-------------------------------
-- 8. boss
-------------------------------

function bossbg(n,plt,bgc,lmt,bias)
 if (not bias) bias=0.1
 return function(t,dx)
  if t<15 then
   rectfill(0,0,127,63,bgc)
  else
   rectfill(0,62,63,63,bgc)
   rectfill(64,0,127,1,bgc)
	  for i=0,n do
	   local x,y=rnd(128)-64,rnd(64)-32
	   local d=x*x+y*y
	   x+=64
	   y+=32
	   local c,r=pget(x,y),rnd()
	   if r>0.97 or d<lmt then
	    c=bgc
	   elseif r<d/12000-bias then
	    c=sget(plt,c)
	   end
	   local dx,dy=
	    -(y-32)*0.05,(x-64)*0.05
	   circ(x+dx,y+dy,1,c)
	  end
	 end
 end
end

function bossmon()
 local stks={
  {12,0,0,3,2},
  {-12,0,0.5,3,2},
  {5,8,0.875,2,2},
  {-5,8,0.625,2,2},
  {6,-10,0.15,2,2},
  {-6,-10,0.35,2,2},
  
  {8,-8,0.06,4,8},
  {-8,-8,0.44,4,8},
  {12,2,0.9,4,8},
  {-12,2,0.6,4,8},
  
  {4,-10,0.18,1.5,8,true},
  {-4,-10,0.32,1.5,8,true},
  {0,-11,0.25,1.5,8,true},
 }
 local blink,blc=0,0
 return function(t)
  local td=t*0.005
  local by=36+sin(td)*10
  -- body
  circfill(64,by,13,0)
  spr(128,52,by-12,3,3)
  -- blinking
  if (rnd()<blc) then
   blink,blc=0,0
  else
   blink+=0.6
   blc+=0.0001
  end
  -- stalks/tentacles
  local i=0
  for stk in all(stks) do
   local dx,dy,a,l,c,eye=
    unpack(stk)
   local fx,fy=stalk(t,64+dx,by+dy,
    a,l,c,i*0.23)
   i+=1
   if eye then
    palt(14,false)
    palt(3,true)
    spr(176,fx-4,fy-4)
    local td=t*0.01
    local lid=mid(0,4,6-abs(blink-6))
    if lid>0 then
     local rx,ry=fx-2,fy-2
     rectfill(rx,ry,rx+3,ry+lid-1,8)
    end
   end
  end
 end
end

function stalk(t,sx,sy,a,l,c,off)
 local w=1
 local pts={}
 for i=0,5 do
  a+=sin(t*0.01+i*0.1827+off)*0.08
  local al,ar=a+0.25,a-0.25
  add(pts,v(sx+cos(al)*w,sy+sin(al)*w))
  add(pts,v(sx+cos(ar)*w,sy+sin(ar)*w))
  sx+=cos(a)*l
  sy+=sin(a)*l
  w*=0.8  
 end
 quadstrip(pts,fl_color(c))
 return sx,sy
end

function quadstrip(pts,fl)
 for si=1,#pts-3,2 do
  holed_ngon({
   pts[si],pts[si+2],
   pts[si+3],pts[si+1]
  },fl)
 end
end


-------------------------------
-- 9. evil
-------------------------------

function evilsky(nstars)
 local ss={}
 for i=1,nstars do
  add(ss,{x=rnd(128),y=rnd(40)})
 end
 return function(t)
	 local moony=28+sin(t/1024)*10
	 
	 gradrect(0,0,128,40,{1,2})
	 for s in all(ss) do
	  pset(s.x,s.y,13)
	 end
	 circfill(64,moony,17,8)
	 circfill(64,moony-1,16,14)
	 circfill(64,moony-2,14,7)
	 rectfill(0,40,127,63,0)
	end
end

function reflect(sy,rh,basey,scale,squeeze,amp,plt)
 local saddr=0x6000+0x40*(vtop+sy)
 --random factors
 local rf,rm={},{}
 for y=0,rh-1 do
  rf[y],rm[y]=
   rnd(),rnd(0.4)+0.8
 end
 
 return function(t)
  palt(14,false)
  memcpy(0x1800,saddr,0x800)
  if (btnp(5)) cstore()
  local ascl=scale
  local segs={}
  palette(plt)
  for y=0,rh-1 do
   local srcy=flr(127-y*1.2)
   local scl=y%2==0 
    and ascl or ascl*0.75
   for i=0,4 do
    segs[i]=(i/2-1)*scl+
     sin(t*rm[y]*0.02+rf[y]*i)*scl*amp
   end
   for i=0,3 do
    local xl,xr=
     64+segs[i],64+segs[i+1]
    sspr(
     16+24*i,srcy,24,1,
    xl,basey+y,xr-xl+1,1)
   end
   ascl*=squeeze
  end
 end
end

-------------------------------
-- 10. travel
-------------------------------

function plane(t)
 local y,r=32+sin(t*0.003)*12
 spr(140,80,y-8,2,2)
 line(79,y,79,y+sin(t*0.6)*3,7)
end

-------------------------------
-- 11. puzzle
-------------------------------

function questions(n,m)
 local qs={}
 for i=0,n-1 do
  add(qs,{
   cm=(rnd()+1)*0.001,
   sm=(rnd()+1)*0.001,
   co=rnd(),so=rnd(),
   dx=rnd(80)-40,
   dy=rnd(20)-10,
   p=3-flr(i*4/n)
  })
 end
 return function(t)
  for q in all(qs) do
   local x,y=
    cos(q.cm*t+q.co)*40+q.dx,
    sin(q.sm*t+q.so)*40+q.dy
   local scale=16*
    (0.8+sin(t*0.006+q.co)*0.4)
   palette(q.p)
   sspr(112,64,16,16,
    64+x-scale*0.5,
    32+y-scale*0.5,
    scale,scale)
  end
  reset_palette()
 end
end

-------------------------------
-- 12. village
-------------------------------

function hills()
 local hs={}
 for i=1,20 do
  local h=hill:new()
  sorted_insert(hs,h,hill.order)
  h.x=(h.x-128)*2
 end
 for i=1,100 do
  local c=cloud:new()
  sorted_insert(hs,c,hill.order)
  c.x=(c.x-128)*2
 end
 return function(t,dx)
	 gradrect(0,40,128,24,{6,7})
	 for h in all(hs) do
	  h:update()
	  h:render(dx)
	 end
	 for _,h in pairs(hs) do
	  if h:done() then
	   del(hs,h)
	   local rep=h.kind==hill
	    and hill:new()
	    or cloud:new()
	   sorted_insert(hs,rep,hill.order) 	  
	  end
	 end
 end
end

function sorted_insert(a,e,fn)
 local i,n=1,#a
 local key=fn(e)
 while i<=n and fn(a[i])<key do
  i+=1
 end
 for j=n,i,-1 do
  a[j+1]=a[j]
 end
 a[i]=e
end


hill=object:extend()
 function hill:create()
  self.y=rnd(18)
  self.r=rnd(10)+15
  self.x=128+self.r+rnd(127)
  self.z=self.r*(rnd(0.3)+0.1)
  self.vx=0.25+self.y/17*0.25
  if rnd()<0.3 then
   self.h={
    a=rnd(0.15)+0.2,
    d=rnd(0.2)+0.7,
    s=28+flr(rnd(4))
   }  
  end
 end
 function hill:update()
  self.x-=self.vx
 end
 function hill:done()
  return self.x<-self.r
 end
 function hill:render(dx)
  local x,y,z,r=
   round(self.x),46+self.y,self.z,
   self.r
  clip(-dx,0,128,vtop+y)
  circfill(x,y+z,r,11)
  circfill(x+4,y+z-2,r-4,3)
  if self.h then
   local a,d=self.h.a,
    self.h.d*self.r
   local hx,hy=round(cos(a)*d),sin(a)*d
   spr(self.h.s,x+hx-4,y+z+hy-14,1,2)
  end
 end
 function hill:order()
  return self.y
 end

cloud=object:extend()
 function cloud:create()
  self.y=rnd(24)
  self.x=136+rnd(127)
  self.s=172+flr(rnd(2))*16
  self.vx=0.33+self.y/17*0.33
 end
 function cloud:update()
  self.x-=self.vx
 end
 function cloud:done()
  return self.x<-24
 end
 function cloud:render(dx)
  clip(-dx,vtop,128,64)
  spr(self.s,self.x,38+self.y,
   3,1)
 end

-------------------------------
-- the pieces
-------------------------------

setlist={
 {
  at=0,title="demented mario",clr=3,
  draws={
   blank(12),
   terrain(0.5,34,10,0.2,13,54),
   platforms()
  }    
 },{
  at=6,title="pastoral",clr=4,
  draws={   
   waterfront,
   mapwrap(96,18,16,1,-1/4,0,false,true),
   mapwrap(96,19,16,1,-1/8,0,false,true,0,8),
   fisherman(),
   watersurf(),
   fishes(6),
   wave(35,24)
  }
 },{
  at=14,title="sand",clr=9,
  draws={
   blank(12),
   fix(spr,15,108,8),
   terrain(1,34,12,0.3,13,114),
   terrain(2,29,10,0.08,9,108),--spd,avgh,rng,v,clr)
   terrain(4,24,8,0.2,10,102),
   terrain(6,9,6,0.1,15,96)
  }
 },{  
  at=18,title="space",
  draws={
   blank(0),
   stars(50),
   mapwrap(0,8,16,8)
  }
 },{
  at=24,title="ice",clr=13,
  draws={
   ice(),
   mapwrap(32,8,16,1,-1/32,0,false,true,0,25),
   reflect(0,8,34,64,0.84,0.1,9),
   floe()
  }
 },{
  at=30,title="nostalgia",clr=12,
  draws={
   nostalgiabg(),
   casette()
  }
 },{
  at=36,title="dungeon",clr=1,
  draws={
   blank(0),
   pillar(),
   stairs()
  }
 },{
  at=42,title="boss",clr=8,
  draws={
   bossbg(400,10,0,1000),
   bossmon()
  }
 },{
  at=46,title="evil",
  clr=2,
  draws={
   blank(0),
   evilsky(0),
   mapwrap(32,16,16,3,-1/8,0,
    false,true,0,16),
   reflect(8,23,41,60,0.91,0.15,0),
  }
 },{
  at=48,title="travel",
  clr=13,
  draws={
   mapwrap(64,16,32,8,0.5,0),
   plane,
   mapwrap(96,16,16,8,1,0)
  }
 },{
  at=55,title="puzzle",
  clr=2,
  draws={
   blank(2),
   questions(100),
  }
 },{
  at=59,title="village",clr=7,
  draws={
   blank(12),
   hills()
  }
 }
}

setlist[0]={
 draws={ 
  title(0), 
  bossbg(400,12,0,50,0.04),
  title(1)
 }
}

------------------------------
-- entity system
------------------------------

-- entity root type
entity=object:extend({
 t=0,state="s_default"
})

-- entities with some special
-- props are tracked separately
tracked_props={"render"}

-- used to add/remove objects
-- in the entities_with list
function update_with_table(e,fn)
 for prop in all(tracked_props) do
  if (e[prop]) fn(entities_with,prop,e)   
 end
end
function g_del(l,prop,e)
 del(l[prop],e)
end

-- all entities do common
-- stuff when created -
-- mostly register in lists
function entity:create()
 e_id+=1
 entities[e_id..""]=self 
 update_with_table(self,g_add)
end

function entity:become(state)
 self.state,self.t=state,0
end

-- this is the core of our
-- _update() method - update
-- each entity in turn
function update_entities()
 for n,e in pairs(entities) do
  local update_fn=e[e.state]  
  if update_fn and update_fn(e,e.t) then
   -- remove entity
   entities[n]=nil
   update_with_table(e,g_del)
  else
   -- bump timer
   e.t+=1
  end
 end
end

------------------------------
-- entity rendering
------------------------------

-- renders entities, sorted by
-- z to get proper occlusion
function render_entities()
 local zsorted={}
 for e in all(entities_with.render) do
  g_add(zsorted,
   e.z and flr(e.z) or 20,
   e)  
 end

 for z=0,20 do  
  for e in all(zsorted[z]) do   
   e:render(e.t)  
   reset_drawstate()
  end
 end
end

function reset_drawstate()
 camera()
 palt(0,false)
 palt(14,true)
end

-------------------------------
-- album text
-------------------------------

textdisp=entity:extend({
 fac=2
})
 function textdisp:create()
  self.x=self.no*256+128
  self.trk=setlist[self.no]
  self.txt=
   "#"..self.no.." - "..self.trk.title
 end
 
 function textdisp:render()
  if (not cm:sees(self)) return
  cm:apply(self)
  
  local pre="#"..self.no..". "
  local tit=self.trk.title
  local dx=(#(pre..tit))*2
  
  rectfill(10,79,118,82,self.trk.clr or 1)
  prints(pre,64-dx,76,15,0.0)
  prints(tit,64+dx,76,7,1.0)
 end

-------------------------------
-- palette
-------------------------------

function palette(no)
 for i=0,15 do
  pal(i,sget(no,i))
 end
end
function reset_palette()
 pal()
 palt(0,false)
 palt(14,true)
end

-------------------------------
-- logo
-------------------------------

logo=entity:extend({
 z=10
})
 function logo:render()
  spr(32,43,vtop-15,4,2)
  spr(2,75,vtop-15,2,2)
 end

-------------------------------
-- album pics
-------------------------------

pic=entity:extend({
 fac=1,z=1,
})
 function pic:create()
  local trk=setlist[self.no]
  self.draws=trk.draws
  self.x=self.no*128+64
 end
 
 function pic:render(t)
  if not cm:sees(self) then
   self.t=0
   return
  end
  local dx=cm:apply(self)
  for d in all(self.draws) do
   clip(self.x-round(cm.x),vtop,128,64)
   reset_palette()
   d(t,dx)
  end
  clip()
 end

-------------------------------
-- hud
-------------------------------

hud=entity:extend({
 fac=0,x=0,z=2,
})
 function hud:render()
  cm:apply(self)
  rectfill(0,-2,127,-2,1)
  rectfill(0,65,127,65,1)  
 end

instr=entity:extend({
 z=2
})
instructions=
" prev/next      pause/play"
 function instr:render()
  print(instructions,0,120,1)
 end
-------------------------------
-- camera
-------------------------------

cam=entity:extend({x=64})
 function cam:s_default()
  local tgt=ply.no*128+64
  lerpp(self,"x",tgt,0.1)
 end
 
 function cam:sees(e)
  local dist=abs(e.x-self.x*e.fac)
  return abs(dist)<128
 end
 
 function cam:apply(e)
  local dx,dy=
   round(self.x*e.fac-e.x),-vtop
  camera(dx,dy)
  return dx,dy
 end
 
-------------------------------
-- player - music manager
-------------------------------

switch_delay=30

player=entity:extend()
 function player:create()
  self:switch(0)
 end
 
 function player:s_play()
  self:do_controls()
 end
 
 function player:s_pause()
  self:do_controls()
 end
 
 function player:s_switch(t)
  if t==switch_delay then
   self:play()
  end
  self:do_controls()
 end
 
 function player:do_controls()
  local swd=nil
  -- forward/back
  if (btnp(1)) swd=1
  if (btnp(0)) then
   swd=self.t<switch_delay
    and -1 or 0
  end
  if swd then
   self:switch(swd)
  end
  -- play/stop
  if btnp(4) or btnp(5) then
   if self.state=="s_play" then
    self:pause()
   else
    self:play()
   end
  end
 end
 
 function player:play()
  if self.trk.at then
   music(self.trk.at)
   self:become("s_play")
  end
 end
 
 function player:pause()
  music(-1,100)
  self:become("s_pause")
 end
 
 function player:switch(d)
  self:pause()
  self.no=
   (self.no+d)%(#setlist+1)
  self.trk=setlist[self.no]
  self:become("s_switch")
 end
 
-------------------------------
-- cover
-------------------------------

function cover()
 local bg=
  coverbg(700,12,0,1500,0.1)
 return function(t)
  bg(t)
  reset_drawstate()  
  rectfill(15,38,100,72,0)
  sspr(0,16,32,16,19,42,64,32)
  sspr(16,0,16,16,83,42,32,32)
 end
end
 
function coverbg(n,plt,bgc,lmt,bias)
 if (not bias) bias=0.1
 return function(t,dx)
  for i=0,n do
   local x,y=rnd(128)-64,rnd(128)-64
   local d=x*x+y*y
   x+=64
   y+=64
   local c,r=pget(x,y),rnd()
   if r>0.97 or d<lmt then
    c=bgc
   elseif r<d/20000-bias then
    c=sget(plt,c)
   end
   local dx,dy=
    -(y-64)*0.05,(x-64)*0.05
   if c~=6 then
    circ(x+dx,y+dy,1,c)
   end
  end
 end
end


--[[
cov=cover()
t=0
function _draw()
 cov(t)
 t+=1
end]]

-------------------------------
-- main loop
-------------------------------

entities,entities_with,e_id=
 {},{},1

function _init() 
 cls()
 
 ply=player:new({no=0})
 cm=cam:new()
 
 hud:new()
 logo:new()
 
 for no=0,#setlist do
  if not setlist[no].draws then
   setlist[no].draws={blank(no)}
  end
  if setlist[no].title then
   textdisp:new({no=no})
  end
  pic:new({no=no})
 end
end

function _update60()
 update_entities()
end

function _draw()
 local saddr=0x6000+88*0x40
 local len=40*0x40
 
 memset(saddr,0,len)
 
 reset_drawstate()
 render_entities()
end
if(_update60)_update=function()_update60()_update_buttons()_update60()end 
__sfx__
010f000005135051050c00005135091351c0150c1351d0150a1351501516015021350713500000051350000003135031350013500000021351b015031351a0150513504135000000713505135037153c7011b725
010f00000c03300000300152401524615200150c013210150c003190151a01500000246153c70129515295150c0332e5052e5150c60524615225150000022515297172b71529014297152461535015295151d015
010f000007135061350000009135071351f711000000510505135041350000007135051351c0151d0150313503135021350000005135031350a1050a135000000113502135031350413505135000000a13500000
010f00000c033225152e5153a515246152b7070a145350150c003290153200529005246152501526015220150c0331e0251f0252700524615225051a0152250522015225152201522515246150a7110a0011d005
0112000003744030250a7040a005137441302508744080251b7110a704037440302524615080240a7440a02508744087250a7040c0241674416025167251652527515140240c7440c025220152e015220150a525
011200000c033247151f5152271524615227151b5051b5151f5201f5201f5221f510225212252022522225150c0331b7151b5151b715246151b5151b5051b515275202752027522275151f5211f5201f5221f515
011200000c0330802508744080250872508044187151b7151b7010f0251174411025246150f0240c7440c0250c0330802508744080250872508044247152b715275020f0251174411025246150f0240c7440c025
011200002452024520245122451524615187151b7151f71527520275202751227515246151f7151b7151f715295202b5212b5122b5152461524715277152e715275002e715275022e715246152b7152771524715
011200002352023520235122351524615177151b7151f715275202752027512275152461523715277152e7152b5202c5212c5202c5202c5202c5222c5222c5222b5202b5202b5222b515225151f5151b51516515
011200000c0330802508744080250872508044177151b7151b7010f0251174411025246150f0240b7440b0250c0330802508744080250872524715277152e715080242e715080242e715246150f0240c7440c025
011600000042500415094250a4250042500415094250a42500425094253f2050a42508425094250a425074250c4250a42503425004150c4250a42503425004150c42500415186150042502425024250342504425
011600000c0330c4130f54510545186150c0330f545105450c0330f5450c41310545115450f545105450c0230c0330c4131554516545186150c03315545165450c0330c5450f4130f4130e5450e5450f54510545
0116000005425054150e4250f42505425054150e4250f425054250e4253f2050f4250d4250e4250f4250c4250a4250a42513425144150a4250a42513425144150a42509415086150741007410074120441101411
011600000c0330c4131454515545186150c03314545155450c033145450c413155451654514545155450c0230c0330c413195451a545186150c033195451a5451a520195201852017522175220c033186150c033
010b00200c03324510245102451024512245122751127510186151841516215184150c0031841516215134150c033114151321516415182151b4151d215224151861524415222151e4151d2151c4151b21518415
011400001051512515150151a5151051512515150151a5151051512515150151a5151051512515150151a5151051512515170151c5151051512515170151c5151051512515160151c5151051512515160151c515
011400000c0330253502525020450e6150252502045025250c0330253502525020450e6150252502045025250c0330252502045025350e6150204502535025250c0330253502525020450e615025250204502525
011400002c7252c0152c7152a0252a7152a0152a7152f0152c7252c0152c7152801525725250152a7252a0152072520715207151e7251e7151e7151e715217152072520715207151e7251e7151e7151e7151e715
011400000c0330653506525060450e6150652506045065250c0330653506525060450e6150652506045065250c0330952509045095350e6150904509535095250c0330953509525090450e615095250904509525
0114000020725200152071520015217252101521715210152c7252c0152c7152c0152a7252a0152a7152a015257252501525715250152672526015267153401532725310152d715280152672525015217151c015
010e000005145185111c725050250c12524515185150c04511045185151d515110250c0451d5151d0250c0450a0451a015190150a02505145190151a015050450c0451d0151c0150012502145187150414518715
010e000021745115152072521735186152072521735186052d7142b7142971426025240351151521035115151d0451c0051c0251d035186151c0251d035115151151530715247151871524716187160c70724717
010e000002145185111c72502125091452451518515090250e045185151d5150e025090451d5151d025090450a0451a015190150a02505045190151a015050450c0451d0151c0150012502145187150414518715
010e000029045000002802529035186152802529035000001a51515515115150e51518615000002603500000240450000023025240351861523025240350000015515185151c51521515186150c615280162d016
010e000002145185112072521025090452451518515090450e04521515265150e025090451d5151d01504045090451d01520015210250414520015210250404509045280152d0150702505145187150414518715
011a00000173401025117341102512734120250873408025127341202501734010251173411025087340802505734050250d7340d025147341402506734060250873408025127341202511734110250d7340d025
010d00200c0331b51119515195152071220712145151451518615317151d5151d515125050c03314515145150c0330150519515195150d517205161451514515186153171520515205150d5110c033145150c033
011a00000a7340a02511734110250d7340d02505734050250673406025147341402511734110250d7340d0250a7340a02511734110250d7340d02508734080250373403025127341202511734110250d7340d025
010d00200c0331b511295122951220712207122c5102c51018615315143151531514295150c03329515295150c0330150525515255150d517205162051520515186153171520515205150d5110c033145150c033
01180000021100211002110021120e1140e1100e1100e1120d1140d1100d1100d1120d1120940509110091120c1100c1100c1100c1120b1110b1100b1100b1120a1100a1100a1100a11209111091100911009112
01180000117201172011722117221d7201d7201d7221d7221c7211c7201c7201c7201c7221c72218720187221b7211b7201b7201b7201b7221b7221d7221d7221a7201a7201a7201a7201a7221a7221672016722
011800001972019720197221972218720187201872018720147201472015720157201f7211f7201d7201d7201c7201c7201c7221c7221a7201a7201a7221a7251a7201a7201a7221a72219721197201972219722
011800001a7201a7201a7221a7221c7201c7201c7221c7221e7201e7202172021720247212472023720237202272022720227202272022722227221f7201f7202272122720227202272221721217202172221722
0118000002114021100211002112091140911009110091120e1140e1100c1100c1120911209110081100811207110071100711007112061110611006110061120111101110011100111202111021100211002112
0118000020720207202072220722217202172021722217222b7212b72029720297202872128720267202672526720267202672026720267222672228721287202672026720267202672225721257202572225722
010e00000c0231951517516195150c0231751519516175150c0231951517516195150c0231751519516175150c023135151f0111f5110c0231751519516175150c0231e7111e7102a7100c023175151951617515
010e000000130070200c51000130070200a51000130070200c51000130070200a5200a5200a5120a5120a51200130070200c51000130070200a51000130070200c510001300b5200a5200a5200a5120a5120a512
010e00000c0231e5151c5161e5150c0231c5151e5161c5150c0231e5151c5161e5150c0231c5151e5161c5150c0230c51518011185110c0231c5151e5161c5150c0231e7111e7102a7100c023175151951617515
010e0000051300c02011010051300c0200f010051300c02011010051300c0200f0200f0200f0120f0120f012061300d02012010071300e02013010081300f0201503012020140101201015030120201401012010
010700000c5370f0370c5270f0270f537120370f527120271e537230371e527230272f537260372f52726027165371903716527190271c537190371c527210271c53621036245262102624536330362452633026
018800000074400730007320073200730007300073200732007300073200730007320073000732007320073200732007300073000730007320073000730007300073200732007300073000732007300073200732
01640020070140801107011060110701108011070110601100013080120701106511070110801707012060110c013080120701106011050110801008017005350053408010070110601100535080170701106011
018800000073000730007320073200730007300073200732007300073200730007320073000732007320073200732007300073000730007320073000730007300073200732007300073000732007300073200732
0164002006510075110851707512060110c0130801207011060110501108017070120801107011060110701108011075110651100523080120701108017005350053408012070110601100535080170701106511
011800001d5351f53516525275151d5351f53516525275151f5352053518525295151f5352053518525295151f5352053517525295151f5352053517525295151d5351f53516525275151d5351f5351652527515
010c00200c0330f13503130377140313533516337140c033306150c0330313003130031253e5153e5150c1430c043161340a1351b3130a1353a7143a7123a715306153e5150313003130031251b3130c0331b313
010c00200c0331413508130377140813533516337140c033306150c0330813008130081253e5153e5150c1330c0430f134031351b313031353a7143a7123a715306153e5150313003130031251b3130c0333e515
011800001f5452253527525295151f5452253527525295151f5452253527525295151f5452253527525295151f5452353527525295151f5452353527525295151f5452253527525295151f545225352752529515
010c002013035165351b0351d53513025165251b0251d52513015165151b0151d51513015165151b0151d51513015165151b0151d51513015165151b0151d51513015165151b0151d51513015165251b0351d545
011200000843508435122150043530615014351221502435034351221508435084353061512215054250341508435084350043501435306150243512215034351221512215084350843530615122151221524615
011200000c033242352323524235202351d2352a5111b1350c0331b1351d1351b135201351d135171350c0330c0332423523235202351d2351b235202352a5110c03326125271162c11523135201351d13512215
0112000001435014352a5110543530615064352a5110743508435115152a5110d43530615014352a511084150d4350d4352a5110543530615064352a5110743508435014352a5110143530615115152a52124615
011200000c033115152823529235282352923511515292350c0332823529216282252923511515115150c0330c033115151c1351d1351c1351d135115151d1350c03323135115152213523116221352013522135
0112000001435014352a5110543530615064352a5110743508435115152a5110d435306150143502435034350443513135141350743516135171350a435191351a1350d4351c1351d1351c1351d1352a5011e131
011200000c033115152823529235282352923511515292350c0332823529216282252923511515115150c0330c033192351a235246151c2351d2350c0331f235202350c033222352323522235232352a50130011
0114001800140005351c7341c725247342472505140055352173421725287342872504140045351f7341f725247342472502140025351d7341d72524734247250000000000000000000000000000000000000000
011400180c043287252b0152f72534015377253061528725290152d72530015377250c0432f7253001534725370153c725306152b7252d01532725370153b7250000000000000000000000000000000000000000
0114001809140095351f7341f7252473424725091400953518734187251f7341f72505140055351f7341f7252473424725051400553518734187251f7341f7250000000000000000000000000000000000000000
0114001802140025351f7341f725247342472504140045351f7341f725247342472505140055352b7242b715307243071507140075352b7242b71534724347150000000000000000000000000000000000000000
011400180c0433772534015307252f0152d725306152d7252f0153072534015377250c0433772534015307252f0152d725306152d7252f0153072534015377250000000000000000000000000000000000000000
011400180c0433c7253701534725300152f725306152f7253001534725370153c7250c0433c7253701534725300152f725306152f7253001534725370153c7250000000000000000000000000000000000000000
011400180c043287252b0152f725340153772530615287252901530725370153c7250c043287252901530725370153c72530615287252901530725370153c7250000000000000000000000000000000000000000
011400180c003287052b0052f705340053770530605287052900530705370053c7050c0032f7053000534705370053c705306052b7052d00532705370053b7050000000000000000000000000000000000000000
000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 00014243
00 00014243
01 00014243
00 00014243
00 02034243
02 02034243
00 04414243
00 04414243
00 04054243
00 04054243
01 04054243
00 04054243
00 06074243
02 08094243
01 0a0b4243
00 0c0d4243
00 0a0e4243
02 0c0e4243
00 10414243
01 100f4243
00 100f4243
00 10114243
00 12114243
02 12134243
01 14154243
00 14154243
00 16154243
00 16154243
00 18174243
02 16174243
00 19414243
01 191a4243
00 191a4243
00 1b1a4243
00 191c4243
02 1b1c4243
01 1d1e4243
00 1d1f4243
00 1d1e4243
00 1d1f4243
00 21204243
02 1d224243
00 27414243
01 24234243
00 24234243
02 26254243
01 28294243
03 2a2b4243
01 2d304243
00 2e304243
00 2d304243
00 2e304243
00 2d2c4243
00 2d2c4243
02 2e2f4243
01 31324243
00 31324243
00 33344243
02 35364243
01 3738423f
00 3738423f
00 393b423f
00 393c423f
02 3a3d423f
