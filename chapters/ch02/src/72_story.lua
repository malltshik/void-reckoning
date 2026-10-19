-- 72_story: Chapter 2 story - XR-7PO. The warp in from Chapter 1, the hostile signal,
-- the archive's short brief and code crack, and the warp out.
-- Tone/canon: chapters/ch02/lore.md (the cart's text is authoritative).

-- speaker patch tables: PP = pilot 1393 (left), RR = the other voice (right), NN = narration
local PP={w=1}
local RR={w=2}
local NN={w=0}

-- right-hand portrait blocks in the sheet (gen_gfx.py): red pilot 36 at (32,16),
-- terminal 38 at (48,16). Globals so 71_station can pick the terminal portrait too.
P_RES={32,16}
P_TERM={48,16}

-- a talk with a chosen right-hand portrait: the engine's PORT table is a global, so the
-- chapter can show a red pilot and a terminal without an engine change.
function talk(id,p)
 PORT[2]=p
 dlg_start(id)
end

talks={
 contact={
  NN,
  "INCOMING SIGNAL",
  "UNREGISTERED CHANNEL",
  RR,
  "courier. surrender your hold.",
  PP,
  "no.",
  RR,
  "fine. you're gonna die.",
 },
 archive={
  NN,
  "XR-7PO ARCHIVE",
  "TERMINAL: STILL RUNNING",
  RR,
  "i am the last thing awake here.",
  "the swarm tore out my navigation relics.",
  "bring them back and i will remember.",
 },
 slice={
  NN,
  "> relics loaded",
  NN,
  "> code accepted",
  RR,
  "coordinates recovered. the gate is open.",
 },
}
talkname={contact="resistance pilot",archive="archive terminal",slice="archive terminal"}

function mission_lines()
 if qs<3 then return {"[main] recover navigation relics ("..p.ore.."/"..RELIC_GOAL..").",
   "[side] salvage wrecks for fuel, missiles and hull."} end
 if qs==3 then return {"[main] dock the archive and crack the code."} end
 return {"[main] fly to the gate and jump."}
end

function inventory_lines()
 return {"relics "..p.ore.." / "..RELIC_GOAL,
  "missiles "..p.mis.." / "..p.mmis,
  "hull "..flr(p.hp).." / "..p.mhp,
  "fuel "..flr(p.fuel).." / "..p.mfuel,
  "cargo: sealed (br-11k0)"}
end

-- warp in from Chapter 1: the recap and the new goal. Keep lines <= 31 chars.
local JIN={
 "the blockade is behind you.",
 "you fitted a cell and jumped.",
 "the wormhole cast you out here.",
 "xr-7po: a dead archive.",
 "the coordinates are inside it.",
 "you don't know how yet.",
 "survive. recover them. get out.",
}

-- warp out
local JOUT={
 "the gate opens onto a road.",
 "the coordinates lead somewhere.",
 "xr-7po is dark behind you.",
 "the crate is still sealed.",
 "(to be continued...)",
}

function init_story()
 qs=1
 ohint=false
 slicing=nil
 bossq=0
 wave=0
 wavet=240
 cleared=true
 intro=false
 spg=1
 spt=0
 dg=nil
 p.credits=0
 p.mcargo=RELIC_GOAL
 jlines=JIN
 spages={{kind="dlg",id="contact"}}
end

-- a new game replays the warp that ended Chapter 1
function start_story()
 intro=true
 jlines=JIN
 jt=0
 state=5
end

function update_story()
 local pg=spages[spg]
 spt+=1
 if spt==1 then talk(pg.id,P_RES) end
 update_dlg()
 if dg==nil then next_spage() end
end

function draw_story()
 draw_dlg()
end

function start_jump()
 if qs<4 then
  msg_set("GATE LOCKED - NO COORDINATES")
  return
 end
 state=5
 jt=0
 jlines=JOUT
 sfx(7,3)
end

-- the intro warp ends in the incoming signal; the final warp hands off to Ch3
function jump_end()
 if intro then
  intro=false
  spg=1
  spt=0
  state=1
  sfx(7,1)
 else
  if load("ch03")==false then reset_game() end
 end
end
