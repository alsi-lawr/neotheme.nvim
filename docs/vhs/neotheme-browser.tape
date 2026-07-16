# Run from the repository root. See docs/vhs/README.md for the exact command.
Output docs/assets/neotheme-browser.webp

Require nvim

Set Shell zsh
Set FontFamily "MesloLGS Nerd Font"
Set FontSize 16
Set Width 1200
Set Height 760
Set TypingSpeed 35ms
Set Framerate 20
Set Theme "Catppuccin Mocha"
Set Padding 12
Set Margin 0
Set CursorBlink false

Type "nvim --clean -u docs/vhs/neotheme-browser.lua"
Enter
Sleep 2s

# Drill from the configured Gruber family into Typeset.
Type ":Neotheme"
Enter
Sleep 2s
Down@350ms 2
Sleep 1s
Enter
Sleep 2s

# Preview Typeset's light member, then cancel the transaction.
Down
Sleep 2s
Escape
Sleep 2s

# Repeat the flow and accept the light theme for this session.
Type ":Neotheme"
Enter
Sleep 1s
Down@250ms 2
Enter
Sleep 1s
Down
Sleep 2s
Enter
Sleep 2s

Type ":NeothemeCurrent"
Enter
Sleep 3s
