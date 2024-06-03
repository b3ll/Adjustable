#!/bin/sh

# Thank you http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html#usage

palette="/tmp/palette.png"
filters="fps=50,scale=420:-1:flags=lanczos"

ffmpeg -v warning -i $1 -vf "$filters,palettegen" -y $palette
ffmpeg -v warning -i $1 -i $palette -lavfi "$filters [x]; [x][1:v] paletteuse" -y $2
