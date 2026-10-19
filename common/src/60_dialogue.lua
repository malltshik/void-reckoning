-- 60_dialogue: character portraits + a dialogue scene runner (mixed-case text)
--
-- The runner is engine; the scripts are chapter content (`talks`, `talkname` in
-- chapters/<ch>/src/72_story.lua). A script is a flat list: a patch table like {w=2}
-- switches the speaker (0 = narration, no portraits; 1 = pilot; 2 = handler/other),
-- every string is typed out and waits for X/Z. talkname[id] overrides the right-hand
-- speaker's name. Start one with dlg_start(id); step it with update_dlg(); draw_dlg().

-- 16x16 portrait blocks in the sheet (see tools/gen_gfx.py), drawn 2x here.
-- PORT[id] = {sheet_x, sheet_y}
PORT={ {0,16}, {16,16} }
PORTNAME={ "pilot 1393", "handler rooke" }

DY=80   -- open y of the text box

-- word-wrap a string, remembering each line's start offset in the source so the
-- typewriter can reveal it without words reflowing.
local function wrap_off(s,w)
 local out={}
 local line=""
 local lo=1
 local i=1
 local n=#s
 while i<=n do
  local j=i
  while j<=n and sub(s,j,j)!=" " do j+=1 end
  local word=sub(s,i,j-1)
  if line=="" then line=word lo=i
  elseif #line+1+#word<=w then line=line.." "..word
  else add(out,{t=line,o=lo}) line=word lo=i end
  i=j+1
 end
 if line!="" then add(out,{t=line,o=lo}) end
 return out
end

function dlg_start(id)
 dg={s=talks[id],i=1,ch=0,y=128,w=1,lines=nil,nm=talkname[id]}
end

function update_dlg()
 if dg==nil then return end
 local st=dg.s[dg.i]
 if st==nil then
  dg.y+=4
  if dg.y>=128 then dg=nil end
  return
 end
 -- slide the box up into place (only while open; never during the close above)
 if dg.y>DY then dg.y=max(DY,dg.y-4) end
 if type(st)=="table" then
  if st.w then dg.w=st.w end
  dg.i+=1
  dg.ch=0
  dg.lines=nil
  return
 end
 if dg.lines==nil then dg.lines=wrap_off(st,27) end
 local total=#st
 if btnp(4) or btnp(5) then
  if dg.ch<total then dg.ch=total
  else dg.i+=1 dg.ch=0 dg.lines=nil end
  return
 end
 if dg.ch<total then
  dg.ch+=2
  if dg.ch>total then dg.ch=total end
  if dg.ch%8<2 then sfx(10,2) end
 end
end

-- draw one portrait 2x; both speakers are always shown undimmed. The active
-- speaker is signalled only by the highlighted name above their head.
local function portrait(id,x,y)
 sspr(PORT[id][1],PORT[id][2],16,16,x,y,32,32)
end

function draw_dlg()
 if dg==nil then return end
 if dg.w!=0 then
  portrait(1,12,8)
  portrait(2,84,8)
  print(PORTNAME[1],12,44,dg.w==1 and 7 or 5)
  local n2=dg.nm or PORTNAME[2]
  print(n2,115-sw(n2),44,dg.w==2 and 7 or 5)
 end
 local y=dg.y
 rectfill(0,y,127,127,1)
 rect(0,y,127,127,5)
 if dg.lines then
  for k=1,min(#dg.lines,5) do
   local L=dg.lines[k]
   local n=clampi(dg.ch-L.o+1,0,#L.t)
   if n>0 then print(sub(L.t,1,n),8,y+6+(k-1)*8,7) end
  end
  if dg.ch>=#dg.s[dg.i] and frame%30<18 then print(chr(131),119,y+30,GT) end
 end
end

-- story helpers shared by chapters: advance a page, and draw a terminal page
function next_spage()
 spg+=1
 spt=0
 if spg>#spages then state=2 end
end

function draw_term(pg)
 local n=spt*3
 local y=30
 for i=1,#pg.lines do
  local s=pg.lines[i]
  local shown=sub(s,1,clampi(n,0,#s))
  for k in all(wrap(shown,29)) do
   print(k,8,y,GT)
   y+=8
  end
  n-=#s
 end
 if frame%30<15 then print(chr(16),8,y,GT) end
end
