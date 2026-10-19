-- 70_world: Chapter 2 content - XR-7PO, a dead Imperium archive stripped bare by
-- scavengers. It is a pure fight: no ore, no trade - the hold carries navigation keys.
--
-- XR-7PO's rules differ from the engine defaults, so this chapter *overrides* the engine
-- sim functions that encode them (71_station/73_combat): update_spawn (paced waves + the
-- reaver), hit_foe / hit_roid (drops), update_drops (pickup kinds), recover (death keeps the
-- keys). The enemy salvo (foes_def.n) and drop colours (drop.c) are engine features driven by data.

CHAPTER=2   -- seeds the system layout (srand 1000+CHAPTER) and tags the save

-- sprites from the shared sheet (the engine only defines SPR_PLAYER and SPR_SCOUT)
SPR_RAIDER=16
SPR_MILITIA=24

RELIC_GOAL=24   -- navigation relics needed; the 24th is torn from the reaver

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

-- no opening patrol: the first wave arrives after the warp-in signal (73_combat.update_spawn),
-- and this hook is still called LAST by load_system so the seeded RNG order stays stable
function ch_foes()
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
   -- jump gate: two pylons with a shimmering field between them (sprite 40)
   rectfill(x-3,y-7,x+2,y+6,frame%40<20 and 12 or 13)
   sspr(64,16,16,16,x-8,y-8)
   pset(x,y-8,frame%24<12 and 7 or 13)
   print("GATE",x-9,y-18,GT)
  end
 end
end
