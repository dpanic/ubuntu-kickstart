# Kickstart TUI Demo
# Recorded with VHS: https://github.com/charmbracelet/vhs

Output demo.gif

Require gum

Set Shell "bash"
Set FontSize 14
Set Width 1100
Set Height 700
Set Padding 20
Set Theme "Catppuccin Mocha"
Set TypingSpeed 50ms
Set Framerate 24

Type "bash main.sh"
Sleep 400ms
Enter

# Wait for banner + update checks + menu
Sleep 7s

# pos=1 GNOME Optimize → select
Space
Sleep 300ms

# pos=2 Nautilus → select
Down
Space
Sleep 300ms

# Down 5: AppArmor(3), spacer(4), Installations(5), zsh(6), fzf(7)
Down 5
Sleep 200ms

# pos=7 fzf → select
Space
Sleep 300ms

# Down 9: starship(8), direnv(9), plugins(10), nvm(11), git(12),
#          spacer(13), byobu(14), ncdu(15), Yazi(16)
Down 9
Sleep 200ms

# pos=16 Yazi → select
Space
Sleep 300ms

# Down 4: spacer(17), Docker(18), Go(19), Neovim(20)
Down 4
Sleep 200ms

# pos=20 Neovim → select
Space
Sleep 1500ms

# Confirm selection
Enter
Sleep 1500ms

# Choose "Install" mode
Enter
Sleep 1500ms

# Decline confirmation
Ctrl+C

Sleep 1s
