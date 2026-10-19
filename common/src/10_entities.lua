-- 10_entities: flight sim, foes, asteroids, drops, particles

-- frames of holding the fire button to reach a full charge (power 1..3)
CHGMAX=45

-- patrol pacing: at most this many foes at once, spawning this rarely (~20-30s)
FOE_CAP=4
SPAWN_MIN=1200
SPAWN_VAR=600

-- enemy stats (foes_def) and the spawn roster (FOE_POOL) are chapter content: chapters/<ch>/src/70_world.lua


function update_flight()
 -- open the ship menu (mission / inventory) with the pause/enter key
 if btnp(6) then open_menu() return end
 if p.ramt>0 then p.ramt-=1 end
 -- X near a station docks / jumps; elsewhere X is the cannon
 if btnp(BY) then
   local st=nearest_station(20)
  if st then
   p.chg=0
   if st.kind=="gate" then start_jump() else dock(st) end
   return
  end
 end
 -- snappy 8-way: nose follows input, quick stop (no drift)
 local ax=0
 local ay=0
 if btn(2) then ay-=1 end
 if btn(3) then ay+=1 end
 if btn(0) then ax-=1 end
 if btn(1) then ax+=1 end
 local tx=0
 local ty=0
 if (ax!=0 or ay!=0) and p.fuel>0 then
  local m=sqrt(ax*ax+ay*ay)
  local spd=1.8
  tx=ax/m*spd
  ty=ay/m*spd
  p.a=atan2(ax,ay)
  p.fuel=max(0,p.fuel-0.06)
 end
 p.dx+=(tx-p.dx)*0.35
 p.dy+=(ty-p.dy)*0.35
 -- free flight: no wall. Fly past the system edge into empty dead space if you want.
 p.x+=p.dx
 p.y+=p.dy
 -- dry out in dead space: no fuel, nothing to hail, nothing to burn - you are lost
 if p.fuel<=0 and arena_dist(p.x,p.y)>ARR then
  damage_player(30000,"ADRIFT IN THE VOID")
  return
 end
 -- shield regen (charging the cannon suppresses it)
 if p.scd>0 then p.scd-=1
 elseif p.shd<p.mshd and p.chg<=0 then p.shd=min(p.mshd,p.shd+0.1) end
 -- weapon: hold X to charge, release to fire (charge -> power 1..3)
 if p.wcd>0 then p.wcd-=1 end
 if btn(BY) and p.wcd<=0 and p.fuel>0 then
  p.chg=min(p.chg+1,CHGMAX)
 elseif p.chg>0 then
  fire_primary(1+flr(p.chg/CHGMAX*2))
  p.chg=0
 end
 -- reinforcements
 update_spawn()
 -- Z: fire a homing missile (no fuel, no launch)
 if btnp(BN) and p.fuel>0 then fire_missile() end
 -- sim
 update_bullets()
 update_missiles()
 update_foes()
 update_roids()
 update_drops()
 update_fx()
 collide_all()
 update_camera()
 -- music: combat theme while enemies are engaged (with hysteresis)
 -- (30000 not 99999: literals past 32767 wrap negative in 16.16 fixed point)
 local dmin=30000
 for f in all(foes) do
  local d=abs(f.x-p.x)+abs(f.y-p.y)
  if d<dmin then dmin=d end
 end
 if dmin<220 then mtcombat=true elseif dmin>340 then mtcombat=false end
 set_music(mtcombat and MUS_COMBAT or MUS_FLIGHT)
end

function spawn_foe(kind,x,y)
 local d=foes_def[kind]
 add(foes,{kind=kind,x=x,y=y,dx=0,dy=0,hp=d.hp,mhp=d.hp,shd=d.shd,mshd=d.shd,cd=d.cd,r=d.r})
end

function update_spawn()
 -- no reinforcements out in dead space: only the system has patrols
 if arena_dist(p.x,p.y)>ARR then return end
 if #foes>=FOE_CAP then return end
 spawnt-=1
 if spawnt>0 then return end
 -- rare patrols: long gaps so you can explore, mine, and just fly in peace
 spawnt=SPAWN_MIN+flr(rnd(SPAWN_VAR))
 local a=rnd(1)
 local dist=150+rnd(60)
 local x=p.x+cos(a)*dist
 local y=p.y+sin(a)*dist
 x,y=clamp_arena(x,y,24)
 spawn_foe(FOE_POOL[1+flr(rnd(#FOE_POOL))],x,y)
end

function update_foes()
 for i=#foes,1,-1 do
  local f=foes[i]
  local d=foes_def[f.kind]
  local ddx=p.x-f.x
  local ddy=p.y-f.y
  local adx=abs(ddx)
  local ady=abs(ddy)
  local a=atan2(ddx,ddy)
  if adx<40 and ady<40 then
   f.dx+=cos(a+0.25)*0.05
   f.dy+=sin(a+0.25)*0.05
  else
   f.dx+=cos(a)*0.06
   f.dy+=sin(a)*0.06
  end
  f.dx*=0.97
  f.dy*=0.97
  local sp=sqrt(f.dx*f.dx+f.dy*f.dy)
  if sp>d.spd then f.dx*=d.spd/sp f.dy*=d.spd/sp end
  f.x+=f.dx
  f.y+=f.dy
  if f.shd<f.mshd then f.shd=min(f.mshd,f.shd+0.05) end
  f.cd-=1
  if f.cd<=0 and adx<d.range and ady<d.range then
   f.cd=d.cd
   spawn_bullet(f.x+cos(a)*5,f.y+sin(a)*5,a,d.bs,d.dmg,1)
  end
 end
end

function update_roids()
 for i=1,#roids do
  local r=roids[i]
  r.x+=r.dx
  r.y+=r.dy
  -- reflect off the round arena rim (no squaring: dist_trig / axis components)
  local dx=r.x-ARX
  local dy=r.y-ARY
  local d=abs(dist_trig(ARX,ARY,r.x,r.y))
  local lim=ARR-r.r
  if d>lim then
   local nx=dx/(d+0.0001)
   local ny=dy/(d+0.0001)
   r.x=ARX+nx*lim
   r.y=ARY+ny*lim
   local dot=r.dx*nx+r.dy*ny
   r.dx=r.dx-2*dot*nx
   r.dy=r.dy-2*dot*ny
  end
 end
 -- top the mineable rocks back up over time
 local solid=0
 for r in all(roids) do if r.solid then solid+=1 end end
 if solid<ROID_CAP then
  roidt-=1
  if roidt<=0 then roidt=ROID_RESPAWN spawn_roid() end
 end
end

function update_drops()
 for i=#drops,1,-1 do
  local o=drops[i]
  local ddx=p.x-o.x
  local ddy=p.y-o.y
  if abs(ddx)<40 and abs(ddy)<40 then
   local dd=sqrt(ddx*ddx+ddy*ddy)+0.001
   if dd<34 then
    o.x+=ddx/dd*1.5
    o.y+=ddy/dd*1.5
   end
   if dd<8 then
    if p.ore<p.mcargo then
     p.ore+=1 sfx(3,3) flt(o.x,o.y-4,"+1 ore",11) deli(drops,i)
    elseif msgt<1 then msg_set("CARGO FULL") end
   end
  end
 end
end

function update_parts()
 for i=#parts,1,-1 do
  local q=parts[i]
  q.x+=q.dx
  q.y+=q.dy
  q.t-=1
  if q.t<=0 then deli(parts,i) end
 end
end

-- small floating "+$15" / "+1 ore" text that drifts up and fades out
function flt(x,y,s,c) add(floats,{x=x,y=y,s=s,c=c,t=50}) end

function update_floats()
 for i=#floats,1,-1 do
  local q=floats[i]
  q.y-=0.4 q.t-=1
  if q.t<1 then deli(floats,i) end
 end
end

-- expanding shock rings from explosions
function update_fx()
 update_parts()
 update_floats()
 for i=#blasts,1,-1 do
  local b=blasts[i]
  b.t-=1
  b.r+=(b.mr-b.r)*0.4
  if b.t<=0 then deli(blasts,i) end
 end
end

function boom(x,y)
 for i=1,12 do
  local a=rnd(1)
  local s=rnd(2.2)
  add(parts,{x=x,y=y,dx=cos(a)*s,dy=sin(a)*s,t=10+flr(rnd(9)),c=8+flr(rnd(3)),s=1})
 end
 add(blasts,{x=x,y=y,r=0,mr=11,t=12,c=10})
end

-- bigger, longer-lived blast for impacts and the player's death
function boom_big(x,y)
 for i=1,44 do
  local a=rnd(1)
  local s=rnd(3.6)
  add(parts,{x=x,y=y,dx=cos(a)*s,dy=sin(a)*s,t=14+flr(rnd(22)),c=8+flr(rnd(5)),s=1+rnd(2)})
 end
 add(blasts,{x=x,y=y,r=0,mr=20,t=16,c=9})
 add(blasts,{x=x,y=y,r=0,mr=36,t=22,c=8})
end

function hit_foe(j,dmg)
 local f=foes[j]
 if f.shd>0 then
  f.shd-=dmg
  if f.shd<0 then f.hp+=f.shd f.shd=0 end
 else
  f.hp-=dmg
 end
 if f.hp<=0 then
  local bo=foes_def[f.kind].bounty
  p.credits+=bo
  flt(f.x,f.y-4,"+$"..bo,10)
  if rnd(1)<0.3 then p.mis=min(p.mmis,p.mis+1) end
  boom(f.x,f.y)
  sfx(2,2)
  deli(foes,j)
 end
end

function hit_roid(j,dmg)
 local r=roids[j]
 r.hp-=dmg
 if r.hp<=0 then
  add(drops,{x=r.x,y=r.y,kind=1})
  boom(r.x,r.y)
  deli(roids,j)
 end
end

function damage_player(d,why)
 p.scd=180
 sfx(4,2)
 shk=max(shk,4)
 if p.shd>=d then
  p.shd-=d
 else
  local r=d-p.shd
  p.shd=0
  p.hp-=r
  if p.hp<=0 then
   p.hp=0
   boom_big(p.x,p.y)
   sfx(2,2)
   shk=12
   dth=why
   got=180
   state=6
  end
 end
end

function update_camera()
 -- keep the ship centred on screen (no clamps at the world edge) so the HUD panel
 -- and radar can never cover it; a short shake offsets the whole scene on impacts.
 if shk>0 then shk-=1 end
 local jx=0
 local jy=0
 if shk>0 then
  jx=(rnd(1)-0.5)*shk
  jy=(rnd(1)-0.5)*shk
 end
 camx=p.x-64+jx
 camy=p.y-64+jy
end
