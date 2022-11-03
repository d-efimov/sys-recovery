#!/usr/bin/env bash

# ------ [ System Recovery Utility ] -----
# ----------------------------------------
#        shell command line utility
#      project source code repository:
# https://github.com/d-efimov/sys-recovery
# open source software © 2022 Denis Efimov
# ----------------------------------------

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
    # unmount storage drive
    unmountStorage;

    # display error message
    clear;
    [ -n "$1" ] && echo "$1";

    # exit from process
    local code;
    [ -z "$2" ] && code=0 || code="$2";
    exit "$code";
}
