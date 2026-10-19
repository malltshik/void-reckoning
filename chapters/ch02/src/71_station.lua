-- 71_station: Chapter 2 docking. XR-7PO has no trade - the hold carries fragments, so the
-- only service here is slicing the archive's dead terminal to rebuild the navigation key.

function nearest_station(range)
 for s in all(stations) do
  if abs(s.x-p.x)<range and abs(s.y-p.y)<range then return s end
 end
 return nil
end

function dock(s)
 active=s
 local items={
  {label="LOCAL INDEX",act=function(m)
   m.sub=p.ore.." of "..RELIC_GOAL.." relics recovered."
  end}
  }
  -- once all relics are aboard, the code can be cracked
  if qs>=3 then
   add(items,{label="CRACK THE CODE",act=function(m)
    if qs>=4 then m.sub="COORDINATES ALREADY LOGGED" return end
    slicing=true
    talk("slice",P_TERM)
   end})
  end
 sm=menu_new("XR-7PO ARCHIVE",items)
 sfx(6,3)
 set_music(MUS_STATION)
 state=4
  -- first dock: the archive explains what it lost
  if not ohint then
   ohint=true
   talk("archive",P_TERM)
  end
 save_game()
end

function update_station()
 -- the archive's briefing plays over the menu; finishing the slice sets the key
 if dg then
  update_dlg()
  if dg==nil and slicing then
   slicing=nil
   qs=4
   msg_set("COORDINATES RECOVERED")
   save_game()
  end
  return
 end
 menu_tick(sm)
 if btnp(BN) then state=2 end
end

function draw_station()
 rectfill(6,6,121,121,1)
 rect(6,6,121,121,GT)
 if dg then draw_dlg() return end
 print("relics "..p.ore.."/"..RELIC_GOAL,10,18,12)
 menu_show(sm)
 pc(BX.." select  "..BO.." undock",112,GT)
end

-- death keeps the fragments: they ARE the progress here, so the engine's default recover
-- (which wipes p.ore) is wrong for XR-7PO. There is no money, so no recovery fee either.
function recover()
 p.hp=p.mhp p.shd=p.mshd p.fuel=p.mfuel
 p.dx=0 p.dy=0 p.chg=0 p.scd=0 p.ramt=0
 p.x=active.x p.y=active.y+18
 msg_set("RECOVERED - RELICS INTACT")
 save_game()
 state=2
end
