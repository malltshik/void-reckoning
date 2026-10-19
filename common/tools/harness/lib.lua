-- harness helpers (included after the game code, before the chapter's test driver).
fails=0

-- assertion: logs a FAIL line instead of aborting so one run reports everything
function ck(c,m)
 if not c then
  fails+=1
  printh("FAIL "..m,"p8log.txt")
 end
end

-- advance n frames of the real game loop
function tick(n)
 for i=1,(n or 1) do
  _update()
  _draw()
  KP={}
 end
end

-- press a button for one frame (arrows 0-3, Z=4, X=5, Enter=6)
function press(b)
 KP[b]=true
 tick(1)
end

-- hold a button for n frames (counts as a fresh press on the first)
function hold(b,n)
 K[b]=true
 KP[b]=true
 tick(n)
 K[b]=nil
end

-- text-clipping guard for the screenshot run: log any print that would run off the 128px
-- screen. Skipped in flight (state 2) where labels are drawn in scrolling world coords.
local _lcprint=print
function print(s,x,y,c)
 if state!=2 and x and (x<0 or x+sw(tostr(s))>128) then
  printh("CLIP \""..tostr(s).."\" x="..x.." w="..sw(tostr(s)),"p8log.txt")
 end
 _lcprint(s,x,y,c)
end

-- dump the 128x128 screen buffer (one hex digit per pixel) for p8check.py to PNG-ify
function shot(name)
 printh("SHOT "..name,"p8shots.txt")
 for y=0,127 do
  local s=""
  for x=0,127 do
   local c=pget(x,y)
   s..=sub("0123456789abcdef",c+1,c+1)
  end
  printh(s,"p8shots.txt")
 end
end

-- end of run: write the verdict and stop the cart
function finish(tag)
 printh(tag.." "..(fails==0 and "OK" or "FAIL ("..fails.." failed)"),"p8log.txt")
 stop()
end
