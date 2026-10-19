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
   -- ring station: a banded wheel, four spokes, a lit hub, panels and a dock port
   circ(x,y,13,1)
   circ(x,y,12,6)
   circ(x,y,11,6)
   circ(x,y,4,1)
   circfill(x,y,2,10)
   line(x-11,y,x-4,y,6)
   line(x+4,y,x+11,y,6)
   line(x,y-11,x,y-4,6)
   line(x,y+11,x,y+4,6)
   rectfill(x-19,y-2,x-13,y+2,12)
   rectfill(x+13,y-2,x+19,y+2,12)
   rectfill(x-3,y-17,x+3,y-12,6)
   rectfill(x-1,y-16,x+1,y-13,9)
   pset(x+11,y-7,frame%30<15 and 8 or 2)
   print("OUTPOST",x-13,y-26,GT)
  else
   -- jump gate: two pylons with a shimmering field between them (sprite 40)
   rectfill(x-3,y-7,x+2,y+6,frame%40<20 and 12 or 13)
   sspr(64,16,16,16,x-8,y-8)
   pset(x,y-8,frame%24<12 and 7 or 13)
   print("GATE",x-9,y-18,GT)
  end
 end
end
