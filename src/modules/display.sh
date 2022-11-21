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

# display header
function displayHeader {
    if [ -n "$1" ]; then
        echo -e "\n${appDefaults[title]}\n";
        echo -e "${appDefaults[padding]}$1\n${appDefaults[padding]}${appDefaults[headDelim]}";
    fi
}

# display footer
function displayFooter {
    if [ -n "$1" ] &&  [ -n "$2" ]; then
        echo -e "\n${appDefaults[padding]}$1 $2...";
    fi
}

# display backup list
function displayBackupList {
    true;
}

# display backup detail
function displayBackupDetail {
    true;
}

# display warning message
function displayWarnMsg {
    true;
}

# display selected drive
function displaySelectedDrive {
    [ ${#storages[@]} -eq 2 ] && echo "${storages[ext]} and ${storages[int]}" || echo "${storages[@]}";
}

# display selection prompt
function displaySelectPrompt {
    echo -e "\n${appDefaults[padding]}${displayMsg[SET_SELECT]}: ";
}

# display selection warning
function displaySelectWarnMsg {
    echo -e "\n${appDefaults[padding]}${displayMsg[WARN_SELECT]}";
}

# display exit prompt
function displayExitPrompt {
    echo -e "\n${appDefaults[padding]}${displayMsg[SET_EXIT]}: ";
}

# display description prompt
function displayDescrPrompt {
    echo -e "\n${appDefaults[padding]}${displayMsg[SET_DESCR]}: ";
}

# display by default entry
function displayByDefault {
    echo -e "${appDefaults[padding]}${displayMsg[BY_DEFAULT]}: ";
}

# display index entry
function displayIndex {
    [ -n "$1" ] && echo -e "${appDefaults[padding]}[ $1 ]\t";
}

# display delimiter
function displayDelimiter {
    echo -e "${appDefaults[padding]}${appDefaults[headDelim]}";
}
