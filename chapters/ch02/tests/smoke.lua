-- Chapter 2 smoke test (run with: python common/tools/p8check.py smoke ch02).
-- Included after the whole game by the harness; every draw function is stubbed out, the
-- rest is the real game driven through scripted buttons. Each ck() is one assertion.
-- Buttons: arrows 0-3 (left right up down), Z=4, X=5, Enter=6.

_init()
ck(state==0 and not hassave,"boots to the title with no save")

-- arrival: X skips the dialogue and the terminal page
press(5)
ck(state==1,"X on the title starts the story")
for i=1,3000 do
 if state!=1 then break end
 press(5)
end
ck(state==2,"the arrival hands over to flight")
ck(p.hp==100 and p.fuel==100 and qs==1,"fresh ship, first quest stage")
local k=stations[1]
local g=stations[2]

-- the gate refuses to open without clearance
p.x=g.x p.y=g.y
press(5)
ck(state==2 and msgt>0,"gate stays locked without clearance")

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

-- bounty pays out
foes={}
spawn_foe("scout",p.x+60,p.y)
local c0=p.credits
hit_foe(1,999)
ck(#foes==0 and p.credits==c0+foes_def.scout.bounty,"a scout kill pays its bounty")

-- music follows the fight
foes={} missiles={}
tick(2)
ck(mtrack==MUS_FLIGHT,"flight music plays while no foe is near")
spawn_foe("scout",p.x+100,p.y)
tick(2)
ck(mtrack==MUS_COMBAT,"combat music plays when a foe is close")

-- dock at the checkpoint: control hails you, then the dockmaster holds clearance
foes={}
p.credits=300 p.hp=90
p.x=k.x p.y=k.y+8
press(5)
ck(state==4,"X beside kaelus docks")
ck(dg!=nil,"control hails on the first visit")
for i=1,300 do
 if not dg then break end
 press(5)
end
ck(dg==nil and ohint and qs==1,"the check-in sets the mission hint")
ck(dget(8)==1,"docking saves")
ck(#sm.items==4,"the dockmaster clearance option appears")

-- services still work (repair + partial refuel regression)
p.credits=100
press(5)
ck(p.hp==p.mhp and p.credits==100-10*ECO.repair,"repair hull")
p.fuel=50 p.credits=10
press(3)
press(5)
ck(p.fuel==60 and p.credits==0,"a short wallet refuels only what it can afford")

-- negotiate: bribe the dockmaster (cost 100) -> clearance granted, no ambush
p.credits=300
press(3) press(3)
ck(sm.i==4,"cursor reaches the dockmaster option")
press(5)
ck(state==3,"choosing the dockmaster starts a negotiation")
ck(ng and ng.s==negs.clearance,"the clearance conversation is loaded")
press(5)
ck(qs==2 and p.credits==200 and nres==1,"the bribe buys clearance")
ck(not ambush,"a clean bribe does not flag you")
press(5)
ck(state==4 and ng==nil,"the negotiation returns to the station")
-- the menu entry is now stale: it must refuse a second negotiation
press(5)
ck(state==4 and sm.sub=="CLEARANCE GRANTED","clearance cannot be bought twice")
press(4)
ck(state==2,"Z undocks")
ck(#foes==0,"a clean departure is quiet")

-- leave: the cleared gate starts the warp, which resets (no ch03 in this cart)
p.x=g.x p.y=g.y
press(5)
ck(state==5,"X at the gate with clearance starts the warp")
for i=1,60 do
 if state!=5 then break end
 press(5)
end
ck(state==0 and not hassave and dget(8)==0,"finishing the warp falls back to the title")

-- the hostile path: no cash, bluff -> flagged -> the patrol is waiting on undock
_init()
press(5)
for i=1,3000 do
 if state!=1 then break end
 press(5)
end
p.credits=0
p.x=k.x p.y=k.y+8
press(5)
for i=1,300 do
 if not dg then break end
 press(5)
end
press(3) press(3) press(3)
press(5)
ck(state==3,"the second negotiation starts")
press(3) press(5)
ck(qs==2 and nres==2 and ambush,"calling the bluff flags you but still opens the gate")
press(5)
ck(state==4,"the negotiation returns to the station")
foes={}
press(4)
ck(state==2 and not ambush,"undocking spends the ambush flag")
ck(#foes>=3,"the flagged patrol is waiting")

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
