# Luau performance patterns for tower defense (T026)

Question: which documented Luau and Roblox patterns help a TD game with many enemies, projectiles and effects?

Docs fetched 2026-10-28; the pages are undated, so re-check before relying on a figure.

## Facts (sourced)
**Luau language guidance** ([Luau, Performance](https://luau.org/performance))
- Build object-like tables with one literal that sets every field (enables a table-templates optimisation); use `table.create` when the final array size is known; keep object shapes uniform because varying keys defeats field-lookup caching.
- `table.insert` is the fastest general append; with a preallocated table an explicit index is faster still. `#t` is cached and usually constant time.
- Avoid allocating closures or temporary tables in tight loops (garbage-collector work). Closures with immutable upvalues are cheaper.
- Use `obj:Method()`, do not cache methods in locals; point `__index` at a table, not a function.
- Luau has a native 3-component float vector type that cuts GC pressure for vector-heavy code. The page quotes 3x or more speedups for tuned array library functions; page-level figures, not game benchmarks.

**Native code generation** ([Roblox, Native code generation](https://create.roblox.com/docs/luau/native-code-gen))
- Server-side scripts can be compiled to machine code with `--!native` (whole script) or `@native` (one function). It helps math-heavy code called often (every frame), on tables and `buffer` data; it does not help code that calls many Roblox APIs. Adding it everywhere is discouraged (startup time, memory, per-game limit). Measure with and without in the Script Profiler. Limits: 64K instructions per code block, 32K blocks per function, 1 million instructions per script.

**Finding the cost** ([Roblox, Identify performance issues](https://create.roblox.com/docs/performance-optimization/identify))
- MicroProfiler (per-frame task breakdown, best for spikes), Developer Console F9 (script performance, memory, network), Scene Analysis. Frame budget at 60 FPS is about 16.67 ms; the server heartbeat is capped at 60 steps per second. Test on weaker hardware and record before and after numbers.

**Spreading work** ([Roblox, Performance design](https://create.roblox.com/docs/performance-optimization/design); see [[Mobile performance limits]])
- Spread heavy work across frames (for example about 5 ms per frame over 20 frames instead of one 100 ms block).

**Object pools (community only)**
- DevForum posts propose pooling for bullets and note that creating, cloning and destroying instances can cause lag spikes ([DevForum thread 2449835](https://devforum.roblox.com/t/2449835), [Pooler](https://devforum.roblox.com/t/pooler-lets-go-for-a-swim/1677672)); both are snippets only, no benchmark. A GameMaker write-up found pooling was not always faster for simple objects ([gamedev.net blog](https://gamedev.net/blogs/entry/2268913-optimization-time-part-one-pooling)). So the benefit depends on how heavy create and destroy are, and should be measured.

## Not found
- No Roblox doc on object pooling or on batching many entities into one Heartbeat loop, and no benchmark of pooled vs unpooled instances.

## Recommendations for us (not sourced rules)
1. Run one server step loop for all enemies and projectiles (the MatchSim design already steps in fixed 0.1 s ticks) and keep per-enemy scripts at zero.
2. Pool the things made most often (damage numbers, projectiles, hit sparks) and measure with the MicroProfiler before and after; skip pooling where the gain is not visible.
3. Keep tables uniform (enemy records with the same keys), pre-size arrays, avoid creating closures inside the step.
4. Consider `@native` only on the pure step and distance functions after a profile shows them hot (T200 strict typing task helps the compiler).
5. Spread spawn cost over frames at wave starts and stage loads.

## Sources
| # | Source | Date | Note |
|---|---|---|---|
| 1 | https://luau.org/performance | fetched 2026-10-28 | read |
| 2 | https://create.roblox.com/docs/luau/native-code-gen | fetched 2026-10-28 | read |
| 3 | https://create.roblox.com/docs/performance-optimization/identify | fetched 2026-10-28 | read |
| 4 | https://create.roblox.com/docs/performance-optimization/design | fetched 2026-10-28 | read |
| 5 | https://devforum.roblox.com/t/2449835 | undated | snippet |
