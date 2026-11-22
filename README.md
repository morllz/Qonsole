**Disclaimer: This fork and patch for the original Qonsole project is fully AI slopped, I just wanted it to work. I won't support this project in any form.**

# ![*](logo/Qonsole_48sm.png) Qonsole

A Quake-like Console Emulator written in AutoHotkey v2. Configurable with [Cmd](https://en.wikipedia.org/wiki/Cmd.exe) and [mintty](https://mintty.github.io/).
Released under the [MIT License](LICENSE.md).

### Requirements
- Windows 10 or Windows 11
- [AutoHotkey v2.0](https://www.autohotkey.com/) or newer (developed against v2.0.31)

Version 2.0 drops the Windows XP compatibility layer and Console2 support.

### Features
- Custom hotkey
- Slide up & down animation
- Enable Ctrl+v Console pasting
- Transparency options
- Configurable with cmd & mintty
- Background screen dimmer
- Internal Update check (a few seconds after start up)
- Optionally Run Qonsole when Windows Starts
- More..

### Windows 11 notes
Windows 11 sends new console windows to Windows Terminal by default, which does not
expose a classic `ConsoleWindowClass` window. Qonsole therefore launches the shell
through `conhost.exe`, so the console stays a classic console and all Qonsole window
features keep working regardless of the *Default terminal application* setting.

Because the shell is started directly through `conhost.exe`, console appearance stored
inside a `.lnk` shortcut (font, colors) is not applied. Configure the console defaults
for the shell executable instead.

Qonsole applies its own console font after attaching. The settings file supports
`Console_Font` (default `CaskaydiaCove NFM`) and `Console_FontSize` (default `16` pixels).
Prompts that use Nerd Font glyphs (Powerline separators, git icons) need a Nerd Font
installed; otherwise conhost renders those glyphs as `?`. Install a Nerd Font such as
CaskaydiaCove and keep the face name in `Console_Font`, or set it to a face you have.

The default hotkey is still `Win+C`, which also opens Copilot on current Windows 11
builds. Change it in the Qonsole settings if you need Copilot.
