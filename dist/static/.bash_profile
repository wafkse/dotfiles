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
    path_component="${PATH_COMPONENTS["$path_index"]}"

    while [[ "$path_component" != "/" ]] && [[ "$path_component" == */ ]]; do
        path_component="${path_component%/}"
    done

    # Empty PATH components mean the current directory. Preserve the existing
    # policy of omitting them rather than allowing them to move during ranking.
    [[ -z "$path_component" ]] && continue

    [[ -n "${PATH_SEEN["$path_component"]+set}" ]] && continue
    PATH_SEEN["$path_component"]=1
    PATH_ORIGINAL_INDEX["$path_component"]="$path_index"

    if [[ -d "$path_component" ]]; then
        path_relative="${path_component#/}"
        IFS=/ read -r -a path_parts <<< "$path_relative"
        path_component_count=0

        for path_part in "${path_parts[@]}"; do
            [[ -n "$path_part" ]] && (( path_component_count += 1 ))
        done

        PATH_COMPONENT_COUNT["$path_component"]="$path_component_count"
        PATH_EXECUTABLE_COUNT["$path_component"]=0

        if [[ "$path_component" == "$HOME" ]]; then
            PATH_HOME_DISTANCE["$path_component"]=0
        elif [[ "$path_component" == "$HOME/"* ]]; then
            home_relative="${path_component#"$HOME"/}"
            IFS=/ read -r -a home_parts <<< "$home_relative"
            home_distance=0

            for path_part in "${home_parts[@]}"; do
                [[ -n "$path_part" ]] && (( home_distance += 1 ))
            done

            PATH_HOME_DISTANCE["$path_component"]="$home_distance"
        else
            # A non-home path ranks after every path contained by $HOME.
            PATH_HOME_DISTANCE["$path_component"]=1000000
        fi

        AVAILABLE_PATH_COMPONENTS+=( "$path_component" )
    else
        # Preserve unavailable components after usable paths without giving them a
        # misleading executable count of zero.
        UNAVAILABLE_PATH_COMPONENTS+=( "$path_component" )
    fi
done

# Count direct executable entries in all usable PATH directories in one GNU find
# pass. -L matches Bash's -f/-x behavior for executable symlinks. Aggregating with
# sort/uniq keeps thousands of directory entries out of Bash itself.
if (( ${#AVAILABLE_PATH_COMPONENTS[@]} )); then
    while IFS= read -r -d '' executable_count_record; do
        if [[ "$executable_count_record" =~ ^[[:space:]]*([0-9]+)[[:space:]](.*)$ ]]; then
            PATH_EXECUTABLE_COUNT["${BASH_REMATCH[2]}"]="${BASH_REMATCH[1]}"
        fi
    done < <(
        find -L -- "${AVAILABLE_PATH_COMPONENTS[@]}" \
            -mindepth 1 -maxdepth 1 -type f -executable -printf '%H\0' \
            | LC_ALL=C sort -z \
            | uniq -zc
    )
fi

# GNU sort performs the same lexicographic ranking as the previous Bash
# insertion sort: home distance, component count, executable count, then the
# component's original PATH position. NUL-delimited records preserve spaces.
while IFS= read -r -d '' path_rank_record; do
    path_rank_record="${path_rank_record#*$'\t'}"
    path_rank_record="${path_rank_record#*$'\t'}"
    path_rank_record="${path_rank_record#*$'\t'}"
    path_rank_record="${path_rank_record#*$'\t'}"
    RANKED_PATH_COMPONENTS+=( "$path_rank_record" )
done < <(
    for path_component in "${AVAILABLE_PATH_COMPONENTS[@]}"; do
        printf '%d\t%d\t%d\t%d\t%s\0' \
            "${PATH_HOME_DISTANCE["$path_component"]}" \
            "${PATH_COMPONENT_COUNT["$path_component"]}" \
            "${PATH_EXECUTABLE_COUNT["$path_component"]}" \
            "${PATH_ORIGINAL_INDEX["$path_component"]}" \
            "$path_component"
    done | LC_ALL=C sort -z -t $'\t' -k1,1n -k2,2n -k3,3n -k4,4n
)

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

    if [[ "$VARIABLE_NAME" =~ ^([Bb][Aa][Rr][Ee]|[Vv][Ii][Ss][Uu][Aa][Ll]):[[:space:]]*([a-zA-Z_][a-zA-Z_0-9]*)$ ]]; then
        VARIABLE_SCOPE="${BASH_REMATCH[1],,}"
        VARIABLE_NAME="${BASH_REMATCH[2]}"

        if [[ "$VARIABLE_SCOPE" = "bare" ]] && [[ "${START_TARGET["BAREBONE"]}" != 1 ]]; then
            continue
        elif [[ "$VARIABLE_SCOPE" = "visual" ]] && [[ "${START_TARGET["DESKTOP"]}" != 1 ]]; then
            continue
        fi
    fi

    EXPORT_LIST+=( "$VARIABLE_NAME" )
    declare "${VARIABLE_NAME}=${VARIABLE_VALUE}"
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
