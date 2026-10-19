-- 72_story: Chapter 2 story - arrival at Kaelus Prime, check-in, the dockmaster
-- clearance negotiation, and the warp out.
--
-- *** PLACEHOLDER SCRIPT ***  Every string below is a stand-in: the author's real Ch2
-- script replaces it. Kept short so the shots clipping sweep stays green.
-- Canon/tone live in chapters/ch02/lore.md.

-- speaker patch tables: PP = pilot, NN = narration (no portrait)
local PP={w=1}
local NN={w=0}

talks={
 arrive={
  NN,
  "KAELUS PRIME",
  "IMPERIUM CORE APPROACH",
  PP,
  "the wormhole cast me out light-years off course.",
  "kaelus prime. the imperium's own face.",
  "traffic control is hailing me.",
 },
 checkin={
  PP,
  "courier 1393, sealed cargo, requesting clearance.",
  NN,
  "TRAFFIC CONTROL",
  "courier 1393. you were logged destroyed six cycles ago.",
  "nobody passes kaelus unflagged. the dockmaster will see you.",
 }
}
talkname={checkin="kaelus control"}

-- the chapter's negotiation set-piece (runtime: common/src/50_negotiation.lua).
-- A bribe buys clearance cleanly; a bluff without proof gets you flagged (ambush on undock).
negs={
 clearance={who=2,name="dockmaster",start="open",n={
  open={t="so the ghost courier walks in. sealed crate, no manifest. give me one reason i don't space you.",tm=300,to="bluff",o={
   {t="offer a bribe",c=100,to="paid"},
   {t="claim imperium property",to="bluff"},
  }},
  paid={t="credits and no questions. stamped. the gate is yours.",res=1,go=function() qs=2 end},
  bluff={t="he laughs. 'no seal, no title.' a klaxon starts. 'detain this one.'",res=2,go=function() qs=2 ambush=true end},
 }}
}

function mission_lines()
 if qs<2 then return {"[main] buy or bluff your way to gate clearance.",
   "[side] mine ore and sell it.","[side] destroy pirates for bounty."} end
 return {"[main] fly to the jump gate and jump."}
end

function inventory_lines()
 return {"$"..p.credits,
  "ore "..p.ore.." / "..p.mcargo,
  "missiles "..p.mis.." / "..p.mmis,
  qs>=2 and "clearance: granted" or "clearance: none"}
end

function init_story()
 qs=1
 ohint=false
 spg=1
 spt=0
 dg=nil
 spages={{kind="dlg",id="arrive"}}
end

function start_story()
 spg=1
 spt=0
end

function update_story()
 spt+=1
 if spt==1 then dlg_start(spages[spg].id) end
 update_dlg()
 if dg==nil then next_spage() end
end

function draw_story()
 draw_dlg()
end

function start_jump()
 if qs<2 then
  msg_set("CHECKPOINT - CLEARANCE REQUIRED")
  return
 end
 state=5
 jt=0
 sfx(7,3)
end

-- warp out of Kaelus. Keep every line <= 31 chars (shots clipping sweep).
jlines={
 "kaelus fills the rear view.",
 "the core draws closer now.",
 "i was meant to be a ghost.",
 "whatever is in this crate,",
 "they will kill to keep.",
}

-- end of chapter: hand off to ch03 in a multicart; a lone cart falls back to the title
function jump_end()
 if load("ch03")==false then reset_game() end
end

-- the dockmaster's flag: a patrol is waiting the moment you leave the dock
function ch_ambush()
 for i=1,3 do spawn_foe("scout",p.x+rnd(140)-70,p.y+rnd(140)-70) end
 msg_set("FLAGGED - PATROL INBOUND")
end
