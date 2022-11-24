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

# set dark theme
gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark;
gsettings set org.gnome.desktop.interface color-scheme prefer-dark;

# set signal handler
trap exitProcess SIGINT;

# mount storage drives
mountStorage;

# select storage drive
selectStorage "${appDefaults[storage]}";

# utility action list
while true
do
    # display header
    clear;
    displayTitle;
    displayHeader "${actionHeaders[action]}";

    # display actions selection dialog
    for index in "${!actionOrder[@]}"
    do
        echo -e "$(displayIndex "$index")${actionHeaders[${actionOrder[$index]}]}";
    done

    displayDelimiter;
    echo -e "$(displayByDefault)${actionHeaders[${actionOrder[${appDefaults[action]}]}]} $(displayDefaultNum "${appDefaults[action]}")";
    selectedAction="$(readInput "$(displaySelectPrompt)")";

    # set default value
    if ! [[ "$selectedAction" =~ ^[0-9]+$ ]] || [ $selectedAction -ge ${#actionOrder[@]} ]; then
        displaySelectWarnMsg;
        selectedAction="${appDefaults[action]}";
        sleep ${appDefaults[timeout]};
    fi
    clear;

    # execute selected action
    selectedAction="${actionOrder[$selectedAction]}";
    case $selectedAction in
        'backup')
            # create system backup
            createBackup;
        ;;

        'restore')
            # restore system backup
            restoreBackup;
        ;;

        'remove')
            # remove system backup
            removeBackup;
        ;;

        'copy')
            # copy system backup
            copyBackup;
        ;;

        'list')
            # display system backup list
            listBackups;
        ;;

        'verify')
            # verify system backup integrity
            verifyBackups;
        ;;

        'storage')
            # select storage drive
            selectStorage;
        ;;

        'about')
            # display info about application
            aboutApp;
        ;;

        'exit')
            # exit from process
            exitProcess '' 0;
        ;;
    esac
done
