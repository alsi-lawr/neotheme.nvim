# VHS fork: https://github.com/alsi-lawr/vhs/tree/feat/xterm6-capture-modes
Output docs/assets/neotheme-palette-editor.webp

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

Set Framerate 30
Set PlaybackSpeed 1
Set TypingSpeed 95ms
Set CursorBlink false

Hide
Type@1ms "rm -rf .agent-workspace/vhs-palette-editor && mkdir -p .agent-workspace/vhs-palette-editor/state && XDG_STATE_HOME=$PWD/.agent-workspace/vhs-palette-editor/state nvim --clean -u docs/vhs/neotheme-palette-editor.lua"
Enter
Sleep 1.5s
Show
Sleep 1s

# Open the three-panel workspace on a persistent Full user theme.
Type ":NeothemePalette"
Enter
Sleep 2.5s

# Move to Themes, then hold on the explicit Simplified/Full choice.
Type "2"
Sleep 2s
Type "a"
Sleep 2s
Type "1"
Enter
Sleep 1s

# Name the new Simplified source at a readable typing pace.
Type "atelier-compact"
Enter
Sleep 3s

# Inspect the compact Syntax roles, edit a colored token, and watch the private preview.
Type "3"
Sleep 2.5s
Down 2
Type "0f#ciW"
Type "#ffaf5f"
Escape
Sleep 3.5s

# Commit through the confirmation prompt, retaining a long result hold.
Type "C"
Sleep 2s
Enter
Sleep 2.5s

# Return to the navigator and open the existing Full source for comparison.
Ctrl+H
Sleep 1.5s
Down
Sleep 2s
Type "e"
Sleep 3s
Type "4"
Sleep 2.5s
Type "7"
Sleep 3s

# Close cleanly and leave the persistent-theme context visible.
Type "q"
Sleep 2.5s
