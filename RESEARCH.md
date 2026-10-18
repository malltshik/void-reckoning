# RESEARCH.md — ideas worth stealing (re-implemented in our own code)

Study notes from reference carts (see `research/<cart>/README.md` for provenance/license).
Nothing here should be copied wholesale — port the *idea*, write our own version, log it.

Primary source so far: **PICO Space** by Drake Blue (CC BY-NC-SA). Decoded source lives in
`research/pico_space/decoded_decompressed.lua`. The author's own teardown is linked there too.

Shorthand in the snippets: the game's locals are single letters. Notably
`a`=player, `q`=enemies, `ee`=particles, `k`=drawable list, `d`=map cursor,
`f`=current system, `u`=systems array, `v`=current state, `l`=level/upgrade tier.

---

## 1. Parallax starfield from a tiny fixed pool  ★ (user liked "parallax / space look")
Objects: `ne`, `nn`, `C`.

```lua
function ne() nn={} for e=1,p(150,100) do
  add(nn,{x=rnd(Z),y=rnd(Z),z=p(30,.1),c=c(5,2)}) end end
function C(n,e,o) clip(r"1,1,126,126") m() local t,i
  if     o then t,i=(n/o>>7)*550,(e/o>>7)*700
  elseif n then t,i=n,e
  else          t,i=sin(e1/1280)*550,sin(e1/2560)*700 end
  for a,e in pairs(nn) do pset((e.x-t)/e.z%128,(e.y-i)/e.z%128,(o or not n)and e.c%5+1or e.c) end
  clip() end
```

- Stars live in a big box `[0, Z]` (`Z` = system radius), each with a **depth** `z` in
  `(0.1 .. 30]` and a colour.
- Screen pos = `(star.x - offset)/star.z % 128`. Depth divides the parallax: near stars
  (`z` small) sweep fast, far ones crawl. The `%128` **wraps** the field, so ~100–250 stars
  tile the whole screen infinitely.
- In flight it's called `C(a.x,a.y)` (offset = ship pos → parallax with movement).
- Idle branch uses `sin(frame/…)` for a slow drift, so space never looks frozen.
- On the map it's reused as decoration: `C(d.x,d.y,h)` with a zoom `h`.
- **Why it matters for us:** cheap, no per-star update loop, one `pset` per star. Directly
  usable for our 512×512 flight field (we currently have no star layer).

## 2. Dithered fade-to-black + free motion trails  ★ (the "signature look")
Objects: `A` (reset draw palette), `eM` (fade), palettes `np`/`ny`.

```lua
function A() poke4(24320,770.00416,1798.0196,2826.03528,3854.05097) end
function eM(e) local e,n=24576+e%2*64, e&2==0 and np or ny
  for o=0,8064,128 do for e=e+o,o+e+60,4 do
    poke(e,n[@e],n[@(e+1)],n[@(e+2)],n[@(e+3)]) end end end
```

- `24320 = 0x5F00` is the **draw palette** region → `A()` resets colour mapping each frame
  (the author calls it "reset_dr_pal"); objects call `pal(...)` then `A()` to undo.
- `24576 = 0x6000` is the **screen buffer**. `eM(s)` is called every frame in the flight
  draw; it walks the buffer **4 pixels at a time** and remaps each nibble through a palette
  table (`np` on even frames, `ny` on odd). Result: the whole previous frame is dimmed a
  step → **fade to black** *and* motion trails, for free.
- Two tables alternate → a 2-stage **dither** (checkerboard-ish) rather than a flat dim.
- **Caution for us:** `cls()` also touches the buffer; the game avoids `cls` in flight
  (uses `cls(e|8)` only on system entry). Our current `cls(1)` tint strategy would fight
  this. Treat as a separate render-mode prototype.

## 3. Vector ship = lines + a cockpit sprite  ★ (user liked the ship animation)
Objects: `eC`, `n1`, engine `nf`.

```lua
function eC(e) pal(8,e.c) pal(2,nR[e.c]) end                 -- captain colour swap
function n1(e) eC(e) local e,n=e.z<1 and -3.5 or 3.5, e.an
  local e,o,t,n,i,a=sin(n)*e,-sin(n-.15)*e,-sin(n+.15)*e, cos(n)*e,-cos(n-.15)*e,-cos(n+.15)*e
  line(n*1.2,e*1.2,i*1.2,o*1.2,2) line(n*1.2,e*1.2,a*1.2,t*1.2) line(i,o,a,t)
  line(n,e,i,o,8) line(n,e,a,t) line(0,0,i,o) line(0,0,a,t) line(0,0,n,e)
  spr(r"0,-4,-4") A() end
```

- Body is a handful of `line`s along the heading; an 8×8 sprite is the cockpit.
- `e.z < 1` mirrors the whole thing → the **flip** ability (also slows the ship, see §8).
- Enemies reuse `n1`; engines emit particles via `nf` (§4).

## 4. Particles as a table with a function pointer  ★ (user liked "animation/SFX feel")
Objects: `eh`, `D`, `eA`, `eV`, `ee`.

```lua
function eA(e) e.x+=e.vx e.y+=e.vy e.l-=1 return e.l>=0 end           -- ballistic
function eV(e) e.x+=rnd{-e.vx,e.vx} e.y+=rnd{-e.vy,e.vy} e.l-=1 return e.l>=0 end -- jitter
function eh(e,n,o,t,i) add(ee,{x=e,y=n,vx=o,vy=t,l=33,c=i,upd=eV,circ=1}) end
function D(e,n,o,t,i,a,d,r,f,s,l) for n=1,n do local n,d=ev(d)
  add(ee,{x=o,y=t,vx=i+n,vy=a+d,l=c(r,f),c=c(l,s),upd=rnd(e)}) end end
```

- A particle carries its own `upd` closure → polymorphic update chosen at spawn
  (`rnd(e)` picks a behaviour). `eA`=ballistic, `eV`=explosion jitter.
- `D(behaviour, count, x, y, vx, vy, rngV, lifeMin, lifeMax, colMin, colMax, ...)` is the
  one generic emitter used for engines, hits, death bursts, jumps.
- Draw: `if(e.circ) circ(e.x,e.y,100-e.l*3,e.c) else pset(e.x,e.y,e.c)` — `circ` ones grow.
- Update loop: `for e=#ee,1,-1 do if(not ee[e]:upd()) deli(ee,e) end` (swap-remove, as we do).

## 5. Generic data-driven menu  ★ (user wants "menu with map/scanner")
Object: `eE` (+ `x` button-sfx wrapper, `M` icon helper).

```lua
function x(e) if(btnp(e)) sfx(63,3,e=="5"and 27or e=="4"and 29or 31,2) return 1 end end
function eE(o,t,e,i,a,n) w=mid(1,w,#e) ?o,14,30
  if(t) M(0,31,rnd"0xffff")
  for e,n in pairs(i) do ?n,16,40+e*8, w==e and 7+B%2 or 13 end
  rectfill(r"0,105,128,109,1") ey(a[w],105,6)
  if x"5" and e[w] then srand(time()) e[w]() end
  if(x"4" and n) v=n end
  if(x"3") w+=1
  if(x"2") w-=1 end
```

- `eE(title, flag, labels, descriptions, callbacks, backTarget)` — one function renders the
  pause menu, station menus, notice-board, etc. Callback array = actions.
- Highlight blinks via `7+B%2` (frame parity). Bottom bar shows the current description.
- **Why it matters:** our negotiation/station UI will outgrow the current `smenu`; adopt a
  callback-list menu now.

## 6. System map & galaxy scanner  ★ (user wants "system map/scanner")
Objects: `nU` (system map), `nE` (galaxy scanner), `map` method on each drawable.

- Every object (planet, station, ship, gate, sun) exposes **two** draw paths: `draw()`
  (world/flight) and `map(scale)` (map mode). The map just calls `e:map(scale)` for each —
  no separate map data.
- Free pan: `d.x += btn"0"and-161 or btn"1"and 161 or 0`; zoom via `h` (clamped `mid`).
- Background reuses `C()`; links between systems drawn as `line`s; current system is
  highlighted; nearest target picked by overflow-safe distance `z` (§9); X confirms jumps.
- **Why it matters:** matches our radar/waypoint needs and the planned map/scanner screen.

## 7. Dialogue: pipe strings + template fill + P8SCII wide glyphs
Objects: `eB`, `K`, `E`/`G`.

```lua
function eB(t,i) local e,n=1,"" while e<=#t do local o=t[e]
  if     o=="#" then e+=1 n..=i[tonum(t[e])]      -- #n -> args[n]
  elseif o=="m" then n..="n\en"                    -- wide 'm' via P8SCII
  elseif o=="w" then n..="v\ev"                    -- wide 'w'
  else n..=o end e+=1 end return n end
function K(e) return rnd(split(e,"|")) end          -- pick a variant line
```

- Dialogue = one long pipe-delimited string; `K` picks a random variant; `eB` substitutes
  `#1..#9` args and expands `m`/`w` into pseudo-wide glyphs using P8SCII cursor moves.
- We already store dialogue as pipe strings — worth adding the `#n` arg substitution and
  the `m`/`w` trick (token-cheap wide letters, big readability win in a narrow font).

## 8. Controls (concrete)
- `btn(0..3)` = move (analog-ish: reads raw bitmask, applies accel).
- `btn(4)` = O/Z = **flip** → `a.z = btn"4" and 0.4 or 1` (ship mirrors, speed ×0.4).
- `btn(5)` = X = **fire**; hold to **charge**: `ek=min(ek+.2,10)`, release fires a
  damage-scaled shot `dam=mid(j,n,9)`; while charging the shield does **not** regen.
- `btn(6)` = P/start = open pause/menu (`eO`), which also pauses the world.
- Menu nav: `btn(2)/btn(3)` = up/down, `btn(5)` = confirm, `btn(4)` = back.
- **Why it matters:** the charge-release + flip is a nice combat verb we lack; the
  "charging blocks shield regen" is a clean risk/reward rule.

## 9. Overflow-safe helpers (the dev-blog tricks)
Objects: `z` (distance), `S` (proximity), `O`/`el` (rng stash).

```lua
function z(e,n) local e,n=n.x-e.x,n.y-e.y local o=atan2(e,n)
  return e*cos(o)+n*sin(o) end                             -- rotate delta -> distance
function S(e,n,o) return abs(e.x-n.x)<o and abs(e.y-n.y)<o end -- axis-guarded AABB
function O(e) n8=rnd() srand(e) end                         -- stash rng state, reseed
function el() srand(n8) end                                 -- restore rng state
```

- `z` = **distance without squaring** (rotate the delta onto an axis; projection = length).
  Overflow-safe by construction on the 16.16 fixed-point range. Complements our `hit2`.
- `O`/`el` let you make a small part of the frame deterministic (e.g. a seeded name/star)
  without disturbing the global RNG stream — good pattern for our seeded dressing.

## 10. Misc worth keeping
- **Save**: `cartdata"…"` at boot + `dset/dget` per index; the web player can't read it and
  the game detects that and tells the player to use desktop. Good UX pattern for us.
- **Audio**: `sfx(n, channel, offset, length)` — e.g. enemy shot pitch-scales with type
  `sfx(60,3,n*4,4)`; UI blips `sfx(63,3,…)`; `music(track)`; instruments restored after
  a `memcpy` when bumping music (`e5`).
- **Galaxy gen** (`ez`): hard-cap system count; place with min-distance rejection, link with
  an MST-ish pass, then add extra links when systems are `<30` apart and degree `<4`;
  `srand(seed)` per galaxy; draws a progress screen while generating.
- **Outlined text** `e3`: prints the string 4× with P8SCII cursor shifts for a 1px outline.
- **Text width/centering**: `ea(e)=print(e,0,128)` returns the draw cursor x = width;
  `ey` centers with `63-width\2`.

---

## Apply to Void Reckoning — candidate prototypes
1. **`dist_trig`** (`z` above) into `00_core.lua` next to `hit2` — exact distance for
   nearest-target without Manhattan approximation. Low risk, small.
2. **Parallax star layer** in `20_world.lua:draw_flight` — tiled `%128` field + `sin` idle
   drift; reuses the same pool on the map/radar. Medium.
3. **Callback-list menu** (`eE`) to replace/extend `smenu` — prerequisite for the
   negotiation layer. Medium.
4. **Fade + trails** (`eM`/`A`) as a flight render mode — signature look but conflicts with
   our `cls(1)` tint; needs a prototype and the user's eyes. Higher risk.
5. **Charge-release fire + flip** verbs in `10_entities.lua`/`30_combat.lua`. Needs balance
   check against `DESIGN.md`.

Ask the user which of these to prototype first (1 and 2 are the cheapest wins).
