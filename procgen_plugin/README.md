# ProcGen World — Procedural World Generator for Godot 4

**ProcGen World** is a free plugin for Godot 4 that generates complete 2D platformer worlds directly inside the editor with one click. Powered by Perlin Noise, it creates natural-looking terrain with biomes, decorations and structures — all without leaving Godot.

> Developed by **xStrix** — CC0, free for personal and commercial use.
> Tiles: Kenney.nl (CC0)

---

## Features

### One-Click World Generation
Press **Generate on TileMap** and a complete world appears in your open scene. Every generation is different — change the seed for a new world, or save it to reproduce the same map later.

### Biome System
Choose which biomes are active using the colored buttons:
- Grass — natural green terrain with rolling hills
- Water — lakes and rivers across the surface
- Snow — icy zones on higher ground
- Lava — volcanic zones mixed into the terrain

**Random Mode** — biomes mix automatically with weighted randomness every generation.

**Custom Zones Mode** — you decide exactly how many zones of each biome appear. Set Grass to 10, Water to 2, Lava to 1 and the world reflects those proportions precisely.

### Procedural Structures
Raise the Structures slider and industrial-style buildings appear randomly on the surface — towers, portals, ruins, pipes and warning signs, all using Kenney's Pixel Platformer Industrial tileset.

### Decoration Density
Control how many trees and decorations appear on the surface using a single slider — from bare terrain to densely forested.

### Auto Viewport Fit
The world always generates to fit the exact size of your game's viewport — no more terrain going out of bounds.

### Preset System
Save your favorite parameter combinations with a name and reload them instantly from the Presets tab. Presets persist between sessions.

---

## Installation

1. Download and extract the plugin
2. Copy the `addons/procgen_world` folder into your Godot project root
3. Open Godot: Project > Project Settings > Plugins
4. Find **ProcGen World** and click Enable
5. The ProcGen World tab appears at the bottom of the editor

---

## First Use

1. Create a new 2D scene (Node2D root)
2. Save the scene
3. Open the plugin tab at the bottom
4. Go to **Tilesets** tab and click **Create TileMap + TileSet** — this sets up everything automatically
5. Go to **Generate** tab, set your parameters and press **Generate on TileMap**

---

## Parameters

| Parameter | Description |
|---|---|
| Seed | Controls world shape — same seed = same world every time |
| Sea Level | How high or low the terrain sits in the viewport |
| Roughness | How dramatic the hills and valleys are |
| Decoration Density | How many trees appear on the surface |
| Structures | How many industrial structures appear on the terrain |

---

## Requirements

- Godot 4.2 or later
- No external dependencies — everything is included

---

## License

MIT License — Copyright (c) 2026 xStrix

Free to use, modify and distribute in personal and commercial projects.

---

## Credits

Developed by **xStrix**
Tiles by Kenney.nl (CC0) — kenney.nl
