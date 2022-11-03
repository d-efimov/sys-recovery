#!/usr/bin/env bash

# ------ [ System Recovery Utility ] -----
# ----------------------------------------
#        shell command line utility
#      project source code repository:
# https://github.com/d-efimov/sys-recovery
# open source software © 2022 Denis Efimov
# ----------------------------------------

# -------------- [ MODULE ] --------------
#           command line utility
# ----------------------------------------

# init application
echo 'loading...';
cwd="$(pwd)";
function init {
    # verify if os running from live usb drive
    local NOT_LIVE_OS;
    NOT_LIVE_OS='recovery utility only runs after booting os from live usb drive';
    df --output=source / | grep -q '/cow' || { echo "$NOT_LIVE_OS"; exit 1; }

    # define modules
    local modulePath;
    local modules;
    modulePath="$cwd/modules";
    declare -a modules=(
        "$modulePath/conf.sh"
        "$modulePath/utils.sh"
        "$modulePath/display.sh"
        "$modulePath/storage.sh"
        "$modulePath/backup.sh"
    );

    # load modules
    local MODULE_NOT_FOUND;
    local module;
    MODULE_NOT_FOUND='module not found';

    for module in "${modules[@]}"
    do
        [ -f "$module" ] && source "$module" 2> /dev/null || { echo "$module $MODULE_NOT_FOUND"; exit 1; }
    done
} && init;

# set signal handler
trap exitProcess SIGINT;

# mount storage drives
mountStorage;

# select storage drive
selectStorage "$defaultStorage";

# utility action list
while true
do
    # display actions selection dialog
    clear;
    displayHeader "$appName";
    selectedAction="$(readInput '')";
    clear;

    # execute selected action
    case $selectedAction in
        1)
            # restore system backup
            restoreBackup;
        ;;

        2)
            # remove system backup
            removeBackup;
        ;;

        3)
            # copy system backup
            copyBackup;
        ;;

        4)
            # select storage drive
            selectStorage;
        ;;

        5)
            # exit from process
            exitProcess;
        ;;

        *)
            # create system backup
            createBackup;
        ;;
    esac

    sleep $displayTimeout;
done
