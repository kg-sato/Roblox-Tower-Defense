# Low-End Device Playbook

Researched 2026-10-24. Goal: the game should run and feel good on phones and tablets, which are most of the audience. Related: [[UI Design Playbook]], [[Animation and Juice Playbook]], [[Screenshot Analysis]], [[Roblox Success Sources]]

## Why it matters

- [Design for Roblox](https://create.roblox.com/docs/production/game-design/design-for-roblox): most players are on mobile, so design UI and UX mobile first, keep load times and friction low, and test performance on lower-end hardware.
- [Performance overview](https://create.roblox.com/docs/performance-optimization): the default target is 60 FPS (about 16.67 ms per frame). Excess client memory can crash clients and keep lower-end devices, especially mobile, from playing at all. Long join times drive players away before they enter. Performant games tend to see higher engagement, retention, and revenue.
- Discovery counts quick leavers as a negative signal ([Discovery](https://create.roblox.com/docs/production/promotion/discovery)), so a slow or crashing first session hurts recommendations directly.

## Process

1. **Pick a baseline low-end phone** and test on it all the time, watching frame rate and memory. ([Design for performance](https://create.roblox.com/docs/performance-optimization/design))
2. **Set budgets.** The official example uses under 1,000 draw calls and 1,000,000 triangles for its baseline device. That is an example, not a rule. Measure on our baseline.
3. **Don't trust the Studio emulator for memory.** Studio runs server and client together, so memory looks much higher than on a real device. Use it to check aspect ratio and controls only.
4. Check client render stats with Shift+F2, and watch LuaHeap, InstanceCount, and memory in the Developer Console.
5. After publishing, keep monitoring ([Performance overview](https://create.roblox.com/docs/performance-optimization) lists identify, improve, monitor as a loop).

## World and graphics

From [Design for performance](https://create.roblox.com/docs/performance-optimization/design) and [Improve performance](https://create.roblox.com/docs/performance-optimization/improve):
- **Reuse meshes and textures.** Upload a mesh once and duplicate it so identical meshes can be instanced. Vary the look by resizing, rotating, and overlapping.
- **Prefer built-in materials.** They use far less memory than custom textures. Spend the texture budget on what matters most.
- **Texture sizes:** most images need at most 512x512, and minor images under 256x256. A 1024x1024 uses 4x the memory of 512x512.
- **Transparency:** keep it at 0 or 1. Layered partial transparency causes overdraw.
- **Enable StreamingEnabled** for most places, especially big ones. It improves join time, memory, and frame rate.
- **Shadows and lights:** turn off `CastShadow` on small or distant parts, and limit light range and count.
- **Particles and decals:** limit them. Changing `ParticleEmitter` properties often hurts performance.
- **Render fidelity:** set `RenderFidelity` to Automatic or Performance. Use box or hull collision instead of Precise.
- **Anchor static parts.** Keep adaptive physics stepping (fixed mode steps at 240 Hz).

## Scripting and networking

From [Improve performance](https://create.roblox.com/docs/performance-optimization/improve):
- Run per-frame code only when it must update every frame. Use less frequent loops or events for everything else. Spread heavy work across frames with `task.wait()`.
- **Disconnect connections** or destroy their owners. Connections are never garbage collected while active. Clean up per-player tables on `PlayerRemoving`.
- **Replicate on change, not every frame.** Throttle input-driven remotes and send only the needed data (the purchased item, not the whole inventory).
- **Keep visuals local.** Create effects and tween on the client, not the server.
- Avoid deep-cloning or serializing big tables.
- Label code with `debug.profilebegin` and `debug.profileend` to find it in the MicroProfiler.

## UI-specific

- **Screen caching:** a ScreenGui's appearance is cached and is recomputed on the next frame after any descendant is added, removed, or has a property change ([ScreenGui](https://create.roblox.com/docs/reference/engine/classes/ScreenGui)). Many constantly changing elements in one ScreenGui means a lot of recomputation. Split rarely-changing UI (frames, nav) from constantly-changing UI (timers, counters) into different ScreenGuis.
- **Anecdotal (DevForum, not official; verify with the MicroProfiler):** plain Frames can be cheaper than ImageLabels, and `CanvasGroup` can be costly on memory, so use it for whole-panel fades but not on dozens of elements. Source: [GUI Optimization tips?](https://devforum.roblox.com/t/gui-optimization-tips/3986563).
- Build lists with a pool or fixed grid instead of hundreds of live frames when inventories get large.
- Don't run per-frame loops for every counter on screen; update only when the value changes.

## Touch and layout

- **Default mobile controls sit in the bottom-left and bottom-right corners.** Don't put important buttons there. Position custom buttons relative to the jump button rather than at fixed coordinates. ([Position and size](https://create.roblox.com/docs/ui/position-and-size))
- **Thumb reach varies by device size.** A button easy to reach on a phone can be hard on a tablet.
- **Safe area:** `ScreenGui.ScreenInsets` defaults to `CoreUISafeInsets`, which keeps UI clear of the Roblox top bar and device cutouts (notches). `None` should only be used for non-interactive backgrounds. Prefer `ScreenInsets` over the older `SafeAreaCompatibility`. ([ScreenGui](https://create.roblox.com/docs/reference/engine/classes/ScreenGui))
- **Rearrange on small screens:** collapse less important buttons into a menu, use panels that resize with their parent. Use `GuiService.ViewportDisplaySize` (Small, Medium, Large) to switch layouts. ([Adaptive design](https://create.roblox.com/docs/production/publishing/adaptive-design), [Cross-platform](https://create.roblox.com/docs/projects/cross-platform))
- **Add a text size constraint** so text isn't tiny on phones or huge on 4K TVs.
- **Input-aware prompts:** use `UserInputService.PreferredInput` and `GetImageForKeyCode()` so tap, key, or button hints match the device.
- Use haptics on mobile where it helps (supported natively; see Cross-platform).
- Touch target size: Roblox gives no number. A third-party guide says 44x44 px minimum. Treat it as a starting point and test with real thumbs.

## Gameplay that suits phones

Observed in [[Screenshot Analysis]] (these are design observations, not Roblox rules):
- **One big primary action.** The pet game puts a huge tap button at bottom-center. Break an Egg has a wide "Auto Swing" toggle.
- **Auto modes.** Auto Swing and "pets kept tapping" mean play continues with little input. This suits low-attention, one-thumb play.
- **Short sessions.** Loops of 30 s to 2 min (see [[Engagement Loop Playbook]]) fit mobile.
- **Fewer simultaneous choices on screen.** Deep Fishing's minimal HUD is the model for a small screen.
- **Offline progress** rewards players who can only play briefly.

## Checklist before publishing

- [ ] Runs at a steady frame rate on the baseline low-end phone, with no crash after 15+ minutes
- [ ] Join time is short, and StreamingEnabled is on
- [ ] No UI sits under the notch, top bar, or default mobile controls
- [ ] Every button is comfortably tappable and text is readable on the smallest phone
- [ ] Menus hide leaderboards and chat while open (see the overlap problems in [[Screenshot Analysis]])
- [ ] No connections or per-player tables leak (watch memory over time)
- [ ] Effects and tweens run on the client, and remotes are throttled
- [ ] Reduced-motion setting works

## Gaps

- Not read: Identify and Monitor performance pages, the MicroProfiler guide, graphics quality settings, and how to profile directly on a phone.
- Not verified: actual memory limits per device. The docs only say mobile is severely limited.
- Not researched: `ContentProvider` preloading and loading-screen techniques.
