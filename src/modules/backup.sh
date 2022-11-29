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
    displayHeader "${actionHeaders[BACKUP]}";
    displayExplain "${explainMsgs[BACKUP]}";
    descr="$(readInput "$(displayDescrPrompt)")";
    [ -z "$descr" ] && descr="${backupMsgs[NO_DESCR]}";

    # create backup name
    name="$(date +%d.%m.%Y)-at-$(date +%H-%M-%S)";

    # create backup directory
    [ ${#storages[@]} -eq 2 ] && index="$EXT" || index="${!storages[@]}";
    dir="${storagePaths[$index]}/$name";
    sudo mkdir "$dir" 2> /dev/null || displayErrorMsg "$dir ${err[FAIL_DIR_CREATE]}";

    # write backup description
    if [ "$status" == "${statusFlags[DONE]}" ]; then
        writeFile "$descr" "$dir/${files[descr]}" || displayErrorMsg "$dir ${err[FAIL_FILE_WRITE]}";
    fi

    # display return prompt
    if [ "$status" == "${statusFlags[DONE]}" ]; then
        local setReturn;
        setReturn="$(readInput "$(displayReturnPrompt)")";

        if [ "$setReturn" == 'n' ]; then
            status="${statusFlags[CANCEL]}";
            sudo rm -rf "$dir" 2> /dev/null;
        fi
    fi

    if [ "$status" == "${statusFlags[DONE]}" ]; then
        # create root file system backup
        declare -a rootPaths;
        local rootPath;
        local home;
        home=$(echo "${storagePaths[user]}" | grep -Eo "${regexps[userHome]}");
        displayLoader "${backupMsgs[IN_PROGRESS]}";

        for rootPath in "${excludeRoot[@]}";
        do
            [ "$rootPath" == "${excludeRoot[home]}" ] && rootPath="${rootPath/${placeholders[home]}/$home}";
            rootPaths+=(--exclude="$rootPath")
        done

        changeDir "${mounts[$ROOT]}";
        sudo tar "${tarOptions[create]}" "$dir/${files[root]}" "${rootPaths[@]}" * 2> /dev/null || displayErrorMsg "$dir/${files[root]} ${err[FAIL_BACKUP_CREATE]}";

        # create home folder backup
        if [ "$status" == "${statusFlags[DONE]}" ]; then
            declare -a homePaths;
            local homePath;

            for homePath in "${excludeHome[@]}";
            do
                homePaths+=(--exclude="$homePath")
            done

            changeDir "${storagePaths[user]}";
            sudo tar "${tarOptions[create]}" "$dir/${files[home]}" "${homePaths[@]}" .* 2> /dev/null ||
                displayErrorMsg "$dir/${files[root]} ${err[FAIL_BACKUP_CREATE]}";
        fi

        # calculate backup checksum
        if [ "$status" == "${statusFlags[DONE]}" ]; then
            displayLoader "${backupMsgs[CALC_HASH]}";
            getHash "$dir/${files[root]}" || displayErrorMsg "$dir/${files[root]} ${err[FAIL_HASH_CACL]}";

            if [ "$status" == "${statusFlags[DONE]}" ]; then
                getHash "$dir/${files[home]}" ||
                    displayErrorMsg "$dir/${files[home]} ${err[FAIL_HASH_CACL]}";
            fi
        fi

        # copy backup to internal drive
        if [ "$status" == "${statusFlags[DONE]}" ] && [ ${#storages[@]} -eq 2 ]; then
            [ ${#storages[@]} -eq 2 ] && displayLoader "${backupMsgs[BE_COPIED]}: ${storages[$INT]}";
            sudo cp -rp "$dir" ${storagePaths[$INT]} 2> /dev/null ||
                displayErrorMsg "${storagePaths[$INT]} ${err[FAIL_BACKUP_COPY]}";

            # verify backup checksum
            if [ "$status" == "${statusFlags[DONE]}" ]; then
                displayLoader "${hashMsgs[IS_VERIFY]}";
                verifyHash "${storagePaths[$INT]}/$name" ||
                    displayErrorMsg "${storagePaths[$INT]}/$name ${err[FAIL_HASH_VERIFY]}";
            fi
        fi

        # build backup model
        buildBackupModel;

        # display backup detail
        if [ "$status" == "${statusFlags[DONE]}" ]; then
            displayBackupDetail "$name" || displayErrorMsg "$name ${err[FAIL_BACKUP_FIND]}";
        fi
    fi

    # display footer
    displayFooter "${actionHeaders[BACKUP]}" "$status";
}

# restore system backup
function restoreBackup {
    local status;
    status="${statusFlags[DONE]}";

    # display header
    displayTitle;
    displayHeader "${actionHeaders[RESTORE]}";
    displayExplain "${explainMsgs[RESTORE]}";

    # display backup restore dialog

    # display footer
    displayFooter "${actionHeaders[RESTORE]}" "$status";
}

# remove system backup
function removeBackup {
    local status;
    status="${statusFlags[DONE]}";

    # display header
    displayTitle;
    displayHeader "${actionHeaders[REMOVE]}";
    displayExplain "${explainMsgs[REMOVE]}";

    # display backup remove dialog

    # display footer
    displayFooter "${actionHeaders[REMOVE]}" "$status";
}

# copy system backup
function copyBackup {
    local status;
    status="${statusFlags[DONE]}";

    # display header
    displayTitle;
    displayHeader "${actionHeaders[COPY]}";
    displayExplain "${explainMsgs[COPY]}";

    # display backup copy dialog

    # display footer
    displayFooter "${actionHeaders[COPY]}" "$status";
}

# display system backup list
function listBackups {
    local status;
    local selectedBackup;
    status="${statusFlags[DONE]}";

    # display backup selection dialog
    while [ -z "$selectedBackup" ]
    do
        # display header
        displayTitle;
        displayHeader "${actionHeaders[LIST]}";
        displayExplain "${explainMsgs[LIST]}";

        # display backup list table
        displayBackupList || { displayErrorMsg "${err[FAIL_BACKUP_FIND]}" && selectedBackup=1; }

        # display selection prompt
        [ "$status" == "${statusFlags[DONE]}" ] && selectedBackup="$(readInput "$(displaySelectPrompt)")";
        [ "$selectedBackup" == 'n' ] && status="${statusFlags[CANCEL]}";

        if [ "$status" == "${statusFlags[DONE]}" ]; then
            if ! [[ "$selectedBackup" =~ ${regexps[numberOnly]} ]] || [ $selectedBackup -ge ${#backups[@]} ]; then
                # display error selection
                selectedBackup='';
                displayLoader "$(displaySelectErrMsg)";
                sleep ${appDefaults[timeout]};
            else
                # display backup detail
                displayBackupDetail $selectedBackup || displayErrorMsg "${err[FAIL_BACKUP_FIND]}";
                selectedBackup='';
                # display footer
                displayFooter "${actionHeaders[DETAIL]}" "$status";
            fi
        else
            # display footer
            displayFooter "${actionHeaders[LIST]}" "$status";
        fi
    done
}

# verify system backup integrity
function verifyBackups {
    local status;
    status="${statusFlags[DONE]}";

    # display header
    displayTitle;
    displayHeader "${actionHeaders[VERIFY]}";
    displayExplain "${explainMsgs[VERIFY]}";

    # display backup verification table

    # display footer
    displayFooter "${actionHeaders[VERIFY]}" "$status";
}

# build backup model
function buildBackupModel {
    declare -a names;
    declare -a fileList;
    declare -A fields;
    local field;
    local index;
    local name;
    local path;
    local backup;
    backups=();

    # generate backup names per device
    for index in "${!storages[@]}"
    do
        readarray -t names < <(ls --time=creation "${storagePaths[$index]}");

        # build backup model by each name
        for name in "${names[@]}"
        do
            # set backup path
            path="${storagePaths[$index]}/$name";

            # set backup status, name and storage
            fields[status]="${commonMsgs[IS_NORMAL]}";
            fields[name]="$name";
            fields[storage]="$index";

            # set backup files
            fileList=();

            for file in "${requiredFiles[@]}"
            do
                [ -f "$path/$file" ] && fileList+=("$file");
            done

            [ ${#fileList[@]} -ne ${#requiredFiles[@]} ] && fields[status]="${commonMsgs[IS_BROKEN]}";
            fields[files]="${fileList[@]}";

            # set backup description
            if [ -f "$path/${files[descr]}" ]; then
                fields[descr]="$(trim "$(sudo cat "$path/${files[descr]}" 2> /dev/null)")";
                if [ -z "${fields[descr]}" ]; then
                    writeFile "${backupMsgs[NO_DESCR]}" "$path/${files[descr]}" || fields[status]="${commonMsgs[IS_BROKEN]}";
                    fields[descr]="${backupMsgs[NO_DESCR]}";
                fi
            else
                fields[descr]="${backupMsgs[NO_DESCR]}";
            fi

            # calculate backup size
            fields[size]="$(convertKb2Gb "$(du -s "$path" | grep -Eo "${regexps[numberStart]}")")";

            # set backup status
            [ "${fields[status]}" == "${commonMsgs[IS_NORMAL]}" ] && [ -f "$path/${files[broken]}" ] && fields[status]="${commonMsgs[IS_BROKEN]}";

            # set broken backup flag
            [ "${fields[status]}" == "${commonMsgs[IS_BROKEN]}" ] && ! [ -f "$path/${files[broken]}" ] && setFlag "$path";

            # build backup model entry
            backup='(';

            for field in "${!modelFields[@]}"
            do
                backup+="[${modelFields[$field]}]='${fields[${modelFields[$field]}]}'";
                [ $field -lt $((${#modelFields[@]}-1)) ] && backup+=' ' || backup+=')';
            done

            backups+=("$backup");
        done
    done
}

# get hash
function getHash {
    if [ -n "$1" ]; then
        local hash;
        local path;
        local file;
        path="$(echo "$1" | sed -E "s/\/${regexps[backupFile]}//")";
        file="$(echo "$1" | grep -o "${regexps[backupFile]}")";

        # create hash
        changeDir "$path";
        hash=$(sudo sha256sum "$file" 2> /dev/null) || {
            setFlag "$path";
            return 1
        };
        writeFile "$hash" "${files[checksum]}" || {
            setFlag "$path";
            return 1;
        };
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
            setFlag "$1";
            return 1;
        }
    else
        return 1;
    fi
}
