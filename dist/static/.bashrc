#!/usr/bin/env bash

declare -A VARIABLE_TABLE=(
    # for pinentry to work inside tmux
    [export:GPG_TTY]="$( tty )"
    # single quotes to avoid expansion
    [PS1]='\[\e[0m\][\[\e[0m\]\u\[\e[0m\]]\[\e[0m\][\[\e[0m\]\W\[\e[0m\]]\n\[\e[0m\]> \[\e[0m\]'
)

for VARIABLE_NAME in "${!VARIABLE_TABLE[@]}"; do
    VARIABLE_VALUE="${VARIABLE_TABLE["$VARIABLE_NAME"]}"

    if (
        shopt -s nocasematch;
        [[ "$VARIABLE_NAME" =~ ^export: ]]
    ); then
        VARIABLE_NAME="$( echo "$VARIABLE_NAME" | grep -Po "(?i)^export:\K([a-z_][a-z_0-9]*)$" )"

        declare "${VARIABLE_NAME}=${VARIABLE_VALUE}"

        export "${VARIABLE_NAME?}"

        continue
    fi

    declare "${VARIABLE_NAME}=${VARIABLE_VALUE}"
done


declare -A PROGRAM_TABLE=(
    [eval:zoxide]="zoxide init bash"
    [eval:starship]="starship init bash"
    # refresh gnupg's target tty
    [gpg-agent]="gpg-connect-agent updatestartuptty /bye > /dev/null 2>&1"
)

for PROGRAM_NAME in "${!PROGRAM_TABLE[@]}"; do
    PROGRAM_COMMAND="${PROGRAM_TABLE["$PROGRAM_NAME"]}"

    PROGRAM_EVALUATE_OUTPUT=0

    if (
        shopt -s nocasematch;
        [[ "$PROGRAM_NAME" =~ ^eval: ]]
    ); then
        PROGRAM_EVALUATE_OUTPUT=1

        PROGRAM_NAME="$( echo "$PROGRAM_NAME" | grep -Po "(?i)^eval:\K([a-z_][a-z_0-9]*)" )"
    fi

    if hash "$PROGRAM_NAME" > /dev/null 2>&1; then
        if [[ "$PROGRAM_EVALUATE_OUTPUT" = 1 ]]; then
            eval "$( $PROGRAM_COMMAND )"
        else
            eval "$PROGRAM_COMMAND"
        fi
    fi
done

declare -A PROGRAM_ALIASES=(
    [cd]="z"
    [ls]="lsd -1 -l --icon never --date relative"
    [cat]="bat"
    [edit]="$EDITOR"
)

for ALIAS_NAME in "${!PROGRAM_ALIASES[@]}"; do
    ALIAS_COMMAND="${PROGRAM_ALIASES["$ALIAS_NAME"]}"

    if hash "$( echo -ne "$ALIAS_COMMAND" | awk '{ print $1 }' )" > /dev/null 2>&1; then
        # NOTE: Explicit shell expansion is required in this case.
        # shellcheck disable=2139
        alias "$ALIAS_NAME"="$ALIAS_COMMAND"
    fi
done

# require argument split
# shellcheck disable=2046
unset -v VARIABLE_TABLE $( compgen -v | grep -Eo "^PROGRAM_[A-Z]+$" | tr "\n" " " )
