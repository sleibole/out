# Once Upon a Toilet

A funny, low-stress 2D platformer in Godot 4.7. A child is sucked through a toilet into the sewer and travels through increasingly impossible worlds to get home.

The current build is **Slice 0**: a short playable stretch of the first sewer level, with movement, a follow camera, one enemy, and an optional golden plunger.

## Start the game for testing

Requires [Godot 4.7](https://godotengine.org/download) on macOS (`/Applications/Godot.app`).

The quickest way is from Terminal:

```sh
cd ~/code/out
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

That opens the game in a 1280×720 window.

To run it from the Godot editor instead, which is better if you want to tweak things:

1. Open Godot.
2. In the Project Manager, click **Import**, choose `project.godot` in this folder, then click **Import & Edit**.
3. Press **⌘B**, or click the Play button at the top right.

The first time you open it in the editor, Godot spends a few seconds importing the art and sounds. After it's imported, the project appears in the Project Manager list so you can open it directly.

## Controls

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Move | ← → or A / D | Left stick or D-pad |
| Jump | Space, W, or ↑ | A |
| Restart | R | Back |

## More

Design notes and the living plan are in [`docs/development/gdd.md`](docs/development/gdd.md).
