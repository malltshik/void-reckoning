-- Chapter 1 smoke test (run with: python common/tools/p8check.py smoke ch01).
-- Included after the whole game by the harness; every draw function is stubbed out, the
-- rest is the real game driven through scripted buttons. Each ck() is one assertion.
-- Buttons: arrows 0-3 (left right up down), Z=4, X=5, Enter=6.

_init()
ck(state==0 and not hassave,"boots to the title with no save")

-- intro: X skips the dialogue, the flight cutscene, the wormhole and the terminal
press(5)
ck(state==1,"X on the title starts the story")
for i=1,3000 do
 if state!=1 then break end
 press(5)
end
ck(state==2,"the intro hands over to flight")
ck(p.hp==100 and p.fuel==100 and qs==1,"fresh ship, first quest stage")
local o=stations[1]
local g=stations[2]

-- the gate refuses to open without a hyper-cell
p.x=g.x p.y=g.y
press(5)
ck(state==2 and msgt>0,"gate stays locked without a hyper-cell")

-- flight, gun, missile
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

-- bounty + reinforcements
foes={}
spawn_foe("scout",p.x+60,p.y)
local c0=p.credits
hit_foe(1,999)
ck(#foes==0 and p.credits==c0+foes_def.scout.bounty,"a scout kill pays its bounty")
spawnt=1
tick(2)
ck(#foes==1,"reinforcements arrive when the timer expires")

-- music follows the fight (regression: a wrapped 99999 literal kept combat music always on)
foes={}
tick(2)
ck(mtrack==MUS_FLIGHT,"flight music plays while no foe is near")
spawn_foe("scout",p.x+100,p.y)
tick(2)
ck(mtrack==MUS_COMBAT,"combat music plays when a foe is close")

-- homing (regression: same wrapped literal made missiles ignore every target)
foes={} missiles={}
p.x=ARX p.y=ARY p.a=0 p.mis=5
spawn_foe("scout",p.x+90,p.y+34)
press(4)
local near=30000
for i=1,250 do
 if #foes==0 then break end
 tick(1)
 if #foes>0 and #missiles>0 then
  near=min(near,abs(foes[1].x-missiles[1].x)+abs(foes[1].y-missiles[1].y))
 end
end
printh("  (closest missile approach: "..near.."px, missiles left "..#missiles..")","p8log.txt")
ck(#foes==0,"a missile fired off-axis homes in on the scout")

-- soak: 1500 frames of flying around with a ship that cannot die
p.hp=9000 p.mhp=9000 p.shd=9000 p.mshd=9000
K[1]=true tick(300) K[1]=nil
K[3]=true tick(300) K[3]=nil
K[5]=true tick(100) K[5]=nil
tick(800)
ck(state==2,"survives a 1500-frame soak")
p.hp=100 p.mhp=100 p.shd=50 p.mshd=50 p.fuel=100

-- dock: officer briefing, then every service
p.x=o.x p.y=o.y+8
press(5)
ck(state==4,"X beside the outpost docks")
ck(dg!=nil,"the officer hails on the first visit")
for i=1,300 do
 if not dg then break end
 press(5)
end
ck(dg==nil and ohint and qs==1,"the briefing sets the mission hint")
ck(dget(8)==1,"docking saves")
p.credits=100 p.hp=90
press(5)
ck(p.hp==p.mhp and p.credits==100-10*ECO.repair,"repair hull")
press(3)
p.fuel=50 p.credits=100
press(5)
ck(p.fuel==p.mfuel and p.credits==100-50*ECO.fuel,"refuel")
press(3)
p.credits=0 p.ore=4
press(5)
ck(p.credits==4*ECO.oresell and p.ore==0 and qs==2,"selling ore pays and advances the mission")
press(3)
p.mis=2
press(5)
ck(p.mis==3 and p.credits==4*ECO.oresell-ECO.missile,"buy a missile")
press(3)
p.credits=ECO.cell-1
press(5)
ck(qs==2 and p.credits==ECO.cell-1,"hyper-cell refused when short of cash")
p.credits=ECO.cell
press(5)
ck(qs==3 and p.credits==0,"hyper-cell fitted, gate unlocked")
press(4)
ck(state==2,"Z undocks")

-- ship menu, then EXIT -> save -> title -> continue
press(6)
ck(state==8,"Enter opens the ship menu")
ck(#mission_lines()>0 and #inventory_lines()>0,"menu panes have content")
press(1)
press(4)
ck(state==2,"Z leaves the ship menu")
p.credits=77 p.ore=3
press(6)
press(3) press(3)
press(5)
ck(state==0 and hassave,"EXIT saves and returns to the title")
ck(dget(3)==77 and dget(1)==3,"the save holds credits and quest stage")
_init()
ck(hassave and qs==3 and p.credits==77 and p.ore==3,"a fresh boot loads the save")
press(5)
ck(state==2,"continue goes straight to flight")
ck(hit2(p.x,p.y,o.x,o.y,40),"continue puts you back at the outpost")

-- death is a setback: fee + lost cargo, but progress stays
p.x=ARX p.y=ARY
p.shd=0 p.hp=1
damage_player(50,"TEST")
ck(state==6,"zero hull is game over")
tick(200)
press(5)
ck(state==2 and p.hp==p.mhp and p.ore==0 and p.credits==77-flr(77*0.25),"recover: full hull, no cargo, 25% fee")
ck(qs==3,"recovery keeps story progress")

-- dead space: no fuel out there is death
p.x=ARX+ARR+100 p.y=ARY p.fuel=0
tick(1)
ck(state==6 and dth=="ADRIFT IN THE VOID","dry in dead space is fatal")
tick(200)
press(5)
ck(state==2,"recovered after dying in dead space")

-- jump + ending + reset
p.x=g.x p.y=g.y
press(5)
ck(state==5,"X at the gate with a cell starts the warp")
for i=1,40 do
 if state!=5 then break end
 press(5)
end
ck(state==7,"the warp narration ends the chapter")
tick(200)
press(5)
ck(state==0 and not hassave and dget(8)==0,"the ending resets to the title")

finish("SMOKE")
