-- void reckoning
-- 00_core: init, main loop, state machine

sys_w=512
sys_h=512

-- pico-8 pscii button glyphs: 142 = O, 151 = X (both 8px wide). lc() leaves >90 alone.
-- (143 is a diamond, NOT the X key -- that was the earlier prompt bug.)
BO=chr(142)
BX=chr(151)
-- terminal green, used for all non-dialogue text
GT=11
-- button roles (one consistent scheme everywhere):
--   X (code 5) = confirm / select / yes / dock / buy / enter / fire gun
--   Z (code 4) = cancel  / exit / no / undock / missiles
BY=5
BN=4

-- music pattern start indices (see tools/gen_audio.py)
MUS_FLIGHT=0
MUS_COMBAT=6
MUS_STATION=10

-- the system is a disc centred here; ARR is the soft boundary. Past it is empty
-- "dead space" (you can keep flying forever, but there is nothing out there).
ARX=256
ARY=256
ARR=380

-- states: 0 title, 1 story, 2 flight, 4 station, 5 jump, 6 gameover, 7 ending, 8 menu
function _init()
 cartdata("vrk1")
 trail=true
 build_fades()
 mtrack=-1
 mtcombat=false
 set_music(MUS_FLIGHT)
 state=0
 frame=0
 chapter=1
 init_player()
 load_system(chapter)
 init_story()
end

function init_player()
 p={x=64,y=64,dx=0,dy=0,a=0.25,
  hp=100,mhp=100,shd=50,mshd=50,scd=0,
  fuel=100,mfuel=100,credits=40,mis=10,mmis=10,
  wpn=1,wcd=0,ore=0,mcargo=10,
 chg=0,
 thermal=false,ecm=false,rebel=false}
 dth=""
 shk=0
 got=0
 spawnt=SPAWN_MIN
 camx=0
 camy=0
 msg=""
 msgt=0
end

function reset_game()
 init_player()
 chapter=1
 load_system(chapter)
 init_story()
 state=0
end

function msg_set(s)
 msg=s
 msgt=200
end

function set_music(n)
 if mtrack!=n then mtrack=n music(n) end
end

function clampi(v,a,b)
 if v<a then return a end
 if v>b then return b end
 return v
end

-- overflow-safe hit test: axis-guard BEFORE squaring.
-- PICO-8 numbers are 16.16 fixed point (+-32768), so d*d overflows past ~181px.
function hit2(x1,y1,x2,y2,r)
 local dx=abs(x1-x2)
 if dx>=r then return false end
 local dy=abs(y1-y2)
 if dy>=r then return false end
 return dx*dx+dy*dy<r*r
end

-- exact overflow-safe distance (PICO Space "dist_trig"): rotate the delta onto an
-- axis with atan2/cos/sin, then the projection IS the length. No squaring -> no wrap.
function dist_trig(x1,y1,x2,y2)
 local dx=x2-x1
 local dy=y2-y1
 local a=atan2(dx,dy)
 return dx*cos(a)+dy*sin(a)
end

function arena_dist(x,y)
 return abs(dist_trig(ARX,ARY,x,y))
end

-- pull a point back inside the arena disc (margin = how far in from the rim)
function clamp_arena(x,y,m)
 local dx=x-ARX
 local dy=y-ARY
 local d=abs(dist_trig(ARX,ARY,x,y))
 local lim=ARR-m
 if d>lim then
  local s=lim/(d+0.0001)
  return ARX+dx*s,ARY+dy*s
 end
 return x,y
end

-- split a string into word-wrapped lines no wider than w characters
function wrap(s,w)
 if s=="" then return {""} end
 local out={}
 local cur=""
 for word in all(split(s," ")) do
  word=tostr(word) -- split() coerces numeric tokens (e.g. "1393") to numbers
  if cur=="" then cur=word
  elseif #cur+1+#word<=w then cur=cur.." "..word
  else add(out,cur) cur=word end
 end
 if cur!="" then add(out,cur) end
 return out
end

-- force all on-screen text to lowercase: pico-8 draws lowercase as small-caps, so
-- this keeps the whole UI at one font size instead of mixing tall caps + small letters.
function lc(s)
 s=tostr(s)
 local o=""
 for i=1,#s do
  local c=ord(s,i)
  if c>=65 and c<=90 then c+=32 end
  o..=chr(c)
 end
 return o
end

_print_builtin=print
function print(s,x,y,c)
 _print_builtin(lc(s),x,y,c)
end

function _update()
 frame+=1
 if msgt>0 then msgt-=1 end
 -- suppress pico-8's built-in pause menu so button 6 drives our own ship menu
 if btn(6) then poke(0x5f30,1) end
 if state==0 then
  if btnp(4) or btnp(5) then
   state=1
   start_story()
  end
 elseif state==1 then
  update_story()
 elseif state==2 then
  update_flight()
 elseif state==4 then
  update_station()
 elseif state==5 then
  update_jump()
 elseif state==8 then
  update_menu()
 elseif state==6 or state==7 then
  if state==6 then update_fx() end
  if got>0 then
   got-=1
  elseif btnp(4) or btnp(5) then reset_game() end
 end
end

function _draw()
 -- state 2 (flight) keeps the previous framebuffer so draw_flight can fade it into
 -- motion trails; every other state clears normally.
 if state!=2 then cls(0) end
 if state==0 then draw_title()
 elseif state==1 then draw_story()
 elseif state==2 then draw_flight()
 elseif state==4 then draw_station()
 elseif state==5 then draw_jump()
 elseif state==8 then draw_menu()
 elseif state==6 then draw_gameover()
 elseif state==7 then draw_ending()
 end
end
