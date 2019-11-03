import sdl2, sdl2/gfx
import geo2d


when defined(wasm):
    {.emit: "#include <emscripten.h>".}
    proc emscripten_set_main_loop_arg*(loopFunction: proc(ctx : pointer) {.cdecl.}, ctx : pointer, fps : cint, simulate_infinite_loop : cint) {.importc.}

discard sdl2.init(INIT_EVERYTHING)

var
    window: WindowPtr
    renderer: RendererPtr

window = createWindow("Game of Life in SDL", 
    SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 
    640, 480, 
    SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE)

renderer = createRenderer(window, -1, Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)

type Context = object
    renderer : RendererPtr

proc mainloop(arg : pointer) {.cdecl.} =
    let windowSize = block:
        var w, h : cint
        window.getSize(w, h)
        Rect2d(tl: newP2d(0f32, 0f32), br: newP2d(w.float32, h.float32))

    let ctx = cast[ptr[Context]](arg)
    let renderer = ctx.renderer
    
    renderer.setDrawColor(255, 0, 0, 255)
    renderer.clear()
    let ticks = getTicks()
    var r : Rect;
    r.x = ((ticks.float64 / 3000 * windowSize.width).cuint mod windowSize.width.cuint).cint
    r.y = 50;
    r.w = 50;
    r.h = 50;
    renderer.setDrawColor(0, 255, 255)
    renderer.fillRect(r)
    renderer.present()

var ctx = Context(renderer : renderer)
emscripten_set_main_loop_arg(mainloop, addr(ctx), -1, 1)

destroy renderer
destroy window