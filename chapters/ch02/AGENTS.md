# AGENTS.md - Chapter 2 (Kaelus Prime)

Read the repo-root `AGENTS.md` first (engine, chapter contract, PICO-8 gotchas, tooling).
Story canon/tone: `chapters/ch02/lore.md`.

**Status: playable vertical slice, PLACEHOLDER script.** Every string in `src/72_story.lua`
is a stand-in for the author's real Ch2 script - replace the text, keep the hooks/flow.

- **Cart budget:** 8079 / 8192 tokens (113 free). It includes `common/src/50_negotiation.lua`
  (~378 tokens); Ch1 does not. Measure with `p8check tokens ch02`.
- **Verification:** `p8check all ch02` = tokens + smoke (scripted logic) + 13 staged screens
  (`tmp/shots/ch02_*.png`) with a text-clipping sweep.

## Source layout

```
chapters/ch02/ch02.p8             cart: includes (adds 50_negotiation) + gfx/label/map/sfx/music
chapters/ch02/src/70_world.lua    CHAPTER=2, foes_def (scout), ch_stations, ch_foes, objective, draw_stations
chapters/ch02/src/71_station.lua  docking, checkpoint services, DOCKMASTER menu item
chapters/ch02/src/72_story.lua    talks, negs (clearance), mission/inventory, story flow, start_jump,
                                  jlines, jump_end, ch_ambush
chapters/ch02/tests/smoke.lua     logic playthrough      chapters/ch02/tests/shots.lua  staged screens
```

## Flow as built

1. **Arrival** (state 1): one dialogue page (`arrive`) -> flight. `update_story` here handles only
   `dlg` pages; add `term`/cutscene page kinds if the real script needs them.
2. **Kaelus checkpoint** (150,110): the first dock starts `checkin` (traffic control), sets
   `ohint=true`/`qs=1`. Services: REPAIR / REFUEL / SELL ORE + **DOCKMASTER (CLEARANCE)** while
   `qs==1`. Docking autosaves. Same partial REPAIR/REFUEL rules as Ch1.
3. **Clearance negotiation** (state 3, `negs.clearance`): `open` is timed (`tm=300`) and falls to
   `bluff` if you stall. Options: **offer a bribe** (`c=100`) -> `paid` (`res=1`, `qs=2`, clean) or
   **claim imperium property** -> `bluff` (`res=2`, `qs=2`, `ambush=true`). Both open the gate; the
   bluff flags you.
4. **Jump gate** (400,400): `start_jump` needs `qs>=2`, then the engine warp with this chapter's
   `jlines`; `jump_end()` calls `load("ch03")` (falls back to the title if absent).
5. **Ambush:** undocking via `leave_station()` spends `ambush` and calls `ch_ambush()` (3 scouts).

## Negotiation schema (`common/src/50_negotiation.lua`)

```
negs.id={who=2,name="...",start="node",n={
  node={t="text",o={{t="label",to="node",c=100}},res=1,go=function() ... end,tm=150,to="timeout"}
}}
```
`who` = portrait id (1 pilot, 2 other); `c` = credit cost (unaffordable options are refused);
`go` runs on entering the node; `res` lands in the `nres` global; `tm`/`to` time the node out.
Ending nodes have no `o`; X returns to the station. Ambush is spent by `leave_station()`.

## Balance / cuts

- Start **40 $** (credits are not carried from Ch1 yet), `ECO` same as Ch1, scout bounty 15, so the
  100 $ bribe takes a little mining/killing unless you carry credits later.
- **Cut for the 8192 wall:** the labour platform (canon is carried in text for now), BUY MISSILE,
  and the raider (scout-only roster). Re-add when the chapter has room (root AGENTS section 9).
- The NEGOTIATION OUTCOME (`nres`) and ambush flag are **not persisted** in the save (root section 13).

## Tests / UI notes

- The smoke missile test clears `roids`/`foes` first: this seed's layout can put a solid rock on
  the spawn point, which would eat the missile on frame 1.
- Negotiation panel: portraits at y10, names y44, node text y54 (4 lines), options at y92 step 8.
  Keep option labels <= 29 chars (a selector glyph is prepended) so `shots` stays green. The timer
  has no visible bar - it just jumps to the fallback node.
