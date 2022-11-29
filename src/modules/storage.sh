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
#           storage drive actions
# ----------------------------------------

# mount storage drive
function mountStorage {
    declare -A devices;

    # set external drive uuid
    local uuidFilePath;
    local extDriveUuid;
    uuidFilePath="$cwd/${files[uuid]}";
    extDriveUuid="$(
        cat "$uuidFilePath" 2> /dev/null || exitProcess "$uuidFilePath ${err[FILE_NOT_FOUND]}" 1;
    )";
    extDriveUuid="$(trim "$extDriveUuid")";

    # set internal drive platform
    local intDrivePlatform;
    intDrivePlatform="$(cat /etc/machine-id 2> /dev/null)";
    intDrivePlatform="$(trim "$intDrivePlatform")";

    # set external and internal drives device
    local rawPlatform;

    for rawPlatform in "${platforms[@]}"
    do
        declare -A platform="$rawPlatform";

        if [ "${platform[type]}" == "$EXT" ]; then
            # set external drive device
            if [ "${platform[recovery]}" == "$extDriveUuid" ]; then
                # set external drive partition
                devices[$STORE]="$(deviceByUuid "${platform[$STORE]}")";

                # set external drive device name
                storageDevs[$EXT]="${platform[name]}";
            fi
        else
            # set internal drive device
            if [ "${platform[hw]}" == "$intDrivePlatform" ]; then
                # set internal drive partition
                devices[$ROOT]="$(deviceByUuid "${platform[$ROOT]}")";
                devices[$BOOT]="$(deviceByUuid "${platform[$BOOT]}")";
                devices[$HOME]="$(deviceByUuid "${platform[$HOME]}")";

                # set internal drive device name
                storageDevs[$INT]="${platform[name]}";

                # set internal drive hardware name
                local hw;
                hw="${platform[hw]}";

                # set internal drive user id
                local user;
                user=${platform[user]};
            fi
        fi
    done

    if [ ${#devices[@]} -ne 4 ] || [ ${#storageDevs[@]} -ne 2 ] || [ -z "$hw" ]; then
        exitProcess "$intDrivePlatform ${err[HARDWARE_NOT_FOUND]}" 1;
    fi

    # set mount points
    if ! [ -d "${mounts[$STORE]}" ]; then
        sudo mkdir "${mounts[$STORE]}" 2> /dev/null ||
            exitProcess "${mounts[$STORE]} ${err[FAIL_DIR_CREATE]}" 1;
    fi

    if ! [ -d "${mounts[$ROOT]}" ]; then
        sudo mkdir "${mounts[$ROOT]}" 2> /dev/null ||
            exitProcess "${mounts[$ROOT]} ${err[FAIL_DIR_CREATE]}" 1;
    fi

    # mount external and internal drive
    local name;

    for name in "${mountOrder[@]}"
    do
        local fs;
        [ "$name" == "$BOOT" ] && fs="${appDefaults[bootFs]}" || fs="${appDefaults[mainFs]}";

        [ -b "${devices[$name]}" ] || exitProcess "${devices[$name]} ${err[DEV_NOT_FOUND]}" 1;

        local srcTarget;
        srcTarget="${devices[$name]} ${mounts[$name]}";
        if ! [ "$(findmnt -o SOURCE,TARGET "${mounts[$name]}" 2> /dev/null | grep "$srcTarget")" ]; then
            sudo mount -o rw -t "$fs" "${devices[$name]}" "${mounts[$name]}" 2> /dev/null ||
                exitProcess "${mounts[$name]} ${err[FAIL_PART_MOUNT]}" 1;
        fi
    done

    # set user rights
    storagePaths[user]="$(find "${mounts[$HOME]}" -maxdepth 1 -type d -uid $user -print 2> /dev/null)";
    [ -d "${storagePaths[user]}" ] || exitProcess "${storagePaths[user]} ${err[DIR_NOT_FOUND]}" 1;
    sudo chmod o+rx "${storagePaths[user]}" 2> /dev/null ||
        exitProcess "${storagePaths[user]} ${err[FAIL_CHANGE_RIGHTS]}" 1;

    # set storage paths
    storagePaths[$EXT]="${paths[$EXT]/${placeholders[hw]}/$hw}";
    storagePaths[$INT]="${paths[$INT]/${placeholders[user]}/${storagePaths[user]}}";

    if ! [ -d "${storagePaths[$EXT]}" ]; then
        sudo mkdir "${storagePaths[$EXT]}" 2> /dev/null ||
            exitProcess "${storagePaths[$EXT]} ${err[FAIL_DIR_CREATE]}" 1;
    fi

    if ! [ -d "${storagePaths[$INT]}" ]; then
        sudo mkdir "${storagePaths[$INT]}" 2> /dev/null ||
            exitProcess "${storagePaths[$INT]} ${err[FAIL_DIR_CREATE]}" 1;
    fi
}

# unmount storage drive
function unmountStorage {
    changeDir "$cwd";

    # restore user rights
    [ -d "${storagePaths[user]}" ] && sudo chmod o-rx "${storagePaths[user]}" 2> /dev/null;

    # unmount external drive
    if [ -d "${mounts[$STORE]}" ]; then
        sudo umount -q "${mounts[$STORE]}" 2> /dev/null;
        sudo rmdir "${mounts[$STORE]}" 2> /dev/null;
    fi

    # unmount internal drive
    if [ -d "${mounts[$ROOT]}" ]; then
        sudo umount -Rq "${mounts[$ROOT]}" 2> /dev/null;
        sudo rmdir "${mounts[$ROOT]}" 2> /dev/null;
    fi
}

# select storage drive
function selectStorage {
    if [ -z "$1" ]; then
        local index;
        local size;
        local type;
        local name;
        local selectedStorage;
        local status;
        status="${statusFlags[DONE]}";

        # display header
        displayTitle;
        displayHeader "${actionHeaders[STORAGE]}";
        displayExplain "${explainMsgs[STORAGE]}";
        displayHeader "${actionHeaders[DRIVES]}";

        # display storage list table
        for index in "${!storageOrder[@]}"
        do

            if [ "${storageOrder[$index]}" != "$BOTH" ]; then
                size="${storageMsgs[GB_FREE]}: $(getFreeSpace "${storagePaths[${storageOrder[$index]}]}")\t";
                type="${storageTypes[${storageOrder[$index]}]}\t";
                name="${storageDevs[${storageOrder[$index]}]}";
            else
                size="\t\t";
                type=$size;
                name="${storageTypes[${storageOrder[$index]}]}";
            fi

            echo -e "$(displayIndex "$index")${type}${size}${name}";
        done

        displayDelimiter;
        echo -e "$(displayByDefault)${storageTypes[${storageOrder[${appDefaults[storage]}]}]} $(displayDefaultNum "${appDefaults[storage]}")";
        echo -e "\n${appDefaults[padding]}${storageMsgs[USED_STORAGE]}: $(displaySelectedDrive)";

        # display selection prompt
        selectedStorage="$(readInput "$(displaySelectPrompt)")";
        [ "$selectedStorage" == 'n' ] && status="${statusFlags[CANCEL]}";
    else
        selectedStorage="$1";
    fi

    if [ "$selectedStorage" != 'n' ]; then
        # set default value
        if ! [[ "$selectedStorage" =~ ${regexps[numberOnly]} ]] || [ $selectedStorage -ge ${#storageOrder[@]} ]; then
            displaySelectWarnMsg;
            selectedStorage="${appDefaults[storage]}";
        fi

        # set selected storage
        selectedStorage="${storageOrder[$selectedStorage]}";
        storages=();

        case $selectedStorage in
            "$EXT")
                # external drive
                storages[$EXT]="${storageDevs[$EXT]}";
            ;;

            "$INT")
                # internal drive
                storages[$INT]="${storageDevs[$INT]}";
            ;;

            "$BOTH")
                # both external and internal drive
                storages[$EXT]="${storageDevs[$EXT]}";
                storages[$INT]="${storageDevs[$INT]}";
            ;;
        esac

        # build backup model
        buildBackupModel;
    fi

    # display footer
    if [ -z "$1" ]; then
        [ "$selectedStorage" != 'n' ] && echo -e "\n${appDefaults[padding]}${storageMsgs[SELECTED_STORAGE]}: $(displaySelectedDrive)";
        displayFooter "${actionHeaders[STORAGE]}" "$status";
    fi
}

# get storage free space
function getFreeSpace {
    if [ -n "$1" ]; then
        local space;
        space="$(df --output=avail "$1" 2> /dev/null | grep -v 'Avail')";
        convertKb2Gb "$(trim "$space")";
    else
        return 1;
    fi
}
