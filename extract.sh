#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] /dashcam/path /library/path

Source path should have the following structure.

source/path/
  Front/
  Back/

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
    if [[ ! -d $1 ]] ; then
        die "Invalid path: $1"
    fi
}

validate_dashcam_path(){
    validate_path $1

  # TODO: Add proper validation for this
    # normal_found=[[ -d "$1/Event" ]]
    # event_found=[[ -d "$1/Normal" ]]

    # if [[ ! $normal_found && ! $event_found ]] ; then
    #   die "Dashcam: Directory 'Normal' and 'Event' could not be found"
    # fi
}

handle_dashcam_root(){
  dashcam_dir=$1
  library_path=$2
  
  for category_dir in $dashcam_dir/*; do
    notify_path $category_dir
    handle_category_directory $category_dir $library_path
  done
}

# Handle a directory category on the dashcam: ex: Event or Normal
handle_category_directory(){
  front_path=$1/Front
  back_path=$1/Back
  library_path=$2

  if [[ -d $front_path ]]; then
    notify_path $front_path
    handle_camera_directory $front_path $library_path "Front"
  fi

  if [[ -d $back_path ]]; then
    notify_path $back_path
    handle_camera_directory $back_path $library_path "Back"
  fi
}

# Handle a directory that contains files, such as Front/ or Back/ 
# Parms: camera_dir libary_root camera_name
handle_camera_directory(){
  cam_dir=$1
  library_path=$2
 
  for file in $cam_dir/* ; do
    date=$(get_date_for_file $file)
    
    library_date_dir=$library_path/$date
    ensure_directory $library_date_dir

    library_date_camera_dir=$library_date_dir/$3
    ensure_directory $library_date_camera_dir

    handle_file $file $library_date_camera_dir
  done
}

handle_file(){
  file_path=$1
  to_dir=$2

  file_name=${file_path##*/}

  dest_path=$to_dir/$file_name
  if [[ -e $dest_path ]]; then
    source_size=$(get_file_size $file_path)
    dest_size=$(get_file_size $dest_path)

    if [[ $source_size -eq $dest_size ]]; then
      echo "File already copied, skipping: $file_name"
      return 0
    fi
  fi

  echo "Moving $file_path to $to_dir"
  mv $file_path $to_dir
}

ensure_directory(){
    if [[ ! -d $1 ]]; then
      echo "Creating directory $1"
      mkdir $1
    fi
}

get_file_size(){
  echo $(du -k $1 | cut -f1)
}

get_date_for_file(){
  date=$(date -r $1 "+%Y-%m-%d")
  echo $date
}

notify_path(){
  echo "Moving to $1"
}

dashcam_path=${args[0]}
library_path=${args[1]} 

validate_dashcam_path $dashcam_path
validate_path $library_path

shopt -s nullglob 

# Move all stuff to pc library
handle_dashcam_root $dashcam_path $library_path

echo "Done moving all content"