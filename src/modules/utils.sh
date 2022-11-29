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
    [ -n "$1" ] && echo "$1" | sed -E "s/${regexps[spaceStart]}|${regexps[spaceEnd]}//g" || return 1;
}

# shorten string
function shorten {
    if [ -n "$1" ] && [[ "$2" =~ ^[0-9]+$ ]]; then
        local str;
        [ ${#1} -gt $2 ] && str="$(echo "$1" | grep -Eo "${regexps[strLength]/${placeholders[length]}/$2}")..." || str="$1";
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

# convert size in kb to gb
function convertKb2Gb {
    [ -n "$1" ] && LC_NUMERIC="${appDefaults[local]}" echo | awk -vOFMT=%.1f "{print $1/1024^2}" | sed -E "s/${regexps[dotZeroEnd]}//" || return 1;
}

# write file
function writeFile {
    if [ -n "$1" ] && [ -n "$2" ]; then
        echo "$1" | sudo tee -a "$2" &> /dev/null || return 1;
    else
        return 1;
    fi
}

# read set file flag
function setFlag {
    [ -n "$1" ] && writeFile "${hashMsgs[IS_BROKEN]}" "$1/${files[broken]}" || return 1;
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
    displayHeader "${actionHeaders[ABOUT]}";
    displayExplain "${explainMsgs[ABOUT]}";

    # display info about application

    # display footer
    displayFooter "${actionHeaders[ABOUT]}" "$status";
}

# exit from process
function exitProcess {
    # set error code
    local code;
    [ -z "$2" ] && code=2 || code="$2";

    # display exit message
    local setExit;
    local exitMsg;

    case $code in
        0)
            # exit manual
            displayTitle;
            displayHeader "${actionHeaders[EXIT]}";
            displayExplain "${explainMsgs[EXIT]}";
            echo -e "\n${appDefaults[padding]}${commonMsgs[WANT_EXIT]}";
            setExit="$(readInput "$(displayReturnPrompt)")";
            exitMsg="${commonMsgs[IS_EXIT]}";
        ;;

        1)
            # exit by application error
            [ -n "$1" ] && echo -e "$(displayErrorMsg "$1")\n" || echo -e "$(displayErrorMsg "${commonMsgs[APP_ERROR]}")\n";
        ;;

        2)
            # exit by press break key combination
            exitMsg="${commonMsgs[PRESS_BREAK]}, ${commonMsgs[IS_EXIT]}";
    esac

    # exit or continue
    if [ "$setExit" != 'n' ]; then
        [ $code -ne 1 ] && displayLoader "$exitMsg";
        unmountStorage;
        [ $code -ne 1 ] && clear;
        exit "$code";
    else
        displayFooter "${actionHeaders[EXIT]}" "${statusFlags[CANCEL]}";
    fi
}
