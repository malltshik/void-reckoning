-- 70_world: Chapter 2 content - XR-7PO, a dead Imperium archive stripped bare by
-- scavengers. No ore, no trade: the hold carries navigation relics, and every relic is
-- sealed in a container that must be sliced open (the minigame lives in 73_combat).
--
-- XR-7PO's rules differ from the engine defaults, so this chapter *overrides* the engine
-- sim functions that encode them (71_station/73_combat): hit_foe (salvage drops),
-- update_drops (pickup kinds + the alarm cool-down), recover (death keeps the relics).
-- The enemy salvo (foes_def.n) is an engine feature driven by data.

CHAPTER=2   -- seeds the system layout (srand 1000+CHAPTER) and tags the save

-- sprites from the shared sheet (the engine only defines SPR_PLAYER and SPR_SCOUT)
SPR_RAIDER=16

RELIC_GOAL=5   -- sealed relic containers drift in the field; the archive reads their key
ROID_CAP=0     -- no white rocks to mine: XR-7PO was stripped bare (the grey ones are scenery)

-- XR-7PO has no ambient patrols: WAVE_MIN=0 makes the engine's reinforcement loop spawn
-- nothing, so the swarm only ever answers an alarm (guards drop when the field is clear).
WAVE_MIN=0
WAVE_VAR=1

-- the alarm guard roster: fast interceptors, lancers join as the alarms get louder
foes_def={
 interceptor={hp=30,shd=0,spd=1.15,r=4,cd=24,range=105,dmg=5,bs=3.0,spr=SPR_SCOUT},
 lancer={hp=60,shd=30,spd=0.95,r=5,cd=44,range=130,dmg=7,bs=3.4,n=3,spr=SPR_RAIDER},
}

-- authored skeleton: the archive (respawn / continue dock), RELIC_GOAL sealed relic
-- containers spread around the disc, and the jump gate. Fixed positions (no rng here)
-- so none of them can land on the archive or the gate.
function ch_stations()
 add(stations,{x=392,y=128,kind="archive"})
 local cx=split("120,330,420,300,90")
 local cy=split("140,90,300,420,300")
 for i=1,RELIC_GOAL do
  add(stations,{x=cx[i],y=cy[i],kind="container",idx=i,label="slice"})
 end
 add(stations,{x=136,y=392,kind="gate"})
end

-- called LAST by load_system so the seeded RNG order stays stable. No opening patrol,
-- and the white mineable rocks go too: the field was picked clean years ago.
function ch_foes()
 for i=#roids,1,-1 do
  if roids[i].solid then deli(roids,i) end
 end
end

-- compass: the next sealed container in order, then the archive, then the gate
function objective()
 if qs>=4 then return stations[7] end
 if qs>=3 then return stations[1] end
 for i=2,6 do
  if not stations[i].sliced then return stations[i] end
 end
 return stations[1]
end

function draw_stations()
 for s in all(stations) do
  local x=s.x local y=s.y
  if s.kind=="archive" then
   -- a dark monolith with one dead beacon still turning
   rectfill(x-16,y-9,x+16,y+9,1)
   rect(x-16,y-9,x+16,y+9,13)
   rect(x-2,y-4,x+4,y+4,5)
   pset(x,y-13,frame%40<20 and 8 or 2)
   print("ARCHIVE",x-14,y-18,GT)
  elseif s.kind=="container" then
   -- a sealed crate with a lit seam; it goes dark once it is empty
   rectfill(x-6,y-5,x+6,y+5,1)
   rect(x-6,y-5,x+6,y+5,s.sliced and 6 or 13)
   line(x-6,y,x+6,y,s.sliced and 6 or 5)
   if not s.sliced then pset(x,y-8,frame%20<10 and (s.hot and 8 or 12) or 1) end
  else
   -- jump gate: two pylons with a shimmering field between them (sprite 40)
   rectfill(x-3,y-7,x+2,y+6,frame%40<20 and 12 or 13)
   sspr(64,16,16,16,x-8,y-8)
   pset(x,y-8,frame%24<12 and 7 or 13)
   print("GATE",x-9,y-18,GT)
  end
 end
end
