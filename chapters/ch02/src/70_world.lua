-- 70_world: Chapter 2 world content - Kaelus Prime, the Imperium's own face.
-- The engine (common/src) calls these hooks; see AGENTS.md "Chapter contract".

CHAPTER=2   -- seeds the system layout (srand 1000+CHAPTER) and tags the save

foes_def={
 scout={hp=25,shd=0,spd=1.0,r=4,cd=30,range=90,dmg=5,bs=2.2,bounty=15,spr=SPR_SCOUT}
}
FOE_POOL={"scout"}

-- authored skeleton: the checkpoint (respawn dock) and the jump gate. The labour
-- platform of the Ch2 outline is represented in text for now (token budget); add it
-- back as a third station when there is room.
function ch_stations()
 add(stations,{x=150,y=110,kind="kaelus"})
 add(stations,{x=400,y=400,kind="gate"})
end

-- opening patrol: called LAST by load_system so the seeded RNG order stays stable
function ch_foes()
 for i=1,3 do spawn_foe("scout",300+rnd(80),300+rnd(80)) end
end

-- compass: the checkpoint until you have clearance, then the gate
function objective()
 return stations[qs>=2 and 2 or 1]
end

function draw_stations()
 for s in all(stations) do
  local x=s.x local y=s.y
  if s.kind=="kaelus" then
   -- imperial checkpoint: a banded ring, a central spire, a lit dock port
   circ(x,y,15,13) circ(x,y,11,6)
   circfill(x,y,5,1) circfill(x,y,3,12)
   line(x-15,y,x-5,y,6) line(x+5,y,x+15,y,6)
   rectfill(x-2,y-24,x+2,y-16,7)
   pset(x+13,y-8,frame%30<15 and 8 or 2)
   print("KAELUS",x-11,y-30,GT)
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
