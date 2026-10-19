-- 72_story: Chapter 1 story - dialogue scripts, mission log, cutscene flow, warp, ending

-- dialogue scripts (format + runner: common/src/60_dialogue.lua).
-- Speaker patch tables keep scripts cheap to author: PP = pilot, RR = rooke / officer.
local PP={w=1}
local RR={w=2}
local NN={w=0}   -- narration: text only, no portrait drawn

-- a script is a flat list: patch tables switch speaker, strings get typed out
talks={
 intro={
  NN,
  "IMPERIUM CENTRAL COMMAND",
  "COURIER 1393 - BRIEFING",
  "ASSET: SEALED",
  "DESTINATION: BR-11K0",
  RR,
  "your training campaign is over, pilot. you're ready for your first mission.",
  "eleven thousand applicants. we chose you.",
  "this is a top-secret delivery run. even i don't know what's in the container.",
  "and to be honest? i don't want to know.",
  PP,
  "...",
  RR,
  "deliver it at all costs. may the imperium protect you.",
 },
 officer={
  RR,
  "so. an imperium courier, out here. in this system that uniform is a death sentence.",
  "your comms are dead and your hyper-cell is shot. you are not going anywhere without one.",
  "br-11k0? that chart's been scrubbed clean. nobody out here goes there.",
  "the white rocks carry ore. break them, sell it here, and i will fit you a spare cell.",
  "there's a word scratched on the wall in here. i can't read it. neither will you.",
  "then take the jump gate and get out. i never saw you. neither did anyone else.",
  PP,
  "understood.",
 },
}

-- per-talk speaker-name overrides (the officer reuses the second portrait's art)
talkname={officer="outpost officer"}

-- mission log for the ship systems menu: [main] objective vs [side] activities
function mission_lines()
 if not ohint then return {"no active orders. hail the outpost."} end
 local m=qs==1 and "break the white rocks and sell ore at the outpost."
  or qs==2 and "buy a hyper-cell at the outpost."
  or "fly to the jump gate and jump."
 return {"[main] "..m,"[side] destroy pirates for bounty.",
  "[side] mine and sell ore."}
end

function inventory_lines()
 return {"$"..p.credits,
  "ore "..p.ore.." / "..p.mcargo,
  "missiles "..p.mis.." / "..p.mmis,
  "cargo: sealed (br-11k0)",
  qs>=3 and "hyper-cell: fitted" or "hyper-cell: none"}
end

function init_story()
 qs=1
 ohint=false
 spg=1
 spt=0
 dg=nil
 spages={
  {kind="dlg",id="intro"},
  {kind="fly"},
  {kind="worm"},
  {kind="term",lines={
   "> critical: wormhole collision",
   "> critical: navigation data corrupted",
   "> critical: hyper-cell damaged",
   "> nav chart: warning entry erased"}}
 }
end

function start_story()
 spg=1
 spt=0
end

function next_spage()
 spg+=1
 spt=0
 if spg>#spages then state=2 end
end

function update_story()
 local pg=spages[spg]
 spt+=1
 if pg.kind=="dlg" then
  if spt==1 then dlg_start(pg.id) end
  update_dlg()
  if dg==nil then next_spage() end
  return
 end
 local ok=btnp(4) or btnp(5)
 if pg.kind=="fly" then
  if spt>112 or ok then next_spage() end
 elseif pg.kind=="worm" then
  if spt>150 or ok then next_spage() end
 elseif pg.kind=="term" then
  local tl=0
  for l in all(pg.lines) do tl+=#l end
  if ok then
   if spt*3<tl then spt=ceil(tl/3) else next_spage() end
  end
 end
end

function draw_story()
 local pg=spages[spg]
 if pg.kind=="fly" then draw_fly()
 elseif pg.kind=="worm" then draw_wormhole()
 elseif pg.kind=="term" then draw_term(pg)
 else draw_dlg() end
end

function draw_term(pg)
 local n=spt*3
 local y=30
 for i=1,#pg.lines do
  local s=pg.lines[i]
  local shown=sub(s,1,clampi(n,0,#s))
  for k in all(wrap(shown,29)) do
   print(k,8,y,GT)
   y+=8
  end
  n-=#s
 end
 if frame%30<15 then print(chr(16),8,y,GT) end
end

-- cutscene: the ship races through open space and is swallowed by the wormhole,
-- handing off to draw_wormhole (the tunnel collapse) on the next page.
function draw_fly()
 local t=spt
 -- star streaks whipping past, the wormhole swelling dead ahead, then a white flash
 for i=1,24 do
  local y=(i*37)%128
  local x=(i*53-t*5)%152-14
  line(x,y,x+4,y,i%4==0 and 7 or 5)
 end
 local wr=5+min(t,84)*0.29
 for r=0,2 do circ(100,64,wr*(0.45+r*0.28),1+r) end
 circfill(100,64,wr*0.34,13)
 circfill(100,64,wr*0.16,7)
 -- the ship races in from the left and reaches the core just before the flash
 spr(SPR_PLAYER,8+min(t,102)*0.9,50)
 if t>104 then circfill(100,64,min(140,(t-104)*18),7) end
end

function draw_wormhole()
 local cx=64
 local cy=58
 local wc={2,12,13}
 for i=5,1,-1 do circ(cx,cy,i*13,wc[1+flr(rnd(#wc))]) end
 for i=0,7 do
  local a=frame*0.02+i/8
  line(cx+cos(a)*24,cy+sin(a)*24,cx+cos(a)*96,cy+sin(a)*96,wc[1+flr(rnd(#wc))])
 end
 -- the ship, dragged into the collapsing core, spins as it is swallowed
 local sa=spt*0.05
 spr(SPR_PLAYER+ship_frame(sa),cx-4,cy-4)
 if spt>120 then circfill(cx,cy,min(60,(spt-120)*2),7) end
end

function start_jump()
 if qs<3 then
  msg_set("GATE LOCKED - FIT A HYPER-CELL")
  return
 end
 state=5
 jt=0
 sfx(7,3)
end

-- warp cutscene: the gate hurls you clear of the system, but your destination is
-- still unknown. Narrated in white (dialogue style) with no portraits.
-- Keep every line <= 32 chars: the screen is 128px and glyphs are 4px (shots test checks).
JPER=45
jlines={
 "the gate folds shut behind you.",
 "the system is gone.",
 "no patrol. no hunter.",
 "this is not your destination -",
 "only the far side of a doorway.",
 "the crate waits.",
 "the coordinates do not.",
 "(to be continued...)"
}

function update_jump()
 jt+=1
 if btnp(4) or btnp(5) then
  -- X skips the reveal; once every line is shown, X ends the chapter back at the title
  if jt>#jlines*JPER then reset_game() else jt=#jlines*JPER+1 end
 end
end

function draw_jump()
 -- warp: radial streaks racing outward from the core
 for i=0,19 do
  local a=i/20
  local r=8+((i*13+frame*16)%104)
  line(64+cos(a)*r,64+sin(a)*r,64+cos(a)*(r+9),64+sin(a)*(r+9),i%4==0 and 7 or 12)
 end
 -- narration revealed a line at a time
 local n=clampi(flr(jt/JPER)+1,0,#jlines)
 for i=1,n do
  local k=jlines[i]
  print(k,flr((128-sw(k))/2),12+(i-1)*11,7)
 end
 if jt>#jlines*JPER and frame%40<25 then pc(BX.." continue",118,GT) end
end
