#!/usr/bin/env bash

# ------ [ System Recovery Utility ] -----
# ----------------------------------------
#        shell command line utility
#      project source code repository:
# https://github.com/d-efimov/sys-recovery
# open source software © 2022 Denis Efimov
# ----------------------------------------
#
# -------------- [ MODULE ] --------------
#          common utils functions
# ----------------------------------------

# trim whitespaces
function trim {
    [ -n "$1" ] && echo "$1" | xargs echo 2> /dev/null;
}

# read user input
function readInput {
    if [ -n "$1" ]; then
        local input;
        read -rp "$1" input;
        trim "$input";
    fi
}

# device by uuid
function deviceByUuid {
    if [ -n "$1" ]; then
        local uuid;
        uuid="$(readlink -e "/dev/disk/by-uuid/$1" 2> /dev/null)";
        trim "$uuid";
    fi
}

# exit from process
function exitProcess {
    # set error code
    local code;
    [ -z "$2" ] && code=2 || code="$2";

    # display exit message
    local setExit;

    case $code in
        0)
            displayHeader "${actionHeaders[exit]}";
            echo -e "${appDefaults[padding]}${displayMsg[WANT_EXIT]}";
            setExit="$(readInput "$(displayExitPrompt)")";
        ;;
        1)
            clear;
            displayHeader "${actionHeaders[error]}";
            local defaultMsg="${appDefaults[padding]} ${displayMsg[APP_ERROR]}";
            [ -n "$1" ] && echo -e "${appDefaults[padding]}$1\n" || echo -e "$defaultMsg\n";
        ;;
        2)
            clear;
            displayHeader "${actionHeaders[exit]}";
            echo -e "${appDefaults[padding]}${displayMsg[PRESS_BREAK]}"
        ;;
    esac

    # exit or continue
    if [ -z "$setExit" ]; then
        [ $code -ne 1 ] && echo -e "\n${appDefaults[padding]}exit...";
        unmountStorage;
        [ $code -ne 1 ] && clear;
        exit "$code";
    else
        displayFooter "${actionHeaders[exit]}" ${displayMsg[IS_CANCEL]};
    fi
}
