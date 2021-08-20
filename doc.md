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
- [x] Tracking and displaying level stats. (08-18-21)
- [ ] Tweened movement.

### The Annoying Stuff
- [ ] Win Screen
- [ ] Main Menu
- [ ] Level Selection
- [x] Reading/writing level data. (08-19-21)
- [ ] Level Editor

### The Bad Stuff
- [ ] Fix player moving diagonally.

## The Level Editor
### Requirements
We don't want to reinvent the wheel here, so let's keep our requirements *simple.*
1. We want the editor to *overlay* current gameplay and edit the map in *realtime.* I could write an essay on *why*, but let's just say it makes iteration faster.
2. We can change what tiles we lay down by numrow. Keeping it simple.
3. The editor displays what tile we have "selected."

That's surface level shit, but here's some programmatic requirements:

4. The editor should write a 2D array of *minimum* width and height. Rather, if right-most wall's x position is 16, then the width of the *entire level* should also be 16. If the bottom-most wall's y position is 32, the height of the level should be 32.
5. *Undo and redo.* Enough said.
6. Of course, we serialize the data on edit.

Other stuff like *line drawing* or *flood fill* is uneccessary or (seemingly) too hard (check up on that, it might not be.)

### Transitioning from Gameplay to Editor
Here's my highly intuitive and naive plan:
1. Find some way to serialize *current level state.*
2. Load this state into the separate `editor` gamestate.
3. Edit to my heart's content.
4. Serialize that data to whatever level we were on.
5. On exit, reload that level using the new data.

However, with this implementation, the player object is left and serialized at whatever position it was. This is (probably) fine and more of a user-detail than anything.

### Cleanup
This is a dated entry, but whatever.

As it stands, we want the editor to create and save new levels, as well as *dynamically* resize the map on save. This seems simple enough; here's the plan:
1. Allow the user to place tiles outside of the known map, but *not* in (x, 0) or (y, 0) regions.
2. Any placement made outside of these bounds is placed in a new array:
   ```lua
   -- Assuming a level is 8x8. [3] is the tile type.
   local out_of_bounds = { {9, 1, 2}, {9, 2, 3}, ... }
   ```
3. On save, we recalculate the size of the array to incorporate these new selections.

There are some other things we should keep track of, like the highest *y* and *x* to quickly create a suitable 2D array.

We're *always* justifying a level to the left and up, by nature of not allowing (x, 0) or (y, 0) placements.