-- Chapter 1 screenshot driver (run with: python common/tools/p8check.py shots ch01).
-- The heavy simulation is stubbed out, so scenes are staged by hand and drawn with the real
-- draw code. PNGs land in tmp/shots/. Camera is set manually (update_camera is stubbed).

_init()
local o=stations[1]
local g=stations[2]

-- the flight view fades the previous frame, so let a few frames settle before each shot
function snap(name,n)
 tick(n or 6)
 shot(name)
end

function cam()
 camx=p.x-64
 camy=p.y-64
end

state=0
snap("title",30)

-- intro: dialogue, flight into the wormhole, tunnel, terminal
state=1 spg=1 spt=0
snap("intro_dialogue",140)
spg=2 spt=0
snap("fly_early",30)
snap("fly_late",65)
spg=3 spt=0
snap("wormhole",60)
spg=4 spt=0
snap("terminal",70)

-- flight
state=2
p.x=o.x-10 p.y=o.y+14
cam()
snap("flight_dock",10)
spawn_foe("scout",p.x+44,p.y-26)
boom(p.x+22,p.y+12)
flt(p.x+10,p.y-12,"+$15",10)
p.chg=CHGMAX p.credits=125 p.ore=4 p.mis=0 p.hp=60 p.shd=20
msg_set("CARGO FULL")
snap("flight_busy",3)
p.chg=0 p.mis=10 p.hp=100 p.shd=50 msgt=0
p.x=g.x-8 p.y=g.y+10
cam()
snap("flight_gate",12)
p.x=ARX+ARR+90 p.y=ARY
cam()
while frame%30>5 do tick(1) end
snap("flight_dead_space",1)

-- station
dock(o)
snap("station_officer",90)
dg=nil
sm.sub="SOLD ORE +50$"
sm.i=3
snap("station_menu",2)

-- text-clip sweep (no screenshots; lib.lua logs any CLIP): every dialogue line at full
-- length, and every station action's success + failure message
state=1
for id,sc in pairs(talks) do
 dlg_start(id)
 for i=1,#sc do
  if type(sc[i])=="string" then
   dg.i=i dg.ch=#sc[i] dg.lines=nil dg.y=DY
   update_dlg()
   draw_dlg()
  end
 end
end
dg=nil
state=4
for it in all(sm.items) do
 for r=0,1 do
  p.credits=r*999 p.ore=r*3 p.hp=50 p.fuel=50 p.mis=r*5 qs=1
  it.act(sm)
  draw_station()
 end
end
qs=3 sm.items[5].act(sm) draw_station()
qs=1 p.credits=0 p.ore=0 p.hp=p.mhp p.fuel=p.mfuel p.mis=10 sm.sub=""

-- ship menu (also sweeps every carousel entry for text clipping)
open_menu()
snap("ship_menu",2)
for k=1,#mm.items do
 mm.i=k
 for ci=1,#mm.items[k].lines do
  mm.items[k].ci=ci
  draw_menu()
 end
end
mm.i=1

-- warp
state=5 jt=0
snap("warp",100)
jt=400
snap("warp_end",10)

-- game over + ending
state=2
cam()
tick(4)
state=6 dth="KILLED BY PIRATES" got=0
boom_big(p.x,p.y)
snap("game_over",8)
state=7 got=0
snap("ending",5)

finish("SHOTS")
