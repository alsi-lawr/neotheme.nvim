# VHS fork: https://github.com/alsi-lawr/vhs/tree/feat/xterm6-capture-modes
Output docs/assets/neotheme-browser.webp

Require nvim

Set Shell zsh
Set Theme { "name": "Tomorrow Night Framed", "black": "#000000", "red": "#cc6666", "green": "#b5bd68", "yellow": "#f0c674", "blue": "#81a2be", "magenta": "#b294bb", "cyan": "#8abeb7", "white": "#c5c8c6", "brightBlack": "#666666", "brightRed": "#d54e53", "brightGreen": "#b9ca4a", "brightYellow": "#e7c547", "brightBlue": "#7aa6da", "brightMagenta": "#c397d8", "brightCyan": "#70c0b1", "brightWhite": "#eaeaea", "background": "#34363c", "foreground": "#c5c8c6", "selection": "#51545c", "cursor": "#c5c8c6" }
Set WindowBar ColorfulRight
Set WindowBarSize 16

Set FontFamily "MesloLGS Nerd Font"
Set FontSize 20

Set Width 1600
Set Height 900
Set BorderRadius 9
Set Padding 0
Set Margin 40
Set MarginFill "docs/vhs/window-shadow.png"

Set Framerate 15
Set PlaybackSpeed 1.5
Set TypingSpeed 20ms
Set CursorBlink false

Hide
Type "nvim --clean -u docs/vhs/neotheme-browser.lua"
Enter
Sleep 2s
Show
Sleep 1s

# Drill from the configured Gruber family into Typeset.
Type ":Neotheme"
Enter
Sleep 2s
Down@350ms 2
Sleep 1s
Enter
Sleep 2s

# Preview Typeset's light member locally, then leave the confirmed theme unchanged.
Down
Sleep 2s
Escape
Sleep 2s

# Confirm the light theme with Space, preview the dark member, then close at the checkpoint.
Type ":Neotheme"
Enter
Sleep 1s
Down@250ms 2
Enter
Sleep 1s
Down
Sleep 2s
Space
Sleep 2s
Up
Sleep 2s
Type "q"
Sleep 2s

Type ":NeothemeCurrent"
Enter
Sleep 3s
