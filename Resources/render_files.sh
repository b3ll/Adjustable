#!/bin/bash

rm -f DemoVideo.gif || true
rm -f DemoVideo-50.mp4 || true

ffmpeg -i DemoVideo.mp4 -filter:v fps=50 DemoVideo-50.mp4

gifski --fps 50 --width 1178 --height 2556 --extra --quality 100 --motion-quality 100 --lossy-quality 100 --repeat 0 -o DemoVideo.gif DemoVideo-50.mp4
