#!/usr/bin/env bash


validate_path(){
    if [[ ! -d "$1" ]] ; then
        die "Invalid path: $1"
    fi
}


merge(){
    local front="$1"
    local back="$2"
    local output="$3"

    rules="[0:v]pad=iw*1:ih[front];[1:v]scale=1280:720[back];[front][back]overlay=0:0[mixed]"

    ffmpeg  -i "$front" -i "$back" -map 0:a -c:a copy -filter_complex "$rules" -map '[mixed]' -c:v libx264 -crf 23 -preset ultrafast "$output"
}


front="$1"
back="$2"
output="$3"

validate_path "$front"
validate_path "$back"

merge "$front" "$back" "$output"