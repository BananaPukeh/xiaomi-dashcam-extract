#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] /raw/library

Raw library should have the following structure

dashcam/
  GT86/
    2021-06-05/
      Front/
        ...
      Back/
        ...

Concatinated library should have the following structure

dashcam/
  GT86/
    GT86 2021-06-05 Front.mp4
    GT86 2021-06-05 Back.mp4
    

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
#   [[ -z "${param-}" ]] && die "Missing required parameter: param"
  [[ ${#args[@]} -lt 2 ]] && die "Missing paths"

  return 0
}

parse_params "$@"
setup_colors

# Script logic


validate_path(){
    if [[ ! -d "$1" ]] ; then
        die "Invalid path: $1"
    fi
}

scan_library(){
    local raw_library_path="$1"
    local concat_library="$2"
    local extension="mp4"

    for car_dir in $raw_library_path/* ; do
        car=${car_dir##*/}
        ensure_directory "$concat_library/$car"
        for date_dir in $car_dir/*; do
            date=${date_dir##*/}
            for camera_dir in $date_dir/*; do
            camera=${camera_dir##*/}
               rel_recording_path=$(get_recording_rel_path "$car" "$date" "$camera" "$extension")

               handle_camera_dir "$camera_dir" "$rel_recording_path" "$concat_library"
            done
        done
    done
}
 
get_recording_rel_path(){
    local car="$1"
    local date="$2"
    local camera="$3"
    local extension="$4"

    echo "$car/$car $date $camera.$extension"
}

handle_camera_dir(){
    local camera_dir="$1"
    local rel_recording_path="$2"
    local concat_library="$3"

    local file_path="$concat_library/$rel_recording_path"

    if [[ -e "$file_path" ]]; then
        echo "Skipping $file_path"
    else
        concat_files "$camera_dir" "$file_path"
    fi
}

concat_files(){
    local directory="$1"
    local output="$2"

    > $list_file

    for f in $(ls -tr "$directory"/*.mp4); do
        echo "file '$f'" >> "$list_file";
    done

    ffmpeg -f concat -safe 0 -i "$list_file" -c copy "$output"
}

ensure_directory(){
    if [[ ! -d "$1" ]]; then
      echo "Creating directory $1"
      mkdir "$1"
    fi
}

shopt -s nullglob 

raw_library=${args[0]}
concat_library=${args[1]} 

validate_path $raw_library
validate_path $concat_library

list_file='.files'

# Go
scan_library "$raw_library" "$concat_library"
