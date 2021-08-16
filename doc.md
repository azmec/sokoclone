# Doc
Scribbles of game and system development.

## To-do
- [ ] Conceptualizing the Grid
- [ ] Drawing the Grid and Player
- [ ] Grid-based movement.
- [ ] Grid-based collisions.
- [ ] Grid-based collisions.

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