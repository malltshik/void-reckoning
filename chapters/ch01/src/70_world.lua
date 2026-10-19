-- 70_world: Chapter 1 world content - the authored layout, the enemy roster and how the
-- stations look. The engine (common/src) calls these hooks; see AGENTS.md "Chapter contract".

CHAPTER=1   -- seeds the system layout (srand 1000+CHAPTER) and tags the save

-- enemy archetypes that exist in this chapter (stat baselines: DESIGN section 9) and the
-- pool update_spawn draws reinforcements from. spr = base frame of the 8-angle sprite.
foes_def={
 scout={hp=25,shd=0,spd=1.0,r=4,cd=30,range=90,dmg=5,bs=2.2,bounty=15,spr=SPR_SCOUT}
}
FOE_POOL={"scout"}

-- authored skeleton: load_system calls this first, then seeds planets/rocks around it
function ch_stations()
 add(stations,{x=150,y=110,kind="outpost"})
 add(stations,{x=400,y=400,kind="gate"})
end

-- opening patrol: called LAST by load_system so the seeded RNG order stays stable
function ch_foes()
 for i=1,2 do
  spawn_foe("scout",300+rnd(80),300+rnd(80))
 end
end

-- what the radar compass points at: the outpost, then the gate once the cell is fitted
function objective()
 return stations[qs>=3 and 2 or 1]
end

function draw_stations()
 for s in all(stations) do
  local x=s.x local y=s.y
  if s.kind=="outpost" then
   -- domed outpost on a lit moon chunk (ref: dome base)
   circfill(x,y+5,12,1)
   circfill(x-2,y+3,9,13)
   circfill(x-5,y+7,2,2)
   circfill(x+4,y+7,2,2)
   circfill(x,y-2,8,12)
   circ(x,y-2,8,1)
   rectfill(x-3,y+2,x+3,y+7,5)
   rectfill(x-1,y+4,x+1,y+6,9)
   pset(x+7,y-6,frame%30<15 and 8 or 2)
   print("OUTPOST",x-13,y-22,GT)
  else
   -- relay satellite: hull, solar panels, beacon (ref: satellite)
   rectfill(x-2,y-5,x+2,y+5,13)
   rectfill(x-1,y-3,x+1,y+2,12)
   rectfill(x-9,y-3,x-4,y+3,14)
   rectfill(x+4,y-3,x+9,y+3,14)
   line(x,y-5,x,y-9,5)
   circfill(x,y-10,1,frame%30<15 and 7 or 12)
   print("GATE",x-9,y-18,GT)
  end
 end
end
