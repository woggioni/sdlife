include options
import sdl2, sdl2/gfx
import grid
import geo2d
import mmath/smatrix
import mmath/svector
from nwo/utils import box

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
  fpsman: FpsManager
fpsman.init

let side : uint32 = 5
let 
    pixelx = 200u32
    pixely = 200u32

var
    current_grid, next_grid : ref[Grid]
block:
    var grid = newGrid(pixelx, pixely)
    grid.rand_init()
    current_grid = box(grid)
    next_grid = box(grid)

let bb = newRect2d(0f32, 0f32, float32(side * pixelx), float32(side * pixely))
let step = 3
var elapsed_time_sec = 0
var 
    uxform : X2d = identity[3, float32]()
    pan_start : Option[P2d] = none[P2d]()

while not quit:
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
                case keyboardEvent.keysym.sym.char:
                    of ' ':
                        freeze = not freeze
                    of 'h':
                        uxform = identity[3, float32]()
                    else:
                        discard
            of MouseButtonDown:
                let mouseButtonDownEvent = cast[MouseButtonEventPtr](addr(evt))
                if mouseButtonDownEvent.which == BUTTON_RIGHT:
                    pan_start = some(newP2d(mouseButtonDownEvent.x.float32, mouseButtonDownEvent.y.float32))
            of MouseButtonUp:
                let mouseButtonDownEvent = cast[MouseButtonEventPtr](addr(evt))
                if mouseButtonDownEvent.which == BUTTON_RIGHT and pan_start.isSome():
                    let xlation = newP2d(mouseButtonDownEvent.x.float32, mouseButtonDownEvent.y.float32) - pan_start.get()
                    pan_start = none[P2d]()
                    uxform = uxform * xlate(xlation.x, xlation.y)
            of MouseWheel:
                let mouseWheelEvent = cast[MouseWheelEventPtr](addr(evt))
                if mouseWheelEvent.y > 0:
                    uxform = uxform * scale(newP2d(windowSize.width.float32 / 2f32, windowSize.height.float32 / 2f32), 1.1f32, 1.1f32)
                else:
                    uxform = uxform * scale(newP2d(windowSize.width.float32 / 2f32, windowSize.height.float32 / 2f32), 0.9f32, 0.9f32)
            of MouseMotion:
                let mouseMotionEvent = cast[MouseMotionEventPtr](addr(evt))
                let position = newP2d(mouseMotionEvent.x.float32, mouseMotionEvent.y.float32)

            else:
                discard

    let dt = fpsman.getFramerate() / 1000

    render.setDrawColor 0,0,0,255
    render.clear
    var
        x : float32 = bb.left
        y : float32 = bb.top

    render.setDrawColor 127,127,127,255        
    let f = min(windowSize.width / bb.width, windowSize.height / bb.height)
    let xform = xlate(-bb.width / 2.0f32, -bb.height / 2.0f32) * scale(f, f) *
        xlate(windowSize.width / 2.0f32, windowSize.height / 2.0f32) * uxform

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
    fpsman.delay
    let current_time_sec = fpsman.getFramecount() div step
    if not freeze and current_time_sec > elapsed_time_sec:
        elapsed_time_sec = current_time_sec
        next_step(current_grid[], next_grid[])
        let tmp = current_grid
        current_grid = next_grid
        next_grid = tmp

destroy render
destroy window