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
    local descr;
    local name;
    local index;
    local dir;
    local status;
    status="${statusFlags[DONE]}";

    # display header
    displayTitle;
    displayHeader "${actionHeaders[backup]}";
    displayExplain "${explainMsgs[BACKUP]}";
    descr="$(readInput "$(displayDescrPrompt)")";
    [ -z "$descr" ] && descr="${backupMsgs[NO_DESCR]}";

    # create backup name
    name="$(date +%d.%m.%Y)-at-$(date +%H-%M-%S)";

    # create backup directory
    [ ${#storages[@]} -eq 2 ] && index="ext" || index="${!storages[@]}";
    dir="${storagePaths[$index]}/$name";
    sudo mkdir "$dir" 2> /dev/null || displayErrorMsg "$dir ${err[FAIL_DIR_CREATE]}";

    # write backup description
    if [ "$status" == "${statusFlags[DONE]}" ]; then
        echo "$descr" | sudo tee "$dir/${files[descr]}" &> /dev/null ||
            displayErrorMsg "$dir ${err[FAIL_FILE_WRITE]}";
    fi

    # display backup detail
    if [ "$status" == "${statusFlags[DONE]}" ]; then
        displayBackupDetail "$dir" "${storages[$index]}";
        [ ${#storages[@]} -eq 2 ] && echo -e "${appDefaults[padding]}${backupMsgs[BE_COPIED]}: ${storages[int]}";
    fi

    # display return dialog
    if [ "$status" == "${statusFlags[DONE]}" ]; then
        local setReturn;
        setReturn="$(readInput "$(displayReturnPrompt)")";
        [ "$setReturn" == 'n' ] && status="${statusFlags[CANCEL]}";
    fi

    if [ "$status" == "${statusFlags[DONE]}" ] && [ "$setReturn" != 'n' ]; then
        # create root file system backup
        declare -a rootPaths;
        local options;
        local rootPath;
        local home;
        options="-cpjf";
        home=$(echo "${storagePaths[user]}" | grep -Eo 'home/[a-z]+');

        echo -e "\n${appDefaults[padding]}${backupMsgs[IN_PROGRESS]}...";
        changeDir "${mounts[root]}";

        for rootPath in "${excludeRoot[@]}";
        do
            [ "$rootPath" == "${excludeRoot[home]}" ] && rootPath=${rootPath/\[home\]/$home};
            rootPaths+=(--exclude="$rootPath")
        done

        sudo tar "$options" "$dir/${files[root]}" "${rootPaths[@]}" * 2> /dev/null || displayErrorMsg "$dir/${files[root]} ${err[FAIL_BACKUP_CREATE]}";

        # create home folder backup
        if [ "$status" == "${statusFlags[DONE]}" ]; then
            changeDir "${storagePaths[user]}";
            declare -a homePaths;
            local homePath;

            for homePath in "${excludeHome[@]}";
            do
                homePaths+=(--exclude="$homePath")
            done

            sudo tar "$options" "$dir/${files[home]}" "${homePaths[@]}" .* 2> /dev/null ||
                displayErrorMsg "$dir/${files[root]} ${err[FAIL_BACKUP_CREATE]}";
        fi

        # calculate backup checksum
        if [ "$status" == "${statusFlags[DONE]}" ]; then
            echo -e "${appDefaults[padding]}${backupMsgs[CALC_HASH]}...";
            getHash "$dir/${files[root]}" || displayErrorMsg "$dir/${files[root]} ${err[FAIL_HASH_CACL]}";

            if [ "$status" == "${statusFlags[DONE]}" ]; then
                getHash "$dir/${files[home]}" ||
                    displayErrorMsg "$dir/${files[home]} ${err[FAIL_HASH_CACL]}";
            fi
        fi

        # copy backup to internal drive
        if [ "$status" == "${statusFlags[DONE]}" ] && [ ${#storages[@]} -eq 2 ]; then
            echo -e "\n${appDefaults[padding]}${commonMsgs[IS_COPIED]} ${storages[int]}...";
            sudo cp -rp "$dir" ${storagePaths[int]} 2> /dev/null ||
                displayErrorMsg "${storagePaths[int]} ${err[FAIL_BACKUP_COPY]}";

            # verify backup checksum
            if [ "$status" == "${statusFlags[DONE]}" ]; then
                echo -e "${appDefaults[padding]}${hashMsgs[IS_VERIFY]}...";
                verifyHash "${storagePaths[int]}/$name" ||
                    displayErrorMsg "${storagePaths[int]}/$name ${err[FAIL_HASH_VERIFY]}";
            fi
        fi

        # display footer
        displayFooter "${actionHeaders[backup]}" "$status";
    else
        # remove backup dir
        sudo rm -rf "$dir" 2> /dev/null;

        # display footer
        displayFooter "${actionHeaders[backup]}" "$status";
    fi
}

# restore system backup
function restoreBackup {
    local status;
    status="${statusFlags[DONE]}";

    # display header
    displayTitle;
    displayHeader "${actionHeaders[restore]}";
    displayExplain "${explainMsgs[RESTORE]}";

    # display backup restore dialog

    # display footer
    displayFooter "${actionHeaders[restore]}" "$status";
}

# remove system backup
function removeBackup {
    local status;
    status="${statusFlags[DONE]}";

    # display header
    displayTitle;
    displayHeader "${actionHeaders[remove]}";
    displayExplain "${explainMsgs[REMOVE]}";

    # display backup remove dialog

    # display footer
    displayFooter "${actionHeaders[remove]}" "$status";
}

# copy system backup
function copyBackup {
    local status;
    status="${statusFlags[DONE]}";

    # display header
    displayTitle;
    displayHeader "${actionHeaders[copy]}";
    displayExplain "${explainMsgs[COPY]}";

    # display backup copy dialog

    # display footer
    displayFooter "${actionHeaders[copy]}" "$status";
}

# display system backup list
function listBackups {
    local status;
    status="${statusFlags[DONE]}";

    # display header
    displayTitle;
    displayHeader "${actionHeaders[list]}";
    displayExplain "${explainMsgs[LIST]}";

    # display backup list table

    # display footer
    displayFooter "${actionHeaders[list]}" "$status";
}

# verify system backup integrity
function verifyBackups {
    local status;
    status="${statusFlags[DONE]}";

    # display header
    displayTitle;
    displayHeader "${actionHeaders[verify]}";
    displayExplain "${explainMsgs[VERIFY]}";

    # display backup verification table

    # display footer
    displayFooter "${actionHeaders[verify]}" "$status";
}

# generate backup list
function generateBackupList {
    true;
    #readarray -t backups < <(ls -t --time=creation $storeDir);
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

        # create hash
        changeDir "$path";
        sudo sha256sum "$file" 2> /dev/null | sudo tee -a "${files[checksum]}" &> /dev/null || {
            setFlag;
            return 1;
        }
    else
        return 1;
    fi
}

# verify hash
function verifyHash {
    if [ -n "$1" ]; then
        changeDir "$1";
        [ -f "${files[broken]}" ] && return 1;
        sudo sha256sum -c "${files[checksum]}" &> /dev/null || {
            setFlag;
            return 1;
        }
    else
        return 1;
    fi
}
