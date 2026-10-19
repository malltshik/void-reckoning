-- 71_station: Chapter 2 docking, checkpoint services, the clearance negotiation.

ECO={oresell=10,cell=250,repair=2,fuel=1,missile=15}

function nearest_station(range)
 for s in all(stations) do
  if abs(s.x-p.x)<range and abs(s.y-p.y)<range then return s end
 end
 return nil
end

function dock(s)
 active=s
 local items={
  {label="REPAIR HULL ("..ECO.repair.."$/HP)",act=function(m)
   local need=ceil(p.mhp-p.hp)
   if need<=0 then m.sub="HULL AT MAXIMUM" return end
   local units=min(need,flr(p.credits/ECO.repair))
   if units<=0 then m.sub="NOT ENOUGH $" return end
   p.credits-=units*ECO.repair
   p.hp=min(p.mhp,p.hp+units)
   m.sub="+"..units.." HP -"..units*ECO.repair.."$"
  end},
  {label="REFUEL ("..ECO.fuel.."$/UNIT)",act=function(m)
   local need=ceil(p.mfuel-p.fuel)
   if need<=0 then m.sub="FUEL FULL" return end
   local units=min(need,flr(p.credits/ECO.fuel))
   if units<=0 then m.sub="NOT ENOUGH $" return end
   p.credits-=units*ECO.fuel
   p.fuel=min(p.mfuel,p.fuel+units)
   m.sub="+"..units.." FUEL -"..units*ECO.fuel.."$"
  end},
  {label="SELL ORE ("..ECO.oresell.."$ EACH)",act=function(m)
   if p.ore<=0 then m.sub="NO ORE TO SELL" return end
   local g=p.ore*ECO.oresell
   p.credits+=g
   p.ore=0
   m.sub="SOLD ORE +"..g.."$"
  end}
 }
 -- the checkpoint's dockmaster holds the gate clearance (the chapter's negotiation)
 if s.kind=="kaelus" and qs==1 then
  add(items,{label="DOCKMASTER (CLEARANCE)",act=function() neg_start("clearance") end})
 end
 sm=menu_new(s.kind=="kaelus" and "KAELUS CHECKPOINT" or "KAELUS SERVICES",items)
 sfx(6,3)
 set_music(MUS_STATION)
 state=4
 -- first dock: traffic control explains you are flagged for inspection
 if s.kind=="kaelus" and not ohint then
  ohint=true
  qs=1
  dlg_start("checkin")
 end
 save_game()
end

function update_station()
 -- the check-in briefing plays over the menu, then hands control back to it
 if dg then update_dlg() return end
 menu_tick(sm)
 if btnp(BN) then leave_station() end
end

function draw_station()
 rectfill(6,6,121,121,1)
 rect(6,6,121,121,GT)
 if dg then draw_dlg() return end
 print("$"..p.credits,10,18,10)
 print("hull "..flr(p.hp).."/"..p.mhp,34,18,GT)
 print("fuel "..flr(p.fuel),84,18,GT)
 menu_show(sm)
 pc(BX.." select  "..BO.." undock",112,GT)
end
