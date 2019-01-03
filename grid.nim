import random
from times import epochTime
type Grid* = object 
    rows*, columns* : uint32
    data : seq[uint32]

proc newGrid*(rows, columns : uint32) : Grid =
    Grid(
        rows: rows, 
        columns: columns,
        data: newSeq[uint32]((rows * columns + 8 - 1) div 8)
    )

proc get(grid : Grid, x, y : uint32) : bool =
    assert x < grid.columns
    assert y < grid.rows
    let index = y * grid.columns + x
    (grid.data[index div 8] and (1u32 shl (index mod 8))) != 0

proc set(grid : var Grid, x, y : uint32, value : bool) : void =
    assert x < grid.columns
    assert y < grid.rows
    let index = y * grid.columns + x
    grid.data[(index div 8)] = 
        if value:
            grid.data[(index div 8)] or (1u32 shl (index mod 8))
        else:
            grid.data[(index div 8)] and (not (1u32 shl (index mod 8)))
    
template `[]`*(grid : Grid, x,y : uint32) : bool =
    get(grid, x, y)

template `[]=`*(grid : Grid, x,y : uint32, value : bool) =
    set(grid, x, y, value)

proc next_step*(old_grid, new_grid : var Grid) =
    for x in 0..<old_grid.columns:
        for y in 0..<old_grid.rows:
            var alive_neighbours = 0 
            if old_grid[(x+1) mod old_grid.columns, y]:
                alive_neighbours += 1
            if old_grid[(x+1) mod old_grid.columns, (y+1) mod old_grid.rows]:
                alive_neighbours += 1
            if old_grid[(x+1) mod old_grid.columns, (y-1) mod old_grid.rows]:
                alive_neighbours += 1
            if old_grid[(x-1) mod old_grid.columns, y]:
                alive_neighbours += 1
            if old_grid[(x-1) mod old_grid.columns, (y + 1) mod old_grid.rows]:
                alive_neighbours += 1
            if old_grid[(x-1) mod old_grid.columns, (y - 1) mod old_grid.rows]:
                alive_neighbours += 1
            if old_grid[x mod old_grid.columns, (y + 1) mod old_grid.rows]:
                alive_neighbours += 1
            if old_grid[x mod old_grid.columns, (y - 1) mod old_grid.rows]:
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

proc rand_init*(grid : var Grid) =
    var rand = initRand(epochTime().int64)
    for x in 0..<grid.columns:
        for y in 0..<grid.rows:
            grid[x, y] = (rand.next() mod 2) != 0


