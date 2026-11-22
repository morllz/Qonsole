; Qonsole - Quake-like Console Emulator
; Supported On AutoHotkey Version: 2.0+ (Windows 10/11)
;
; Original: Joe DF - joedf@ahkscript.org - MIT License
;
; v2 port notes:
;   * conhost.exe is used to launch the shell so Windows 11 does not hand the
;     console to Windows Terminal, which has no ConsoleWindowClass window.
;   * The XP compatibility layer and Console2 support have been removed.

AppName := "Qonsole"
Version := "2.0.0"
;@Ahk2Exe-SetVersion 2.0.0.0
;@Ahk2Exe-SetProductVersion 2.0.0.0
App_date := "2026/11/22"
;@Ahk2Exe-SetCopyright (C) 2026`, joedf@ahkscript.org
Update_URL := "https://raw.githubusercontent.com/joedf/Qonsole/master/update.ini"
Project_URL := "https://github.com/joedf/Qonsole"
;@Ahk2Exe-SetMainIcon logo\Qonsole_sm2.ico
;@Ahk2Exe-SetDescription Qonsole - Quake-like Console Emulator
;@Ahk2Exe-SetOrigFilename Qonsole.exe
;@Ahk2Exe-SetProductName Qonsole
;@Ahk2Exe-SetInternalName Qonsole

#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off
#Include LibCon.ahk

;###################[ State ]#####################

global configFile := ""
global Default_CMD_Width := 80
global WelcomeFirstTime := false

global Speed := 1
global Delay := 20
global dx := 25
global HideOnInActive := 0
global HorizontallyCentered := 0
global BottomPlaced := 0
global AnimationDisabled := 0
global CmdPaste := 1
global RunOnStartUp := 0
global AutoWinActivate := 1
global ReduceMemory := 1
global chkActiveDelay := 100
global Console_Mode := "Cmd"
global TransparencyPercent := 20
global CMD_Path := ""
global CMD_Width := 0
global CMD_Height := 266
global CMD_StartUpArgs := " "
global CMD_offset := 0
global Mintty_path := ""
global Console_Font := "CaskaydiaCove NFM"
global Console_FontSize := 16
global GuiBGDarken_Increment := 6
global GuiBGDarken_Max := 128
global GuiBGDarken_Color := "0x1A1A1A"
global OpenHotkey := "#c"

global ScreenScaleFactor := 1
global WinTenPlus := 2   ; modern console chrome compensation (px)

global con := ""
global cPID := 0
global open := 0
global cShown := 0
global anim := 0
global xC_height := 0
global cmd_w_fix := 0
global offset := 0
global winCh := 0
global hGuiBGDarken := 0
global guiBGDarken := ""
global settingsGui := ""
global SettingsCtl := ""
global aboutGui := ""
global CheckUpdate_hide := 0
global Check4Update_hidden_fail := 1

;###################[ Start up ]#####################

SetWinDelay(-1)
SetTitleMatchMode(2)
DetectHiddenWindows(true)
SetWorkingDir(A_ScriptDir)
OnExit(AppExit)

configFile := SubStr(A_ScriptName, 1, -4) "_settings.ini"
Default_CMD_Width := Round((A_ScreenWidth * 0.75) / 8)
WelcomeFirstTime := !FileExist(configFile)
CheckUpdate_hide := 0

IniReadSetting() {
    global Speed, Delay, dx, HideOnInActive, HorizontallyCentered, BottomPlaced
    global AnimationDisabled, CmdPaste, RunOnStartUp, AutoWinActivate, ReduceMemory
    global Console_Mode, TransparencyPercent, CMD_Path, Mintty_path, OpenHotkey
    global CMD_Width, CMD_Height, CMD_StartUpArgs, CMD_offset
    global Console_Font, Console_FontSize
    global GuiBGDarken_Increment, GuiBGDarken_Max, GuiBGDarken_Color

    Speed := Num(IniRead(configFile, "Animation", "Speed", 1), 1)
    Delay := Num(IniRead(configFile, "Animation", "Delay", 20), 20)
    dx := Num(IniRead(configFile, "Animation", "dx", 25), 25)
    HideOnInActive := Num(IniRead(configFile, "Settings", "HideOnInActive", 0), 0)
    HorizontallyCentered := Num(IniRead(configFile, "Settings", "HorizontallyCentered", 0), 0)
    BottomPlaced := Num(IniRead(configFile, "Settings", "BottomPlaced", 0), 0)
    AnimationDisabled := Num(IniRead(configFile, "Animation", "AnimationDisabled", 0), 0)
    CmdPaste := Num(IniRead(configFile, "Settings", "CmdPaste", 1), 1)
    RunOnStartUp := Num(IniRead(configFile, "Settings", "RunOnStartUp", 0), 0)
    AutoWinActivate := Num(IniRead(configFile, "Settings", "AutoWinActivate", 1), 1)
    ReduceMemory := Num(IniRead(configFile, "Settings", "ReduceMemory", 1), 1)
    Console_Mode := IniRead(configFile, "Settings", "Console_Mode", "Cmd")
    TransparencyPercent := Num(IniRead(configFile, "Settings", "TransparencyPercent", 20), 20)
    CMD_Path := IniRead(configFile, "Settings", "CMD_Path", A_ScriptDir "\cmd_Qonsole.lnk")
    Mintty_path := IniRead(configFile, "Settings", "Mintty_path", A_ScriptDir "\mintty.exe")
    OpenHotkey := IniRead(configFile, "Settings", "OpenHotkey", "#c")
    CMD_Width := Num(IniRead(configFile, "Settings", "CMD_Width", Default_CMD_Width * 8), Default_CMD_Width * 8)
    CMD_Height := Num(IniRead(configFile, "Settings", "CMD_Height", 266), 266)
    CMD_StartUpArgs := IniRead(configFile, "Settings", "CMD_StartUpArgs", A_Space)
    CMD_offset := Num(IniRead(configFile, "Settings", "CMD_offset", 0), 0)
    Console_Font := IniRead(configFile, "Settings", "Console_Font", "CaskaydiaCove NFM")
    Console_FontSize := Num(IniRead(configFile, "Settings", "Console_FontSize", 16), 16)
    GuiBGDarken_Increment := Num(IniRead(configFile, "Animation", "GuiBGDarken_Increment", 6), 6)
    GuiBGDarken_Max := Num(IniRead(configFile, "Animation", "GuiBGDarken_Max", 128), 128)
    GuiBGDarken_Color := IniRead(configFile, "Animation", "GuiBGDarken_Color", "0x1A1A1A")
}

IniReadSetting()

if (!InStr(Console_Mode, "Mintty"))
    Console_Mode := "Cmd"
else
    Console_Mode := "Mintty"

Speed := Max(1, Speed)

; High-DPI: WinSetRegion works in device pixels while AutoHotkey is system-DPI aware.
ScreenScaleFactor := 1
CMD_Width := Round(CMD_Width * ScreenScaleFactor)
CMD_Height := Round(CMD_Height * ScreenScaleFactor)
Speed := Round(Speed * ScreenScaleFactor)

if (GuiBGDarken_Max)
    CreateGuiBGDarken()

if (A_IsCompiled)
    TraySetIcon(A_ScriptFullPath, 1)

A_TrayMenu.Delete()
if (!A_IsCompiled)
    A_TrayMenu.AddStandard()
A_IconTip := AppName " v" Version
A_TrayMenu.Add("Show/Hide Console", ToggleConsole)
A_TrayMenu.Default := "Show/Hide Console"
A_TrayMenu.Add("Settings", ShowProgramSettings)
A_TrayMenu.Add()
A_TrayMenu.Add("Check for update", UpdateCheck)
A_TrayMenu.Add("Project Webpage", (*) => Run(Project_URL))
A_TrayMenu.Add("About", ShowAbout)
A_TrayMenu.Add()
A_TrayMenu.Add("Reload", ReloadApp)
A_TrayMenu.Add("Quit", QuitApp)
A_TrayMenu.ClickCount := 1

GroupAdd("Console_Classes", "ahk_class ConsoleWindowClass")
GroupAdd("Console_Classes", "ahk_class mintty")

if (CmdPaste) {
    HotIfWinActive("ahk_class ConsoleWindowClass")
    Hotkey("^v", PasteHotkey, "On")
    HotIf()
}

try
    Hotkey(OpenHotkey, ToggleConsole, "On")
catch as e
    MsgBoxTop("Could not register the global hotkey " OpenHotkey ".`n`n" e.Message, AppName " - Error", 0x30)

if (WelcomeFirstTime) {
    ShowAbout()
    MsgBoxTop("Welcome!`nSee the tray icon/menu in the notifications area.", AppName " - Version " Version, 0x40)
}

; Check a few seconds after startup so the download cannot delay hotkey handling.
SetTimer(UpdateCheckHidden, -5000)
SetTimer(UpdateCheckHidden, -300000)

SetAutorun(RunOnStartUp)

SetTimer(CleanSelf, -1)

;###################[ Console hotkeys ]#####################

#HotIf WinActive("ahk_group Console_Classes")
~Enter:: {
    if InStr(WinGetTitle("A"), "@")
        return
    if (con != "" && WinActive(con))
        ConsoleScrollBottom(con)
}
#HotIf

;###################[ Show / hide ]#####################

ToggleConsole(*) {
    ; SetTimer allows the open/close to be caught even during an animation.
    SetTimer(HideConsole, 0)
    SetTimer(ShowConsole, 0)
    SetTimer(ShowConsole, -1)

    if (HideOnInActive)
        SetTimer(CheckActive, chkActiveDelay)
}

ShowConsole(*) {
    global open, cShown, cPID, xC_height, offset, Console_Mode

    if (con = "" || !WinExist(con)) {
        open := 0
        cShown := 0
        cPID := 0
        xC_height := CMD_Height
    } else {
        if (cShown) {
            HideConsole()
            return
        }
        WinShow(con)
        WinActivate(con)
    }

    if (!open && !cPID) {
        if (Console_Mode = "Mintty") {
            if (!LaunchMintty()) {
                ; Fall back to cmd instead of asking again on every toggle.
                Console_Mode := "Cmd"
                IniWrite(Console_Mode, configFile, "Settings", "Console_Mode")
                if (!LaunchCmd())
                    return
            }
        } else {
            if (!LaunchCmd())
                return
        }

        offset := Mod(winCh, Speed) - winCh + Speed
        ; Keep the window off-screen for the first slide. Bottom placement is
        ; positioned directly because its slide target is the screen bottom.
        PositionConsole(ComputeX(), ComputeY(), BottomPlaced)
        open := 1
    } else {
        PositionConsole(ComputeX(), ComputeY(), false)
    }

    cShown := 1
    SetTimer(CleanSelf, -1)
}

ComputeX() {
    x := ((HorizontallyCentered) ? ((cmd_w_fix < A_ScreenWidth) ? Abs((A_ScreenWidth - cmd_w_fix) / 2) : 0) : 0) - 2
    if (InStr(Console_Mode, "Cmd"))
        x += 2
    return x
}

ComputeY() {
    if (BottomPlaced)
        return (xC_height < A_ScreenHeight) ? Abs(A_ScreenHeight - xC_height + 16) : 0
    return -2
}

PositionConsole(x, y, moveY) {
    if (hGuiBGDarken) {
        WinSetAlwaysOnTop(1, "ahk_id " hGuiBGDarken)
        WinActivate("ahk_id " hGuiBGDarken)
    }
    WinSetAlwaysOnTop(1, con)
    WinActivate(con)

    if (moveY)
        WinMove(x, y, , , con)
    else
        WinMove(x, , , , con)

    if (InStr(Console_Mode, "Mintty"))
        WinSetTransparent(Round(Abs(100 - TransparencyPercent) / 100 * 255), con)

    if (hGuiBGDarken)
        WinFade("ahk_id " hGuiBGDarken, GuiBGDarken_Max, GuiBGDarken_Increment)

    ; When Qonsole is at the bottom, hiding is the same movement as showing at the top.
    if (BottomPlaced)
        WinSlideUpExp(con, Delay, Speed, Round(A_ScreenHeight - ((xC_height - CMD_offset) * ScreenScaleFactor) + 24), dx)
    else
        WinSlideDownExp(con, Delay, Speed, Round(CMD_offset * ScreenScaleFactor), dx)
}

HideConsole(*) {
    global cShown

    if (cShown) {
        if (BottomPlaced)
            WinSlideDownExp(con, Delay, Speed, A_ScreenHeight, dx)
        else
            WinSlideUpExp(con, Delay, Speed, offset * ScreenScaleFactor, dx)

        if (WinExist(con))
            WinHide(con)

        if (hGuiBGDarken)
            WinFade("ahk_id " hGuiBGDarken, 0, GuiBGDarken_Increment)

        cShown := 0
    }
    SetTimer(CleanSelf, -1)
}

CheckActive(*) {
    if (HideOnInActive) {
        if (con != "" && !WinActive(con)) {
            HideConsole()
            SetTimer(CheckActive, 0)
        }
    }
}

CloseConsole() {
    global open

    if (con != "" && WinExist(con))
        WinKill(con)
    if (hGuiBGDarken)
        WinSetTransparent(0, "ahk_id " hGuiBGDarken)
    open := 0
    SetTimer(CleanSelf, -1)
}

;###################[ Launch ]#####################

LaunchCmd() {
    global con, cPID, offset, winCh, cmd_w_fix, CMD_Path

    con := "ahk_class ConsoleWindowClass"

    if (!FileExist(CMD_Path)) {
        if (WelcomeFirstTime)
            MsgBoxTop("There is no Cmd path currently set.`nQonsole will set it up for you.", AppName " - Version " Version, 0x40)
        else
            MsgBoxTop("The Cmd path is invalid.`nQonsole will set it up for you.", AppName " - Error", 0x30)
        newLnk := A_ScriptDir "\cmd_Qonsole.lnk"
        created := false
        try {
            FileCreateShortcut(A_ComSpec, newLnk)
            created := FileExist(newLnk)
        }
        CMD_Path := created ? newLnk : A_ComSpec
        IniWrite(CMD_Path, configFile, "Settings", "CMD_Path")
    }

    exe := CMD_Path
    extraArgs := ""
    SplitPath(CMD_Path, , , &ext)
    ext := StrLower(ext)
    if (ext = "lnk") {
        target := "", sargs := ""
        try
            FileGetShortcut(CMD_Path, &target, , &sargs)
        if (target != "") {
            exe := target
            extraArgs := sargs
        }
    } else if (ext = "bat" || ext = "cmd" || ext = "vbs") {
        exe := A_ComSpec
        extraArgs := '/k "' CMD_Path '"'
    }

    before := Map()
    for h in WinGetList("ahk_class ConsoleWindowClass")
        before[h] := true

    ; conhost.exe forces a classic console window even when Windows Terminal is
    ; the default terminal application.
    try
        Run('conhost.exe "' exe '" ' extraArgs ' ' CMD_StartUpArgs, , , &launchPid)
    catch
        return false

    hwnd := 0
    Loop 60 {
        Sleep(100)
        for h in WinGetList("ahk_class ConsoleWindowClass") {
            if !before.Has(h) {
                hwnd := h
                break 2
            }
        }
    }
    if (!hwnd)
        return false

    con := "ahk_id " hwnd
    cPID := WinGetPID(con)
    WinWaitActive(con, , 3)

    ; Park the window well above the screen before resizing. The final height is
    ; not known yet, and leaving it partially visible makes the slide jump.
    WinMove(0, -(xC_height + 200), , , con)

    hc := hwnd
    RemoveTaskbarButton(hc)

    attached := AttachConsole(cPID)
    if (attached) {
        ; Nerd Font glyphs (Powerline prompts) need a face that has them; if the
        ; configured face is absent, the console keeps its current font.
        SetConsoleFont(Console_Font, Console_FontSize)
        cw := 0, chh := 0
        if (GetConsoleSize(&cw, &chh))
            SetConsoleSize(cw, chh)
    }

    winW := CMD_Width + 50
    tbarH := DllCall("GetSystemMetrics", "Int", 4)
    WinMove(, , winW, xC_height + tbarH, con)

    WindowDesign(hc)

    if (attached)
        FreeConsole()

    try
        WinGetPos(, , , &winCh, con)
    catch
        return false
    winCh := winCh + 2
    ; Offset must use the final window height, otherwise a console configured
    ; taller than the shell's default window cannot slide fully off-screen.
    offset := Mod(winCh, Speed) - winCh + Speed
    WinMove(0, offset, , , con)
    cmd_w_fix := winW
    return true
}

LaunchMintty() {
    global con, cPID, cmd_w_fix, winCh, xC_height, Mintty_path

    con := "ahk_class mintty"

    if (!FileExist(Mintty_path)) {
        r := MsgBoxTop("mintty was not found.`nBrowse for mintty.exe?", AppName " - Error", 0x34)
        if (r = 6) {
            p := BrowseForConsole("mintty")
            if (p != "" && FileExist(p)) {
                Mintty_path := p
                IniWrite(p, configFile, "Settings", "Mintty_path")
            }
        }
    }
    if (!FileExist(Mintty_path)) {
        MsgBoxTop("mintty was not found. Cmd mode will be used.", AppName " - Error", 0x30)
        return false
    }

    try
        Run('"' Mintty_path '" ' CMD_StartUpArgs, , , &launchPid)
    catch
        return false
    cPID := launchPid

    if (!WinWait(con, , 5))
        return false
    WinWaitActive(con, , 5)

    WinSetAlwaysOnTop(1, con)
    cmd_height__ := -xC_height

    ; hide the window border
    WinSetStyle("-0x40000", con)
    WinSetStyle("-0x80000", con)
    WinSetStyle("-0x200000", con)
    WinSetStyle("-0xC00000", con)
    WinSetStyle("-0x800000", con)
    WinSetStyle("-0x400000", con)

    WinMove(, cmd_height__, CMD_Width, xC_height, "ahk_pid " launchPid)
    WinMove(, cmd_height__, CMD_Width, xC_height, con)

    try
        WinGetPos(, , &cw_w, &ch, con)
    catch
        return false

    hc := WinGetID(con)
    con := "ahk_id " hc
    cmd_w_fix := cw_w
    WinMove(, , , ch - 14, con)
    winCh := ch - 14
    xC_height -= 14
    return true
}

RemoveTaskbarButton(hwnd) {
    static IID_ITaskbarList := "{56FDF342-FD6D-11d0-958A-006097C9A090}"
    try {
        tbl := ComObject("{56FDF344-FD6D-11d0-958A-006097C9A090}", IID_ITaskbarList)
        ComCall(3, tbl)                  ; HrInit
        ComCall(5, tbl, "Ptr", hwnd)     ; DeleteTab
    }
}

;###################[ Background dimmer ]#####################

CreateGuiBGDarken() {
    global guiBGDarken, hGuiBGDarken

    vLeft := DllCall("GetSystemMetrics", "Int", 76)
    vTop := DllCall("GetSystemMetrics", "Int", 77)
    vWidth := DllCall("GetSystemMetrics", "Int", 78)
    vHeight := DllCall("GetSystemMetrics", "Int", 79)

    g := Gui("+E0x20 -Caption +ToolWindow +AlwaysOnTop", "Qonsole_GuiBGDarken")
    try
        g.BackColor := RegExReplace(GuiBGDarken_Color, "i)^0x", "")
    catch
        g.BackColor := "1A1A1A"
    g.Show("x" vLeft " y" vTop " w" vWidth " h" vHeight)
    WinSetTransparent(0, "ahk_id " g.Hwnd)

    guiBGDarken := g
    hGuiBGDarken := g.Hwnd
}

WinFade(w := "", t := 128, i := 1, d := 10) {
    if (w = "") {
        h := WinActive("A")
        if (!h)
            return
        w := "ahk_id " h
    }
    t := (t > 255) ? 255 : (t < 0) ? 0 : t
    s := WinGetTransparent(w)
    if (s = "")
        s := 255
    WinSetTransparent(s, w)

    i := (s < t) ? Abs(i) : -Abs(i)
    Loop {
        if (i < 0) {
            if (s <= t)
                break
        } else {
            if (s >= t || !WinExist(w))
                break
        }
        s := WinGetTransparent(w)
        if (s = "")
            s := 255
        s += i
        WinSetTransparent(s, w)
        Sleep(d)
    }
}

;###################[ Console window design ]#####################

WindowDesign(WindowHWND) {
    WinSetTransparent(Round((Abs(100 - TransparencyPercent) / 100) * 255), "ahk_id " WindowHWND)
    WinSetAlwaysOnTop(1, "ahk_id " WindowHWND)

    ; The borderless trick from quahke-console.
    ; Each style must be passed in its own call (v2 applies a single token per call).
    WinSetStyle("-0x80000000", "ahk_id " WindowHWND)
    WinSetStyle("-0xC00000", "ahk_id " WindowHWND)
    WinSetStyle("-0x40000", "ahk_id " WindowHWND)
    WinSetExStyle("-0x200", "ahk_id " WindowHWND)
    WinSetExStyle("+0x80", "ahk_id " WindowHWND)
    WinSetExStyle("-0x40000", "ahk_id " WindowHWND)

    fw := 0, fh := 0
    if (!GetFontSize(&fw, &fh) || !fh)
        return
    cw := 0, ch := 0
    if (!GetConsoleSize(&cw, &ch))
        return

    try
        WinGetPos(, , , &winFH, "ahk_id " WindowHWND)
    catch
        return

    tbarH := DllCall("GetSystemMetrics", "Int", 4)
    winBH := DllCall("GetSystemMetrics", "Int", 31)
    dlines := Ceil(((winFH - tbarH) - winBH) / fh)
    RectX := fw * cw + 2 - 2
    RectY := fh * dlines + 2 - 2

    _scale := A_ScreenDPI / 96
    RectX *= _scale
    RectY *= _scale

    RectX += WinTenPlus
    RectY += WinTenPlus
    if (InStr(Console_Mode, "Cmd")) {
        RectY -= fh
    } else if (((winFH - RectY) < 39) || ((CMD_Height - RectY) < 16)) {
        RectY += (fh * 3)
    }

    WinSetRegion("0-0 w" Round(RectX) " h" Round(RectY), "ahk_id " WindowHWND)
    WinRedraw("ahk_id " WindowHWND)
}

; Modern-like exponential movement - inspired by quahke.
WinSlideDownExp(Wintitle, Delay, spd, fy, dx) {
    global anim

    if (AnimationDisabled) {
        WinMove(, Round(Abs(fy)), , , Wintitle)
        anim := 0
        return
    }

    anim := -1
    tau := 8 * ATan(1)
    try
        WinGetPos(, &y, , , Wintitle)
    catch
        return

    ; The exponential term decays to zero, so keep a minimum step proportional
    ; to the distance; a fixed 1px step makes tall consoles crawl or stall.
    distance := Abs(fy - y)
    minStep := Max(1, distance / 40)

    while (y < (fy - 1)) {
        if !WinExist(Wintitle)
            return
        if (anim = 1)
            return
        WinGetPos(, &y, , , Wintitle)
        inc := (spd * (-(1 - Exp((Abs(dx) - A_Index) / tau)) + 1)) + 1
        if (inc < minStep)
            inc := minStep
        b := y + inc
        if (b > fy)
            WinMove(, Round(Abs(y - fy) + y), , , Wintitle)
        else
            WinMove(, Round(b), , , Wintitle)
        if (Delay)
            Sleep(Delay)
        if (b >= fy)
            break
    }
    anim := 0
}

WinSlideUpExp(Wintitle, Delay, spd, fy, dx) {
    global anim

    if (AnimationDisabled) {
        WinMove(, Round(fy), , , Wintitle)
        anim := 0
        return
    }

    anim := 1
    tau := 8 * ATan(1)
    try
        WinGetPos(, &y, , , Wintitle)
    catch
        return

    ; See WinSlideDownExp: -1 here would move the window backwards and spin forever.
    distance := Abs(fy - y)
    minStep := Max(1, distance / 40)

    while (y > (fy + 1)) {
        if (anim = -1)
            return
        if !WinExist(Wintitle)
            return
        WinGetPos(, &y, , , Wintitle)
        inc := (spd * (-(1 - Exp((Abs(dx) - A_Index) / tau)) + 1)) - 1
        if (inc < minStep)
            inc := minStep
        b := y - inc
        if (b <= fy) {
            WinMove(, Round(fy), , , Wintitle)
            break
        }
        if (b <= y)
            WinMove(, Round(b), , , Wintitle)
        if (Delay)
            Sleep(Delay)
    }
    anim := 0
}

;###################[ Settings ]#####################

ShowProgramSettings(*) {
    global settingsGui, SettingsCtl

    if IsObject(settingsGui) {
        WinActivate(AppName " Settings")
        return
    }

    CMD_PathS := CMD_Path
    Mintty_pathS := Mintty_path

    g := Gui(, AppName " Settings")
    settingsGui := g
    g.OnEvent("Close", SettingsGuiClose)
    g.OnEvent("Escape", SettingsGuiClose)

    g.AddButton("x12 y20 w100 h20", "Console Settings").OnEvent("Click", ShowConsoleSettings)

    WinKey := InStr(OpenHotkey, "#") ? 1 : 0
    cbWinKey := g.AddCheckBox("x12 y40 w80 h20" (WinKey ? " Checked" : ""), "Windows... +")

    OpenHotkeyX := StrReplace(OpenHotkey, "#")
    hk := g.AddHotkey("x102 y40 w60 h20", OpenHotkeyX)
    g.AddEdit("x102 y60 w60 h20")
    upTransparency := g.AddUpDown("Range0-100", TransparencyPercent)
    g.AddText("x16 y64 w80 h20", "Transparency %")

    g.AddText("x170 y24 w75 h16", "Cmd Path")
    g.AddText("x190 y44 w50 h16", "Mintty Path")
    g.AddButton("x250 y20 w80 h20", "Browse...").OnEvent("Click", BrowseCmd_Click)
    g.AddButton("x250 y40 w80 h20", "Browse...").OnEvent("Click", BrowseMintty_Click)

    g.AddText("x172 y83 w70 h16", "Console Mode")
    ddMode := g.AddDropDownList("x246 y82 w80 h20", ["Cmd", "Mintty"])

    WidthMax := A_ScreenWidth + 8
    g.AddText("x12 y85 h20", "Width (approx. in px)")
    g.AddEdit("x+4 yp-3 w55 h20")
    upWidth := g.AddUpDown("Range24-" WidthMax, CMD_Width)

    HeightMax := A_ScreenHeight + 8
    g.AddText("x9 y+5 h20", "Height (approx. in px)")
    g.AddEdit("x+4 yp-3 w55 h20")
    upHeight := g.AddUpDown("Range24-" HeightMax, CMD_Height)

    cbCentered := g.AddCheckBox("x+12 yp h20" (HorizontallyCentered ? " Checked" : ""), "Centered")
    cbBottom := g.AddCheckBox("x+12 yp h20" (BottomPlaced ? " Checked" : ""), "Bottom")

    g.AddText("x16 yp+26", "Start Up Arguments")
    editArgs := g.AddEdit("x+4 yp-2 h20 w214", CMD_StartUpArgs)

    g.AddText("x16 yp+26", "Vertical offset/margin (px)")
    g.AddEdit("x+4 yp-3 w55 h20")
    upOffset := g.AddUpDown("Range-100-100", CMD_offset)

    g.AddGroupBox("x4 y4 w330 h175", "Console Settings")

    ;------------- Animation -------------
    g.AddGroupBox("x4 y+2 w330 h44", "Animation Settings")
    g.AddText("xp+12 yp+20 w36 h20", "Speed")
    g.AddEdit("x+0 yp-3 w60 h20")
    upSpeed := g.AddUpDown("Range1-100", Speed)
    g.AddText("xp+76 yp+3 w30 h20", "Delay")
    g.AddEdit("x+4 yp-3 w60 h20")
    upDelay := g.AddUpDown("Range0-1000", Delay)
    g.AddText("xp+74 yp+3 w16 h20", "dx")
    g.AddEdit("x+0 yp-3 w60 h20")
    upDx := g.AddUpDown("Range0-100", dx)

    ;------------- Background -------------
    g.AddGroupBox("x4 y+8 w330 h62", "Background Settings")
    g.AddText("x16 yp+20 h20", "BG Color")
    editBG := g.AddEdit("x+4 yp-3 w52 h20 Uppercase", StrUpper(RegExReplace(GuiBGDarken_Color, "i)^0x")))
    editBG.OnEvent("Change", GuiSettingColor)
    BGMaxPc := Round((Abs(255 - GuiBGDarken_Max) / 255) * 100)
    g.AddText("x+4 yp+3 h20", "Transparency %")
    g.AddEdit("x+4 yp-3 w44 h20")
    upBGMax := g.AddUpDown("Range0-100", BGMaxPc)
    g.AddText("x+6 yp+3 h20", "Speed")
    g.AddEdit("x+4 yp-3 w44 h20")
    upBGInc := g.AddUpDown("Range1-100", GuiBGDarken_Increment)

    g.SetFont("italic underline c666666")
    g.AddText("x4 y+3 w330 h20 Center BackgroundTrans", "Note: Set the Transparency to '100%' to Disable the Background")
    g.SetFont()

    ;------------- Other -------------
    g.AddGroupBox("x4 y+8 w330 h70", "Other Settings")
    cbRunStartup := g.AddCheckBox("x16 yp+16 h20" (RunOnStartUp ? " Checked" : ""), "Run " AppName " when Windows Starts")
    cbAnimDisabled := g.AddCheckBox("x+8 yp h20" (AnimationDisabled ? " Checked" : ""), "Disable Animation")
    cbCmdPaste := g.AddCheckBox("x16 y+4 h20" (CmdPaste ? " Checked" : ""), "Enable Console Ctrl+V Pasting")
    cbHideInactive := g.AddCheckBox("x+29 yp h20" (HideOnInActive ? " Checked" : ""), "Hide when inactive")
    cbReduceMem := g.AddCheckBox("x16 y+4 h20" (ReduceMemory ? " Checked" : ""), "Reduce Memory Usage")
    cbAutoWinActivate := g.AddCheckBox("x+64 yp h20 Disabled" (AutoWinActivate ? " Checked" : ""), "Auto WinActivate")

    g.AddButton("x62 y+14 w100 h30 Default", "&Save").OnEvent("Click", GuiSave)
    g.AddButton("x+100 yp w100 h30", "&Cancel").OnEvent("Click", SettingsGuiClose)

    SettingsCtl := {
        WinKey: cbWinKey, Hotkey: hk, Transparency: upTransparency,
        Width: upWidth, Height: upHeight, Centered: cbCentered, Bottom: cbBottom,
        Args: editArgs, Offset: upOffset, Speed: upSpeed, Delay: upDelay, Dx: upDx,
        BGColor: editBG, BGMax: upBGMax, BGInc: upBGInc,
        RunStartup: cbRunStartup, AnimDisabled: cbAnimDisabled, CmdPaste: cbCmdPaste,
        HideInactive: cbHideInactive, ReduceMem: cbReduceMem, AutoWinActivate: cbAutoWinActivate,
        Mode: ddMode, PathCMD: CMD_PathS, PathMintty: Mintty_pathS
    }

    g.Show("w338")
    ddMode.Choose((Console_Mode = "Mintty") ? 2 : 1)
    SetEditPlaceholder(editArgs, "...to be appended when run/launched...")
}

BrowseCmd_Click(*) {
    p := BrowseForConsole("Cmd")
    if (p != "")
        SettingsCtl.PathCMD := p
}

BrowseMintty_Click(*) {
    p := BrowseForConsole("Mintty")
    if (p != "")
        SettingsCtl.PathMintty := p
}

GuiSettingColor(*) {
    v := SettingsCtl.BGColor.Value
    if (v = "")
        return
    v := RegExReplace(v, "i)^0x", "")
    if (!RegExMatch(v, "^[0-9A-Fa-f]{1,6}$"))
        return
    SettingsCtl.BGColor.Value := Format("{:X}", HexToInt(v))
}

GuiSave(*) {
    global OpenHotkey

    hot := SettingsCtl.Hotkey.Value
    if (SettingsCtl.WinKey.Value)
        hot := "#" hot
    if (hot != "" && hot != "#")
        OpenHotkey := hot

    SpeedV := SettingsCtl.Speed.Value
    DelayV := SettingsCtl.Delay.Value
    DxV := SettingsCtl.Dx.Value
    HideOnInActiveV := SettingsCtl.HideInactive.Value
    HorizontallyCenteredV := SettingsCtl.Centered.Value
    BottomPlacedV := SettingsCtl.Bottom.Value
    AnimationDisabledV := SettingsCtl.AnimDisabled.Value
    CmdPasteV := SettingsCtl.CmdPaste.Value
    AutoWinActivateV := SettingsCtl.AutoWinActivate.Value
    ReduceMemoryV := SettingsCtl.ReduceMem.Value
    RunOnStartUpV := SettingsCtl.RunStartup.Value
    ModeV := (SettingsCtl.Mode.Value = 2) ? "Mintty" : "Cmd"
    TransparencyV := SettingsCtl.Transparency.Value
    WidthV := SettingsCtl.Width.Value
    HeightV := SettingsCtl.Height.Value
    ArgsV := SettingsCtl.Args.Value
    OffsetV := SettingsCtl.Offset.Value
    BGIncV := SettingsCtl.BGInc.Value
    BGMaxV := Abs(255 - Round((SettingsCtl.BGMax.Value / 100) * 255))
    bgTxt := RegExReplace(SettingsCtl.BGColor.Value, "i)^0x", "")
    BGColorV := (bgTxt = "") ? GuiBGDarken_Color : "0x" SubStr(StrUpper(bgTxt), 1, 6)
    CMD_PathV := SettingsCtl.PathCMD
    Mintty_pathV := SettingsCtl.PathMintty

    IniWrite(SpeedV, configFile, "Animation", "Speed")
    IniWrite(DelayV, configFile, "Animation", "Delay")
    IniWrite(DxV, configFile, "Animation", "dx")
    IniWrite(HideOnInActiveV, configFile, "Settings", "HideOnInActive")
    IniWrite(HorizontallyCenteredV, configFile, "Settings", "HorizontallyCentered")
    IniWrite(BottomPlacedV, configFile, "Settings", "BottomPlaced")
    IniWrite(AnimationDisabledV, configFile, "Animation", "AnimationDisabled")
    IniWrite(CmdPasteV, configFile, "Settings", "CmdPaste")
    IniWrite(AutoWinActivateV, configFile, "Settings", "AutoWinActivate")
    IniWrite(ReduceMemoryV, configFile, "Settings", "ReduceMemory")
    IniWrite(RunOnStartUpV, configFile, "Settings", "RunOnStartUp")
    SetAutorun(RunOnStartUpV)
    IniWrite(ModeV, configFile, "Settings", "Console_Mode")
    IniWrite(TransparencyV, configFile, "Settings", "TransparencyPercent")

    if (FileExist(CMD_PathV)) {
        SplitPath(CMD_PathV, , , &cmdExt, &cmdName)
        if (cmdExt = "lnk") {
            IniWrite(CMD_PathV, configFile, "Settings", "CMD_Path")
        } else {
            CMD_PathV := A_ScriptDir "\" cmdName "_Qonsole.lnk"
            try
                FileCreateShortcut(SettingsCtl.PathCMD, CMD_PathV)
            IniWrite(CMD_PathV, configFile, "Settings", "CMD_Path")
        }
    }
    if (FileExist(Mintty_pathV))
        IniWrite(Mintty_pathV, configFile, "Settings", "Mintty_path")

    IniWrite(OpenHotkey, configFile, "Settings", "OpenHotkey")
    IniWrite(WidthV, configFile, "Settings", "CMD_Width")
    IniWrite(HeightV, configFile, "Settings", "CMD_Height")
    IniWrite(ArgsV, configFile, "Settings", "CMD_StartUpArgs")
    IniWrite(OffsetV, configFile, "Settings", "CMD_offset")
    IniWrite(BGIncV, configFile, "Animation", "GuiBGDarken_Increment")
    IniWrite(BGMaxV, configFile, "Animation", "GuiBGDarken_Max")
    IniWrite(BGColorV, configFile, "Animation", "GuiBGDarken_Color")

    SettingsGuiClose()

    r := MsgBoxTop("A restart is needed to appropriately apply the new settings.`n`tWould you like to restart the program now?", AppName " Settings", 0x44)
    if (r = 6)
        ReloadApp()
}

SettingsGuiClose(*) {
    global settingsGui, SettingsCtl

    if IsObject(settingsGui) {
        settingsGui.Destroy()
        settingsGui := ""
    }
    SettingsCtl := ""
}

BrowseForConsole(name) {
    ; v2 renamed FileSelectFile to FileSelect and reordered Root before Title.
    tmp := FileSelect("3", A_ScriptDir, name " Path", "Files (*.exe; *.lnk; *.bat; *.com; *.vbs)")
    if (tmp = "")
        return ""
    SplitPath(tmp, , , &ext)
    if (ext = "lnk") {
        target := ""
        try
            FileGetShortcut(tmp, &target)
        return target
    }
    return tmp
}

;###################[ About ]#####################

ShowAbout(*) {
    global aboutGui

    if IsObject(aboutGui) {
        WinActivate("About " AppName)
        return
    }

    g := Gui("+ToolWindow -Caption +AlwaysOnTop", "About " AppName)
    g.OnEvent("Escape", AboutGuiClose)
    g.BackColor := "333333"
    aboutGui := g

    if (A_IsCompiled) {
        try
            g.AddPicture("x2 y2 w48 h48 Icon1", A_ScriptFullPath)
    } else {
        g.AddPicture("x2 y2 w48 h48", A_ScriptDir "\logo\Qonsole_sm2.ico")
    }

    g.SetFont("s16 c00FF00", "Segoe UI Light")
    g.AddText("x+2 yp+4", "Qonsole")
    g.SetFont("s8 cFFFFFF", "Segoe UI")
    g.AddText("xp+2 y+4", "Version " Version " (" App_date ")`nBy Joe DF")
    g.AddText("xp yp+30", "Proudly under the MIT License")
    g.Show("w218 h92")

    EnableGuiDrag(g)
    WinWaitNotActive("ahk_id " g.Hwnd)
    AboutGuiClose()
}

AboutGuiClose(*) {
    global aboutGui

    if IsObject(aboutGui) {
        aboutGui.Destroy()
        aboutGui := ""
    }
}

EnableGuiDrag(g) {
    WinGetPos(, , &w, &h, "ahk_id " g.Hwnd)
    cover := g.AddText("x0 y0 w" w " h" h " BackgroundTrans", "")
    cover.OnEvent("Click", (*) => PostMessage(0xA1, 2, 0, , "ahk_id " g.Hwnd))
}

;###################[ Console settings / update / tray ]#####################

ShowConsoleSettings(*) {
    if (Console_Mode = "Mintty") {
        if (!cShown)
            ToggleConsole()
        aKeyD := A_KeyDelay
        aCtrlD := A_ControlDelay
        SetKeyDelay(-1)
        SetControlDelay(-1)
        ControlClick("", con, "Right")
        ControlSend("O", , con)
        SetKeyDelay(aKeyD)
        SetControlDelay(aCtrlD)
        WinWaitActive("ahk_class ConfigBox", , 5)
        WinWaitClose("ahk_class ConfigBox", , 5)
    } else {
        ShowProperties(CMD_Path)
    }
}

ShowProperties(file) {
    oldMode := A_TitleMatchMode
    SetTitleMatchMode(2)
    fn := ""
    SplitPath(file, &fn)
    try
        Run('properties "' file '"')
    catch {
        SetTitleMatchMode(oldMode)
        return 0
    }
    WinWaitActive(fn " Properties", , 5)
    WinWaitClose(fn " Properties", , 5)
    SetTitleMatchMode(oldMode)
    return 1
}

UpdateCheck(*) {
    global Check4Update_hidden_fail

    tempUpdate := A_Temp "\" AppName "_update" A_Now A_MSec A_TickCount ".tmp"
    NewVersion := ""
    __URL := ""

    try {
        err := Download(Update_URL, tempUpdate)
        if (err != "" || !FileExist(tempUpdate))
            throw Error(err != "" ? err : "download failed")
        NewVersion := IniRead(tempUpdate, "Update", "Version", "")
        __URL := IniRead(tempUpdate, "Update", "URL", "")
    } catch {
        NewVersion := ""
    }
    try
        FileDelete(tempUpdate)

    if (NewVersion = "" || InStr(NewVersion, "NULL") || InStr(NewVersion, "Error")) {
        if (CheckUpdate_hide)
            Check4Update_hidden_fail := 1
        else
            MsgBoxTop("An error occurred.`nPlease check your internet connection and try again.", AppName " - Update", 0x30)
        return
    }

    if (VerCompare(NewVersion, Version) > 0) {
        if (CheckUpdate_hide) {
            Check4Update_hidden_fail := 0
            try
                A_TrayMenu.Rename("Check for update", "Update available...")
            A_IconTip := AppName " v" Version "`nUpdate available..."
        } else {
            r := MsgBoxTop("A new version is available.`nCurrent Version: `t" Version "`nLatest Version: `t" NewVersion "`nWould you like to update?", AppName " - Update", 0x44)
            if (r = 6)
                Run(__URL)
        }
    } else {
        if (CheckUpdate_hide)
            Check4Update_hidden_fail := 0
        else
            MsgBoxTop("You have the latest version.", AppName " - Update", 0x40)
    }
}

UpdateCheckHidden(*) {
    global CheckUpdate_hide, Check4Update_hidden_fail

    if (Check4Update_hidden_fail) {
        CheckUpdate_hide := 1
        UpdateCheck()
        CheckUpdate_hide := 0
    }
}

ReloadApp(*) {
    CloseConsole()
    Reload()
}

QuitApp(*) {
    CloseConsole()
    ExitApp()
}

AppExit(ExitReason, ExitCode) {
    CloseConsole()
}

;###################[ Helpers ]#####################

PasteHotkey(*) {
    if WinActive("ahk_class ConsoleWindowClass")
        SendInput("{Raw}" A_Clipboard)
}

ConsoleScrollBottom(chwnd) {
    ControlSend("{End}", , chwnd)
}

SetEditPlaceholder(ctrl, text) {
    SendMessage(0x1501, 0, StrPtr(text), ctrl)
}

SetAutorun(query) {
    lnk := A_Startup "\" AppName ".lnk"
    if (query) {
        try
            FileCreateShortcut(A_ScriptFullPath, lnk, A_WorkingDir)
    } else {
        try
            FileDelete(lnk)
    }
}

CleanSelf(*) {
    if (ReduceMemory)
        EmptyMem()
}

EmptyMem() {
    pid := DllCall("GetCurrentProcessId", "UInt")
    h := DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "UInt", pid, "Ptr")
    if (h) {
        DllCall("SetProcessWorkingSetSize", "Ptr", h, "Ptr", -1, "Ptr", -1)
        DllCall("CloseHandle", "Ptr", h)
    }
}

Num(v, def := 0) {
    return IsNumber(v) ? v + 0 : def
}

HexToInt(hex) {
    static digits := "0123456789ABCDEF"
    hex := StrUpper(Trim(RegExReplace(hex, "i)^0x", "")))
    n := 0
    for ch in StrSplit(hex) {
        d := InStr(digits, ch) - 1
        if (d < 0)
            continue
        n := n * 16 + d
    }
    return n
}

MsgBoxTop(text, title, flags := 0x40) {
    return DllCall("MessageBoxW", "Ptr", 0, "Str", text, "Str", title, "UInt", flags | 0x40000 | 0x10000, "Int")
}
