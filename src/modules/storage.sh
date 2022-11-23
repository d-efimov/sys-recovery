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

    # set external drive device
    local extPlatform;

    for extPlatform in "${extPlatforms[@]}"
    do
        local extPlatformRef;
        declare -n extPlatformRef=$extPlatform 2> /dev/null;

        if [ "${extPlatformRef[recovery]}" == "$extDriveUuid" ]; then
            # set external drive partition
            devices[store]="$(deviceByUuid "${extPlatformRef[store]}")";

            # set external drive device name
            storageDevs[ext]="${extPlatformRef[name]}";

            break;
        fi

        unset -n extPlatformRef;
    done

    if [ ${#devices[@]} -ne 1 ] || [ ${#storageDevs[@]} -ne 1 ]; then
        exitProcess "$extDriveUuid ${err[HARDWARE_NOT_FOUND]}" 1;
    fi

    # set internal drive platform
    local intDrivePlatform;
    intDrivePlatform="$(cat /etc/machine-id 2> /dev/null)";
    intDrivePlatform="$(trim "$intDrivePlatform")";

    # set internal drive device
    local intPlatform;

    for intPlatform in "${intPlatforms[@]}"
    do
        local intPlatformRef;
        declare -n intPlatformRef=$intPlatform 2> /dev/null;

        if [ "${intPlatformRef[hw]}" == "$intDrivePlatform" ]; then
            # set internal drive partition
            devices[root]="$(deviceByUuid "${intPlatformRef[root]}")";
            devices[boot]="$(deviceByUuid "${intPlatformRef[boot]}")";
            devices[home]="$(deviceByUuid "${intPlatformRef[home]}")";

            # set internal drive device name
            storageDevs[int]="${intPlatformRef[name]}";

            # set internal drive hardware name
            local hw;
            hw="${intPlatformRef[hw]}";

            # set internal drive user id
            local user;
            user=${intPlatformRef[user]};

            break;
        fi

        unset -n intPlatformRef;
    done

    if [ ${#devices[@]} -ne 4 ] || [ ${#storageDevs[@]} -ne 2 ] || [ -z "$hw" ]; then
        exitProcess "$intDrivePlatform ${err[HARDWARE_NOT_FOUND]}" 1;
    fi

    # set mount points
    if ! [ -d "${mounts[store]}" ]; then
        sudo mkdir "${mounts[store]}" 2> /dev/null ||
            exitProcess "${mounts[store]} ${err[FAIL_DIR_CREATE]}" 1;
    fi

    if ! [ -d "${mounts[root]}" ]; then
        sudo mkdir "${mounts[root]}" 2> /dev/null ||
            exitProcess "${mounts[root]} ${err[FAIL_DIR_CREATE]}" 1;
    fi

    # mount external and internal drive
    local name;
    for name in "${mountOrder[@]}"
    do
        local fs;
        [ "$name" == 'boot' ] && fs='vfat' || fs='ext4';

        [ -b "${devices[$name]}" ] || exitProcess "${devices[$name]} ${err[DEV_NOT_FOUND]}" 1;

        local srcTarget;
        srcTarget="${devices[$name]} ${mounts[$name]}";
        if ! [ "$(findmnt -o SOURCE,TARGET "${mounts[$name]}" 2> /dev/null | grep "$srcTarget")" ]; then
            sudo mount -o rw -t "$fs" "${devices[$name]}" "${mounts[$name]}" 2> /dev/null ||
                exitProcess "${mounts[$name]} ${err[FAIL_PART_MOUNT]}" 1;
        fi
    done

    # set user rights
    storagePaths[user]="$(find "${mounts[home]}" -maxdepth 1 -type d -uid $user -print 2> /dev/null)";
    [ -d "${storagePaths[user]}" ] || exitProcess "${storagePaths[user]} ${err[DIR_NOT_FOUND]}" 1;
    sudo chmod o+rx "${storagePaths[user]}" 2> /dev/null ||
        exitProcess "${storagePaths[user]} ${err[FAIL_CHANGE_RIGHTS]}" 1;

    # set storage paths
    storagePaths[ext]="${paths[ext]/\[hw\]/$hw}";
    storagePaths[int]="${paths[int]/\[user\]/${storagePaths[user]}}";

    if ! [ -d "${storagePaths[ext]}" ]; then
        sudo mkdir "${storagePaths[ext]}" 2> /dev/null ||
            exitProcess "${storagePaths[ext]} ${err[FAIL_DIR_CREATE]}" 1;
    fi

    if ! [ -d "${storagePaths[int]}" ]; then
        sudo mkdir "${storagePaths[int]}" 2> /dev/null ||
            exitProcess "${storagePaths[int]} ${err[FAIL_DIR_CREATE]}" 1;
    fi
}

# unmount storage drive
function unmountStorage {
    cd "$cwd" 2> /dev/null;

    # restore user rights
    [ -d "${storagePaths[user]}" ] && sudo chmod o-rx "${storagePaths[user]}" 2> /dev/null;

    # unmount external drive
    if [ -d "${mounts[store]}" ]; then
        sudo umount -q "${mounts[store]}" 2> /dev/null;
        sudo rmdir "${mounts[store]}" 2> /dev/null;
    fi

    # unmount internal drive
    if [ -d "${mounts[root]}" ]; then
        sudo umount -Rq "${mounts[root]}" 2> /dev/null;
        sudo rmdir "${mounts[root]}" 2> /dev/null;
    fi
}

# select storage drive
function selectStorage {
    # display storage selection dialog
    if [ -z "$1" ]; then
        local index;
        local size;
        local type;
        local name;
        displayTitle;
        displayHeader "${actionHeaders[storage]}";
        displayExplain "${explainMsgs[storage]}";
        displayHeader "${actionHeaders[drive]}";

        for index in "${!storageOrder[@]}"
        do

            if [ "${storageOrder[$index]}" != 'both' ]; then
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
        local selectedStorage;
        selectedStorage="$(readInput "$(displaySelectPrompt)")";
    else
        selectedStorage="$1";
    fi

    if [ "$selectedStorage" != 'n' ]; then
        # set default value
        if ! [[ "$selectedStorage" =~ ^[0-9]+$ ]] || [ $selectedStorage -ge ${#storageOrder[@]} ]; then
            displaySelectWarnMsg;
            selectedStorage="${appDefaults[storage]}";
        fi

        # set selected storage
        selectedStorage="${storageOrder[$selectedStorage]}";
        storages=();

        case $selectedStorage in
            'ext')
                # external drive
                storages[ext]="${storageDevs[ext]}";
            ;;

            'int')
                # internal drive
                storages[int]="${storageDevs[int]}";
            ;;

            'both')
                # both external and internal drive
                storages[ext]="${storageDevs[ext]}";
                storages[int]="${storageDevs[int]}";
            ;;
        esac

        # display footer
        if [ -z "$1" ]; then
            echo -e "\n${appDefaults[padding]}${storageMsgs[SELECTED_STORAGE]}: $(displaySelectedDrive)";
            displayFooter "${actionHeaders[storage]}" true;
        fi
    else
        # display footer
        displayFooter "${actionHeaders[storage]}";
    fi
}

# get storage free space
function getFreeSpace {
    if [ -n "$1" ]; then
        local space;
        space="$(df --output=avail "$1" 2> /dev/null | grep -v 'Avail')";
        space="$(trim "$space")";
        echo $((space/1024**2));
    fi
}
