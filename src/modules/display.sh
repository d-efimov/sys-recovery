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
            local status;
            [ "$2" == "${statusFlags[DONE]}" ] && status="${commonMsgs[IS_SUCCESS]}" || status="${commonMsgs[IS_FAIL]}";
            printf "\n%s, %s..." "${appDefaults[padding]}$1 $status" "${commonMsgs[PRESS_ENTER]}";
            read -rs;
        else
            # action is canceled
            echo -e "\n${appDefaults[padding]}$1 ${commonMsgs[IS_CANCEL]}...";
            sleep ${appDefaults[timeout]};
        fi
    else
        return 1;
    fi
}

# display backup list
function displayBackupList {
    true;
}

# display backup detail
function displayBackupDetail {
    if [ -n "$1" ] && [ -n "$2" ]; then
        # read backup description
        local descr;
        local content;
        descr="$(readFile "$1/${files[descr]}")";
        [ -z "$descr" ] && content="${backupMsgs[NO_DESCR]}" || content="$(shorten "$descr" 55)";

        # display backup detail
        local regexp='[0-9.at-]*$';
        local path;
        local name;
        path="$(echo "$1" | sed -e "s/\/$regexp//")";
        name="$(echo "$1" | grep -o "$regexp")";
        displayHeader "${actionHeaders[detail]}";
        echo -e "${appDefaults[padding]}${detailMsgs[PATH]}:\t$path";
        echo -e "${appDefaults[padding]}${detailMsgs[NAME]}:\t$name";
        echo -e "${appDefaults[padding]}${detailMsgs[FILE]}:\t${files[root]}, ${files[home]}";
        echo -e "${appDefaults[padding]}${detailMsgs[CONTENT]}:\t$content";
        echo -e "${appDefaults[padding]}${detailMsgs[STORAGE]}:\t"$2"";
        displayDelimiter;
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
    echo -e "\n${appDefaults[padding]}${commonMsgs[SET_SELECT]}: ";
}

# display description prompt
function displayDescrPrompt {
    echo -e "\n${appDefaults[padding]}${backupMsgs[SET_DESCR]}: ";
}

# display selected drive
function displaySelectedDrive {
    [ ${#storages[@]} -eq 2 ] && echo "${storages[ext]} and ${storages[int]}" || echo "${storages[@]}";
}

# display selection warning
function displaySelectWarnMsg {
    echo -e "\n${appDefaults[padding]}${commonMsgs[WARN_SELECT]}";
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
        displayHeader "${actionHeaders[error]}";
        echo -e "${appDefaults[padding]}$(echo "$1" | sed -e "s/.\{70\}/&\n${appDefaults[padding]}/g")";
        displayDelimiter;
        [ -n "$status" ] && status="${statusFlags[FAIL]}";
    fi
}
