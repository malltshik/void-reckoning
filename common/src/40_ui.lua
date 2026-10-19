-- 40_ui: text helpers, HUD, radar, overlays

-- string pixel width: pscii codes 128-255 draw 8px wide, 16-127 draw 4px.
function sw(s)
 local w=0
 for i=1,#s do w+=(ord(s,i)>=128 and 8 or 4) end
 return w
end

function pc(s,y,c)
 print(s,max(0,flr((128-sw(s))/2)),y,c)
end

-- generic callback-list menu (from PICO Space's eE): title + items, each item is
-- {label=..., act=function(m) end}. Actions can set m.sub for a status line.
function menu_new(t,items)
 return {title=t,i=1,items=items,sub=""}
end

function menu_move(m,d)
 local n=clampi(m.i+d,1,#m.items)
 if n!=m.i then m.i=n sfx(5,3) end
end

function menu_tick(m)
 if btnp(3) then menu_move(m,1) end
 if btnp(2) then menu_move(m,-1) end
 if btnp(BY) then
  local it=m.items[m.i]
  if it.act then it.act(m) end
 end
end

-- station services list: title + numbered items + a 1-2 line status
function menu_show(m)
 print(m.title,12,8,GT)
 for k,it in ipairs(m.items) do
  local sel=k==m.i
  print((sel and chr(23) or " ")..k.."."..it.label,8,26+(k-1)*11,sel and 7 or GT)
 end
 if m.sub!="" then
  local ls=wrap(m.sub,31)
  for i=1,min(2,#ls) do print(ls[i],8,92+(i-1)*8,GT) end
 end
end

-- big title in the custom font (0x5f58 enables it at 0x5600) with a drop shadow
function print_title(s,y,c)
 poke(0x5f58,0x81)
 local x=flr(64-#s*4)
 print(s,x,y+2,1)
 print(s,x,y,c)
 poke(0x5f58,0)
end

function draw_title()
 for i=1,60 do
  local x=(i*53+flr(frame*0.2))%128
  pset(x,(i*37)%128,i%5==0 and 7 or 5)
 end
 -- a planet fills the view; the title is printed over it (the ship was removed)
 circfill(64,78,44,1)
 circ(64,78,44,6)
 circfill(50,104,12,2)
 circfill(84,60,8,2)
 print_title("void reckoning",52,7)
 if hassave then pc(BX.." continue    "..BO.." new game",100,GT)
 elseif frame%40<25 then pc(BX.." begin",100,GT) end
  pc("audio: gruber & krajzeg",120,5)
end

-- ship systems menu (state 8): a 3-item list + a one-entry-at-a-time carousel pane
function open_menu()
 mm=menu_new("",{
  {label="MISSIONS",lines=mission_lines()},
  {label="INVENTORY",lines=inventory_lines()},
  {label="EXIT",lines={"save and quit to the title page."},act=function() save_game() state=0 end}
 })
 state=8
 sfx(5,3)
end

function update_menu()
 if btnp(3) then menu_move(mm,1) end
 if btnp(2) then menu_move(mm,-1) end
 local it=mm.items[mm.i]
 it.ci=it.ci or 1
 local n=#it.lines
 if n>1 and btnp(0) then it.ci=(it.ci+n-2)%n+1 end
 if n>1 and btnp(1) then it.ci=it.ci%n+1 end
 if btnp(BY) and it.act then it.act() end
 if btnp(BN) or btnp(6) then state=2 end
end

function draw_menu()
 rectfill(6,6,121,121,1)
 rect(6,6,121,121,GT)
 for k,it in ipairs(mm.items) do
  local sel=k==mm.i
  print((sel and chr(23) or " ")..k.."."..it.label,10,14+(k-1)*10,sel and 7 or GT)
 end
 line(10,42,117,42,5)
 local it=mm.items[mm.i]
 it.ci=it.ci or 1
 local ls=wrap(it.lines[it.ci] or "",25)
 for k=1,#ls do pc(ls[k],54+(k-1)*9,7) end
 if #it.lines>1 then
  print(chr(139),8,58,GT)
  print(chr(145),114,58,GT)
 end
 pc(BX.." select  "..BO.." exit",112,GT)
end

-- one HUD bar: 2-char label + an w x 4 trough + a coloured fill (all bars identical
-- size, colour is the only difference). bx/by = top-left of the trough.
function hbar(l,bx,by,w,v,mv,c)
 print(l,bx-10,by-1,GT)
 rectfill(bx,by,bx+w-1,by+3,2)
 rectfill(bx,by,bx+flr(v/mv*(w-1)),by+3,c)
end

-- tiny missile glyph (a 2x4 bar): red when out of rockets, green otherwise
function misicon(x,y,c)
 rectfill(x,y,x+1,y+3,c)
end

function draw_hud()
 rectfill(0,0,127,13,1)
 hbar("HP",11,1,42,p.hp,p.mhp,11)
 hbar("SH",11,7,42,p.shd,p.mshd,12)
 hbar("FU",66,1,42,p.fuel,p.mfuel,9)
 hbar("CG",66,7,42,p.ore,p.mcargo,10)
 local s="$"..p.credits
 print(s,127-sw(s),0,10)
 local mc=p.mis>0 and 11 or 8
 misicon(111,7,mc)
 print(p.mis,116,7,mc)
end

-- plot a world point on the round radar, clamped to the rim so off-system (dead
-- space) contacts still show on the edge instead of vanishing
function rplot(cx,cy,rr,sc,x,y,c)
 local px=(x-ARX)*sc
 local py=(y-ARY)*sc
 local d=abs(dist_trig(0,0,px,py))
 if d>rr-1 then
  local k=(rr-1)/(d+0.0001)
  px*=k py*=k
 end
 pset(cx+px,cy+py,c)
end

function draw_radar()
 local cx=106
 local cy=104
 local rr=16
 circfill(cx,cy,rr,1)
 circ(cx,cy,rr,6)
 local sc=rr/ARR
 for s in all(stations) do rplot(cx,cy,rr,sc,s.x,s.y,10) end
 for f in all(foes) do rplot(cx,cy,rr,sc,f.x,f.y,8) end
 for r in all(roids) do
  if r.solid then rplot(cx,cy,rr,sc,r.x,r.y,6) end
 end
 local pc2=11
 if arena_dist(p.x,p.y)>ARR then pc2=8 end
 rplot(cx,cy,rr,sc,p.x,p.y,pc2)
 -- compass needle: an arrow just OUTSIDE the ring pointing at the current objective
 local tgt=objective()
 if tgt then
  local a=atan2(tgt.x-p.x,tgt.y-p.y)
  local tx=cx+cos(a)*(rr+4)
  local ty=cy+sin(a)*(rr+4)
  local bx=tx-cos(a)*5
  local by=ty-sin(a)*5
  line(tx,ty,bx-sin(a)*3,by+cos(a)*3,10)
  line(tx,ty,bx+sin(a)*3,by-cos(a)*3,10)
 end
end

function draw_msg()
 if msgt>0 then
  rectfill(0,114,127,127,1)
  pc(msg,117,GT)
 end
end

function draw_gameover()
 -- show the death blast at the ship's last camera position
 camera(camx,camy)
 draw_parts()
 camera()
 pc("GAME OVER",46,GT)
 pc(dth,60,GT)
 if got>0 then
  pc("STANDBY...",88,GT)
 else
  if frame%40<25 then pc("press "..BX.." to recover",92,GT) end
 end
end

-- warp cutscene (state 5): radial streaks + one narration line per beat. The chapter
-- supplies `jlines` (keep lines <= 31 chars) and defines `jump_end()` (title, or the
-- multicart chain to the next cart).
JPER=45

function update_jump()
 jt+=1
 if btnp(4) or btnp(5) then
  -- X skips the reveal; once every line is shown, X leaves the cutscene
  if jt>#jlines*JPER then jump_end() else jt=#jlines*JPER+1 end
 end
end

function draw_jump()
 for i=0,19 do
  local a=i/20
  local r=8+((i*13+frame*16)%104)
  line(64+cos(a)*r,64+sin(a)*r,64+cos(a)*(r+9),64+sin(a)*(r+9),i%4==0 and 7 or 12)
 end
 local n=clampi(flr(jt/JPER)+1,0,#jlines)
 for i=1,n do
  local k=jlines[i]
  print(k,flr((128-sw(k))/2),12+(i-1)*11,7)
 end
 if jt>#jlines*JPER and frame%40<25 then pc(BX.." continue",118,GT) end
end
