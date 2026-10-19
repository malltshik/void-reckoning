-- 70_world: Chapter 2 content - XR-7PO, a dead Imperium archive stripped bare by
-- scavengers. It is a pure fight: no ore, no trade - the hold carries navigation keys.
--
-- XR-7PO's rules differ from the engine defaults, so this chapter *overrides* the engine
-- sim functions that encode them (71_station/73_combat): update_spawn (waves + the reaver),
-- hit_foe / hit_roid (drops), update_drops (pickup kinds), recover (death keeps the keys).
-- The enemy salvo (foes_def.n) and drop colours (drop.c) are engine features driven by data.

CHAPTER=2   -- seeds the system layout (srand 1000+CHAPTER) and tags the save

-- sprites from the shared sheet (the engine only defines SPR_PLAYER and SPR_SCOUT)
SPR_RAIDER=16
SPR_MILITIA=24

-- aggression: a fight, not a mining run - short lulls and bigger swarms than Ch1
FOE_CAP=10
SPAWN_MIN=300
SPAWN_VAR=300
WAVE_MIN=3
WAVE_VAR=3

RELIC_GOAL=24   -- navigation fragments needed; the 24th is torn from the reaver

foes_def={
 interceptor={hp=30,shd=0,spd=1.15,r=4,cd=24,range=105,dmg=5,bs=3.0,spr=SPR_SCOUT},
 lancer={hp=60,shd=30,spd=0.95,r=5,cd=44,range=130,dmg=7,bs=3.4,n=3,spr=SPR_RAIDER},
 reaver={hp=240,shd=140,spd=0.5,r=9,cd=40,range=150,dmg=11,bs=2.4,n=3,spr=SPR_MILITIA},
}
-- the swarm is mostly light interceptors, with the odd lancer escort
FOE_POOL={"interceptor","interceptor","interceptor","lancer"}

-- authored skeleton: the stripped archive (respawn / continue dock) and the jump gate
function ch_stations()
 add(stations,{x=392,y=128,kind="archive"})
 add(stations,{x=136,y=392,kind="gate"})
end

-- opening picket: called LAST by load_system so the seeded RNG order stays stable
function ch_foes()
 for i=1,4 do spawn_foe("interceptor",ARX-60+rnd(120),ARY+rnd(140)) end
end

-- compass: while hunting it tracks the nearest drone; then the archive, then the gate
function objective()
 if qs>=4 then return stations[2] end
 if qs>=3 then return stations[1] end
 local best=nil
 local bd=30000
 for f in all(foes) do
  local d=abs(f.x-p.x)+abs(f.y-p.y)
  if d<bd then bd=d best=f end
 end
 return best or stations[1]
end

function draw_stations()
 for s in all(stations) do
  local x=s.x local y=s.y
  if s.kind=="archive" then
   -- a dark monolith: sealed bays and one dead beacon still turning
   rectfill(x-16,y-9,x+16,y+9,1)
   rect(x-16,y-9,x+16,y+9,13)
   rect(x-11,y-4,x-5,y+4,5) rect(x-2,y-4,x+4,y+4,5) rect(x+7,y-4,x+13,y+4,5)
   pset(x,y-13,frame%40<20 and 8 or 2)
   print("ARCHIVE",x-14,y-18,GT)
  else
   -- relay satellite gate
   rectfill(x-2,y-5,x+2,y+5,13)
   rectfill(x-9,y-3,x-4,y+3,14) rectfill(x+4,y-3,x+9,y+3,14)
   line(x,y-5,x,y-9,5)
   circfill(x,y-10,1,frame%30<15 and 7 or 12)
   print("GATE",x-9,y-18,GT)
  end
 end
end
