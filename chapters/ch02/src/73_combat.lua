-- 73_combat: XR-7PO's combat rules. These override engine sim functions because the rules
-- differ (see the header of 70_world.lua). Functions are globals, so a later definition wins;
-- the engine calls them by name at run time and the harness stubs by name.

-- a kill drops a relic (until 23 are aboard - the reaver holds the last) and sometimes a
-- salvage canister (white; its kind decides what it restores)
function hit_foe(j,dmg)
 local f=foes[j]
 if f.shd>0 then
  f.shd-=dmg
  if f.shd<0 then f.hp+=f.shd f.shd=0 end
 else
  f.hp-=dmg
 end
 if f.hp<=0 then
  boom(f.x,f.y)
  sfx(2,2)
  if f.kind=="reaver" or p.ore<RELIC_GOAL-1 then
   add(drops,{x=f.x,y=f.y,kind=2,c=12})
  end
  if rnd(1)<0.35 then
   add(drops,{x=f.x+rnd(8)-4,y=f.y+rnd(8)-4,kind=3+flr(rnd(3)),c=7})
  end
  deli(foes,j)
 end
end

-- waves: a small group arrives, then a salvage break while the field is clear, then the
-- next (bigger) wave. The reaver comes alone after the wave that brings the count to 23.
function update_spawn()
 if arena_dist(p.x,p.y)>ARR then return end
 if #foes>0 or bossq>0 then return end
 if not cleared then
  cleared=true
  wavet=240
  msg_set("WAVE CLEARED - SALVAGE")
  return
 end
 wavet-=1
 if wavet>0 then return end
 if p.ore>=RELIC_GOAL-1 then
  bossq=1
  local a=rnd(1)
  local x,y=clamp_arena(p.x+cos(a)*210,p.y+sin(a)*210,24)
  spawn_foe("reaver",x,y)
  msg_set("THE REAVER WAKES")
  sfx(7,2)
  return
 end
 wave+=1
 cleared=false
 local n=min(2+wave,7)
 for i=1,n do
  local a=rnd(1)
  local x,y=clamp_arena(p.x+cos(a)*(150+rnd(60)),p.y+sin(a)*(150+rnd(60)),24)
  spawn_foe(rnd(1)<min(0.1+wave*0.08,0.5) and "lancer" or "interceptor",x,y)
 end
 msg_set("WAVE "..wave)
 sfx(7,2)
end

-- pickups (2 relic, 1/3 fuel, 4 missiles, 5 hull)
function update_drops()
 for i=#drops,1,-1 do
  local o=drops[i]
  local ddx=p.x-o.x
  local ddy=p.y-o.y
  if abs(ddx)<36 and abs(ddy)<36 then
   local dd=sqrt(ddx*ddx+ddy*ddy)+0.001
   if dd<30 then
    o.x+=ddx/dd*1.6
    o.y+=ddy/dd*1.6
   end
   if dd<8 then
    local k=o.kind
    if k==2 then
     if p.ore<RELIC_GOAL then
      p.ore+=1
      flt(o.x,o.y-4,"+relic",12)
      if p.ore>=RELIC_GOAL then qs=3 msg_set("RELICS COMPLETE - DOCK ARCHIVE")
      else msg_set("RELICS "..p.ore.." / "..RELIC_GOAL) end
     end
    elseif k==4 then p.mis=min(p.mmis,p.mis+2) msg_set("MISSILES +2")
    elseif k==5 then p.hp=min(p.mhp,p.hp+25) msg_set("HULL +25")
    else p.fuel=min(p.mfuel,p.fuel+30) msg_set("FUEL +30") end
    sfx(3,3)
    deli(drops,i)
   end
  end
 end
end
