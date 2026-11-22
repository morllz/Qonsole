; LibCon - minimal console support library for AutoHotkey v2
; ------------------------------------------------
; Derived from LibCon 1.0.4.2 by Joe DF (MIT License)
; Windows-only. Requires AutoHotkey v2.0+.
;
; The legacy XP support (SizeCon.dll) and the FileOpen-based handle
; wrappers have been removed. Console handles are used directly, which
; is all Qonsole needs.

#Requires AutoHotkey v2.0

global LibConVersion := "2.0.0"
global LibConDebug := 1      ; show a message box when a console call fails
global LibConErrorLevel := 0
global LibConStdout := 0     ; raw stdout handle, set by AttachConsole()

; Console sizes, as returned by GetConsoleScreenBufferInfo().
global sType := { SHORT: 2, COORD: 4, WORD: 2, SMALL_RECT: 8, DWORD: 4, LONG: 4, BOOL: 4, RECT: 16, CHAR: 1 }

; AttachConsole() - http://msdn.microsoft.com/library/ms681952
; Defaults to the parent process: ATTACH_PARENT_PROCESS = (DWORD)-1
AttachConsole(cPID := -1) {
    global LibConStdout
    param := (cPID = -1) ? 0xFFFFFFFF : cPID
    x := DllCall("AttachConsole", "UInt", param, "Int")
    if (!x && cPID != -1)
        return LibConError("AttachConsole")
    LibConStdout := DllCall("GetStdHandle", "Int", -11, "Ptr")
    return x
}

; FreeConsole() - http://msdn.microsoft.com/library/ms683150
FreeConsole() {
    x := DllCall("FreeConsole", "Int")
    if (!x)
        return LibConError("FreeConsole")
    return x
}

; GetConsoleWindow() - http://msdn.microsoft.com/library/ms683175
GetConsoleHandle() {
    hConsole := DllCall("GetConsoleWindow", "Ptr")
    if (!hConsole)
        return LibConError("GetConsoleHandle")
    return hConsole
}

; GetConsoleScreenBufferInfo() - http://msdn.microsoft.com/library/ms683171
; CONSOLE_SCREEN_BUFFER_INFO.dwSize is at offset 0: two USHORTs (width, height).
GetConsoleSize(&bufferWidth, &bufferHeight) {
    global LibConStdout
    buf := Buffer(24, 0)
    if (!DllCall("GetConsoleScreenBufferInfo", "Ptr", LibConStdout, "Ptr", buf, "Int"))
        return LibConError("GetConsoleSize")
    bufferWidth := NumGet(buf, 0, "UShort")
    bufferHeight := NumGet(buf, 2, "UShort")
    return 1
}

GetConsoleHeight() {
    width := 0, height := 0
    if (!GetConsoleSize(&width, &height))
        return 0
    return height
}

; GetCurrentConsoleFont() - http://msdn.microsoft.com/library/ms683176
; CONSOLE_FONT_INFO: DWORD nFont; COORD dwFontSize (offsets 4 and 6).
GetFontSize(&fontWidth, &fontHeight) {
    global LibConStdout
    buf := Buffer(8, 0)
    if (!DllCall("GetCurrentConsoleFont", "Ptr", LibConStdout, "Int", 0, "Ptr", buf, "Int"))
        return LibConError("GetFontSize")
    fontWidth := NumGet(buf, 4, "UShort")
    fontHeight := NumGet(buf, 6, "UShort")
    return 1
}

GetFontWidth() {
    width := 0, height := 0
    if (!GetFontSize(&width, &height))
        return 0
    return width
}

; SetConsoleScreenBufferSize() + MoveWindow()
; Width and height are in character cells.
SetConsoleSize(width, height, sizeHeight := 0) {
    global LibConStdout
    hConsole := GetConsoleHandle()
    if (!hConsole)
        return 0

    cW := 0, cH := 0
    GetConsoleSize(&cW, &cH)
    wX := 0, wY := 0, wH := 0
    WinGetPos(&wX, &wY, , &wH, "ahk_id " hConsole)
    fW := 0, fH := 0
    GetFontSize(&fW, &fH)
    if (!fW || !fH)
        return 0

    newW := width * fW
    newH := height * fH
    oldW := cW * fW
    oldH := cH * fH

    ; A COORD is packed as width | (height << 16) and passed by value.
    packed := width | (height << 16)

    if (newW >= oldW && newH >= oldH) {
        ok := DllCall("SetConsoleScreenBufferSize", "Ptr", LibConStdout, "UInt", packed, "Int")
            && DllCall("MoveWindow", "Ptr", hConsole, "Int", wX, "Int", wY, "Int", newW, "Int", newH, "Int", 1, "Int")
    } else {
        ok := DllCall("MoveWindow", "Ptr", hConsole, "Int", wX, "Int", wY, "Int", newW, "Int", newH, "Int", 1, "Int")
            && DllCall("SetConsoleScreenBufferSize", "Ptr", LibConStdout, "UInt", packed, "Int")
    }

    if (!ok)
        return LibConError("SetConsoleSize")
    if (sizeHeight)
        WinMove(, , , wH, "ahk_id " hConsole)
    return 1
}

; SetCurrentConsoleFontEx() - applies a TrueType face to the attached console.
; height is the cell height in pixels. Returns 1 on success, 0 on failure.
SetConsoleFont(face, height := 16) {
    global LibConStdout
    if (!LibConStdout || face = "")
        return 0
    info := Buffer(84, 0)
    NumPut("UInt", 84, info, 0)          ; cbSize
    NumPut("Short", 0, info, 8)          ; dwFontSize.X (0 = auto)
    NumPut("Short", height, info, 10)    ; dwFontSize.Y
    NumPut("UInt", 0x36, info, 12)       ; FontFamily: FF_MODERN | fixed pitch
    NumPut("UInt", 400, info, 16)        ; FontWeight
    StrPut(face, info.Ptr + 20, 32, "UTF-16")
    return DllCall("SetCurrentConsoleFontEx", "Ptr", LibConStdout, "Int", 0, "Ptr", info, "Int")
}

; WriteConsoleW() - writes directly to the attached console.
Print(string := "") {
    global LibConStdout
    if (string = "")
        return 1
    written := 0
    if (!DllCall("WriteConsoleW", "Ptr", LibConStdout, "Str", string
        , "UInt", StrLen(string), "UInt*", &written, "Ptr", 0, "Int"))
        return LibConError("Print")
    return 1
}

; Failure handler (only reports when LibConDebug is enabled).
LibConError(fname := "") {
    global LibConDebug, LibConErrorLevel
    LibConErrorLevel := A_LastError
    if (LibConDebug)
        MsgBox(fname "() failed.`nLast error: " A_LastError, "LibCon", "Icon!")
    return 0
}
