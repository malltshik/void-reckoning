-- 30_combat: weapons, projectiles, missiles, collision

function ang_lerp(a,b,t)
 local d=(b-a)%1
 if d>0.5 then d-=1 end
 return (a+d*t)%1
end

function fire_primary(power)
 power=power or 1
 tut=0
 local dmg=8*power
 local spd=4+(power-1)*0.5
 p.wcd=8
 spawn_bullet(p.x+cos(p.a)*6,p.y+sin(p.a)*6,p.a,spd,dmg,0)
 if power>=3 then
  spawn_bullet(p.x+cos(p.a+0.14)*6,p.y+sin(p.a+0.14)*6,p.a+0.08,spd,dmg/2,0)
  spawn_bullet(p.x+cos(p.a-0.14)*6,p.y+sin(p.a-0.14)*6,p.a-0.08,spd,dmg/2,0)
 end
 sfx(0,3)
end

function fire_missile()
 if p.mis<=0 then return end
 p.mis-=1
 add(missiles,{x=p.x,y=p.y,a=p.a,dx=cos(p.a)*1.5,dy=sin(p.a)*1.5,life=300})
 sfx(1,3)
end

function spawn_bullet(x,y,a,s,d,own)
 add(bullets,{x=x,y=y,dx=cos(a)*s,dy=sin(a)*s,d=d,own=own,life=120})
end

function update_bullets()
 for i=#bullets,1,-1 do
  local b=bullets[i]
  b.x+=b.dx
  b.y+=b.dy
  b.life-=1
  if b.life<=0 then
   deli(bullets,i)
  end
 end
end

function update_missiles()
 for i=#missiles,1,-1 do
  local m=missiles[i]
  local best=nil
  local bd=99999
  for j=1,#foes do
   local f=foes[j]
   local d=abs(f.x-m.x)+abs(f.y-m.y)
   if d<bd then bd=d best=f end
  end
  if best then
   local want=atan2(best.x-m.x,best.y-m.y)
   m.a=ang_lerp(m.a,want,0.06)
  end
  m.dx+=cos(m.a)*0.25
  m.dy+=sin(m.a)*0.25
  local sp=sqrt(m.dx*m.dx+m.dy*m.dy)
  if sp>3.5 then m.dx*=3.5/sp m.dy*=3.5/sp end
  m.x+=m.dx
  m.y+=m.dy
  m.life-=1
  if m.life<=0 then deli(missiles,i) end
 end
end

function collide_all()
 for i=#bullets,1,-1 do
  local b=bullets[i]
  if b.own==0 then
   local hit=false
   for j=1,#foes do
    local f=foes[j]
    if hit2(b.x,b.y,f.x,f.y,f.r+2) then
     hit_foe(j,b.d)
     hit=true
     break
    end
   end
    if not hit then
     for j=1,#roids do
      local r=roids[j]
      if r.solid and hit2(b.x,b.y,r.x,r.y,r.r) then
       hit_roid(j,b.d)
       hit=true
       break
      end
     end
    end
   if hit then deli(bullets,i) end
  else
   if hit2(b.x,b.y,p.x,p.y,5) then
    damage_player(b.d,"KILLED BY PIRATES")
    deli(bullets,i)
   end
  end
 end
 for i=#missiles,1,-1 do
  local m=missiles[i]
  local hit=false
  for j=1,#foes do
   local f=foes[j]
   if hit2(m.x,m.y,f.x,f.y,f.r+3) then
    hit_foe(j,40)
    hit=true
    break
   end
  end
  if not hit then
   for j=1,#roids do
    local r=roids[j]
    if r.solid and hit2(m.x,m.y,r.x,r.y,r.r) then
     hit_roid(j,12)
     hit=true
     break
    end
   end
  end
  if hit then deli(missiles,i) end
 end
 for j=#roids,1,-1 do
  local r=roids[j]
  if r.solid and hit2(p.x,p.y,r.x,r.y,r.r+4) then
   local v=sqrt(p.dx*p.dx+p.dy*p.dy)
   if v>0.4 then
    damage_player(ceil(r.r*v*1.5),"CRASHED INTO AN ASTEROID")
    -- impact blow + knock the player back off the rock
    boom(p.x+(r.x-p.x)*0.5,p.y+(r.y-p.y)*0.5)
    boom_big(p.x,p.y)
    sfx(2,2)
    shk=8
    p.dx=(p.x-r.x)*0.06
    p.dy=(p.y-r.y)*0.06
    r.dx=-r.dx
    r.dy=-r.dy
   end
  end
 end
 for j=1,#foes do
  local f=foes[j]
  if hit2(p.x,p.y,f.x,f.y,f.r+4) and p.ramt<=0 then
   damage_player(2,"RAMMED BY A PIRATE")
   p.ramt=30
   local a=atan2(p.x-f.x,p.y-f.y)
   p.dx+=cos(a)*1.2
   p.dy+=sin(a)*1.2
  end
 end
end
