-- Chapter 2 screenshot driver (run with: python common/tools/p8check.py shots ch02).
-- The heavy simulation is stubbed out, so scenes are staged by hand and drawn with the real
-- draw code. PNGs land in tmp/shots/. Camera is set manually (update_camera is stubbed).

_init()
local k=stations[1]
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

-- warp in from Chapter 1, then the incoming signal
state=5 jt=40
snap("warp_in",6)
state=1 spg=1 spt=0
snap("contact_dialogue",140)
-- hold on the red pilot's line so the portrait is in the shot
dg.i=5 dg.w=2 dg.ch=#talks.contact[5] dg.lines=nil
snap("contact_pilot",2)

-- flight
state=2
p.x=k.x-10 p.y=k.y+14
cam()
snap("flight_archive",10)
spawn_foe("interceptor",p.x+44,p.y-26)
spawn_foe("lancer",p.x-40,p.y+30)
boom(p.x+22,p.y+12)
flt(p.x+10,p.y-12,"+relic",12)
add(drops,{x=p.x+20,y=p.y-6,kind=2,c=12})
add(drops,{x=p.x-18,y=p.y+10,kind=3,c=9})
p.chg=CHGMAX p.ore=12 p.mis=0 p.hp=60 p.shd=20
msg_set("RELICS 12 / 24")
snap("flight_busy",3)
p.chg=0 p.mis=10 p.hp=100 p.shd=50 msgt=0
p.x=g.x-8 p.y=g.y+10
cam()
snap("flight_gate",12)
-- the reaver
foes={}
spawn_foe("reaver",p.x+44,p.y-30)
spawn_foe("interceptor",p.x-50,p.y+20)
msg_set("THE REAVER WAKES")
snap("flight_reaver",3)

-- station: the archive's request, then the terminal slice
foes={}
p.x=k.x p.y=k.y+8
qs=3
dock(k)
snap("station_archive",100)
-- hold on the terminal's line so the portrait is in the shot
dg.i=5 dg.w=2 dg.ch=#talks.archive[5] dg.lines=nil
snap("station_terminal",2)
dg=nil slicing=nil
sm.items[2].act(sm)
snap("station_slice",120)
dg=nil slicing=nil
sm.i=1 sm.sub=""
snap("station_menu",2)

-- text-clip sweep: every dialogue line
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
dg=nil state=4

-- station action sweep (both outcomes), then reset
for r=0,1 do
 for it in all(sm.items) do
  p.ore=r*RELIC_GOAL
  it.act(sm)
  draw_station()
 end
end
sm.sub="" p.ore=3 qs=3

-- ship menu (also sweeps every carousel entry for text clipping)
open_menu()
snap("ship_menu",2)
for kk=1,#mm.items do
 mm.i=kk
 for ci=1,#mm.items[kk].lines do
  mm.items[kk].ci=ci
  draw_menu()
 end
end
mm.i=1

-- warp
state=5 jt=0
snap("warp",100)
jt=400
snap("warp_end",10)

-- game over
state=2
cam()
tick(4)
state=6 dth="KILLED BY PIRATES" got=0
boom_big(p.x,p.y)
snap("game_over",8)

finish("SHOTS")
