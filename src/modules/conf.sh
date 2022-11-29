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
#       configuration data structures
# ----------------------------------------

# global constants
declare -g INT='int';
declare -g EXT='ext';
declare -g BOTH='both';
declare -g STORE='store';
declare -g ROOT='root';
declare -g BOOT='boot';
declare -g HOME='home';

# global runtime variables
declare -gA storages;
declare -gA storagePaths;
declare -gA storageDevs;
declare -ga backups;

# application defaults
declare -gA appDefaults=(
    [title]='    --------------------- [ System Recovery Utility ] ---------------------    '
    [storage]=2
    [timeout]=3
    [action]=0
    [delim]='-----------------------------------------------------------------------'
    [padding]="    "
    [local]='en_US.UTF-8'
    [mainFs]='ext4'
    [bootFs]='vfat'
);

# hardware platforms
declare -ga platforms=(
    "(
        [type]='$INT'
        [hw]='6bb29f2e1e1f4a2e82d57f5db07b46aa'
        [$ROOT]='0e7cf068-09c9-42cc-b9de-d8b83633bd0e'
        [$BOOT]='3769-DEF8'
        [$HOME]='d3f0279b-a740-48cc-a118-83666b828c85'
        [user]=1000
        [name]='SATA Hard Drive Disk'
    )" "(
        [type]='$INT'
        [hw]='6ffbe13075134f048186af5d2db766ff'
        [$ROOT]='69863c14-c6d7-4536-8a15-858e5ef5701d'
        [$BOOT]='C6EB-942C'
        [$HOME]='66f91c76-ffb3-4f9e-8387-283952186eb3'
        [user]=1000
        [name]='NVMe Solid-State Drive'
    )" "(
        [type]='$INT'
        [hw]='91303e3ef8e64b8dbea461642ef5e7f5'
        [$ROOT]='38ccd535-396b-444c-adcc-c55f6fd6c2ca'
        [$BOOT]='8688-D47A'
        [$HOME]='3724792d-829c-4c39-9831-573a762ca9ab'
        [user]=1000
        [name]='Virtual Hard Drive Disk'
    )" "(
        [type]='$EXT'
        [$STORE]='6fa86c00-11e9-470b-8441-ddbfdb172bde'
        [recovery]='801379be-e3e7-4200-963e-f627a35e6c68'
        [name]='USB Hard Drive Disk'
    )" "(
        [type]='$EXT'
        [$STORE]='ac3d1382-c98a-4133-a52f-edcedd2f7910'
        [recovery]='980ac95d-5e53-40e8-9ba1-c8b5538bbd3a'
        [name]='USB Flash Drive'
    )"
);

# mount order
declare -ga mountOrder=(
    "$STORE"
    "$ROOT"
    "$BOOT"
    "$HOME"
);

# mount points
declare extStore="/media/$EXT-store";
declare intStore="/media/$INT-store";
declare -gA mounts=(
    [$STORE]="$extStore"
    [$ROOT]="$intStore"
    [$BOOT]="$intStore/boot/efi"
    [$HOME]="$intStore/home"
);

# placeholders
declare -gA placeholders=(
    [home]="pl-home"
    [user]="pl-user"
    [hw]="pl-hw"
    [length]="pl-length"
);

# file paths
declare -gA paths=(
    [$EXT]="$extStore/${placeholders[hw]}"
    [$INT]="${placeholders[user]}/backup"
);

# tar archive options
declare -gA tarOptions=(
    [ext]='tar.bz2'
    [create]='-cpjf'
    [restore]='-xpjf'
);

# exclude root file system backup paths
declare -gA excludeRoot=(
    [home]="${placeholders[home]}/*"
    [var]='var/cache/apt/archives/*'
    [tmp]='tmp/*'
    [swap]='swapfile'
);

# exclude home folder backup paths
declare -gA excludeHome=(
    [current]='.'
    [parent]='..'
    [cache]='.cache/*'
    [trash]='.local/share/Trash/*'
);

# regular expressions
declare -gA regexps=(
    [errLength]='.{70}'
    [backupName]='^[0-9.at-]{22}$'
    [strLength]="^.{0,${placeholders[length]}}"
    [userHome]='home/[a-z]+'
    [backupFile]="[a-z-]*.${tarOptions[ext]}$"
    [numberOnly]='^[0-9]+$'
    [numberStart]='^[0-9]+'
    [dotZeroEnd]='\.0$'
    [spaceStart]='^\s*'
    [spaceEnd]='\s*$'
    [spaceSingle]='\s'
);

# file names
declare -gA files=(
    [uuid]='uuid'
    [root]="root-backup.${tarOptions[ext]}"
    [home]="home-backup.${tarOptions[ext]}"
    [descr]='descr.txt'
    [checksum]='checksum.sha256'
    [broken]='broken'
);

# required backup files
declare -ga requiredFiles=(
    "${files[root]}"
    "${files[home]}"
    "${files[descr]}"
    "${files[checksum]}"
);

# action headers
declare -gA actionHeaders=(
    [BACKUP]='create system backup'
    [RESTORE]='restore system backup'
    [REMOVE]='remove system backup'
    [COPY]='copy system backup'
    [STORAGE]='select storage drive'
    [DRIVES]='drives list'
    [LIST]='display system backup list'
    [BACKUPS]='backup list'
    [VERIFY]='verify system backup integrity'
    [ABOUT]='display info about application'
    [EXIT]='exit from application'
    [ERROR]='application error'
    [ACTION]='select action'
    [DETAIL]='backup detail'
);

# action order
declare -ga actionOrder=(
    'BACKUP'
    'RESTORE'
    'REMOVE'
    'COPY'
    'LIST'
    'VERIFY'
    'STORAGE'
    'ABOUT'
    'EXIT'
);

# storage order
declare -ga storageOrder=(
    "$EXT"
    "$INT"
    "$BOTH"
);

# storage type
declare -gA storageTypes=(
    [$EXT]='external'
    [$INT]='internal'
    [$BOTH]='external and internal drive'
);

# error messages
declare -gA err=(
    [FILE_NOT_FOUND]='file not found'
    [DIR_NOT_FOUND]='directory not found'
    [DEV_NOT_FOUND]='device not found'
    [HARDWARE_NOT_FOUND]='hardware not found'
    [FAIL_DIR_CREATE]='failed to create directory'
    [FAIL_FILE_WRITE]='failed to write file'
    [FAIL_PART_MOUNT]='failed to mount partition'
    [FAIL_CHANGE_DIR]='failed to change directory'
    [FAIL_CHANGE_RIGHTS]='failed to change user rights'
    [FAIL_BACKUP_CREATE]='failed to create backup'
    [FAIL_BACKUP_FIND]='failed to find backup'
    [FAIL_BACKUP_COPY]='failed to copy backup'
    [FAIL_HASH_CACL]='failed to calculate checksum'
    [FAIL_HASH_VERIFY]='failed to verify checksum'
);

# explain messages
declare -gA explainMsgs=(
    [BACKUP]='backup all files in root, efi partitions and hidden files in home dir'
    [RESTORE]='remove current system and restore from backup, except files in home dir'
    [REMOVE]='remove selected backup from storage drive'
    [COPY]='copy selected backup between storage drives'
    [STORAGE]='select storage drives to create, restore and display backup list'
    [LIST]='list all available backups on selected storage drives'
    [VERIFY]='verify all system backup integrity by recalculate checksum'
    [ABOUT]='system recovery command line utility, copyright © 2022 Denis Efimov'
    [EXIT]='unmount storage drives, exit from recovery utility'
);

# common application messages
declare -gA commonMsgs=(
    [ONLY_SELECT]='type number and press enter for selection'
    [SET_SELECT]='type n for return or type number and press enter for selection'
    [SET_RETURN]='type n for return or press enter to continue'
    [SET_CONFIRM]='type y for confirm or press enter to return'
    [WANT_EXIT]='do you want to exit from application?'
    [WARN_SELECT]='incorrect selection, default value will be used'
    [ERR_SELECT]='incorrect selection, please try again'
    [APP_ERROR]='runtime application error'
    [PRESS_BREAK]='pressing break key combination'
    [BY_DEFAULT]='by default'
    [IS_SUCCESS]='successful'
    [IS_FAIL]='fail'
    [IS_CANCEL]='canceled'
    [IS_COPIED]='copy backup to'
    [IS_EXIT]='exit'
    [TO_CONTINUE]='press enter to continue'
    [IS_BROKEN]='broken'
    [IS_NORMAL]='normal'
    [LOADING]='loading'
);

# storage action messages
declare -gA storageMsgs=(
    [SELECTED_STORAGE]='selected storage'
    [USED_STORAGE]='currently used storage'
    [GB_FREE]='free GB'
);

# backup action messages
declare -gA backupMsgs=(
    [SET_DESCR]='type description and press enter'
    [BE_COPIED]='after creation backup will be copied to'
    [NO_DESCR]='description not specified'
    [IN_PROGRESS]='backup current system'
    [CALC_HASH]='calculate backup checksum'
);

# backup detail messages
declare -gA detailMsgs=(
    [PATH]='path'
    [NAME]='name'
    [FILES]='files'
    [STORAGE]='storage'
    [DESCR]='descr'
    [STATUS]='status'
    [SIZE]='size GB'
);

# verify hash messages
declare -gA hashMsgs=(
    [IS_BROKEN]='backup is broken'
    [IS_VERIFY]='verify backup checksum'
);

# execution status flags
declare -gA statusFlags=(
    [DONE]='done'
    [FAIL]='fail'
    [CANCEL]='cancel'
);

# backup model fields
declare -ga modelFields=(
    'name'
    'storage'
    'descr'
    'status'
    'files'
    'size'
);
