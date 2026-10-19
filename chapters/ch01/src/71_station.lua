-- 71_station: Chapter 1 docking, services menu, economy

-- tunable economy
ECO={oresell=10,cell=250,repair=2,fuel=1,missile=15}

function nearest_station(range)
 for s in all(stations) do
  if abs(s.x-p.x)<range and abs(s.y-p.y)<range then return s end
 end
 return nil
end

function dock(s)
 active=s
 sm=menu_new("OUTPOST - SERVICES",{
  {label="REPAIR HULL ("..ECO.repair.."$/HP)",act=function(m)
   local need=ceil(p.mhp-p.hp)
   if need<=0 then m.sub="HULL AT MAXIMUM" return end
   local cost=need*ECO.repair
   if p.credits>=cost then p.credits-=cost p.hp=p.mhp m.sub="REPAIRED -"..cost.."$"
   else m.sub="NOT ENOUGH $" end
  end},
  {label="REFUEL ("..ECO.fuel.."$/UNIT)",act=function(m)
   local need=ceil(p.mfuel-p.fuel)
   if need<=0 then m.sub="FUEL FULL" return end
   local cost=need*ECO.fuel
   if p.credits>=cost then p.credits-=cost p.fuel=p.mfuel m.sub="REFUELED -"..cost.."$"
   else m.sub="NOT ENOUGH $" end
  end},
  {label="SELL ORE ("..ECO.oresell.."$ EACH)",act=function(m)
   if p.ore<=0 then m.sub="NO ORE TO SELL" return end
   local g=p.ore*ECO.oresell
   p.credits+=g
   p.ore=0
   if qs==1 then qs=2 end
   m.sub="SOLD ORE +"..g.."$"
  end},
  {label="BUY MISSILE ("..ECO.missile.."$)",act=function(m)
   if p.mis>=p.mmis then m.sub="MISSILE BAY FULL" return end
   if p.credits<ECO.missile then m.sub="NOT ENOUGH $" return end
   p.credits-=ECO.missile
   p.mis+=1
   m.sub="MISSILE LOADED ("..p.mis.."/"..p.mmis..")"
  end},
  {label="BUY HYPER-CELL ("..ECO.cell.."$)",act=function(m)
   if qs>=3 then m.sub="HYPER-CELL ALREADY FITTED" return end
   if p.credits>=ECO.cell then
    p.credits-=ECO.cell
    qs=3
    m.sub="HYPER-CELL FITTED. GATE UNLOCKED."
   else m.sub="NEED "..ECO.cell.."$" end
  end}
 })
 sfx(6,3)
 set_music(MUS_STATION)
 state=4
 -- first visit to the outpost: the officer explains where you are and gives the hint
 if s.kind=="outpost" and not ohint then
  ohint=true
  qs=1
  dlg_start("officer")
 end
 save_game()
end

function update_station()
 -- the officer briefing plays over the menu, then hands control back to it
 if dg then update_dlg() return end
 menu_tick(sm)
 if btnp(BN) then state=2 end
end

function draw_station()
 rectfill(6,6,121,121,1)
 rect(6,6,121,121,GT)
 if dg then draw_dlg() return end
 -- status strip (below the title, above the item list)
 print("$"..p.credits,10,18,10)
 print("hull "..flr(p.hp).."/"..p.mhp,34,18,GT)
 print("fuel "..flr(p.fuel),84,18,GT)
 menu_show(sm)
 pc(BX.." select  "..BO.." undock",112,GT)
end
