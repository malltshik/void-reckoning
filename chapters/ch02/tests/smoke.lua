-- Chapter 2 smoke test (run with: python common/tools/p8check.py smoke ch02).
-- Included after the whole game by the harness; every draw function is stubbed out, the
-- rest is the real game driven through scripted buttons. Each ck() is one assertion.
-- Buttons: arrows 0-3 (left right up down), Z=4, X=5, Enter=6.

_init()
ck(state==0 and not hassave,"boots to the title with no save")

-- arrival: two dialogue pages, then flight
press(5)
ck(state==1,"X on the title starts the story")
for i=1,3000 do
 if state!=1 then break end
 press(5)
end
ck(state==2,"the arrival hands over to flight")
ck(p.hp==100 and p.fuel==100 and qs==1,"fresh ship, first quest stage")
ck(p.mcargo==RELIC_GOAL,"the hold carries fragments, not ore")
local k=stations[1]
local g=stations[2]

-- the gate refuses to open before the nav key is rebuilt
p.x=g.x p.y=g.y
press(5)
ck(state==2 and msgt>0,"gate stays locked without the nav key")

-- flight, gun, missile (clear the seeded rocks/foes so the shot paths are deterministic)
roids={} foes={}
p.x=ARX p.y=ARY-60
local x0=p.x
hold(1,30)
ck(p.x>x0+10,"arrows fly the ship")
ck(p.fuel<100,"thrust burns fuel")
p.x=ARX p.y=ARY
hold(5,50)
tick(1)
ck(#bullets>=3,"a full charge fires the 3-shot spread")
local m0=p.mis
press(4)
ck(p.mis==m0-1 and #missiles>0,"Z launches a missile")

-- a kill drops a fragment and pays no bounty
foes={} drops={}
spawn_foe("interceptor",p.x+60,p.y)
local c0=p.credits
hit_foe(1,999)
ck(#foes==0,"a kill clears the foe")
ck(p.credits==c0,"scavengers pay no bounty")
local frag=nil
for d in all(drops) do if d.kind==2 then frag=d end end
ck(frag!=nil,"a kill drops a navigation fragment")

-- flying over the fragment recovers it
p.x=frag.x p.y=frag.y
tick(2)
ck(p.ore==1,"flying over a fragment recovers it")

-- salvage canisters restore fuel
drops={}
p.fuel=50
add(drops,{x=p.x,y=p.y,kind=3,c=9})
tick(2)
ck(p.fuel==80,"a fuel cell refuels")

-- asteroid wrecks only ever hold salvage
roids={} drops={}
add(roids,{x=p.x+30,y=p.y,dx=0,dy=0,r=4,hp=1,c=7,solid=true})
p.ore=0
hit_roid(1,99)
local onlysal=true
for d in all(drops) do if d.kind==2 then onlysal=false end end
ck(onlysal,"asteroid wrecks never drop fragments")

-- the reaver wakes when the archive is one fragment short
foes={} drops={}
p.x=ARX p.y=ARY
p.ore=RELIC_GOAL-1
update_drops()
local boss=0
for f in all(foes) do if f.kind=="reaver" then boss+=1 end end
ck(boss==1,"the reaver wakes at 23 fragments")

-- killing the reaver drops the last fragment; collecting it rebuilds the key
drops={}
hit_foe(1,999)
frag=nil
for d in all(drops) do if d.kind==2 then frag=d end end
ck(frag!=nil,"the reaver drops the final fragment")
p.x=frag.x p.y=frag.y
tick(2)
ck(p.ore==RELIC_GOAL and qs==3,"the 24th fragment rebuilds the nav key")

-- a lancer's volley is a fan of bullets, not one shot
foes={} bullets={}
p.x=ARX p.y=ARY
spawn_foe("lancer",p.x+40,p.y)
foes[1].cd=0
update_foes()
local nb=0
for b in all(bullets) do nb+=1 end
ck(nb>=3,"a lancer fires a salvo of 3")

-- dock: the archive speaks, then the terminal slices the nav key
foes={} bullets={}
p.x=k.x p.y=k.y+8
press(5)
ck(state==4,"X beside the archive docks")
ck(dg!=nil,"the archive speaks on the first visit")
for i=1,300 do
 if not dg then break end
 press(5)
end
ck(dg==nil and ohint,"the archive sets the mission hint")
ck(dget(8)==1,"docking saves")
ck(#sm.items>=2,"the slice option is available with the key complete")
sm.i=2
press(5)
ck(dg!=nil and slicing,"choosing SLICE runs the terminal")
for i=1,300 do
 if not dg then break end
 press(5)
end
tick(2)
ck(qs==4,"the sliced terminal rebuilds the nav key")
-- the option is now stale: it must refuse a second slice
sm.sub=""
press(5)
ck(sm.sub=="COORDINATES ALREADY LOGGED","the terminal cannot be sliced twice")
press(4)
ck(state==2,"Z undocks")

-- death keeps the fragments (they are the progress, and there is no money to strip)
p.ore=7
recover()
ck(p.ore==7 and state==2,"recovery keeps the fragments")
ck(p.hp==p.mhp and p.fuel==p.mfuel,"recovery refits the ship")

-- leave: the rebuilt key opens the gate
p.x=g.x p.y=g.y
press(5)
ck(state==5,"X at the gate with the key starts the warp")
for i=1,60 do
 if state!=5 then break end
 press(5)
end
ck(state==0 and not hassave and dget(8)==0,"finishing the warp falls back to the title")

-- layout varies per run but a given seed rebuilds it exactly
local s0=SEED
local k0=0 for r in all(roids) do k0+=flr(r.x) end
reset_game()
local k1=0 for r in all(roids) do k1+=flr(r.x) end
ck(k1!=k0,"a new game picks a different layout")
SEED=s0 load_system()
local k2=0 for r in all(roids) do k2+=flr(r.x) end
ck(k2==k0,"the saved seed rebuilds the same map")

finish("SMOKE")
