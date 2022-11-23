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
    if [ -n "$1" ]; then
        echo -e "\n${appDefaults[padding]}[ $1 ]\n${appDefaults[padding]}${appDefaults[headDelim]}";
    fi
}

# display explain
function displayExplain {
    if [ -n "$1" ]; then
        echo -e "${appDefaults[padding]}$1";
    fi
}

# display footer
function displayFooter {
    if [ -n "$1" ]; then
        if [ -n "$2" ]; then
            printf "\n%s, %s... " "${appDefaults[padding]}$1 ${commonMsgs[IS_SUCCESS]}" "${commonMsgs[PRESS_ENTER]}";
            read -rs;
        else
            echo -e "\n${appDefaults[padding]}$1 ${commonMsgs[IS_CANCEL]}...";
            sleep ${appDefaults[timeout]};
        fi
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
        descr="$(sudo cat "$1/${files[descr]}" 2> /dev/null)" ||
            exitProcess "$1/${files[descr]} ${err[FAIL_FILE_READ]}" 1;
        content=$(shorten "$descr" 55);

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
        echo -e "${appDefaults[padding]}${appDefaults[headDelim]}";
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
    [ -n "$1" ] && echo -e "[ $1 ]";
}

# display index entry
function displayIndex {
    [ -n "$1" ] && echo -e "${appDefaults[padding]}[ $1 ]\t";
}

# display delimiter
function displayDelimiter {
    echo -e "${appDefaults[padding]}${appDefaults[headDelim]}";
}
