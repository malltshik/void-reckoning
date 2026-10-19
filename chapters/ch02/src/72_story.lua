-- 72_story: Chapter 2 story - XR-7PO. Arrival and the scavenger picket's hail, the
-- archive's request, the terminal slice, and the warp out. Tone/canon: chapters/ch02/lore.md.

-- speaker patch tables: PP = pilot, RR = the other voice, NN = narration (no portrait)
local PP={w=1}
local RR={w=2}
local NN={w=0}

talks={
 arrive={
  NN,
  "XR-7PO",
  "IMPERIUM ARCHIVE - SEALED",
  "STATUS: STRIPPED, 400 CYCLES",
  PP,
  "the wormhole cast me out at the dead edge of the chart.",
  "xr-7po. an archive the imperium sealed and then forgot.",
  "someone did not forget it. the wreckage out here is fresh.",
 },
 hail={
  RR,
  "unregistered vessel. this system is claimed.",
  "dump your hold and your core, and the swarm lets you drift.",
  PP,
  "...",
  RR,
  "no answer. good. the screen was getting bored.",
 },
 archive={
  NN,
  "XR-7PO ARCHIVE",
  "TERMINAL: STILL RUNNING",
  RR,
  "the terminal speaks with a voice that has not been alive for a long time.",
  "it kept direction keys for a road it can no longer see.",
  "the scavengers tore twenty-four of them out. they wear them as trophies.",
  "bring the fragments back and i will remember where you are going.",
  PP,
  "and the scavengers?",
  RR,
  "they will send their reaver. they always do.",
 },
 slice={
  NN,
  "> inserting 24 fragments",
  NN,
  "> reassembling navigation key",
  NN,
  "> the archive remembers",
  RR,
  "there. a road, and a name at the end of it.",
  "the gate will hear you now. go, before the swarm wakes.",
 },
}
talkname={hail="scavenger picket",archive="archive terminal",slice="archive terminal"}

function mission_lines()
 if qs<3 then return {"[main] recover the navigation fragments ("..p.ore.."/"..RELIC_GOAL..").",
   "[side] salvage wrecks for fuel, missiles and hull."} end
 if qs==3 then return {"[main] dock the archive and slice its terminal."} end
 return {"[main] fly to the gate and jump."}
end

function inventory_lines()
 return {"fragments "..p.ore.." / "..RELIC_GOAL,
  "missiles "..p.mis.." / "..p.mmis,
  "hull "..flr(p.hp).." / "..p.mhp,
  "fuel "..flr(p.fuel).." / "..p.mfuel,
  "cargo: sealed (br-11k0)"}
end

function init_story()
 qs=1
 ohint=false
 slicing=nil
 bossq=0
 spg=1
 spt=0
 dg=nil
 p.credits=0
 p.mcargo=RELIC_GOAL
 spages={{kind="dlg",id="arrive"},{kind="dlg",id="hail"}}
end

function start_story()
 spg=1
 spt=0
end

function update_story()
 local pg=spages[spg]
 spt+=1
 if spt==1 then dlg_start(pg.id) end
 update_dlg()
 if dg==nil then next_spage() end
end

function draw_story()
 draw_dlg()
end

function start_jump()
 if qs<4 then
  msg_set("GATE LOCKED - NAV KEY INCOMPLETE")
  return
 end
 state=5
 jt=0
 sfx(7,3)
end

-- warp out of XR-7PO. Keep every line <= 31 chars (shots clipping sweep).
jlines={
 "xr-7po goes dark behind you.",
 "a dead archive, stripped bare.",
 "the crate never opened.",
 "ahead: a road, and a name.",
 "(to be continued...)",
}

-- end of chapter: hand off to ch03 in a multicart; a lone cart falls back to the title
function jump_end()
 if load("ch03")==false then reset_game() end
end
