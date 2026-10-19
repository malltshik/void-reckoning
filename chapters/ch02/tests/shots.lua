-- Chapter 2 screenshot driver (run with: python common/tools/p8check.py shots ch02).
-- The heavy simulation is stubbed out, so scenes are staged by hand and drawn with the real
-- draw code. PNGs land in tmp/shots/. Camera is set manually (update_camera is stubbed).

_init()
local a=stations[1]

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
start_story()
jt=40
snap("warp_in",6)
state=1 spg=1 spt=0
snap("contact_dialogue",140)
-- hold on the red pilot's line so the portrait is in the shot
dg.i=5 dg.w=2 dg.ch=#talks.contact[5] dg.lines=nil
snap("contact_pilot",2)
dg=nil

-- flight past the archive, then a busy field around a container
state=2
p.x=a.x-10 p.y=a.y+14
cam()
snap("flight_archive",10)
local c=stations[2]
p.x=c.x-12 p.y=c.y+10
cam()
spawn_foe("interceptor",p.x+46,p.y-24)
spawn_foe("lancer",p.x-42,p.y+28)
boom(p.x+22,p.y+12)
flt(c.x,c.y-10,"+relic",12)
add(drops,{x=p.x+20,y=p.y-6,kind=3,c=9})
add(drops,{x=p.x-18,y=p.y+10,kind=4,c=7})
p.chg=CHGMAX p.ore=2 p.mis=4 p.hp=60 p.shd=20
snap("flight_busy",3)
p.chg=0 p.mis=10 p.hp=100 p.shd=50 msgt=0
p.x=stations[7].x-8 p.y=stations[7].y+10
cam()
snap("flight_gate",12)

-- the slicing minigame: a container, then the archive's terminal (hardest timer)
start_slice(c)
snap("minigame",4)
qs=3
start_slice(a)
snap("minigame_terminal",4)
mg=nil

-- a timed-out slice: the alarm trips and the guards come
p.x=c.x p.y=c.y
cam()
start_slice(c)
mg.t=1
tick(2)
snap("flight_alarm",4)
foes={} stations[2].hot=nil msgt=0

-- station: the archive's brief, the terminal portrait, then the silent screen
p.x=a.x p.y=a.y+8
ohint=false
dock(a)
snap("station_archive",100)
dg.i=5 dg.w=2 dg.ch=#talks.archive[5] dg.lines=nil
snap("station_terminal",2)
dg=nil
snap("station_silent",4)

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

-- warp out
start_jump()
snap("warp",100)
jt=400
snap("warp_end",10)

-- game over
state=2
cam()
tick(4)
state=6 dth="KILLED BY SCAVENGERS" got=0
boom_big(p.x,p.y)
snap("game_over",8)

finish("SHOTS")
