# Doc
Scribbles of game and system development.

## To-do
### The Boring Stuff
- [x] Conceptualizing the Grid (08-16-21)
- [x] Drawing the Grid and Player (08-16-21)
- [x] Grid-based movement (08-17-21)
- [x] Grid-based collisions (08-17-21)

### The Good Stuff
- [x] Registering goals. (08-18-21)
- [x] Cloning the player. (08-18-21)
- [ ] Tracking and displaying level stats.
- [ ] Tweened movement.

### The Annoying Stuff
- [ ] Win Screen
- [ ] Main Menu
- [ ] Level Selection
- [ ] Level Editor

## Grid Based Movement
Grids can be thought of likeso:
```lua
local level = {
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 4, 0, 0, 0, 0 },
    { 0, 0, 2, 3, 0, 0, 0, 0 },
    { 0, 0, 2, 2, 2, 3, 1, 0 },
    { 0, 4, 2, 3, 3, 4, 0, 0 },
    { 0, 0, 0, 0, 2, 0, 0, 0 },
    { 0, 0, 0, 0, 4, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
}
```

In which the legend is:
- `0` - Walls
- `1` - Player
- `2` - Floor
- `3` - Boxes
- `4` - Goals

In regards to generation, *anything that is not 0 will have a floor placed "under" it*.