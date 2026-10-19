-- 50_negotiation: docked negotiation (state 3) - the second pillar (DESIGN sec 6).
-- Only chapters that use it #include this file, so Ch1 pays no tokens for it.
--
-- Chapter content supplies `negs`:
--   negs.id={who=2,name="...",start="node",n={...}}
--   node={t="text",o={{t="label",to="node",c=100}},res=1,go=fn,tm=150,to="timeout"}
-- `who` picks a portrait (1 pilot, 2 other). `c` = credit cost; an unaffordable option
-- is refused. `go` runs on entering the node; `res` lands in the `nres` global (in-memory
-- only - the outcome is not saved yet, see root AGENTS section 13).
-- `tm`/`to` make the node timed (jump to `to` when it runs out).

function neg_start(id)
 local s=negs[id]
 ng={s=s,i=s.start,k=1,t=0}
 state=3 sfx(5,3)
end

function neg_go(i)
 local n=ng.s.n[i]
 ng.i=i ng.t=0 ng.k=1
 if n.res then nres=n.res end
 if n.go then n.go() end
end

function update_neg()
 local n=ng.s.n[ng.i]
 ng.t+=1
 if n.tm and ng.t>n.tm then neg_go(n.to) return end
 if not n.o then
  if btnp(4) or btnp(5) then ng=nil state=active and 4 or 2 end
  return
 end
 local o=n.o
 if btnp(3) then ng.k=ng.k%#o+1 sfx(5,2) end
 if btnp(2) then ng.k=(ng.k+#o-2)%#o+1 sfx(5,2) end
 if btnp(BY) then
  local q=o[ng.k]
  if q.c and p.credits<q.c then sfx(8,3) return end
  if q.c then p.credits-=q.c end
  neg_go(q.to)
 end
end

function draw_neg()
 local n=ng.s.n[ng.i]
 rectfill(6,6,121,121,1)
 rect(6,6,121,121,GT)
 sspr(PORT[1][1],PORT[1][2],16,16,10,10,32,32)
 local w=ng.s.who or 2
 sspr(PORT[w][1],PORT[w][2],16,16,84,10,32,32)
 print(PORTNAME[1],10,44,5)
 local nm=ng.s.name or PORTNAME[w]
 print(nm,115-sw(nm),44,7)
 local ls=wrap(n.t,29)
 for i=1,min(4,#ls) do print(ls[i],8,54+(i-1)*8,7) end
 if not n.o then
  if frame%40<25 then pc(BX.." continue",116,GT) end
  return
 end
 for i=1,#n.o do
  local s=i==ng.k
  print((s and chr(23) or " ")..n.o[i].t,8,92+(i-1)*8,s and 7 or 5)
 end
end

-- undock helper: an ambush flagged by a failed negotiation starts the moment you leave
function leave_station()
 state=2
 if ambush then ambush=false if ch_ambush then ch_ambush() end end
end
