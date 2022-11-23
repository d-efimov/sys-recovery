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

# shorten string
function shorten {
    if [ -n "$1" ] && [[ "$2" =~ ^[0-9]+$ ]]; then
        local str;
        str=$(trim "$1");
        [ ${#str} -gt $2 ] && str="$(echo "$str" | grep -Eo "^.{0,$2}")...";
        echo "$str";
    fi
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
    clear;
    displayTitle;

    case $code in
        0)
            # exit manual
            displayHeader "${actionHeaders[exit]}";
            displayExplain "${explainMsgs[exit]}";
            echo -e "\n${appDefaults[padding]}${commonMsgs[WANT_EXIT]}";
            setExit="$(readInput "$(displayReturnPrompt)")";
        ;;

        1)
            # exit by application error
            displayHeader "${actionHeaders[error]}";
            local defaultMsg;
            local msg;
            defaultMsg="${appDefaults[padding]} ${commonMsgs[APP_ERROR]}";
            msg="$(echo "$1" | sed -e "s/.\{70\}/&\n${appDefaults[padding]}/g")";
            [ -n "$1" ] && echo -e "${appDefaults[padding]}$msg\n" || echo -e "$defaultMsg\n";
        ;;

        2)
            # exit by press break key combination
            displayHeader "${actionHeaders[exit]}";
            displayExplain "${explainMsgs[exit]}";
            echo -e "${appDefaults[padding]}${commonMsgs[PRESS_BREAK]}"
        ;;
    esac

    # exit or continue
    if [ "$setExit" != 'n' ]; then
        [ $code -ne 1 ] && echo -e "\n${appDefaults[padding]}exit...";
        unmountStorage;
        [ $code -ne 1 ] && clear;
        exit "$code";
    else
        displayFooter "${actionHeaders[exit]}";
    fi
}
