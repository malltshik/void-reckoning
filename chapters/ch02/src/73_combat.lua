-- 73_combat: XR-7PO's combat rules. These override engine sim functions because the rules
-- differ (see the header of 70_world.lua). Functions are globals, so a later definition
-- wins; the engine calls them by name at run time and the harness stubs by name.
--
-- THE SLICING MINIGAME: a stream of random symbols hides exactly one 4-char sequence that
-- appears twice. Find it, move the 4-char window over either copy (arrows shift by one
-- symbol) and take it before the timer empties. Every container slices faster than the
-- last; a timeout trips the alarm and the guards come; a wrong pick just buzzes.

-- frames: containers 1-5, then the archive's terminal. Playtest: even the easiest slice
-- was too short, so the first is now 10x longer and the hardest 5x, scaled linearly.
SLICE_T={3400,2340,1600,1050,600,400}

-- stream of 120 symbols (6 rows of 20) with one 4-char run (the key) placed twice: the
-- key IS a slice of the stream, copied to a second spot further along. The symbol soup
-- is pscii 35-70 (#$%&'()*+,-./0-9:;<=>?@A-F); 36 symbols keeps accidental duplicate
-- 4-grams rare enough (~0.4%) to skip a uniqueness check.
function gen_buf()
 local b=""
 for i=1,120 do b..=chr(35+flr(rnd(36))) end
 -- both copies of the key sit fully inside one 20-char row
 local c=1+flr(rnd(17))
 local rp=flr(rnd(5))
 local rq=rp+1+flr(rnd(5-rp))
 local p=rp*20+c
 local q=rq*20+c
 local k=sub(b,p,p+3)
 return sub(b,1,p-1)..k..sub(b,p+4,q-1)..k..sub(b,q+4),k
end

-- open a container (or the archive's terminal) and start the timer
function start_slice(s)
 local tm=SLICE_T[s.idx or 6]
 local b,k=gen_buf()
 mg={s=s,buf=b,key=k,pos=1,t=tm,tm=tm}
 state=4
 sfx(10,2)
end

-- drop a container at a fresh random spot inside the disc
function relocate(s)
 local a=rnd(1)
 s.x,s.y=clamp_arena(ARX+cos(a)*(120+rnd(200)),ARY+sin(a)*(120+rnd(200)),40)
end

-- a timed-out or abandoned slice trips the alarm: the relic blows and, for a container,
-- turns up somewhere else (the archive stays put)
function fail_slice()
 local s=mg.s
 mg=nil
 if s.kind=="container" then relocate(s) end
 s.hot=true
 msg_set("ALARM")
 sfx(7,2)
 for i=1,min(2+(s.idx or 4),6) do
  local a=rnd(1)
  spawn_foe(rnd(1)<(s.idx or 4)*0.14 and "lancer" or "interceptor",clamp_arena(p.x+cos(a)*100,p.y+sin(a)*100,24))
 end
 state=2
end

function update_mg()
 mg.t-=1
 if mg.t<1 then fail_slice() return end
 for i=0,3 do
  if btnp(i) then mg.pos=mid(1,mg.pos+({-1,1,-20,20})[i+1],117) end
 end
 if btnp(BY) then
  if sub(mg.buf,mg.pos,mg.pos+3)==mg.key then
   -- the key: a container gives up its relic, the archive gives up the coordinates
   local s=mg.s
   mg=nil
   if s.kind=="container" then
    s.sliced=true
    p.ore=min(RELIC_GOAL,p.ore+1)
    -- a little fuel rides in the case: the loop stays survivable without the alarms
    p.fuel=min(p.mfuel,p.fuel+20)
    flt(s.x,s.y-10,"+relic",12)
    if p.ore>=RELIC_GOAL then qs=3 end
   else
    qs=4
    msg_set("COORDINATES RECOVERED")
   end
   sfx(3,3)
   save_game()
   state=2
  else
   sfx(2,1)
  end
 elseif btnp(BN) then
  fail_slice()
 end
end

function draw_mg()
 print(mg.s.kind=="container" and "RELIC CONTAINER" or "ARCHIVE TERMINAL",24,8,GT)
 rect(14,20,113,24,5)
 rectfill(15,21,15+flr(mg.t/mg.tm*98),23,mg.t<90 and 8 or 12)
 for r=0,5 do
  print(sub(mg.buf,1+r*20,20+r*20),24,32+r*8,5)
 end
 local x,y=24+(mg.pos-1)%20*4,32+(mg.pos-1)\20*8
 print(sub(mg.buf,mg.pos,mg.pos+3),x,y,7)
 pc("ARROWS MOVE  X TAKE  Z LEAVE",112,GT)
end

-- kills drop no loot to chase: salvage comes straight off the wreck (fuel, missiles or
-- hull), scavengers pay no bounty, and the last kill cools every alarmed container down
function hit_foe(j,dmg)
 local f=foes[j]
 if f.shd>0 then
  f.shd-=dmg
  if f.shd<0 then f.hp+=f.shd f.shd=0 end
 else
  f.hp-=dmg
 end
 if f.hp<1 then
  boom(f.x,f.y)
  sfx(2,2)
  local r=flr(rnd(3))
  if r<1 then
   p.fuel=min(p.mfuel,p.fuel+30)
   flt(f.x,f.y-6,"+fuel",9)
  elseif r<2 then
   p.mis=min(p.mmis,p.mis+2)
   flt(f.x,f.y-6,"+missiles",7)
  else
   p.hp=min(p.mhp,p.hp+25)
   flt(f.x,f.y-6,"+hull",7)
  end
  deli(foes,j)
  if #foes<1 then
   for s in all(stations) do
    if s.hot then s.hot=false msg_set("GUARDS DOWN") end
   end
  end
 end
end
