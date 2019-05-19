## Controls
- press **space bar** to start the game
- use **mouse scroll** to zoom in/out
- keep pressed **mouse right button** to pan
- use **mouse left click** to switch on/off individual pixels
- press `[` to decrease game speed and `]` to increase it
- press `c` to clear the screen
- press `s` to do a single game step
- press `h` to restore the default zoom level

## Demo
You can find a live example [here](http://woggioni.net/game_of_life) (requires a keyboard and a mouse)

## Build
to compile for desktop

```
nim c -d:release -o:sdlife main.nim
```

to compile for web browsers using [emscripten](https://emscripten.org/)

```
nim c -d:release -d:wasm main.nim
```

