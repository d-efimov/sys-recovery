#!/usr/bin/env bash

# ------ [ System Recovery Utility ] -----
# ----------------------------------------
#        shell command line utility
#      project source code repository:
# https://github.com/d-efimov/sys-recovery
# open source software © 2022 Denis Efimov
# ----------------------------------------

# -------------- [ MODULE ] --------------
#           storage drive actions
# ----------------------------------------

# mount storage drive
function mountStorage {
    declare -a devices;

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
            devices+=("$(deviceByUuid "${extPlatformRef[store]}")");

            # set external drive device name
            storages[extName]="${extPlatformRef[name]}";

            break;
        fi

        unset -n extPlatformRef;
    done

    if [ ${#devices[@]} -ne 1 ] || [ ${#storages[@]} -ne 1 ]; then
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
            devices+=("$(deviceByUuid "${intPlatformRef[root]}")");
            devices+=("$(deviceByUuid "${intPlatformRef[boot]}")");
            devices+=("$(deviceByUuid "${intPlatformRef[home]}")");

            # set internal drive device name
            storages[intName]="${intPlatformRef[name]}";

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

    if [ ${#devices[@]} -ne 4 ] || [ ${#storages[@]} -ne 2 ] || [ -z "$hw" ]; then
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

    # mount external ans internal drive
    local index;
    for index in "${!devices[@]}"
    do
        declare -a names=('store' 'root' 'boot' 'home');
        local name;
        name="${names[$index]}";

        local fs;
        [ "$name" == 'boot' ] && fs='vfat' || fs='ext4';

        [ -b "${devices[$index]}" ] || exitProcess "${devices[$index]} ${err[DEV_NOT_FOUND]}" 1;

        local srcTarget;
        srcTarget="${devices[$index]} ${mounts[$name]}";
        if ! [ "$(findmnt -o SOURCE,TARGET "${mounts[$name]}" 2> /dev/null | grep -q "$srcTarget")" ]; then
            sudo mount -o rw -t "$fs" "${devices[$index]}" "${mounts[$name]}" 2> /dev/null ||
                exitProcess "${mounts[$name]} ${err[FAIL_PART_MOUNT]}" 1;
        fi
    done

    # set user rights
    storages[user]="$(find "${mounts[home]}" -maxdepth 1 -type d -uid $user -print 2> /dev/null)";
    [ -d "${storages[user]}" ] || exitProcess "${storages[user]} $DIR_NOT_FOUND" 1;
    sudo chmod o+rx "${storages[user]}" 2> /dev/null ||
        exitProcess "${storages[user]} ${err[FAIL_CHANGE_RIGHTS]}" 1;

    # set storage paths
    storages[extPath]="${paths[ext]//\[hw\]/$hw/}";
    storages[intPath]="${paths[int]//\[user\]/${storages[user]}/}";
    [ -d "${storages[extPath]}" ] || exitProcess "${storages[extPath]} ${err[DIR_NOT_FOUND]}" 1;
    [ -d "${storages[intPath]}" ] || exitProcess "${storages[intPath]} ${err[DIR_NOT_FOUND]}" 1;
}

# unmount storage drive
function unmountStorage {
    cd "$cwd" 2> /dev/null;

    # restore user rights
    [ -d "${storages[user]}" ] && sudo chmod o-rx "${storages[user]}" 2> /dev/null;

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
    local selectedStorage;

    if [ -z "$1" ]; then
        displayHeader 'Select Storage Drive';
        selectedStorage="$(readInput '')";
    else
        selectedStorage="$1";
    fi

    # set selected storage
    storagePaths=();
    storageNames=();

    case $selectedStorage in
        1)
            # external drive
            storagePaths[ext]="${storages[extPath]}";
            storageNames[ext]="${storages[extName]}";
        ;;

        2)
            # internal drive
            storagePaths[int]="${storages[intPath]}";
            storageNames[int]="${storages[intName]}";
        ;;

        *)
            # both external and internal drive
            storagePaths[ext]=("${storages[extPath]}");
            storagePaths[int]=("${storages[intPath]}");
            storageNames[ext]="${storages[extName]}";
            storageNames[int]="${storages[intName]}";
        ;;
    esac

    if [ -z "$1" ]; then
        displayFooter '';
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
