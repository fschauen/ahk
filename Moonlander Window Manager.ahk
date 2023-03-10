log(text)
{
    FileAppend(text . "`n", "log.txt")
}

; Return the number of the monitor that contains a window.
getMonitor(winId:="A")
{
    WinGetPos(&x,, &width,, winId)
    midx := x + width // 2

    Loop MonitorGetCount() {
        MonitorGetWorkArea(A_Index, &left,, &right)
        if (left <= midx and midx < right)
            return A_Index
    }

    return MonitorGetPrimary()  ; fallback to primary if none found
}

; Returns the bound of the monitor that contains a window.
getMonitorBounds(winId:="A")
{
    monitor := getMonitor(winId)
    MonitorGetWorkArea(monitor, &left, &top, &right, &bottom)
    return {
        x      : left,
        y      : top,
        width  : Abs(right - left),
        height : Abs(bottom - top),
    }
}

clamp(n, limit:=1)
{
    n := Abs(n)
    if (n > limit)
        return Mod(n, limit)
    return n
}

; Move and resize window to match spec (x, y, width, height).
positionWindow(spec, winId:="A")
{
    xScale := clamp(spec.x)
    yScale := clamp(spec.y)
    wScale := clamp(spec.w)
    hScale := clamp(spec.h)

    monitor := getMonitorBounds(winId)

    x      := Round(monitor.x + xScale * monitor.width)
    y      := Round(monitor.y + yScale * monitor.height)
    width  := Round(            wScale * monitor.width)
    height := Round(            hScale * monitor.height)

    WinMove(x, y, width, height, winId)
}

; Center a window without changing its size.
centerWindow(winId:="A")
{
    WinGetPos(,, &width, &height, winId)

    monitor := getMonitorBounds(winId)

    x := Round(monitor.x + monitor.width/2  - width/2)
    y := Round(monitor.y + monitor.height/2 - height/2)

    WinMove(x, y, width, height, winId)
}

; Move a window wihtou changing its size.
moveWindow(dx, dy, winId:="A")
{
    WinGetPos(&x, &y, &width, &height, winId)
    WinMove(x + dx, y + dy, width, height, winId)
}

SPECS := {
    ; 2x3 matrix
    upperLeft    : {x:   0,   y:    0,   w: 1/3,   h:  1/2 },
    upperMiddle  : {x: 1/3,   y:    0,   w: 1/3,   h:  1/2 },
    upperRight   : {x: 2/3,   y:    0,   w: 1/3,   h:  1/2 },
    lowerLeft    : {x:   0,   y:  1/2,   w: 1/3,   h:  1/2 },
    lowerMiddle  : {x: 1/3,   y:  1/2,   w: 1/3,   h:  1/2 },
    lowerRight   : {x: 2/3,   y:  1/2,   w: 1/3,   h:  1/2 },

    ; full height thirds
    thirdLeft    : {x:   0,   y:    0,   w: 1/3,   h:    1 },
    doubleLeft   : {x:   0,   y:    0,   w: 2/3,   h:    1 },
    thirdRight   : {x: 2/3,   y:    0,   w: 1/3,   h:    1 },
    doubleRight  : {x: 1/3,   y:    0,   w: 2/3,   h:    1 },

    ; full height halves
    halfLeft    : {x:   0,   y:    0,   w: 1/2,   h:    1 },
    halfRight   : {x: 1/2,   y:    0,   w: 1/2,   h:    1 },

    ; center
    mainFocus   : {x: 0.18,   y:   0,   w: 0.64,   h:    1 },
}

^!r::Reload

; 2x3 matrix
!#Numpad7::     positionWindow(SPECS.upperLeft)
!#NumpadDiv::   positionWindow(SPECS.upperMiddle)
!#Numpad8::     positionWindow(SPECS.upperMiddle)
!#Numpad9::     positionWindow(SPECS.upperRight)
!#Numpad1::     positionWindow(SPECS.lowerLeft)
!#NumpadSub::   positionWindow(SPECS.lowerMiddle)
!#Numpad2::     positionWindow(SPECS.lowerMiddle)
!#Numpad3::     positionWindow(SPECS.lowerRight)

; Full height thirds
!#Numpad4::     positionWindow(SPECS.thirdLeft)
!#NumpadMult::  positionWindow(SPECS.doubleLeft)
!#Numpad5::     positionWindow(SPECS.doubleRight)
!#Numpad6::     positionWindow(SPECS.thirdRight)

; Full height halves
!^Numpad1::positionWindow(SPECS.halfLeft)
!^Numpad3::positionWindow(SPECS.halfRight)

; Center and...
!#NumpadAdd::   positionWindow(SPECS.mainFocus) ; ... resize to default.
!^Numpad5::     centerWindow()                  ; ... keep size.

; Move to other monitor
; !^Left:: TODO move to other monitor
; !^Right:: TODO move to other monitor

; Move without resize
step := 50              ;    dx     dy
!^Numpad4::     moveWindow(-step,     0) ; left  (H)
!^Numpad2::     moveWindow(    0,  step) ; down  (J)
!^Numpad8::     moveWindow(    0, -step) ; up    (K)
!^Numpad6::     moveWindow( step,     0) ; right (L)

