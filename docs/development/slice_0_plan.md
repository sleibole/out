# Slice 0 — The First Escape

Created September 30, 2026. This plan expands the Slice 0 section of `gdd.md` into buildable work. **Decided** items come from the GDD; **Proposed** items are recommendations for this slice that can change after the first build or playtest. `concept_1.png` is the visual target.

## Goal

Build one short, playable part of the first sewer level, 1–2 screens long and taking 1–2 minutes, that a child can finish without help. It should answer three questions:

1. Do moving and jumping feel good and forgiving to a young player?
2. Does the cel-shaded, shape-built art read clearly while playing at 1080p and above?
3. Does a child notice the optional golden plunger and try to get it without being told?

Slice 0 is complete when the son can play from start to exit without adult help, and we have written notes on what he did.

## Scope

**In scope**

- Godot project setup: resolution, stretch, input map, folder layout.
- Player: run, jump, variable jump height, coyote time, jump buffering, facing direction, simple animation.
- Smoothed follow camera with level limits.
- One level of about two screens: tile ground, stone platforms, pipes, sewage water.
- One patrolling rat that acts as a hazard.
- A water fall that respawns the player gently, with no lives or game over.
- One optional route with a slightly harder climb that ends at one golden plunger.
- A clear start, a clear exit, and a short "you did it" ending.
- Parallax layers: sky/back pipes, middle ground, and foreground silhouettes.
- Minimal sound: jump, land, splash, rat bump, plunger pickup, exit.

**Out of scope** (these follow in the core mechanics prototype)

- The poop projectile and any combat. The rat is only something to avoid in this slice.
- Food powers, double jump, object throwing, physics-driven enemies.
- Health, lives, inventory, menus beyond a title and restart, and saving.
- Story scenes involving the Toilet King. A single `TK` mark on a sign or pipe is allowed as a joke.
- Ladders and climbing. The plunger route uses jumps only, so no new mechanic is needed.

**Stretch, only if the slice stays small:** stomping on the rat's head so it pops away comically. This previews the jump-on-head idea from the GDD without committing to combat tuning.

## Character pose

### Options

**Full side profile.** The body, head and face point in the direction of travel, and only one eye is visible.

- Pros: the direction you're facing and moving is unmistakable; the silhouette is narrow and matches the collision box; mirroring with `scale.x = -1` is exact; a walk cycle only needs legs that swing past each other; there are the fewest shape parts to rig.
- Cons: with one eye and half a mouth, expressions are weaker; the character looks flatter and less charming than the concept; faces are what children connect with, and profile hides the face.

**Three-quarter view (as in the concept).** The body and face turn partly toward the camera, and both eyes are visible.

- Pros: expressive and appealing; matches the concept art children would see in marketing; reactions like surprise or giggling read clearly.
- Cons: near and far limbs must be drawn differently, which doubles the limb work; mirroring shows the "other side" of any asymmetric detail such as a hair part or hood seam; the silhouette is wider than the collision box, so hits can look unfair; aim and facing direction are less obvious, which matters once the poop throw exists; it's harder to keep consistent across animation frames.

**Front-facing, South Park style.** The body faces the camera and slides sideways, as South Park characters do.

- Pros: very cheap to animate; strongly on-brand for the South Park influence; funny.
- Cons: in a platformer you can't tell which way the character faces, and aiming the throw becomes unclear. It works for cutscenes, not gameplay.

### Recommendation — Proposed

Use a **hybrid: side-profile body, head turned about a quarter toward the camera.** Legs, torso and arms are in true profile, so movement, facing and the future throw read clearly, and mirroring stays clean. The head turns just enough to show both eyes (the far eye slightly smaller and closer to the nose side) and a full mouth, which keeps the expressions and charm of the concept. Many cartoon platformers use this "cheat."

In shape-rig terms, the body is a profile rig, and the head is one separate `Node2D` whose eyes, brows and mouth can change expression on their own. Keep asymmetric details (pigtails, hood) simple enough that mirroring them looks fine. Draw a separate direction only if something looks wrong in testing.

Use the same approach for the rat: profile body and tail, head slightly turned so both eyes show the startled expression.

Test this in milestone 2: build the player rig in the hybrid pose, and also place a static full-profile version beside it. Compare them at gameplay scale before animating.

## Technical setup

### Project — Proposed

| Setting | Value |
| --- | --- |
| Engine | Godot 4.7.2 stable (installed at `/Applications/Godot.app`) |
| Language | GDScript |
| Viewport size | 1920 × 1080 |
| Stretch mode | `canvas_items` |
| Stretch aspect | `keep` (letterbox to 16:9) |
| Renderer | Compatibility (keeps an itch.io web build possible) |
| Texture filter | Decide by testing scaled builds (GDD open item); start with Linear and compare against Nearest at 1440p and 4K |
| Physics | Default 2D physics, `CharacterBody2D` for player and rat |

### Input map — Proposed

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| `move_left` | A, Left | D-pad left, left stick |
| `move_right` | D, Right | D-pad right, left stick |
| `jump` | Space, W, Up | South button (A / Cross) |
| `restart` | R | Select / Back |

Gamepad support matters because young children often find a controller easier than a keyboard.

### Folder layout — Proposed

```text
project.godot
scenes/
  main.tscn
  levels/level_0.tscn
  player/player.tscn
  enemies/rat.tscn
  objects/golden_plunger.tscn, exit.tscn, water_hazard.tscn, checkpoint.tscn
  ui/end_screen.tscn
scripts/            (only if a script isn't kept beside its scene)
art/
  tiles/            tile sheets (SVG or painted PNG)
  backgrounds/
  palette.tres      shared colors
audio/sfx/
docs/development/
```

### Collision layers — Proposed

1. World (ground, platforms, pipes)
2. Player
3. Enemy
4. Pickup
5. Hazard (water)

Keep collision shapes as simple rectangles and capsules on their own nodes, separate from decorative polygons, as the GDD requires.

## Player controller

Starting values, all exported on the player so they can be tuned in the Inspector. The first build draws the player about 188 px tall (roughly 3 tiles, `rig_scale` 1.25).

| Parameter | Start value | Notes |
| --- | --- | --- |
| Run speed | 420 px/s | About 6.5 tiles per second |
| Ground acceleration | 2400 px/s² | Quick but not instant start |
| Ground deceleration | 3000 px/s² | Stops quickly, little sliding |
| Air control | 80% of ground acceleration | Forgiving mid-air correction |
| Jump height (full) | 3.5 tiles (224 px) | Velocity and gravity are derived from height and time to apex |
| Time to apex | 0.38 s | Floaty enough for kids |
| Fall gravity multiplier | 1.6× | Snappier fall, less floaty landing |
| Variable jump | Cut upward velocity by 50% on release | Short hop on tap |
| Max fall speed | 1100 px/s | |
| Coyote time | 0.12 s | Slightly generous |
| Jump buffer | 0.15 s | Slightly generous |

States for animation: idle, run, jump rise, fall, land (brief squash). Handle movement with simple code logic inside `_physics_process`; a full state machine isn't needed yet.

**Forgiveness rules — Proposed:** jumps that barely miss a ledge corner nudge the player up and onto it (corner correction of about 8 px); water respawns the player at the last checkpoint after a splash and a short pause; touching the rat bumps the player back with 1 second of flashing invulnerability and no other penalty.

## Camera

- `Camera2D` as a child of the player, or following it via script, with position smoothing on (speed about 6).
- Horizontal look-ahead of about 120 px in the facing direction, eased so turning doesn't jerk the view.
- Minimal vertical movement: follow upward only after the player lands on a higher platform, so jumping doesn't bounce the camera.
- Camera limits clamp to the level bounds so the view never shows outside the level.
- A subtle zoom-out or upward shift where the optional route starts, if testing shows children don't see the plunger.

## Level design

The level is about 60 tiles wide (two 1920 px screens) and 17 tiles tall. Beats from left to right:

1. **Arrival (tiles 0–10).** The child drops out of a pipe onto a wide, safe ledge, a funny "plop" landing beat. Flat ground teaches running with no danger. A sewage waterfall on the left edge frames the start, as in the concept.
2. **First gaps (tiles 10–22).** Two small gaps over sewage water, each clearly jumpable. Falling in splashes and respawns at a checkpoint at the start of this section. This teaches that water is "oops," not scary.
3. **Rat platform (tiles 22–34).** A wider stone platform where the rat patrols back and forth. The player can time a jump over it; a pipe above gives a second way to pass.
4. **Optional route branch (tiles 30–40).** Visible from the rat platform: a line of pipe tops rising up and to the right toward the golden plunger, which sits high on a pipe and glints. Each jump is a little narrower or higher than on the main path, but none needs precision. Missing a jump drops the player back on the main path, not into water. The plunger stays in view the whole time.
5. **Final stretch (tiles 40–55).** One more gap and a step up. The main path stays easy.
6. **Exit (tiles 55–60).** A large, clearly marked exit: a round sewer tunnel with light coming through, or a door with a hand-painted "THIS WAY UP?" sign. Reaching it shows a short end card with a count of plungers collected (0/1 or 1/1) and a "play again" prompt.

Put a `TK` mark on one pipe or sign as a background joke.

**Readability rules** (from the concept review):

- Walkable surfaces have a lighter top edge and a color that no decorative background pipe uses.
- Background pipes are lighter and lower contrast; foreground silhouettes stay out of the band where the player moves and never cover platform edges.
- Hazards (water) always have a visible surface line and moving highlights.
- The plunger has an idle bob and glint so it reads as a collectible even when small.

## Art plan

### Palette — Proposed

Approximate values sampled by eye from `concept_1.png`; sample exact values from the image and save them in `art/palette.tres` before building.

| Use | Base | Shadow |
| --- | --- | --- |
| Outline | `#1E1A22` | — |
| Sewage water | `#5FD4A8` | `#3FA886` |
| Background teal | `#7BB3AE` | `#5E9591` |
| Warm light / sky | `#F2D57A` | — |
| Pipe grey (gameplay) | `#5A5560` | `#3F3B45` |
| Stone platform | `#7A7480` | `#56515C` |
| Hoodie green | `#557F48` | `#3E6135` |
| Skin | `#F6CFB0` | `#E0AE8C` |
| Hair | `#8A4B2A` | `#6A361C` |
| Boots | `#F2C230` | `#C99A1C` |
| Rat body | `#6E6878` | `#524D5B` |
| Rat pink | `#E89AA8` | `#C87888` |
| Golden plunger | `#F2A81C` | `#C47F0E` |

Rule: one base and one shadow tone per main form, as the GDD specifies.

### Asset list

| Asset | Build method — Proposed | Notes |
| --- | --- | --- |
| Child | `Polygon2D` parts in a node rig | Hybrid pose; head as a separate node with swappable eyes and mouth |
| Rat | `Polygon2D` parts, `Line2D` tail | Tail wiggles procedurally |
| Golden plunger | `Polygon2D` or SVG | Glint animation |
| Stone platforms | Tile sheet, SVG source | 64 px tiles; left cap, middle, right cap, underside |
| Gameplay pipes | Tile sheet or `Polygon2D` pieces | Straight, elbow, cap, collar |
| Sewage water | Shader or animated `Polygon2D` with a surface line | Gentle waves; splash particles |
| Waterfalls | Animated shapes with a foam base | Decorative, frames each end of the level |
| Background | One painted or generated image, plus a separate back-pipe layer | Generated art is acceptable here, per the GDD |
| Foreground silhouettes | `Polygon2D` shapes | Cattails and pipe shapes, dark, low on the screen |
| Exit | `Polygon2D` + light gradient | Must read as "the way out" |
| End card | Simple UI | Plunger count, play again |

**Tile source size:** the GDD selected 128 × 128 source art displayed at 64 × 64. For SVG tiles, author at 64 px and import with a scale of 2 or higher, so they stay sharp at 1440p and 4K. For painted tiles, paint at 128 px and set the `TileMapLayer` scale to 0.5, or use a 128 px tile set with a scaled layer. Pick one approach in milestone 3 and write it down here.

## Audio

Keep audio minimal and funny: a springy jump, a soft landing thud, a big wet splash, a rat squeak when bumped, a sparkly chime for the plunger, and a toilet-flush flourish at the exit. One quiet, looping ambient sewer track with drips. Free sound libraries or quick recordings are fine for Slice 0.

## Milestones

Each milestone ends with something playable.

1. **Project skeleton.** Godot project, settings, input map, folders, git repo. A grey-box level of rectangles, a rectangle player that runs and jumps with coyote time and buffering, and the camera with limits. *Check: movement feels good with placeholder shapes.*
2. **Player look and size.** The child rig in the hybrid pose next to a full-profile variant; test scale against 64 px tiles; idle, run, jump and fall poses; mirroring. *Check: pose chosen, size locked, jump values rechecked.*
3. **Level art pass.** Tile set, pipes, water, parallax layers and palette. Replace the grey box with the real layout. *Check: screenshots at 1080p, 1440p and 4K; decide the texture filter.*
4. **Rat, water and forgiveness.** Rat patrol, bump and invulnerability, water splash and respawn, checkpoints, corner correction. *Check: an adult can fall in and get bumped without it feeling bad.*
5. **Plunger route and exit.** The optional route, plunger pickup, exit, end card, restart. *Check: complete loop from start to end card.*
6. **Juice and audio.** Squash and stretch, dust puffs, splash particles, sounds, plunger glint. *Check: the whole thing feels pleasant and funny.*
7. **Playtest.** Run the protocol below, write notes, list changes.

## Playtest protocol

- Let the child play with no explanation beyond "use these buttons to move and jump."
- Don't point at the plunger or give hints. Answer questions with "What do you think?"
- Write down, with rough times: first jump, first fall, first rat contact, whether and when they notice the plunger, whether they try the route, how many attempts it takes, when they laugh, and when they look confused or frustrated.
- After the run, ask only: "What was your favorite part?" and "What was weird?" Then watch whether he asks to play again without being prompted.
- Save a short summary in `docs/development/playtests/` with the date and build.

## Implementation status — September 30, 2026

A first playable build covers milestones 1–6 and uses the hybrid pose. Open `project.godot` in Godot 4.7 and press Play, or run `Godot --path .` from the repo root.

- **Generated scenes.** `tools/build_slice0.gd` builds the character, rat and plunger rigs from `Polygon2D` shapes, the tile set from `art/tiles/sewer_tiles.svg`, and `scenes/levels/level_0.tscn`. Run it with `Godot --headless --path . res://tools/build_slice0.tscn`. Rerunning overwrites those scenes, so stop using it for a scene once that scene is edited by hand.
- **Checks.** `tools/bot.tscn` plays the level with scripted input (`--route=main`, `plunger` or `fall`). `tools/capture.tscn` saves screenshots to `.captures/` (`--x=`, `--zoom=`, `--pose=run|jump`).
- **Sounds** in `audio/sfx/` are synthesized placeholders; there is no ambient track yet.
- **Level length.** The level is 60 × 17 tiles. An adult at full speed finishes in about 8 seconds, so it may need more length or detours to reach the 1–2 minute target once real play time with children is known.
- **Not done yet:** the side-by-side full-profile comparison from milestone 2, the 1440p/4K texture-filter check, and the playtest itself.

## Decisions to make during Slice 0

| Question | When |
| --- | --- |
| Hybrid or full-profile pose | Milestone 2 |
| Player height in tiles and final jump values | Milestone 2 |
| SVG or painted tiles; tile import scale | Milestone 3 |
| Texture filter (Linear or Nearest) | Milestone 3 |
| Renderer (Compatibility vs Forward+) | Milestone 1, based on whether a web build is wanted |
| Whether to add rat stomp as a stretch goal | After milestone 5 |
| Whether the hero design stays as in the concept | Before milestone 2, ideally with the son's input |
