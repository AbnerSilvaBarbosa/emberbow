#!/bin/zsh
cd -- "${0:A:h}"
if [[ -x "$PWD/.tools/Godot.app/Contents/MacOS/Godot" ]]; then
  engine="$PWD/.tools/Godot.app/Contents/MacOS/Godot"
elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
  engine="/Applications/Godot.app/Contents/MacOS/Godot"
else
  print "Instale Godot 4.5.1 ou superior e abra project.godot."
  exit 1
fi
"$engine" --headless --path "$PWD" --editor --import --quit
exec "$engine" --path "$PWD"
