-- Chapter 2 smoke test (run with: python common/tools/p8check.py smoke ch02).
-- Included after the whole game by the harness; every draw function is stubbed out, the
-- rest is the real game driven through scripted buttons. Each ck() is one assertion.
-- Buttons: arrows 0-3 (left right up down), Z=4, X=5, Enter=6.

_init()
ck(state==0 and not hassave,"boots to the title with no save")

-- the warp in: Chapter 1 recap, then the incoming signal, then flight
press(5)
ck(state==5,"X on the title starts the warp-in")
for i=1,600 do
 if state!=5 then break end
 press(5)
end
ck(state==1,"the warp hands over to the incoming signal")
for i=1,3000 do
 if state!=1 then break end
 press(5)
end
ck(state==2,"the signal hands over to flight")
ck(p.hp==100 and p.fuel==100 and qs==1,"fresh ship, first quest stage")
ck(p.mcargo==RELIC_GOAL,"the hold carries relics, not ore")
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

-- a kill drops a relic and pays no bounty
foes={} drops={}
spawn_foe("interceptor",p.x+60,p.y)
local c0=p.credits
hit_foe(1,999)
ck(#foes==0,"a kill clears the foe")
ck(p.credits==c0,"scavengers pay no bounty")
local frag=nil
for d in all(drops) do if d.kind==2 then frag=d end end
ck(frag!=nil,"a kill drops a navigation relic")

-- flying over the relic recovers it
p.x=frag.x p.y=frag.y
tick(2)
ck(p.ore==1,"flying over a relic recovers it")

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
ck(onlysal,"asteroid wrecks never drop relics")

-- waves: the first one arrives as a group, and clearing it opens a salvage break
foes={} p.ore=0 bossq=0 cleared=true wavet=0
update_spawn()
ck(#foes==3,"the first wave is a group of 3")
foes={} cleared=false
update_spawn()
ck(cleared and wavet==240,"a cleared wave starts a salvage break")

-- the reaver wakes when the archive is one relic short
foes={} drops={}
p.x=ARX p.y=ARY
p.ore=RELIC_GOAL-1
bossq=0 cleared=true wavet=0
update_spawn()
local boss=0
for f in all(foes) do if f.kind=="reaver" then boss+=1 end end
ck(boss==1,"the reaver wakes at 23 relics")

-- killing the reaver drops the last relic; collecting it completes the set
drops={}
hit_foe(1,999)
frag=nil
for d in all(drops) do if d.kind==2 then frag=d end end
ck(frag!=nil,"the reaver drops the final relic")
p.x=frag.x p.y=frag.y
tick(2)
ck(p.ore==RELIC_GOAL and qs==3,"the 24th relic completes the set")

-- a lancer's volley is a fan of bullets, not one shot
foes={} bullets={}
p.x=ARX p.y=ARY
spawn_foe("lancer",p.x+40,p.y)
foes[1].cd=0
update_foes()
local nb=0
for b in all(bullets) do nb+=1 end
ck(nb>=3,"a lancer fires a salvo of 3")

-- dock: the archive speaks, then the terminal cracks the code
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
ck(#sm.items>=2,"the code-crack option is available with the set complete")
sm.i=2
press(5)
ck(dg!=nil and slicing,"choosing CRACK THE CODE runs the terminal")
for i=1,300 do
 if not dg then break end
 press(5)
end
tick(2)
ck(qs==4,"cracking the code recovers the coordinates")
-- the option is now stale: it must refuse a second crack
sm.sub=""
press(5)
ck(sm.sub=="COORDINATES ALREADY LOGGED","the terminal cannot be cracked twice")
press(4)
ck(state==2,"Z undocks")

-- death keeps the relics (they are the progress, and there is no money to strip)
p.ore=7
recover()
ck(p.ore==7 and state==2,"recovery keeps the relics")
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
