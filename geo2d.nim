import mmath/smatrix
import mmath/svector
from nwo/utils import `...`
from math import sin, cos

type
    X2d* = SquareSMatrix[3, float32]
    P2d* = SVector[3, float32]
    Rect2d* = object
        tl*, br* : P2d

proc newP2d*(x, y : float32) : P2d =
    P2d(buildSVector[3, float32](x,y,1f32))

proc x*(p : P2d) : float32 = p[0]
proc y*(p : P2d) : float32 = p[1]

proc newRect2d*(x, y, width, height : float32) : Rect2d = Rect2d(tl: newP2d(x,y), br: newP2d(x + width, y + height))
proc top*(rect : Rect2d) : float32 = rect.tl.y
proc bottom*(rect : Rect2d) : float32 = rect.br.y
proc left*(rect : Rect2d) : float32 = rect.tl.x
proc right*(rect : Rect2d) : float32 = rect.br.x
proc width*(rect : Rect2d) : float32 = rect.br.x - rect.tl.x
proc height*(rect : Rect2d) : float32 = rect.br.y - rect.tl.y
proc `*`*(rect : Rect2d, xform : X2d) : Rect2d = Rect2d(tl: rect.tl * xform, br: rect.br * xform) 

proc rot*(alpha: float32) : X2d = 
    result = identity[3,float32]()
    let ca = cos(alpha)
    let sa = sin(alpha)
    result[0,0] = ca
    result[1,1] = ca
    result[0,1] = sa
    result[1,0] = -sa

proc scale*(x, y: float32) : X2d = 
    result = identity[3,float32]()
    result[0,0] = x
    result[1,1] = y  

proc xlate*(x, y: float32) : X2d =
    result = identity[3,float32]()
    result[2,0] = x
    result[2,1] = y

proc scale*(center : P2d, x, y : float32) : X2d = xlate(-center.x, -center.y) * scale(x,y) * xlate(center.x, center.y)
proc rot*(center : P2d, angle : float32) : X2d = xlate(-center.x, -center.y) * rot(angle) * xlate(center.x, center.y)

    

