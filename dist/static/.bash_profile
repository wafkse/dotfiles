#!/usr/bin/env bash

declare -A ENVIRONMENT_TABLE=(
    [ARCH]="$( uname -m )"
    [EDITOR]="$( command -v helix vim nano emacs | head -1 )"
    [TERMINAL]="ghostty"
    [SSH_AUTH_SOCK]="$( gpgconf --list-dirs agent-ssh-socket 2> /dev/null )"
    [SSH_AGENT_PID]="$( pgrep "gpg-agent" )"
    [GPG_TTY]="$( tty )"
)

# Inherit the previously set $PATH from /etc/profile, then rank its components.

# The rank is lexicographic, directories below $HOME come first, then shallower
# home-relative paths, fewer path components, fewer direct executable entries,
# and finally their original PATH order.
declare -a PATH_LIST=( "$HOME/util" "$HOME/.local/bin" )

[ -d "$HOME/games/bin" ] && PATH_LIST+=( "$HOME/games/bin" )

[ -d "$HOME/.lmstudio/bin" ] && PATH_LIST+=( "$HOME/.lmstudio/bin" )

if hash cargo > /dev/null 2>&1; then
    PATH_LIST+=( "$HOME/.cargo/bin" )
fi

if hash luarocks > /dev/null 2>&1; then
    PATH_LIST+=( "$( luarocks path --lr-bin )" )

    ENVIRONMENT_TABLE[LUA_PATH]="$( luarocks path --lr-path )"
    ENVIRONMENT_TABLE[LUA_CPATH]="$( luarocks path --lr-cpath )"
fi

normalize_path_component() {
    local path_component="$1"

    while [[ "$path_component" != "/" ]] && [[ "$path_component" == */ ]]; do
        path_component="${path_component%/}"
    done

    printf '%s' "$path_component"
}

count_path_components() {
    local path_component="${1#/}"
    local -a path_parts=()
    local part
    local count=0

    IFS=/ read -r -a path_parts <<< "$path_component"

    for part in "${path_parts[@]}"; do
        [[ -n "$part" ]] && (( count += 1 ))
    done

    printf '%d' "$count"
}

home_path_distance() {
    local path_component="$1"

    if [[ "$path_component" == "$HOME" ]]; then
        printf '0'
    elif [[ "$path_component" == "$HOME/"* ]]; then
        count_path_components "${path_component#"$HOME"/}"
    else
        # A non-home path ranks after every path contained by $HOME.
        printf '1000000'
    fi
}

count_directory_executables() {
    local directory="$1"
    local entry
    local count=0

    # -f and -x include executable symlinks while avoiding a recursive scan.
    for entry in "$directory"/* "$directory"/.[!.]* "$directory"/..?*; do
        [[ -f "$entry" ]] && [[ -x "$entry" ]] && (( count += 1 ))
    done

    printf '%d' "$count"
}

path_ranks_before() {
    local left="$1"
    local right="$2"

    if (( PATH_HOME_DISTANCE["$left"] != PATH_HOME_DISTANCE["$right"] )); then
        (( PATH_HOME_DISTANCE["$left"] < PATH_HOME_DISTANCE["$right"] ))
        return
    fi

    if (( PATH_COMPONENT_COUNT["$left"] != PATH_COMPONENT_COUNT["$right"] )); then
        (( PATH_COMPONENT_COUNT["$left"] < PATH_COMPONENT_COUNT["$right"] ))
        return
    fi

    if (( PATH_EXECUTABLE_COUNT["$left"] != PATH_EXECUTABLE_COUNT["$right"] )); then
        (( PATH_EXECUTABLE_COUNT["$left"] < PATH_EXECUTABLE_COUNT["$right"] ))
        return
    fi

    (( PATH_ORIGINAL_INDEX["$left"] < PATH_ORIGINAL_INDEX["$right"] ))
}

declare -a INHERITED_PATH=()
declare -a PATH_COMPONENTS=()
declare -a AVAILABLE_PATH_COMPONENTS=()
declare -a UNAVAILABLE_PATH_COMPONENTS=()
declare -a RANKED_PATH_COMPONENTS=()
declare -A PATH_SEEN=()
declare -A PATH_HOME_DISTANCE=()
declare -A PATH_COMPONENT_COUNT=()
declare -A PATH_EXECUTABLE_COUNT=()
declare -A PATH_ORIGINAL_INDEX=()

IFS=: read -r -a INHERITED_PATH <<< "$PATH"
PATH_COMPONENTS=( "${INHERITED_PATH[@]}" "${PATH_LIST[@]}" )

for path_index in "${!PATH_COMPONENTS[@]}"; do
    path_component="$( normalize_path_component "${PATH_COMPONENTS["$path_index"]}" )"

    # Empty PATH components mean the current directory. Do not add or reorder them.
    [[ -z "$path_component" ]] && continue

    [[ -n "${PATH_SEEN["$path_component"]+set}" ]] && continue
    PATH_SEEN["$path_component"]=1

    PATH_ORIGINAL_INDEX["$path_component"]="$path_index"

    if [[ -d "$path_component" ]]; then
        PATH_HOME_DISTANCE["$path_component"]="$( home_path_distance "$path_component" )"
        PATH_COMPONENT_COUNT["$path_component"]="$( count_path_components "$path_component" )"
        PATH_EXECUTABLE_COUNT["$path_component"]="$( count_directory_executables "$path_component" )"
        AVAILABLE_PATH_COMPONENTS+=( "$path_component" )
    else
        # Preserve unavailable components after usable paths without giving them a
        # misleading executable count of zero.
        UNAVAILABLE_PATH_COMPONENTS+=( "$path_component" )
    fi
done

for path_component in "${AVAILABLE_PATH_COMPONENTS[@]}"; do
    path_inserted=0

    for ranked_index in "${!RANKED_PATH_COMPONENTS[@]}"; do
        if path_ranks_before "$path_component" "${RANKED_PATH_COMPONENTS["$ranked_index"]}"; then
            RANKED_PATH_COMPONENTS=(
                "${RANKED_PATH_COMPONENTS[@]:0:ranked_index}"
                "$path_component"
                "${RANKED_PATH_COMPONENTS[@]:ranked_index}"
            )
            path_inserted=1
            break
        fi
    done

    (( path_inserted )) || RANKED_PATH_COMPONENTS+=( "$path_component" )
done

RANKED_PATH_COMPONENTS+=( "${UNAVAILABLE_PATH_COMPONENTS[@]}" )

printf -v PATH_VALUE '%s:' "${RANKED_PATH_COMPONENTS[@]}"
ENVIRONMENT_TABLE["PATH"]="${PATH_VALUE%:}"

# NOTE: Re-export the XDG_* directories as their own environment variables.

if [[ -f "$( realpath -Pm "${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs" )" ]]; then
    eval "$( grep -E "^[A-Z_]+=\"\S+\"$" "${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs" )"

    XDG_DIRECTORY_LIST="$( grep -Eo "^[A-Z_]+" "${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs" | tr "\n" " " )"

    for XDG_DIRECTORY in $XDG_DIRECTORY_LIST; do
        mkdir -vp "${!XDG_DIRECTORY}"
    done

    # NOTE: Word-splitting is required as this emits a sequence of variable names.
    # shellcheck disable=2068
    export ${XDG_DIRECTORY_LIST[@]}

    :
fi

declare -A START_TARGET=(
    [BAREBONE]=0
    [DESKTOP]=0
)

[[ -n "${WAYLAND_DISPLAY}" ]] && [[ "$XDG_VTNR" != 1 ]] && START_TARGET["BAREBONE"]=1

[[ -z "${WAYLAND_DISPLAY}" ]] && [[ -z "$NIRI_SOCKET" ]] && [[ -z "$TMUX" ]] && [[ "$XDG_VTNR" = 1 ]] && START_TARGET["DESKTOP"]=1

declare -a EXPORT_LIST=()

for VARIABLE_NAME in "${!ENVIRONMENT_TABLE[@]}"; do
    VARIABLE_VALUE="${ENVIRONMENT_TABLE["$VARIABLE_NAME"]}"

    if (
        shopt -s nocasematch;
        [[ "$VARIABLE_NAME" =~ ^(bare|visual): ]]
    ); then

        VARIABLE_NAME="$( echo "$VARIABLE_NAME" | grep -Po "(?i)^(bare|visual):\K([a-z_][a-z_0-9]*)$" )"

        EXPORT_LIST+=( "$VARIABLE_NAME" )

        if (
            shopt -s nocasematch;
            [[ "$VARIABLE_NAME" =~ ^bare: ]]
        ) && [[ "${START_TARGET["BAREBONE"]}" = 1 ]]; then
            declare "${VARIABLE_NAME}=${VARIABLE_VALUE}"
        elif (
            shopt -s nocasematch;
            [[ "$VARIABLE_NAME" =~ ^visual: ]]
        ) && [[ "${START_TARGET["DESKTOP"]}" = 1 ]]; then
            declare "${VARIABLE_NAME}=${VARIABLE_VALUE}"
        fi
    else
        EXPORT_LIST+=( "$VARIABLE_NAME" )

        declare "${VARIABLE_NAME}=${VARIABLE_VALUE}"
    fi
done

# NOTE: Export to program environment, the SystemD User Session, and the DBus Activation Environment.

export "${EXPORT_LIST[@]}"

case $- in
  *i*)
    systemctl --user import-environment "${EXPORT_LIST[@]}"

    if hash dbus-update-activation-environment 2>/dev/null; then
        dbus-update-activation-environment --all
    fi

    if [[ "${START_TARGET["DESKTOP"]}" = 1 ]]; then
        systemctl --user reset-failed

        systemctl --user --wait start niri.service

        systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP NIRI_SOCKET

        exit
    elif [[ -n "$SSH_CONNECTION" ]] || [[ -n "$TERMUX_VERSION" ]]; then
        exec bash
    else
        exec tmux new "-As${USER:-default}"
    fi
  ;;
  *) :;;
esac
