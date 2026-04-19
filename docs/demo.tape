# VHS recipe for the first-principles-review hero asset.
# Regenerate with:   vhs docs/demo.tape
# Requires VHS (brew install vhs) and ffmpeg.
# Outputs: docs/hero.gif

Output docs/hero.gif

Set Theme "Dracula"
Set FontSize 13
Set Width 1200
Set Height 860
Set Padding 30
Set TypingSpeed 25ms

Hide
Type "clear"
Enter
Show

Sleep 400ms
Type "bash docs/demo-session.sh"
Sleep 300ms
Enter
Sleep 16s
