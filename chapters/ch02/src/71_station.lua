-- 71_station: Chapter 2 docking. The archive has no services: the first dock plays its
-- short brief, and once every relic is aboard it goes straight into the code crack.
-- A container opens the slicing minigame directly (rules + screens in 73_combat).

function nearest_station(range)
 for s in all(stations) do
  if abs(s.x-p.x)<range and abs(s.y-p.y)<range then return s end
 end
 return nil
end

function dock(s)
 if s.hot then msg_set("GUARDS NEARBY") return end
 if s.kind=="container" then
  start_slice(s)
  return
 end
 active=s
 state=4
 sfx(6,3)
 save_game()
 if not ohint then
  ohint=true
  talk("archive",P_TERM)
 elseif qs>=3 and qs<4 then
  start_slice(s)
 end
end

function update_station()
 if mg then update_mg() return end
 if dg then
  update_dlg()
  -- the brief ends with the crack, if the relics are already aboard
  if dg==nil and qs>=3 and qs<4 then start_slice(active) end
  return
 end
 if btnp(BN) then state=2 end
end

function draw_station()
 if mg then draw_mg() return end
 rectfill(6,6,121,121,1)
 rect(6,6,121,121,GT)
 if dg then draw_dlg() return end
 print("the archive is silent.",12,26,GT)
 print("it wants its relics.",12,36,GT)
 pc(BO.." undock",112,GT)
end

-- death keeps the relics: they ARE the progress here, so the engine's default recover
-- (which wipes p.ore) is wrong for XR-7PO. There is no money, so no recovery fee either.
function recover()
 p.hp=p.mhp p.shd=p.mshd p.fuel=p.mfuel
 p.dx=0 p.dy=0 p.chg=0 p.scd=0 p.ramt=0
 p.x=active.x p.y=active.y+18
 msg_set("RECOVERED - RELICS INTACT")
 save_game()
 state=2
end
