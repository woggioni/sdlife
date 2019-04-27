import options
import sdl2, sdl2/gfx
import grid
import geo2d
import mmath/smatrix
import mmath/svector
from nwo/utils import box

when defined(wasm):
    {.emit: "#include <emscripten.h>".}
    proc emscripten_set_main_loop_arg*(loopFunction: proc(ctx : pointer) {.cdecl.}, ctx : pointer, fps : cint, simulate_infinite_loop : cint) {.importc.}

discard sdl2.init(INIT_EVERYTHING)

proc drawLine(renderer : RendererPtr, p0, p1 : P2d) = renderer.drawLine(p0.x.cint, p0.y.cint, p1.x.cint, p1.y.cint)
proc fillRect(renderer : RendererPtr, rect : Rect2d) = 
    var rect : Rect = (rect.left.cint, rect.top.cint, rect.width.cint, rect.height.cint)
    renderer.fillRect(addr(rect))

var
  window: WindowPtr
  render: RendererPtr

window = createWindow("Game of Life in SDL", 
    SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 
    640, 480, 
    SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE)
render = createRenderer(window, -1, Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)

var
  evt = sdl2.defaultEvent
  quit = false
  freeze = true
#   fpsman: FpsManager
# fpsman.init

let side = 5
let 
    pixelx = 200
    pixely = 200

var
    current_grid, next_grid : ref[Grid]
block:
    var grid = newGrid(pixelx, pixely)
    grid.rand_init()
    current_grid = box(grid)
    next_grid = box(grid)

let bb = newRect2d(0f32, 0f32, float32(side * pixelx), float32(side * pixely))
var step : uint = 3
var elapsed_time : uint = 0
var 
    xform : X2d = identity[3, float32]()
    uxform : X2d = identity[3, float32]()
    pan_start : Option[P2d] = none[P2d]()

proc main_loop(arg : pointer) {.cdecl.} =
    let windowSize = block:
        var w, h : cint
        window.getSize(w, h)
        Rect2d(tl: newP2d(0f32, 0f32), br: newP2d(w.float32, h.float32))
    while pollEvent(evt):
        case evt.kind:
            of QuitEvent:
                quit = true
                break
            of KeyDown:
                let keyboardEvent = cast[KeyboardEventPtr](addr(evt))
                case keyboardEvent.keysym.sym:
                    of ' '.int:
                        freeze = not freeze
                    of 'h'.int:
                        uxform = identity[3, float32]()
                    of 'c'.int:
                        current_grid[].clear()
                    of 's'.int:
                        next_step(current_grid[], next_grid[])
                    of '['.int:
                        if step > 0u:
                            step -= 1
                    of ']'.int:
                        if step < 10:
                            step += 1
                    else:
                        discard
            of MouseButtonDown:
                let mouseButtonDownEvent = cast[MouseButtonEventPtr](addr(evt))
                case mouseButtonDownEvent.button:
                    of BUTTON_RIGHT:
                        pan_start = some(newP2d(mouseButtonDownEvent.x.float32, mouseButtonDownEvent.y.float32))
                    of BUTTON_LEFT:
                        let inv = xform.invert()
                        let position = newP2d(mouseButtonDownEvent.x.float32, mouseButtonDownEvent.y.float32) * inv / side.float32
                        let row = position.x.int
                        let column = position.y.int
                        current_grid[][row, column] = not current_grid[][row, column]    
                    else:
                        discard
            of MouseButtonUp:
                let mouseButtonUpEvent = cast[MouseButtonEventPtr](addr(evt))
                case mouseButtonUpEvent.button:
                    of BUTTON_RIGHT:
                        let xlation = newP2d(mouseButtonUpEvent.x.float32, mouseButtonUpEvent.y.float32) - pan_start.get()
                        pan_start = none[P2d]()
                        uxform = uxform * xlate(xlation.x, xlation.y)
                    else:
                        discard
            of MouseWheel:
                let mouseWheelEvent = cast[MouseWheelEventPtr](addr(evt))
                let zoomCenter = (block:
                    var x,y : cint
                    getMouseState(x,y)
                    newP2d(x.float32, y.float32)
                )
                if mouseWheelEvent.y > 0:
                    uxform = uxform * scale(zoomCenter, 1.1f32, 1.1f32)
                else:
                    uxform = uxform * scale(zoomCenter, 0.9f32, 0.9f32)
            # of MouseMotion:
            #     let mouseMotionEvent = cast[MouseMotionEventPtr](addr(evt))
            #     if pan_start.isSome:
            #         pan = pan * xlate(newP2d(mouseMotionEvent.x.float32, mouseMotionEvent.y.float32) - pan_start.get())
                
            else:
                discard

    # let dt = fpsman.getFramerate() / 1000
    # let dt = 10

    render.setDrawColor 0,0,0,255
    render.clear
    var
        x : float32 = bb.left
        y : float32 = bb.top

    render.setDrawColor 127,127,127,255        
    let f = min(windowSize.width / bb.width, windowSize.height / bb.height)
    # let pan_xform = block:
    #     if pan_start.isSome():
    #         x

    let pan = block:
        if pan_start.isSome:
            var x, y : cint
            getMouseState(x, y)
            xlate(newP2d(x.float32, y.float32) - pan_start.get())
        else:
            identity[3, float32]()

    xform = xlate(-bb.width / 2.0f32, -bb.height / 2.0f32) * scale(f, f) *
        xlate(windowSize.width / 2.0f32, windowSize.height / 2.0f32) * uxform * pan

    while x <= bb.width:
        render.drawLine(newP2d(x, bb.top) * xform, newP2d(x, bb.height) * xform)
        x += side.float32

    while y <= bb.height:
        render.drawLine(newP2d(bb.left, y) * xform, newP2d(bb.width, y) * xform)
        y += side.float32

    render.setDrawColor 255,255,255,255  
    for i in 0..<current_grid.columns:
        for j in 0..<current_grid.rows:
            if current_grid[][i, j]:
                render.fillRect(newRect2d((i * side).float32, (j * side).float32, side.float32, side.float32) * xform)
    render.present
    # fpsman.delay
    # delay(0)
    let current_time = getTicks().uint
    if not freeze and current_time - elapsed_time > step * 50:
        elapsed_time = current_time
        next_step(current_grid[], next_grid[])


when defined(wasm):
    emscripten_set_main_loop_arg(mainloop, nil, -1, 1)
else:
    while not quit:
        main_loop(nil)
        delay(0)

destroy render
destroy window