# settlrs
Godot multiplayer hex strategy game for mobile.

**Including;**
- [x] Touch Top-down Camera Controller
- [x] Simplex-noise map generation and resource distribution
- [x] Technology, units, cities, roads and resources.
- [x] Dijkstra’s Algorithm based One-Turn pathfinding.
- [x] Tech Tree
- [x] Fog of War - 3d default (needs to be optimised) or simple 2d
- [ ] Civilizations
- [ ] Firebase implementation - Accounts and multiplayer games
- [ ] Audio player

**TODO**
* Optimise Fog of War
* Distribute responsibility of GameController
* Intergrate Serialization of maps and game state
* Intergrate with Firebase for accounts and multiplayer games
* Implement different Civilizations
* Clean and generalise code base
* Add Menu System
* Rework UI
* Add Basic Localisation
* Add Audio System


**Fog of war**
**3D** - This is the default fog of war, it uses a rasied hex and instanciates edges along the edges of the fog. It is un-optimised currently and will use more processing and a ltitle more graphical power than the simple 2d fog of war.
**2D** - This simple version of the fog of war can be enabled by commenting out or removing all code marked "#Disable if using 2d Simple fog" on Hexmap.gd, City.gd, Unit.gd and of course FogOfWar.gd
Set the fog of war mesh to a y transform of only 0.05 or so and enable no depth test on the material flags.
This will run a little lighter and however you may have to tweak it a bit as it will currently draw over objects like units and cities in a undesired way. 

The Hex implementation is based on RedBlobGame's tutorial https://www.redblobgames.com/grids/hexagons/
The pathfinding implementation is based on RedBlobGame's tutorial https://www.redblobgames.com/pathfinding/a-star/introduction.html

Feel free to use any parts of this project as a base for creating strategy games in Godot.
