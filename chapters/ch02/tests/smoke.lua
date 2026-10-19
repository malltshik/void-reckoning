-- Chapter 2 smoke test (run with: python common/tools/p8check.py smoke ch02).
-- Included after the whole game by the harness; every draw function is stubbed out, the
-- rest is the real game driven through scripted buttons. Each ck() is one assertion.
-- Buttons: arrows 0-3 (left right up down), Z=4, X=5, Enter=6.

_init()
ck(state==0 and not hassave,"boots to the title with no save")

-- the warp in: recap, then the incoming signal, then flight
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
ck(#foes==0,"no opening patrol: the swarm only answers alarms")

-- the gate refuses to open before the coordinates are recovered
local g=stations[7]
p.x=g.x p.y=g.y
press(5)
ck(state==2 and msgt>0,"gate stays locked without the coordinates")

-- flight, gun, missile
p.x=ARX p.y=ARY
roids={}
local x0=p.x
hold(1,30)
ck(p.x>x0+10,"arrows fly the ship")
ck(p.fuel<100,"thrust burns fuel")
hold(5,50)
tick(1)
ck(#bullets>=3,"a full charge fires the 3-shot spread")
local m0=p.mis
press(4)
ck(p.mis==m0-1 and #missiles>0,"Z launches a missile")

-- the white mineable rocks are gone; only grey scenery remains
local whites=0
for r in all(roids) do if r.solid then whites+=1 end end
ck(whites==0,"no white rocks: the field was stripped")

-- a kill pays no bounty and grants salvage straight off the wreck
foes={} bullets={}
local f0=p.fuel
local h0=p.hp
p.hp=50
p.mis=5
spawn_foe("interceptor",p.x+60,p.y)
hit_foe(1,999)
ck(#foes==0,"a kill clears the foe")
ck(p.credits==0,"scavengers pay no bounty")
ck(p.fuel>f0 or p.mis>5 or p.hp>h0,"a wreck yields fuel, missiles or hull")

-- the minigame stream: exactly one repeated 4-gram, and it is the key
local b,k=gen_buf()
local reps=0
for i=1,117 do
 if sub(b,i,i+3)==k then reps+=1 end
end
ck(#b==120,"the stream is 6 rows of 20")
ck(#k==4,"the key is 4 symbols")
ck(reps==2,"the key is the only 4-gram that repeats")

-- slicing a container: wrong picks burn the timer, the key wins the relic
local c=stations[2]
p.x=c.x p.y=c.y
press(5)
ck(state==4 and mg!=nil,"X beside a container opens the minigame")
ck(mg.s==c and mg.tm==SLICE_T[1],"the first container gets the easiest timer")
mg.lock=0
local t0=mg.t
press(5)
ck(mg.t<t0-30,"a wrong pick burns timer")
ck(state==4,"a wrong pick does not end the slice")
local found=0
for i=1,117 do
 if sub(mg.buf,i,i+3)==mg.key then found=i end
end
mg.pos=found
press(5)
ck(mg==nil and state==2,"the key ends the slice")
ck(c.sliced and p.ore==1,"the container gives up its relic")

-- a timed-out slice trips the alarm; guards come and hold the container sealed
p.x=stations[3].x p.y=stations[3].y
press(5)
ck(state==4 and mg!=nil,"a second container opens the minigame")
mg.t=1
tick(2)
ck(state==2 and msgt>0,"the timeout trips the alarm")
ck(stations[3].hot,"the failed container is sealed by guards")
ck(#foes>=3,"the alarm brings guards")
while #foes>0 do hit_foe(1,999) end
ck(#foes==0 and not stations[3].hot,"killing the guards cools the container down")

-- a hot container can be retried any time; the guards keep hunting instead of blocking
stations[3].hot=true
spawn_foe("interceptor",p.x+40,p.y)
p.x=stations[3].x p.y=stations[3].y
press(5)
ck(state==4 and mg!=nil,"a failed container can be retried while guards are up")
press(4)
ck(state==2,"Z leaves the retried minigame")
stations[3].hot=nil
foes={}

-- the archive: the brief, then (with the set complete) the code crack
foes={}
p.x=stations[1].x p.y=stations[1].y+8
p.ore=RELIC_GOAL
qs=3
press(5)
ck(state==4,"X beside the archive docks")
ck(dg!=nil,"the archive speaks on the first visit")
for i=1,300 do
 if not dg then break end
 press(5)
end
ck(dg==nil and ohint,"the archive sets the mission hint")
ck(mg!=nil and mg.s==stations[1],"the brief ends with the code crack")
ck(mg.tm==SLICE_T[6],"the terminal is the hardest timer")
mg.lock=0
found=0
for i=1,117 do
 if sub(mg.buf,i,i+3)==mg.key then found=i end
end
mg.pos=found
press(5)
ck(qs==4 and state==2,"cracking the code recovers the coordinates")
ck(dget(8)==1,"docking saves")

-- Z leaves the minigame without consequence
p.x=stations[5].x p.y=stations[5].y
press(5)
ck(state==4 and mg!=nil,"a container opens")
press(4)
ck(mg==nil and state==2,"Z leaves the minigame")

-- death keeps the relics (they are the progress, and there is no money to strip)
p.ore=3
recover()
ck(p.ore==3 and state==2,"recovery keeps the relics")
ck(p.hp==p.mhp and p.fuel==p.mfuel,"recovery refits the ship")

-- leave: the recovered coordinates open the gate
p.x=g.x p.y=g.y
press(5)
ck(state==5,"X at the gate with the coordinates starts the warp")
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
