#!/bin/sh


proton_dir="$HOME/.steam/steam/steamapps/common/Proton - Experimental" # Change this based on the proton version you need MAKE SURE TO DOWLOAD THEM FIRST!(to do so just dowload them from steam).
compat_data_path="NONE" # Set to none if you dont have a compact data path in hand.
executable_name="FILE.exe" # The game main ".exe" file
extra_flags="" # Add here any extra flag that should get parsed to the game

# NOTE: make sure to set the working directory correctly(cd to/game/files/folder).

# IGNORE THIS UNLESS YOU KNOW WHAT YOU ARE DOING #


config_file="$HOME/.config/proton-game-path.conf"

if [ ! -f "$config_file" ]; then
    echo "NONE" > "$config_file"
fi

current_compat_data_path=$(cat "$config_file")

if [ "$current_compat_data_path" = "NONE" ]; then
    echo "Creating new compat data path..."
    new_compat_data_path="$HOME/.steam/steam/steamapps/compatdata/$(date +%s)/pfx"
    mkdir -p "$new_compat_data_path"
    echo "$new_compat_data_path" > "$config_file"
    compat_data_path="$new_compat_data_path"
fi

if [ ! -d "$proton_dir" ]; then
    echo "Proton Experimental not found at $proton_dir"
    exit 1
fi

if [ ! -d "$compat_data_path" ]; then
  echo "Compat data path not found exiting."
  exit 1
fi

if [ -x "$1" ]; then
    executable_name="$1"
    echo "Target executable: $1"
    shift
fi

if [ -z "${executable_name}" ] || [ ! -x "${executable_name}" ]; then
    echo "Please set executable_name to a valid name in a text editor or as the first command line parameter"
    exit 1
fi

a="/$0"; a=${a%/*}; a=${a#/}; a=${a:-.}; BASEDIR=$(cd "$a" || exit; pwd -P)

abs_path() {
    echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

_readlink() {
    ab_path="$(abs_path "$1")"
    link="$(readlink "${ab_path}")"
    case $link in
        /*);;
        *) link="$(dirname "$ab_path")/$link";;
    esac
    echo "$link"
}

resolve_executable_path() {
    e_path="$(abs_path "$1")"
    while [ -L "${e_path}" ]; do
        e_path=$(_readlink "${e_path}")
    done
    echo "${e_path}"
}

executable_path=$(resolve_executable_path "${executable_name}")
echo "Executable path: ${executable_path}"

doorstop_bool() {
    case "$1" in
        TRUE|true|t|T|1|Y|y|yes)
            echo "1"
        ;;
        FALSE|false|f|F|0|N|n|no)
            echo "0"
        ;;
    esac
}

while :; do
    case "$1" in
        --doorstop_enabled)
            enabled="$(doorstop_bool "$2")"
            shift
        ;;
        --doorstop_target_assembly)
            target_assembly="$2"
            shift
        ;;
        --doorstop-boot-config-override)
            boot_config_override="$2"
            shift
        ;;
        --doorstop-mono-dll-search-path-override)
            dll_search_path_override="$2"
            shift
        ;;
        --doorstop-mono-debug-enabled)
            debug_enable="$(doorstop_bool "$2")"
            shift
        ;;
        --doorstop-mono-debug-suspend)
            debug_suspend="$(doorstop_bool "$2")"
            shift
        ;;
        --doorstop-mono-debug-address)
            debug_address="$2"
            shift
        ;;
        *)
            if [ -z "$1" ]; then
                break
            fi
            rest_args="$rest_args $1"
        ;;
    esac
    shift
done

export DOORSTOP_ENABLED="$enabled"
export DOORSTOP_TARGET_ASSEMBLY="$target_assembly"
export DOORSTOP_IGNORE_DISABLED_ENV="$ignore_disable_switch"
export DOORSTOP_MONO_DLL_SEARCH_PATH_OVERRIDE="$dll_search_path_override"
export DOORSTOP_MONO_DEBUG_ENABLED="$debug_enable"
export DOORSTOP_MONO_DEBUG_ADDRESS="$debug_address"
export DOORSTOP_MONO_DEBUG_SUSPEND="$debug_suspend"

export STEAM_COMPAT_DATA_PATH="$compat_data_path"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.steam/steam"
export PROTON_USE_WINED3D=1
export PROTON_NO_ESYNC=1
export PROTON_NO_FSYNC=1

exec "$proton_dir/proton" run "$executable_path" $rest_args $extra_flags
