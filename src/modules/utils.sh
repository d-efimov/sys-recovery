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
    [ -n "$1" ] && echo "$1" | xargs echo 2> /dev/null || return 1;
}

# shorten string
function shorten {
    if [ -n "$1" ] && [[ "$2" =~ ^[0-9]+$ ]]; then
        local str;
        [ ${#1} -gt $2 ] && str="$(echo "$1" | grep -Eo "^.{0,$2}")..." || str="$1";
        echo "$str";
    else
        return 1;
    fi
}

# read user input
function readInput {
    if [ -n "$1" ]; then
        local input;
        read -rp "$1" input;
        trim "$input";
    else
        return 1;
    fi
}

# device by uuid
function deviceByUuid {
    if [ -n "$1" ]; then
        local uuid;
        uuid="$(readlink -e "/dev/disk/by-uuid/$1" 2> /dev/null)";
        trim "$uuid";
    else
        return 1;
    fi
}

# read file
function readFile {
    [ -n "$1" ] && trim "$(sudo cat "$1" 2> /dev/null)" || return 1;
}

# read set file flag
function setFlag {
    echo "${hashMsgs[IS_BROKEN]}" | sudo tee "${files[broken]}" &> /dev/null;
}

# change directory
function changeDir {
    if [ -n "$1" ]; then
        cd "$1" 2> /dev/null || exitProcess "$1 ${err[FAIL_CHANGE_DIR]}" 1;
    else
        return 1;
    fi
}

# display info about application
function aboutApp {
    local status;
    status="${statusFlags[DONE]}";

    # display header
    displayTitle;
    displayHeader "${actionHeaders[about]}";
    displayExplain "${explainMsgs[ABOUT]}";

    # display info about application

    # display footer
    displayFooter "${actionHeaders[about]}" "$status";
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
            displayExplain "${explainMsgs[EXIT]}";
            echo -e "\n${appDefaults[padding]}${commonMsgs[WANT_EXIT]}";
            setExit="$(readInput "$(displayReturnPrompt)")";
        ;;

        1)
            # exit by application error
            local defaultMsg;
            defaultMsg="${appDefaults[padding]} ${commonMsgs[APP_ERROR]}";
            [ -n "$1" ] && echo -e "$(displayErrorMsg "$1")\n" || echo -e "$defaultMsg\n";
        ;;

        2)
            # exit by press break key combination
            displayHeader "${actionHeaders[exit]}";
            echo -e "${appDefaults[padding]}${commonMsgs[PRESS_BREAK]}"
        ;;
    esac

    # exit or continue
    if [ "$setExit" != 'n' ]; then
        [ $code -ne 1 ] && echo -e "\n${appDefaults[padding]}${commonMsgs[IS_EXIT]}...";
        unmountStorage;
        [ $code -ne 1 ] && clear;
        exit "$code";
    else
        displayFooter "${actionHeaders[exit]}" "cancel";
    fi
}
