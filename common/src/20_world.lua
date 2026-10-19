-- 20_world: system generation, hazards, camera draw

-- solid (mineable) rocks are kept topped up: as you mine them they respawn over time
ROID_CAP=22
ROID_RESPAWN=150
ROID_HP=12

function spawn_roid()
 local a=rnd(1)
 local rr=rnd(1)*(ARR-30)
 local x=ARX+cos(a)*rr
 local y=ARY+sin(a)*rr
 if hit2(x,y,p.x,p.y,30) then return end
 add(roids,{x=x,y=y,dx=(rnd(1)-0.5)*0.4,dy=(rnd(1)-0.5)*0.4,r=3+rnd(4),hp=ROID_HP,c=7,solid=true})
end

-- build a system: the chapter authors the skeleton (ch_stations, ch_foes - see
-- chapters/<ch>/src/70_world.lua); planets and rocks are seeded dressing around it.
-- The layout seed (`SEED`) is picked per new game and saved, so a continue rebuilds the
-- same map. The RNG call order is part of the layout: do not reorder it.
function load_system()
 srand(SEED)
 planets={} stations={} roids={} foes={} drops={} bullets={} missiles={} parts={} blasts={} floats={}
 ch_stations()
 active=stations[1] -- the dock you respawn / continue at
 for i=1,4+flr(rnd(3)) do
  local a=rnd(1)
  local rr=rnd(1)*(ARR-50)
  local x=ARX+cos(a)*rr
  local y=ARY+sin(a)*rr
  local clear=true
  for s in all(stations) do
   if abs(x-s.x)+abs(y-s.y)<=60 then clear=false end
  end
  if clear then
   add(planets,{x=x,y=y,r=10+rnd(12),c=1+flr(rnd(15))})
  end
 end
 for i=1,36 do
  -- solid = white rock you can mine/ram; the dark/grey ones are just background
  -- depth (non-solid) so they never look like a hazard you can hit.
  local solid=rnd(1)<0.6
  local c=7
  if not solid then
   if rnd(1)<0.4 then c=1 else c=5 end
  end
  local a=rnd(1)
  local rr=rnd(1)*(ARR-20)
  add(roids,{x=ARX+cos(a)*rr,y=ARY+sin(a)*rr,
   dx=(rnd(1)-0.5)*0.4,dy=(rnd(1)-0.5)*0.4,r=3+rnd(4),hp=ROID_HP,c=c,solid=solid})
 end
 ch_foes()
 p.x=ARX
 p.y=ARY+80
 p.dx=0
 p.dy=0
 spawnt=SPAWN_MIN
 roidt=ROID_RESPAWN
 srand(SEED+8000)
 ne_stars()
end
-- parallax starfield: one fixed pool, tiled with a screen-space modulo so a few
-- stars fill the whole view. Depth `z` scales the parallax (near = fast).
function ne_stars()
 stars={}
 local cc={1,1,1,5,5,6,7,12,13}
 for i=1,90 do
  add(stars,{x=rnd(2048),y=rnd(2048),z=1+rnd(3),c=cc[1+flr(rnd(#cc))]})
 end
end

-- Motion-trail fade: dim every colour on screen one step toward black (two steps on odd
-- frames, for a dithered fade). Done by redrawing the screen onto itself through the draw
-- palette: poke(0x5f54,0x60) makes the screen the sprite source, so one sspr remaps all
-- 16k pixels in C. Colour 0 is transparent to sspr, which is fine - it is already black.
DIM=split"0,0,0,1,1,1,5,6,4,4,9,3,2,2,2,9"

function fade_screen()
 for i=0,15 do
  local v=DIM[i+1]
  pal(i,frame%2<1 and v or DIM[v+1])
 end
 poke(0x5f54,0x60)
 sspr(0,0,128,128,0,0)
 poke(0x5f54,0)
 pal()
end

function draw_flight()
 fade_screen()
 for s in all(stars) do
  pset((s.x-camx)/s.z%128,(s.y-camy)/s.z%128,s.c)
 end
 camera(camx,camy)
 -- background (non-solid) rocks drift behind everything, dim + no outline
 for r in all(roids) do if not r.solid then circfill(r.x,r.y,r.r,r.c) end end
 for pl in all(planets) do
  circfill(pl.x,pl.y,pl.r,pl.c)
  circfill(pl.x-pl.r*0.3,pl.y-pl.r*0.3,pl.r*0.55,pl.c+1)
  circ(pl.x,pl.y,pl.r,0)
 end
 -- solid rocks sit on top: bright fill + outline so they read as foreground
 for r in all(roids) do
  if r.solid then
   circfill(r.x,r.y,r.r,r.c)
   circ(r.x,r.y,r.r,1)
  end
 end
 for o in all(drops) do
  -- a chapter may colour a drop via o.c (relic vs salvage); ore keeps the old blink
  local c=o.c or (frame%20<10 and 11 or 10)
  rectfill(o.x-2,o.y-2,o.x+2,o.y+2,c)
 end
 draw_parts()
 draw_floats()
 for b in all(bullets) do
  if b.own==0 then pset(b.x,b.y,7) else pset(b.x,b.y,8) end
 end
 for m in all(missiles) do
  circfill(m.x,m.y,1,11)
 end
 draw_foes()
 draw_stations()
 draw_player()
 camera()
  local st=nearest_station(20)
  if st then pc(BX..(st.kind=="gate" and " jump" or " dock"),105,GT) end
  -- dead space warning (past the system edge) / stranded warning (no fuel inside)
 local ad=arena_dist(p.x,p.y)
 if frame%30<20 then
  if ad>ARR then pc("dead space area",30,8)
  elseif p.fuel<=0 then pc("no fuel",44,8) end
 end
 draw_hud()
 draw_radar()
 draw_msg()
end

function draw_floats()
 for q in all(floats) do
  print(q.s,q.x-sw(q.s)*0.5,q.y,q.t<20 and frame%4<2 and 6 or q.c)
 end
end

function draw_parts()
 for q in all(parts) do
  local c=q.c or (q.t>6 and 10 or 2)
  pset(q.x,q.y,c)
  if (q.s or 1)>1 and frame%2<1 then
   pset(q.x+1,q.y,c)
   pset(q.x,q.y+1,c)
  end
 end
 for b in all(blasts) do
  circ(b.x,b.y,b.r,b.c)
 end
end

-- sprite bases in the sheet (see tools/gen_gfx.py): 8 angle frames each. The sheet also
-- holds a raider (16) and militia gunship (24) for later chapters' foes_def.spr.
SPR_PLAYER=0
SPR_SCOUT=8

-- heading (turns, atan2 convention) -> frame 0..7 (0=E,1=NE,2=N,3=NW,4=W,5=SW,6=S,7=SE)
function ship_frame(a)
 return flr(a*8+0.5)%8
end

function draw_player()
 local a=p.a
 local k=ship_frame(a)
 spr(SPR_PLAYER+k,p.x-4,p.y-4)
 -- engine flicker out the back while under way
 if abs(p.dx)+abs(p.dy)>0.5 and frame%4<2 then
  local b=a+0.5
  pset(p.x+cos(b)*4,p.y+sin(b)*4,9)
 end
 if p.scd>150 and frame%6<3 then circ(p.x,p.y,7,8) end
 -- ready cue: ring the ship while the cannon sits at full charge
 if p.chg>=CHGMAX then circ(p.x,p.y,6,10) end
end

function draw_foes()
 for f in all(foes) do
  local a=atan2(p.x-f.x,p.y-f.y)
  spr(foes_def[f.kind].spr+ship_frame(a),f.x-4,f.y-4)
 end
end
