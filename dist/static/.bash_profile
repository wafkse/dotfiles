#!/usr/bin/env bash

declare -A ENVIRONMENT_TABLE=(
    [ARCH]="$( uname -m )"
    [EDITOR]="$( command -v helix vim nano emacs | head -1 )"
    [TERMINAL]="ghostty"
    [SSH_AUTH_SOCK]="$( gpgconf --list-dirs agent-ssh-socket 2> /dev/null )"
    [SSH_AGENT_PID]="$( pgrep "gpg-agent" )"
    [GPG_TTY]="$( tty )"
)

# Inherit previously set $PATH from /etc/profile

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

# shellcheck disable=2207
declare -a DEFAULT_PATH=( $( echo "$PATH" | tr ":" " " ) )

DEFAULT_PATH+=( "${PATH_LIST[*]}" )

# shellcheck disable=2016
AWK_DUPLICATE_REMOVER='
BEGIN {
    RS = ":"
}

{
    sub(sprintf("%c$", 10), "")
    if (A[$0]) {
        # Do nothing
    } else {
        A[$0] = 1
        printf((NR == 1 ? "" : ":") $0)
    }
}
'

ENVIRONMENT_TABLE["PATH"]="$(echo -ne "${DEFAULT_PATH[*]}" | tr -d "\n" | tr "[:space:]" ":" | awk "$AWK_DUPLICATE_REMOVER")"

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
