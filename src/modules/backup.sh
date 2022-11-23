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
#           system backup actions
# ----------------------------------------

# create system backup
function createBackup {
    # display backup creation dialog
    local descr;
    local name;
    local index;
    local dir;
    displayTitle;
    displayHeader "${actionHeaders[backup]}";
    displayExplain "${explainMsgs[backup]}";
    descr="$(readInput "$(displayDescrPrompt)")";
    [ -z "$descr" ] && descr="${backupMsgs[NO_DESCR]}";

    # create backup name
    name="$(date +%d.%m.%Y)-at-$(date +%H-%M-%S)";

    # create backup directory
    [ ${#storages[@]} -eq 2 ] && index="ext" || index="${!storages[@]}";
    dir="${storagePaths[$index]}/$name";
    sudo mkdir "$dir" 2> /dev/null || exitProcess "$dir ${err[FAIL_DIR_CREATE]}" 1;

    # write backup description
    echo "$descr" | sudo tee "$dir/${files[descr]}" &> /dev/null ||
        exitProcess "$dir/${files[descr]} ${err[FAIL_FILE_WRITE]}" 1;

    # display backup detail
    displayBackupDetail "$dir" "${storages[$index]}";
    [ ${#storages[@]} -eq 2 ] && echo -e "${appDefaults[padding]}${backupMsgs[BE_COPIED]}: ${storages[int]}";

    # display return dialog
    local setReturn;
    setReturn="$(readInput "$(displayReturnPrompt)")";

    if [ "$setReturn" != 'n' ]; then
        # create root file system backup
        echo -e "\n${appDefaults[padding]}${backupMsgs[IN_PROGRESS]}...";
        cd "${mounts[root]}" 2> /dev/null || exitProcess "${mounts[root]} ${err[FAIL_CHANGE_DIR]}" 1;
        declare -a rootPaths;
        local rootPath;
        local home;
        home=$(echo "${storagePaths[user]}" | grep -Eo 'home/[a-z]+');

        for rootPath in "${excludeRoot[@]}";
        do
            [ "$rootPath" == "${excludeRoot[home]}" ] && rootPath=${rootPath/\[home\]/$home};
            rootPaths+=(--exclude="$rootPath")
        done

        sudo tar -cpjf "$dir/${files[root]}" "${rootPaths[@]}" * 2> /dev/null ||
            exitProcess "$dir/${files[root]} ${err[FAIL_BACKUP_CREATE]}" 1;

        # create home folder backup
        cd "${storagePaths[user]}" 2> /dev/null || exitProcess "${mounts[home]} ${err[FAIL_CHANGE_DIR]}" 1;
        declare -a homePaths;
        local homePath;

        for homePath in "${excludeHome[@]}";
        do
            homePaths+=(--exclude="$homePath")
        done

        sudo tar -cpjf "$dir/${files[home]}" "${homePaths[@]}" .* 2> /dev/null ||
            exitProcess "$dir/${files[home]} ${err[FAIL_BACKUP_CREATE]}" 1;

        # calculate backup checksum
        echo -e "${appDefaults[padding]}${backupMsgs[CALC_HASH]}...";
        getHash "$dir/${files[root]}";
        getHash "$dir/${files[home]}";

        # copy backup to internal drive
        if [ ${#storages[@]} -eq 2 ]; then
            echo -e "\n${appDefaults[padding]}${commonMsgs[IS_COPIED]} ${storages[int]}...";
            sudo cp -rp "$dir" ${storagePaths[int]} ||
                exitProcess "${storagePaths[int]} ${err[FAIL_BACKUP_COPY]}" 1;

            # verify backup checksum
            echo -e "${appDefaults[padding]}${hashMsgs[VERIFY]}...";
            verifyHash "${storagePaths[int]}/$name";
        fi

        # display footer
        displayFooter "${actionHeaders[backup]}" true;
    else
        # remove backup dir
        sudo rm -rf "$dir";

        # display footer
        displayFooter "${actionHeaders[backup]}";
    fi
}

# restore system backup
function restoreBackup {
    displayTitle;
    displayHeader "${actionHeaders[restore]}";
    displayExplain "${explainMsgs[restore]}";
}

# remove system backup
function removeBackup {
    displayTitle;
    displayHeader "${actionHeaders[remove]}";
    displayExplain "${explainMsgs[remove]}";
}

# copy system backup
function copyBackup {
    displayTitle;
    displayHeader "${actionHeaders[copy]}";
    displayExplain "${explainMsgs[copy]}";
}

# display system backup list
function listBackups {
    displayTitle;
    displayHeader "${actionHeaders[list]}";
    displayExplain "${explainMsgs[list]}";
}

# select system backup
function selectBackup {
    true;
}

# get hash
function getHash {
    if [ -n "$1" ]; then
        local regexp='[a-z-]*.tar.bz2$';
        local path;
        local file;
        path="$(echo "$1" | sed -e "s/\/$regexp//")";
        file="$(echo "$1" | grep -o "$regexp")";
        cd "$path" 2> /dev/null || exitProcess "$path ${err[FAIL_CHANGE_DIR]}" 1;
        sudo sha256sum "$file" 2> /dev/null | sudo tee -a "${files[checksum]}" &> /dev/null ||
            exitProcess "$path/${files[checksum]} ${err[FAIL_HASH_CACL]}" 1;
    fi
}

# verify hash
function verifyHash {
    if [ -n "$1" ]; then
        cd "$1" 2> /dev/null || exitProcess "$1 ${err[FAIL_CHANGE_DIR]}" 1;
        sudo sha256sum -c "${files[checksum]}" &> /dev/null || {
            echo "${hashMsgs[IS_BROKEN]}" | sudo tee "${files[broken]}" &> /dev/null;
            echo -e "${appDefaults[padding]} ${err[FAIL_HASH_VERIFY]}";
        }
    fi
}
