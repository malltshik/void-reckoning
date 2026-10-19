-- harness prelude (included FIRST by p8check.py; never part of a shipped cart).
-- Isolates the player's real save and replaces the buttons with scripted input.
local mem={}
function cartdata() end
function dset(i,v) mem[i]=v end
function dget(i) return mem[i] or 0 end
K={}   -- buttons held this frame
KP={}  -- buttons pressed this frame (cleared after every tick)
function btn(i) return K[i] end
function btnp(i) return KP[i] end
