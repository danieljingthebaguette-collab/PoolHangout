#!/bin/bash
# Contact sheets of a video, for reading reference or playtest clips without opening every frame: a frame at each
# scene change and at least every few seconds, 16 to a JPG (4 × 4, read left to right, top to bottom), and times.txt
# giving each sheet's frame times. Pull a single frame at full size afterwards for detail:
#   ffmpeg -ss 83.5 -i clip.mov -frames:v 1 frame.png
# Usage: tools/ContactSheet.sh <video> <out-dir> [scene threshold, default 0.25] [most seconds between frames, default 10]
set -euo pipefail
video=$1
out=$2
scene=${3:-0.25}
every=${4:-10}
mkdir -p "$out"
# 5 frames a second is enough to catch screens changing, and makes the scene score compare frames 0.2 s apart
ffmpeg -hide_banner -nostats -loglevel info -hwaccel videotoolbox -i "$video" -an \
	-vf "fps=5,scale=480:-2,select='isnan(prev_selected_t)+gte(t-prev_selected_t,$every)+gt(scene,$scene)*gte(t-prev_selected_t,1)',showinfo,tile=4x4" \
	-fps_mode vfr -q:v 4 "$out/sheet%02d.jpg" 2>"$out/ffmpeg.log"
grep -o 'pts_time:[0-9.]*' "$out/ffmpeg.log" | cut -d: -f2 | awk '
	{ n = NR - 1; if (n % 16 == 0) printf "%ssheet%02d:", (n ? "\n" : ""), n / 16 + 1; printf " %d:%04.1f", $1 / 60, $1 % 60 }
	END { print "" }' >"$out/times.txt"
echo "$(ls "$out"/sheet*.jpg | wc -l | tr -d ' ') sheets, $(grep -c 'pts_time' "$out/ffmpeg.log") frames in $out"
