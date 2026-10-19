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
  if s.kind=="outpost" then
   rectfill(s.x-6,s.y-6,s.x+6,s.y+6,9)
   rect(s.x-6,s.y-6,s.x+6,s.y+6,7)
   line(s.x-6,s.y,s.x+6,s.y,7)
   line(s.x,s.y-6,s.x,s.y+6,7)
   local c=10
   if frame%30<15 then c=7 end
   circ(s.x,s.y,11,c)
   print("OUTPOST",s.x-13,s.y-19,GT)
  else
   local c=10
   if frame%30<15 then c=11 end
   rect(s.x-4,s.y-4,s.x+4,s.y+4,c)
   line(s.x-8,s.y,s.x+8,s.y,c)
   line(s.x,s.y-8,s.x,s.y+8,c)
   print("GATE",s.x-9,s.y-16,GT)
  end
 end
end
