import random
from times import epochTime
from nwo/utils import nmod
type Grid* = object 
    rows*, columns* : int
    data : seq[uint32]

proc newGrid*(rows, columns : int) : Grid =
    Grid(
        rows: rows, 
        columns: columns,
        data: newSeq[uint32]((rows * columns + 8 - 1) div 8)
    )

proc get(grid : Grid, x, y : int) : bool =
    assert x < grid.columns
    assert y < grid.rows
    let index = y * grid.columns + x
    (grid.data[index div 8] and (1u32 shl (index mod 8))) != 0

proc set(grid : var Grid, x, y : int, value : bool) : void =
    assert x < grid.columns
    assert y < grid.rows
    let index = y * grid.columns + x
    grid.data[index div 8] = 
        if value:
            grid.data[index div 8] or (1u32 shl (index mod 8))
        else:
            grid.data[index div 8] and (not (1u32 shl (index mod 8)))
    
template `[]`*(grid : Grid, x,y : int) : bool =
    get(grid, x, y)

template `[]=`*(grid : Grid, x,y : int, value : bool) =
    set(grid, x, y, value)

proc next_step*(old_grid, new_grid : var Grid) =
    for x in 0..<old_grid.columns:
        for y in 0..<old_grid.rows:
            var alive_neighbours = 0 
            if old_grid[nmod(x+1, old_grid.columns), y]:
                alive_neighbours += 1
            if old_grid[nmod(x+1, old_grid.columns), nmod(y+1, old_grid.rows)]:
                alive_neighbours += 1
            if old_grid[nmod(x+1, old_grid.columns), nmod(y-1, old_grid.rows)]:
                alive_neighbours += 1
            if old_grid[nmod(x-1, old_grid.columns), y]:
                alive_neighbours += 1
            if old_grid[nmod(x-1, old_grid.columns), nmod(y + 1, old_grid.rows)]:
                alive_neighbours += 1
            if old_grid[nmod(x-1, old_grid.columns), nmod(y - 1, old_grid.rows)]:
                alive_neighbours += 1
            if old_grid[nmod(x, old_grid.columns), nmod(y + 1, old_grid.rows)]:
                alive_neighbours += 1
            if old_grid[nmod(x, old_grid.columns), nmod(y - 1, old_grid.rows)]:
                alive_neighbours += 1
            
            if old_grid[x, y]:
                if alive_neighbours < 2 or alive_neighbours > 3:
                    new_grid[x, y] = false
                else:
                    new_grid[x, y] = true
            elif alive_neighbours == 3:
                new_grid[x, y] = true
            else:
                new_grid[x, y] = false
    let tmp = old_grid
    old_grid = new_grid
    new_grid = tmp
        

proc rand_init*(grid : var Grid) =
    var rand = initRand(epochTime().int64)
    for x in 0..<grid.columns:
        for y in 0..<grid.rows:
            grid[x, y] = (rand.next() mod 2) != 0

proc clear*(grid : var Grid) =
    for x in 0..<grid.columns:
        for y in 0..<grid.rows:
            grid[x, y] = false
            
