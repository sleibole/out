# Once Upon a Toilet — Living Plan

Updated September 29, 2026. This consolidates the OUT project discussions. **Decided** marks choices the creator expressed or accepted; **Explore** marks ideas discussed but not settled. The most recent art request is included.

## The game

**Once Upon a Toilet (OUT)** is a funny, low-stress 2D platformer in Godot for children. A child is sucked through a toilet into the sewer and travels through increasingly impossible worlds to get home. The experience should invite curiosity, laughter, and small discoveries. It is slower and more forgiving than a precision platformer.

**Tone — decided:** Go all in on silly, absurd, slightly gross, and non-scary. A proposed grief/dead-father story was rejected after it upset the creator's son. The worlds can escalate like a dream, but the emotional contract remains playful.

**Audience and test:** The creator's son is the primary early tester; friends and other children of similar age can test later. Watch what makes them laugh, where they get confused, which mechanics they ignore, whether they seek optional routes, and whether they ask to play again. Avoid explaining the intended answer during a test.

## Art direction

**Decided:** A South Park–inspired look with **cel shading**, mixed with a whimsical storybook feel. Use simple geometric, expressive characters with strong readable silhouettes and full side-profile poses. Favor clean shapes, bold contour decisions, and a small number of clear shadow tones over realistic lighting. Soft warm pastels and restrained paper or watercolor texture can give the environments a fairy-tale quality. Let backgrounds be richer than characters, while keeping platforms, enemies, projectiles, and hazards easy to read at play speed. This is non-pixel art.

**2D presentation:** Side-scrolling Godot scene with parallax foreground, middle ground, and background. Repeating pipes, ground, and platforms use tiles. Inkscape is useful for editable vector shapes; Krita and the Huion tablet can add texture and paint. Mirror characters in Godot where appropriate; draw separate directional art when asymmetry demands it.

**Slice 0 art setup — previously selected:** 64 × 64 in-game tiles; 1920 × 1080 fixed 16:9 target with letterboxing to preserve the aspect ratio. Draw tile source art at 2× (128 × 128); a 512 × 512 sheet holds a 4 × 4 grid at that source size. Use an 8-bit sRGB document with alpha. Test seamless edges. Earlier chats contain conflicting texture-filter and pixel-snap advice, so choose those settings by looking at actual scaled builds rather than treating either recommendation as settled. Cel shading is the current direction and should guide that test.

### Art production with Cursor and Godot

**Current approach — decided September 29:** Vibe code the game with Cursor while keeping Godot as the engine. Try making the recurring art from editable 2D primitives and polygons. A character can be assembled from separate head, body, eyes, mouth, and limb shapes, with one deliberate darker shadow shape on each major part. This produces crisp, controllable cel shading without requiring realistic lighting or a complex shader. Simple flat colors and clean silhouettes come first; outlines and restrained texture can be added after the shapes read well in motion.

Use `Polygon2D` or a scene of shape nodes for pieces that need editing and animation. Godot's custom `_draw()` commands can generate repeated or procedural details. SVG is another editable source format for vector-shaped assets that Godot can import as textures. A shared 2D shader may be useful later for a repeated effect, but manually placed shadow shapes give better art direction for expressive faces and fixed side-profile characters. Keep collision and gameplay behavior separate from decorative drawing.

**Generated art:** AI-generated images can provide character concepts, color and lighting references, background paintings, textures, and sprite references. For recurring playable characters and tiles, translate a selected concept into editable shapes or SVGs so proportions, poses, colors, and shading remain consistent across animations and revisions. Generated images can be used directly where consistency across many frames matters less, such as a backdrop. Review legibility at the actual gameplay scale.

**First art test:** Build one moving screen containing the child, a rat, a pipe, a platform, and a background. Use a restricted palette and one shadow tone per main form. Check the silhouettes, animation, projectile readability, and separation of foreground from background while playing, then add subtle storybook texture if it improves the result. Use this test to decide which assets stay as Godot shapes, which become SVG or painted textures, and whether any shader is needed.

## Player loop and movement

1. Move through an inviting main path and notice an unusual route or object.
2. Take an optional detour with a modestly harder movement or enemy challenge.
3. Find a golden plunger, return to the main route, and reach the next strange area.

**Decided:** Golden plungers reward exploration and 100% completion. They are optional pride collectibles, not required to progress and not currency. The first slice should test whether children notice and pursue one.

**Movement:** Start with move and jump, coyote time, jump buffering, and a smooth follow camera. A possible double jump that fires a poop shot downward for lift has been discussed, but its feel and place in progression need a prototype.

## Combat and interactions

**Decided:** The poop projectile is the permanent, always-available core attack. Food powers alter it rather than replacing it. It has unlimited use; avoid a food-ammo requirement. Grounded firing, a slight wind-up or cooldown, and a lobbed arc can make timing and positioning matter. Air time can emphasize movement. Tune this with children before locking timings or damage; one proposed relationship was a head jump defeating an enemy faster than two poop hits.

**Food power ideas — explore:** Watermelon seeds/spread, jalapeño fire, corn bounce, and milk splash. Establish their actual effects and duration in playtests. Throwing loose objects is an optional experiment that supplements the poop attack only if it adds fun without complicating controls.

**Enemies — candidates:** A patrolling rat, an arc-swooping bat, and an alligator that pops from a water-filled break in the ground. Physics reactions are an exciting later direction: a shot sends an enemy bouncing or rolling through stairs, slopes, angled ceilings, corridors, pipes, and ledges, potentially turning it into a moving hazard. Test one controlled encounter before making every enemy physics driven; chaotic reactions must remain legible and fair to young players.

## Story and progression

**Decided:** The Toilet King (TK) is a recurring, ridiculous villain. He steals an important item the child needs to get home. Defeating him at the end returns it. His `TK` mark can appear on doors, jewelry, pipes, or signs as a recurring joke and clue.

**Leading item idea — not fully locked:** The Golden Plunger is a strong candidate for the stolen item, linking the plot to the optional plunger collectibles. Work out why the hero needs that particular plunger to get home and how it differs visually from ordinary collectibles.

**World sketch — explore:** Sewer → expanded sewer → strange food/material zone → floating nonsense → full dream absurdity. Boss candidates have included a Rat King or Trash Monster, a food creature, and a final battle in which TK controls or becomes an enormous toilet or throne. TK could appear early for the theft, interrupt the journey with taunts and flush hazards, and return for a late chase or showdown. The exact world order, bosses, and set pieces remain open.

## Build sequence

### Slice 0 — The First Escape

Make a cohesive, playable 1–2 screen section of the first level, roughly 1–2 minutes long:

- A clear start and exit; one easy main path and one visible optional side path.
- Movement, jump, coyote time, jump buffering, and smoothed follow camera.
- TileMapLayer ground and platforms, a simple storybook background, a player, and one enemy or hazard.
- One slightly harder optional challenge containing one golden plunger.
- Minimal sound and impact feedback to make the short experience understandable and pleasant.

Keep extra levels, inventory, food powers, sophisticated combat, large tilesets, and advanced animation outside this first slice. Earlier plans described Slice 0 before combat was settled; the first combat prototype can follow immediately or be added only if the slice remains small.

### Core mechanics prototype

Add the permanent poop attack; compare a grounded lob, wind-up/cooldown, jump-on-head, and one enemy reaction. Prototype one food modifier and, separately, the downward-shot double jump or object throwing only if the basic loop warrants them.

### First full vertical slice

Build a short sewer level with a readable entrance, exploration detour, golden plunger, enemy encounters, a food power or other signature surprise, and a funny ending beat. Test it with the son and peers before expanding the world list. Record observed behavior and revise controls, difficulty, and visual clarity.

### Expansion and release

Add worlds and recurring TK moments only after the core loop works for children. An itch.io release was discussed as a possible first public test. Android and Steam are possible later platforms; iOS remains undecided. Platform, pricing, scope, and launch date are open decisions. Earlier revenue guesses were speculative and are not product targets.

## Current open decisions

| Question | Smallest useful test |
| --- | --- |
| Is the stolen homeward item the special Golden Plunger? | One short intro and ending storyboard; ask children what they think must be recovered. |
| Does the basic lob feel fair with grounded firing? | One rat encounter with adjustable wind-up, cooldown, arc, and jump damage. |
| Does the downward poop shot improve movement? | One gap built for optional lift; watch whether children discover and understand it. |
| Which food modifier is fun and distinct first? | Prototype a single modifier in one encounter. |
| Are physics enemies delightful or confusing? | One contained room with a bouncing rat and readable hazards. |
| Do cel shading and storybook texture coexist cleanly at target scale? | One character, tile set, and parallax scene viewed at 1080p, 1440p, and 4K. |
| Do golden plungers motivate exploration? | Observe children playing Slice 0 without hints. |

## Decision record

- Godot 2D, non-pixel-art platformer; direct OUT vertical slice instead of a separate practice game.
- Silly, child-first dream escalation; grief narrative removed.
- South Park–inspired shapes and storybook atmosphere; cel shading added September 29, 2026.
- Permanent unlimited poop projectile, with food variants; object throwing remains experimental.
- Relaxed exploration, optional golden plungers, and a recurring Toilet King.
- Small first slice and observation-led playtesting before adding worlds.
