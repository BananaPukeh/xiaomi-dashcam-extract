#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] library/path


Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  flag=0
  param=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -f | --flag) flag=1 ;; # example flag
    -p | --param) # example named parameter
      param="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
  [[ ${#args[@]} -lt 1 ]] && die "Missing paths"

  return 0
}

parse_params "$@"
setup_colors

# Script logic

scan_library() {
    local library_path="$1"
    local suffix=" Front.mp4"

    for car_dir in "$library_path"/* ; do       
        for front_vid in "$car_dir"/*"$suffix" ; do
            local basename=${front_vid##*/}
            local basename_without_camera=${basename/%$suffix}

            local mixedname="$basename_without_camera Mixed.mp4"
            local mixed_path="$car_dir/$mixedname"

            local backname="$basename_without_camera Back.mp4"
            local back_path="$car_dir/$backname"


            if [[ -e "$mixed_path" ]]; then
                echo "Skipping $basename, already created"
                elif [[ ! -e "$back_path" ]]; then
                echo "Skipping $basename, no back video"
            else
                echo "Creating $mixed_path"
                merge "$front_vid" "$back_path" "$mixed_path"
            fi
        done
    done
}

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

    ffmpeg  -i "$front" -i "$back" -map 0:a -c:a copy -filter_complex "$rules" -map '[mixed]' -c:v libx264 -crf 23 -preset veryfast "$output"
}

library_path="$1"

scan_library "$library_path"


# front="$1"
# back="$2"
# output="$3"

# validate_path "$front"
# validate_path "$back"

# merge "$front" "$back" "$output"