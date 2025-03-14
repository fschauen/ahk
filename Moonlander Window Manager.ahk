; See LICENSE file for copyright and license details.
;
; Simple window manager for MS Windows, made to work in tandem with my
; Moonlander keyboard configuration:
;
;   https://configure.zsa.io/moonlander/layouts/553D6/latest/0

try TraySetIcon("img\win_manager.ico")

TERMINAL_EXE := "ahk_exe mintty.exe"
TERMINAL_CMD := "
(LTrim Join`s
    C:\Users\fernando.schauenburg\AppData\Local\wsltty\bin\mintty.exe
    --WSL=
    --configdir="C:\Users\fernando.schauenburg\AppData\Roaming\wsltty"
    -~
    -
)"

BROWSER_EXE := "ahk_exe librewolf.exe"
BROWSER_CMD := "C:\Program Files\LibreWolf\librewolf.exe"

; Returns the rectangle (position & size) of a given monitor.
MonitorGetRect(N)
{
    MonitorGetWorkArea(N, &left, &top, &right, &bottom)
    return {
        pos: {
            x: left,
            y: top,
        },
        size: {
            width:  Abs(right - left),
            height: Abs(bottom - top),
        }
    }
}

; Return the number of the monitor that contains a window.
WinGetMonitor(WinTitle:="A")
{
    WinGetPos(&x,, &width,, WinTitle)
    midx := x + width // 2

    Loop MonitorGetCount() {
        MonitorGetWorkArea(A_Index, &left,, &right)
        if (left <= midx and midx < right)
            return A_Index
    }

    return MonitorGetPrimary()  ; fallback to primary if none found
}

; Center a window without changing its size.
WinCenter(WinTitle:="A")
{
    WinGetPos(,, &width, &height, WinTitle)
    r := MonitorGetRect(WinGetMonitor(WinTitle))
    x := Round(r.pos.x + r.size.width/2  - width/2)
    y := Round(r.pos.y + r.size.height/2 - height/2)
    WinMove(x, y, width, height, WinTitle)
}

; Return the rect (in percentages) of a window in its current monitor.
WinGetRelativeRect(WinTitle:="A")
{
    WinGetPos(&x, &y, &width, &height, WinTitle)
    monitor := WinGetMonitor(WinTitle)
    rect := MonitorGetRect(monitor)
    return {
        pos: {
            x: Abs((x - rect.pos.x) / rect.size.width),
            y: Abs((y - rect.pos.y) / rect.size.height),
        },
        size: {
            width:  width / rect.size.width,
            height: height / rect.size.height,
        }
    }
}

; Move and resize window to a rect (in percentage) in a given monitor.
WinSetRelativeRect(winRect, monitor?, WinTitle:="A")
{
    if not IsSet(monitor)
        monitor := WinGetMonitor(WinTitle)

    rect := MonitorGetRect(monitor)

    x      := Round(rect.pos.x + winRect.pos.x       * rect.size.width)
    y      := Round(rect.pos.y + winRect.pos.y       * rect.size.height)
    width  := Round(             winRect.size.width  * rect.size.width)
    height := Round(             winRect.size.height * rect.size.height)

    WinMove(x, y, width, height, WinTitle)
}

; Move a window wihtout changing its size.
WinTranslate(dx, dy, WinTitle:="A")
{
    WinGetPos(&x, &y, &width, &height, WinTitle)
    WinMove(x + dx, y + dy, width, height, WinTitle)
}

; Move a window to a different monitor, ajusting the relative scaling.
WinSetMonitor(target, WinTitle:="A")
{
    WinSetRelativeRect(WinGetRelativeRect(WinTitle), target, WinTitle)
}

openProgram(WinExe, Target, WorkingDir, rect?)
{
    if WinExist(WinExe) {
        WinActivate(WinExe)
    } else {
        Run(Target, WorkingDir)
        if IsSet(rect)
            if WinWait(WinExe,,5)
                WinSetRelativeRect(rect, 1, WinExe)
    }
}

POS := {
    ; 2x3 matrix
    upperLeft   : {pos: {x:   0, y:   0}, size: {width: 1/3, height: 1/2 }},
    upperMiddle : {pos: {x: 1/3, y:   0}, size: {width: 1/3, height: 1/2 }},
    upperRight  : {pos: {x: 2/3, y:   0}, size: {width: 1/3, height: 1/2 }},
    lowerLeft   : {pos: {x:   0, y: 1/2}, size: {width: 1/3, height: 1/2 }},
    lowerMiddle : {pos: {x: 1/3, y: 1/2}, size: {width: 1/3, height: 1/2 }},
    lowerRight  : {pos: {x: 2/3, y: 1/2}, size: {width: 1/3, height: 1/2 }},

    ; Full Height Thirds
    thirdLeft   : {pos: {x:   0, y:   0}, size: {width: 1/3, height:   1 }},
    doubleLeft  : {pos: {x:   0, y:   0}, size: {width: 2/3, height:   1 }},
    thirdRight  : {pos: {x: 2/3, y:   0}, size: {width: 1/3, height:   1 }},
    doubleRight : {pos: {x: 1/3, y:   0}, size: {width: 2/3, height:   1 }},

    ; Full Height Halves
    halfLeft    : {pos: {x:   0, y:   0}, size: {width: 1/2, height:   1 }},
    halfRight   : {pos: {x: 1/2, y:   0}, size: {width: 1/2, height:   1 }},

    ; Center
    mainFocus   : {pos: {x: 0.18, y:  0}, size: {width: 0.64, height:  1 }},
    fullScreen  : {pos: {x:    0, y:  0}, size: {width:    1, height:  1 }},
}

; Uncomment the following line while making changes for easy reload.
; ^!r::Reload

; Make sure NumLock is active so that Numpad mappinfs below will work.
SetNumLockState True

; 2x3 matrix
!#Numpad7::     WinSetRelativeRect(POS.upperLeft)
!#NumpadDiv::   WinSetRelativeRect(POS.upperMiddle)
!#Numpad8::     WinSetRelativeRect(POS.upperMiddle)
!#Numpad9::     WinSetRelativeRect(POS.upperRight)
!#Numpad1::     WinSetRelativeRect(POS.lowerLeft)
!#NumpadSub::   WinSetRelativeRect(POS.lowerMiddle)
!#Numpad2::     WinSetRelativeRect(POS.lowerMiddle)
!#Numpad3::     WinSetRelativeRect(POS.lowerRight)

; Full height thirds
!#Numpad4::     WinSetRelativeRect(POS.thirdLeft)
!#NumpadMult::  WinSetRelativeRect(POS.doubleLeft)
!#Numpad5::     WinSetRelativeRect(POS.doubleRight)
!#Numpad6::     WinSetRelativeRect(POS.thirdRight)

; Full height halves
!^Numpad1::     WinSetRelativeRect(POS.halfLeft)
!^Numpad3::     WinSetRelativeRect(POS.halfRight)

; Center and...
!#NumpadAdd::   WinSetRelativeRect(POS.fullScreen)  ; ... make full screen.
!^Numpad5::     WinCenter()                         ; ... keep size.

; Move to other monitor (FIXME this is a hack, but works on my current setup)
!^Left::        WinSetMonitor(2)
!^Right::       WinSetMonitor(1)

; Move without resize
step := 50                 ;    dx     dy
!^Numpad4::     WinTranslate(-step,     0) ; left  (H)
!^Numpad2::     WinTranslate(    0,  step) ; down  (J)
!^Numpad8::     WinTranslate(    0, -step) ; up    (K)
!^Numpad6::     WinTranslate( step,     0) ; right (L)

; Launch programs
!^+t::openProgram(TERMINAL_EXE, TERMINAL_CMD, A_Temp, POS.mainFocus)
!^+b::openProgram(BROWSER_EXE, BROWSER_CMD, A_Temp, POS.mainFocus)

