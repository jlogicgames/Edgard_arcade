# Feature parity plan: Godot port vs. Java/libGDX reference

Reference implementation: `../edgard_in_kimeria_libgdx` (Java/libGDX, which is itself a
parity port of the Flame original plus the Rust/Bevy version's menus, localization,
gamepad support and dev hotkeys). Its README lists its full feature set; everything below
compares that against this Godot project as of 2026-09-23.

Legend: **[BUG]** existing Godot behaviour is broken · **[MISSING]** feature absent ·
**[DIFF]** present, but behaves differently from the reference. Rows marked
**Decided** were settled in section 3.

---

## 1. Gap list

### 1.1 Level data / import pipeline

| # | Kind | Gap |
|---|---|---|
| L1 | BUG | The TMX importers (`scripts/tools/import_tmx.gd`, `run_import.gd`) drop each spawn object's `name`, `width` and `height`. The reference uses `name` as the Collectable kind (`Coin`/`Heart`), the Trigger/Actionable target id, and `width`/`height` as Trigger, Wall, Checkpoint and Torch bounds. As a result, **every Heart in `forest.tscn` spawns as a Coin** (`level.gd` reads a `collectable_type` meta that nothing writes). |
| L2 | BUG | `forest1.tscn` contains hand-added metadata (`target_id`, `wall_width`, `wall_height`). Re-running the importer silently deletes it. |
| L3 | DIFF | Both importers hard-code `TMX_DIR` to an absolute path in the Flutter project. |
| L4 | BUG | `level.gd` sets `get_tree().debug_collisions_hint = true` unconditionally, so collision shapes always render. In the reference they're behind the F1 toggle. |
| L5 | DIFF | Spawn markers keep only the object's top-left corner. Entity scenes are authored with top-left origins, but the Actionable Wall's shape is centred on its origin, so it's offset by half its size. |

### 1.2 Player

| # | Kind | Gap (reference → Godot) |
|---|---|---|
| P1 | BUG | **Lives reset on every level.** The reference keeps one `Player` across levels. Godot creates a new player per scene with `lives = 3`. Lives need to live in `GameManager`. |
| P2 | DIFF | Death count: the reference has `NUMBER_OF_TRIES = 3` and decrements after respawn, so the game ends on the **4th** death. Godot ends it on the 3rd. **Decided: keep 3** (see section 3). |
| P3 | DIFF | Jump: the reference jumps while J is **held**, so holding it auto-hops. Godot uses `just_pressed`. |
| P4 | DIFF | Coyote time: the reference stays grounded until `velocity.y > 147` (9.8·15). Godot uses a fixed 0.15 s timer. Close enough; keep Godot's version and note it as a deviation. |
| P5 | DIFF | Quicksand: the reference always applies ×0.1 horizontal speed and a ×0.1 jump, and treats the sand as ground (vy = 0). Godot applies ×0.1 only while airborne, gives a full jump, caps terminal velocity at 30, and **kills the player on leaving quicksand while falling** (not in the reference). |
| P6 | DIFF | Wall clamber: in the reference, only `Wall`-type collision blocks and Actionable Walls are climbable. Contact while airborne sets `clambering` with no input needed, and vy is multiplied by 0.1 each frame. A wall jump gives vy = −182, vx = ±130 away from the wall, and a 0.1 s input lock. In Godot, any wall is climbable, input toward the wall is required, and wall-jump vx is 300. |
| P7 | DIFF | Attack: the reference allows attacking only when on the ground, not jumping and not clambering. It freezes horizontal movement for the whole animation (7 frames at 0.1 s), uses a hitbox of 37 × 36 in front of the player, and re-reads input afterwards. Godot allows attacking in the air and keeps moving. |
| P8 | DIFF | Fall-off-map kill: reference `y > 380`, Godot `350`. |
| P9 | DIFF | Respawn: the reference resets facing to right and snaps the camera back toward the spawn point. |
| P10 | DIFF | Camera: the reference uses a look-ahead that moves at 1400 px/s. The player sits about 213 px from the left when facing right and about 433 px when facing left, with y offset −200. Godot uses Camera2D smoothing with a drag margin. Keep Godot's level limits, which improve on the reference, but add the directional look-ahead. |

### 1.3 Enemies

| # | Kind | Gap |
|---|---|---|
| E1 | BUG | **`Engine.time_scale` can get stuck at 0.5.** It's set on DetectionZone enter and reset only on exit or when the bat dies. Changing level, dying, pausing or overlapping two bats while inside a zone leaves the whole game, UI included, in slow motion. The reference recomputes "near any bat (< 50 px from the hitbox)" every frame and slows only the level simulation. |
| E2 | MISSING | Bat stomp: in Java, landing on a bat while falling kills it (bounce sound, no bounce). The Flutter original makes any contact lethal. Godot hurts the player on any contact. **Decided: follow Java.** |
| E3 | DIFF | Yellow/Red mob idle: the reference mobs **stand idle** unless the player's X is inside `[x − offNeg·16, x + offPos·16]` and overlaps vertically. Then they charge at 80 px/s, and the lerped direction only drives facing. Godot mobs patrol constantly and move at `lerp(dir) × speed`, so their speed varies. |
| E4 | DIFF | Red mob attack: the reference uses a ±65 px attack box and a 0.8 s animation (4 frames at 0.2 s), and deals damage **on every frame** of the attack while the player is in the box. Godot uses 36 px and a single check at 0.4 s. |
| E5 | DIFF | After an attack, the reference Red mob does `position.x += 300`; the Flutter comment reads "back to initial position after attack". **Decided: return it to its spawn X** instead. |
| E6 | DIFF | In the reference, touching a Red mob's body neither hurts the player nor gets stomped, because the player's overlap check only covers Bat and YellowMob. **Decided: body contact hurts and stomping kills,** as Godot does now; keep that behaviour when moving it to an Area2D hurtbox (E7). |
| E7 | DIFF | Stomp and contact detection in Godot rely on the mob's own `move_and_slide` collisions, so an idle mob that isn't moving never registers them. Replace this with an Area2D hurtbox so it works both ways. |

### 1.4 Level objects

| # | Kind | Gap |
|---|---|---|
| O1 | BUG | `actionable_wall.gd` calls `set_deferred("disabled", …)` on the **StaticBody2D**, which has no such property. The wall hides but **stays solid**. The reference also removes the wall permanently, where Godot toggles it. |
| O2 | MISSING | Falling platform warning: when triggered, the reference spawns a small torch (intensity 5) on the platform. The torch goes out when the fall starts and is removed with the platform. |
| O3 | MISSING | Coin pickup has a gold ripple ring (0.75 s, r = 300); Heart pickup has a shockwave ring (0.6 s, r = 64). |
| O4 | DIFF | In the reference, a Heart grants **no** life, only the shockwave. Godot gives +1 life, capped at 3. **Decided: keep +1 life** and add the shockwave. |
| O5 | DIFF | Bomb: the reference uses a shader explosion (64 px, 0.7 s) where Godot uses CPU particles. Replace with a port of `bomb_explosion.frag`. |
| O6 | DIFF | Checkpoint: invisible in the reference, but Godot draws a 50% yellow debug rectangle. Show it only in F1 debug mode. |
| O7 | DIFF | Escalator: the reference can be toggled by a trigger (Actionable) and mirrors its sprite at each end of a horizontal run. Its sprite is drawn at a native height of 8 px, centred in a 16 px footprint. |
| O8 | DIFF | Actionable Torch with `Intensity` 0 or absent starts **unlit** in the reference; Godot defaults it to 80. Its toggle switches intensity between 0 and 200. |
| O9 | DIFF | Torch visuals: the reference has four particle kinds (core flame, green embers, green sparkles, grey smoke) plus a flickering additive glow. Godot has flame and embers plus a PointLight2D. Visual tuning only. |

### 1.5 Ambience and effects

| # | Kind | Gap |
|---|---|---|
| A1 | MISSING | Rain in `forest-1`: 48 black 1.2 × 14 px streaks at 400–480 px/s with one shared random wind (±24), respawning above the camera. |
| A2 | MISSING | `forest` has 24 black fireflies that fly quadratic-bezier paths and fade in and out, plus a full-screen **fog shader** (`fog.frag`). |
| A3 | MISSING | The shaders `fog.frag`, `shockwave.frag` and `bomb_explosion.frag` need porting to Godot `canvas_item` shaders. The Java versions are already plain GLSL, so this is mostly renaming uniforms to `UV` and `TIME`. |

### 1.6 UI, menus and meta flow

| # | Kind | Gap |
|---|---|---|
| U1 | MISSING | Main menu has **Play / About / Options / Exit**, a title, a controls help block and a navigation hint along the bottom. Godot has only Start. |
| U2 | MISSING | About screen (body text and Back button). |
| U3 | MISSING | Options screen with a language toggle (English ⇄ Українська). |
| U4 | MISSING | **Localization** for all 15 UI strings in `Msg.java`, EN and UK. This needs a font with Cyrillic glyphs. Check whether PixelOperator8 has them; if not, copy `QuestSquare.ttf` from the Java assets. |
| U5 | MISSING | Menu backdrop: fog plus 18 gold (`#ffcc33`) fireflies behind the Main, About and Options screens. |
| U6 | MISSING | Menu music `main_menu.mp3`, looped, fading in over 2 s and out over 1 s. It plays only on menu screens. |
| U7 | MISSING | Button sounds: `button_click.wav` on activate, and the same sound at 35% volume on hover or focus change. |
| U8 | MISSING | Keyboard and gamepad menu navigation: Up/Down and Tab/Shift+Tab move, Enter/Space/A confirm, Esc/B go back. In Godot this means `grab_focus()` on show, Back handling, and focus-change sounds. |
| U9 | DIFF | Pause menu: labels should be "Pause Menu", "Resume" and "Exit to Menu". Exit to Menu must also reset `GameManager` (coins, level, lives) and time scale, which the current Quit skips. |
| U10 | DIFF | Game over: labels should be "Game Over" and "Play Again". |
| U11 | DIFF | HUD: the reference shows a 32 px coin icon at (10, 10) with the count at font size 20, and no lives row. Keep Godot's lives row, since hearts heal (see O4), but match the coin sizing. |
| U12 | MISSING | FPS counter in the top-right corner, drawn on every screen. |
| U13 | MISSING | 1 s delay before each level load, with a fade or black screen in between. |

### 1.7 Input and dev tools

| # | Kind | Gap |
|---|---|---|
| I1 | MISSING | Gamepad input. Left stick or D-pad moves, South (A) jumps, West (X) or East (B) attacks, North (Y) interacts, and Start pauses. Add joypad events to the existing input actions in `project.godot`. |
| I2 | DIFF | Arrow keys: the reference moves with arrows as well as WASD. Godot maps left and right, but W/Up/S/Down have no use in gameplay, so there's nothing to add. |
| I3 | MISSING | Dev hotkeys: **F1** toggles hitbox gizmos, **F2** toggles invulnerability, **F3** spawns a shockwave and ripple at the player, **F4** advances to the next level, and **F5** triggers the checkpoint. |

### 1.8 Tracked tickets from the sibling ports

These tickets are open against the Java and Rust versions. They go beyond the current
reference behaviour, and they're included here so the Godot port picks them up too.

| # | Source | Gap |
|---|---|---|
| T1 | [edgard_in_kimeria_java#3](https://github.com/jlogicgames/edgard_in_kimeria_java/issues/3) | **Chromatic-aberration glitch on pause, game view only.** While paused, the frozen world renders through a chromatic-aberration shader. The pause menu on top stays crisp and unaffected. On Resume the effect stops at once and leaves nothing behind. The glitch can be static or have a slow idle animation, whichever looks better. Frame pacing must not regress; check it with the FPS counter (U12). Shader source: `../edgard_in_kimeria/shaders/chroma_glitch.frag`; the Rust port has the uniforms in `effects/postprocess.rs` (`chroma_intensity`, `chroma_shift`). |
| T2 | [edgard_in_kimeria_rs#22](https://github.com/jlogicgames/edgard_in_kimeria_rs/issues/22) | **Fullscreen by default on desktop and mobile, with a windowed opt-out in the menu.** The web build is excluded. The setting should persist across sessions. |
| T3 | [edgard_in_kimeria_rs#21](https://github.com/jlogicgames/edgard_in_kimeria_rs/issues/21) | **Web-only start screen.** Browsers block audio until the user interacts with the page, so the web export shows a single "Play" button before audio and game init. Desktop and mobile builds skip it. This matters here because U6 plays menu music as soon as the game launches. |

### 1.9 Assets to copy from `../edgard_in_kimeria_libgdx/assets`

- `audio/main_menu.mp3`, `audio/button_click.wav`. The Java README notes it re-encoded this file to plain PCM, which is fine for Godot too.
- `shaders/fog.frag`, `shockwave.frag`, `bomb_explosion.frag`, as sources to port.
- `fonts/QuestSquare.ttf`, only if PixelOperator8 lacks Cyrillic.
- `tiles/forest-1.tmx`, `forest.tmx`, `Forest.tsx`, vendored into `assets/tiles/` so the importer no longer depends on a sibling repo (L3).
- `../edgard_in_kimeria/shaders/chroma_glitch.frag`, as the source to port for T1.

Sound mapping: reference `hit` → Godot `hurt.wav`. The reference Bomb plays `bounce`; Godot's `explosion.wav` is better, so keep it and document the deviation.

---

## 2. Implementation plan

Phases are ordered so that each one leaves the game playable and verifiable (run with
F5 and walk both levels). Bugs come first, because later phases build on correct data
and state.

### Phase 1: Fix the data pipeline (L1–L3, L5) — done
1. Vendor the `.tmx` and `.tsx` files into `assets/tiles/`. Point `TMX_DIR` at `res://assets/tiles/`, and delete the duplicated parser by making `run_import.gd` call the same code as `import_tmx.gd` (a shared `tmx_parser.gd`).
2. Write `name`, `width` and `height` into each marker's metadata (`tiled_name`, `tiled_size`).
3. Update `level.gd` to read `Collectable` kind, Trigger and Actionable `target_id`, and Wall, Trigger and Checkpoint sizes from that metadata. Remove the hand-edited fallbacks.
4. Re-generate both levels.
5. Verify: `forest` shows a heart at x = 656. `forest1`'s trigger opens the wall and toggles the torch. Inspecting the markers shows the new metadata.

### Phase 2: Game state and correctness bugs (P1, E1, O1, L4, U9) — done
1. Move `lives` into `GameManager`, together with `coins`, `current_level_index`, `invulnerable`, `debug_draw` and `language`. The player reads and writes lives through GameManager, and `reset()` restores them.
2. Replace the Bat DetectionZone and `Engine.time_scale` with a per-frame "any bat within 50 px" check in `level.gd`. Scale the level's simulation only: set `process_mode` and use a custom `time_scale` factor that player and enemies multiply into `delta`, and keep `Engine.time_scale` at 1.0 (decided, E1), which also leaves UI tweens and music at normal speed.
3. Fix `actionable_wall.gd` to disable the **shape**, and make the removal permanent (`queue_free`).
4. Put the collision debug draw behind the F1 flag.
5. Make pause → Exit to Menu call a full reset.

### Phase 3: Player feel parity (P2–P10) — done
Adjust `player.gd` constants and rules: held jump, quicksand rules, clamber only on the `wall` group, wall-jump vector, attack restrictions and movement freeze, fall-off at y = 380, and respawn facing. Keep 3 deaths (P2). Use a custom camera controller node for the look-ahead.

### Phase 4: Enemy parity (E2–E7) — done
1. Give each enemy an Area2D hurtbox on layer 8, and move all player↔enemy contact logic to it (stomp when `player.velocity.y > 0`, otherwise damage).
2. Make mobs idle until the player is in range, with facing from the lerped direction.
3. Red mob: ±65 px attack box, damage every frame during its 0.8 s attack, then return to its spawn X (E5). Body contact hurts and stomping kills (E6).
4. Add the Bat stomp.

### Phase 5: Objects and effects (O2–O9, A1–A3) — done
1. Port the three shaders to `res://shaders/*.gdshader`. Create reusable scenes: `shockwave_effect.tscn` (with a colour parameter, reused for the ripple), `bomb_explosion.tscn`, and `fog_overlay.tscn` (a CanvasLayer ColorRect).
2. Collectable ripple and shockwave; Bomb explosion; FallingPlatform warning torch; hide the Checkpoint rectangle outside debug mode; escalator Actionable support and sprite mirroring; unlit Torch when intensity is 0.
3. Ambience: `rain.gd`, drawn with `_draw()` from a pooled drop array for forest1; `firefly.gd` with a colour export for forest; fog on forest. Choose ambience per level with a `level.gd` export (`ambience = RAIN | FIREFLIES_FOG`).
4. Torch particle retune (optional polish).

### Phase 6: Menus, localization and audio (U1–U13) — done
1. A `Localization` helper: add the EN and UK strings from `Msg.java` to a Godot translation CSV (`locale/strings.csv`) and use `TranslationServer.set_locale()`. This gives `tr()` in Labels for free. Check or add a Cyrillic font.
2. A single `ui/menu_screen` pattern: a shared Theme with button styling like the reference (grey buttons, white selection border), `grab_focus()` on show, and hover and focus sounds.
3. Screens: MainMenu (Play, About, Options, Exit, controls help, hint), About, Options (language), and updated Pause and Game Over screens.
4. MenuBackdrop scene with fog and gold fireflies.
5. A music autoload or GameManager method with a looped `main_menu.mp3` and volume tweens (2 s in, 1 s out) keyed to menu visibility.
6. HUD sizing, an FPS label, and a 1 s level-load transition with a fade.

### Phase 7: Input and dev tools (I1, I3)
1. Add joypad events to `move_left`, `move_right`, `jump`, `attack` and `interact`; add a `pause` action (Esc and Start), plus Tab and joypad bindings for the `ui_*` actions.
2. Add a `DevTools` autoload for F1–F5, active in debug builds only (`OS.is_debug_build()`).

### Phase 8: Tickets T1–T3
1. **T3, web start screen.** Do this first, because Phase 6 starts menu music at launch. When `OS.has_feature("web")` is true, `game.tscn` shows a single-button CanvasLayer ahead of the MainMenu. The music autoload doesn't start playback until that button is pressed. Other builds skip the screen. Verify with a web export (`godot --export-release "Web"`) in a fresh browser tab: music starts only after the click, and there are no autoplay warnings in the console.
2. **T2, fullscreen default.** Add a `Settings` store in `GameManager` backed by `ConfigFile` at `user://settings.cfg`, which also persists `language` (U3). On startup in non-web builds, apply `DisplayServer.WINDOW_MODE_FULLSCREEN` (or `window_set_mode` from the saved value). Add a "Display: Fullscreen / Windowed" toggle to the Options screen and hide it on web. **Windowed mode is a fixed 640×360 window**, the viewport size defined in `project.godot`. On switching to windowed, call `DisplayServer.window_set_size(Vector2i(640, 360))` and centre the window on the current screen. Window resizing stays enabled, as in the project's current settings, and the saved window size isn't restored: every switch returns to 640×360. The 640×360 `canvas_items` stretch already scales to fullscreen; check that fullscreen stays pixel-crisp on common resolutions such as 1920×1080 (an exact 3×) and 2560×1440 (4×).
3. **T1, pause glitch.** Port `chroma_glitch.frag` to `shaders/chroma_glitch.gdshader`, a `canvas_item` shader that reads `hint_screen_texture`. **Only the game layer is glitched**, meaning the sky background and the world; the HUD and the pause menu stay crisp. Place a full-rect ColorRect with that material on a CanvasLayer at **layer 5**: above the world (default canvas, layer 0) and the sky (−1), and below the HUD (10) and the pause menu (20). Show it only while `get_tree().paused`, and hide it on resume. `hint_screen_texture` at layer 5 captures only the layers beneath it, so the HUD and menu can't be affected and no manual FBO is needed. If a later UI layer is added below 5, it would get glitched too, so keep every UI CanvasLayer at 10 or above. Uniforms: `intensity`, `shift` and an optional slow `TIME` idle, with `process_mode = ALWAYS` so the idle keeps animating while paused. Check the acceptance criteria against the ticket and the FPS counter.

### Phase 9: Docs
Update `CLAUDE.md` (level setup, collision layers, new autoloads, controls) and add a
"Deviations from the reference" section listing: P2 three deaths; O4 heart heals; E5 Red mob
returns to spawn X; E6 Red mob body contact hurts and can be stomped; E2 bat stomp (a Java
addition that isn't in Flutter); P4 coyote timer; bomb explosion sound; camera level limits.

---

## 3. Decisions (all settled 2026-09-23)

| # | Question | Decision |
|---|---|---|
| P2 | Deaths before game over | **3 deaths**, one per heart in the HUD. The reference's 4th death comes from an off-by-one that its missing lives counter hides. This is a deviation. |
| O4 | Does a Heart give a life? | **Yes: +1 life, capped at 3, plus the shockwave effect.** This is a deviation. |
| E5 | Red mob's `position.x += 300` after an attack | **It returns to its spawn X** with a short walk or tween. The Flutter comment says *"back to initial position after attack"*, so this restores the intent without the always-rightward jump. This is a deviation. |
| E6 | Red mob body contact | **Contact hurts, and stomping kills,** the same as the Yellow mob. The Red mob's own stomp code exists in Flutter and Java, but the player never checks for it, which looks like an oversight. This is a deviation. |
| E1 | How slow motion near bats works | **Slow only the level simulation** with a factor that level entities multiply into `delta`. `Engine.time_scale` stays at 1.0, so the UI, music fades and effects run at normal speed. |
| E2 | Bat stomp | **Allowed**, following Java: stomping a bat from above kills it. The Flutter original makes any bat contact lethal. |
| T1 | Pause glitch scope | **Game layer only** (sky and world); the HUD and pause menu stay crisp. |
| T2 | Windowed size | **Fixed 640×360**, the project's defined viewport size. |
