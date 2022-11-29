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
#          display screen messages
# ----------------------------------------

# display title
function displayTitle {
    clear;
    echo -e "\n${appDefaults[title]}";
}

# display header
function displayHeader {
    [ -n "$1" ] && echo -e "\n${appDefaults[padding]}[ $1 ]\n$(displayDelimiter)" || return 1;
}

# display explain
function displayExplain {
    [ -n "$1" ] && echo -e "${appDefaults[padding]}$1" || return 1;
}

# display footer
function displayFooter {
    if [ -n "$1" ] && [ -n "$2" ]; then
        if [ "$2" == "${statusFlags[DONE]}" ] || [ "$2" == "${statusFlags[FAIL]}" ]; then
            # action is done or fail
            local result;
            [ "$2" == "${statusFlags[DONE]}" ] && result="${commonMsgs[IS_SUCCESS]}" || result="${commonMsgs[IS_FAIL]}";
            printf "\n%s, %s..." "${appDefaults[padding]}$1 $result" "${commonMsgs[TO_CONTINUE]}";
            read -rs;
        else
            # action is canceled
            displayLoader "$1 ${commonMsgs[IS_CANCEL]}";
            sleep ${appDefaults[timeout]};
        fi
    else
        return 1;
    fi
}

# display backup list
function displayBackupList {
    local index;

    [ ${#backups[@]} -eq 0 ] && return 1;
    displayHeader "${actionHeaders[BACKUPS]}";
    for index in "${!backups[@]}"
    do
        declare -A fields="${backups[$index]}";
        echo -e "$(displayIndex "$index")${fields[name]}\t${fields[status]}\t${storages[${fields[storage]}]}";
        echo -e "\t\t$(shorten "${fields[descr]}" 56)";
        displayDelimiter;
    done
}

# display backup detail
function displayBackupDetail {
    if [ -n "$1" ]; then
        declare -a findBackups;
        local index;

        # find backup
        if [[ "$1" =~ ${regexps[numberOnly]} ]] && [ $1 -lt ${#backups[@]} ]; then
            # find backup by index
            findBackups+=("${backups[$1]}");
        elif [[ "$1" =~ ${regexps[backupName]} ]]; then
            # find backup by name
            for index in "${!backups[@]}"
            do
                echo "${backups[$index]}" | grep -q "$1" && findBackups+=("${backups[$index]}");
            done
        else
            return 1
        fi

        # check backup find result
        [ ${#findBackups[@]} -eq 0 ] && return 1;

        # display backup detail
        displayTitle;
        local backup;

        for backup in "${findBackups[@]}"
        do
            declare -A fields="${backup}";
            local path;
            local files;
            path="${storagePaths[${fields[storage]}]}";
            files="$(echo "${fields[files]}" | sed -E "s/${regexps[spaceSingle]}/\n${appDefaults[padding]}\t\t/2")";
            displayHeader "${actionHeaders[DETAIL]}";
            echo -e "${appDefaults[padding]}${detailMsgs[STATUS]}:\t${fields[status]}";
            echo -e "${appDefaults[padding]}${detailMsgs[NAME]}:\t${fields[name]}";
            echo -e "${appDefaults[padding]}${detailMsgs[DESCR]}:\t$(shorten "${fields[descr]}" 55)";
            echo -e "${appDefaults[padding]}${detailMsgs[STORAGE]}:\t${storageDevs[${fields[storage]}]}";
            echo -e "${appDefaults[padding]}${detailMsgs[PATH]}:\t$path";
            echo -e "${appDefaults[padding]}${detailMsgs[FILES]}:\t$files";
            echo -e "${appDefaults[padding]}${detailMsgs[SIZE]}:\t${fields[size]}";
            displayDelimiter;
        done
    else
        return 1;
    fi
}

# display return prompt
function displayReturnPrompt {
    echo -e "\n${appDefaults[padding]}${commonMsgs[SET_RETURN]}: ";
}

# display confirm prompt
function displayConfirmPrompt {
    echo -e "\n${appDefaults[padding]}${commonMsgs[SET_CONFIRM]}: ";
}

# display selection prompt
function displaySelectPrompt {
    local msg;
    [ -n "$1" ] && msg="${commonMsgs[ONLY_SELECT]}" || msg="${commonMsgs[SET_SELECT]}";
    echo -e "\n${appDefaults[padding]}$msg: ";
}

# display description prompt
function displayDescrPrompt {
    echo -e "\n${appDefaults[padding]}${backupMsgs[SET_DESCR]}: ";
}

# display selected drive
function displaySelectedDrive {
    [ ${#storages[@]} -eq 2 ] && echo "${storages[$EXT]} and ${storages[$INT]}" || echo "${storages[@]}";
}

# display selection warning
function displaySelectWarnMsg {
    echo -e "\n${appDefaults[padding]}${commonMsgs[WARN_SELECT]}";
}

# display selection error
function displaySelectErrMsg {
    echo -e "${commonMsgs[ERR_SELECT]}";
}

# display by default entry
function displayByDefault {
    echo -e "${appDefaults[padding]}${commonMsgs[BY_DEFAULT]}: ";
}

# display default value number
function displayDefaultNum {
    [ -n "$1" ] && echo -e "[ $1 ]" || return 1;
}

# display index entry
function displayIndex {
    [ -n "$1" ] && echo -e "${appDefaults[padding]}[ $1 ]\t" || return 1;
}

# display delimiter
function displayDelimiter {
    echo -e "${appDefaults[padding]}${appDefaults[delim]}";
}

# display error message
function displayErrorMsg {
    if [ -n "$1" ]; then
        displayTitle;
        displayHeader "${actionHeaders[ERROR]}";
        echo -e "${appDefaults[padding]}$(echo "$1" | sed -E "s/${regexps[errLength]}/&\n${appDefaults[padding]}/g")";
        displayDelimiter;
        [ -n "$status" ] && status="${statusFlags[FAIL]}";
    else
        return 1;
    fi
}

# display loader
function displayLoader {
    if [ -n "$1" ]; then
        local leftPad;
        local vertPad;
        leftPad=$((COLUMNS/2+${#1}/2));
        vertPad="$(for i in $(seq 1 $((LINES/2-2))); do echo -n '\n'; done)";

        displayTitle;
        printf "$vertPad%${leftPad}s%s...$vertPad" "$1";
        displayDelimiter;
    else
        return 1;
    fi
}
