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

# global runtime variables
declare -gA storages;
declare -gA storagePaths;
declare -gA storageDevs;

# error messages
declare -gA err=(
    [FILE_NOT_FOUND]='file not found'
    [DIR_NOT_FOUND]='directory not found'
    [DEV_NOT_FOUND]='device not found'
    [HARDWARE_NOT_FOUND]='hardware not found'
    [FAIL_DIR_CREATE]='failed to create directory'
    [FAIL_PART_MOUNT]='failed to mount partition'
    [FAIL_CHANGE_DIR]='failed to change directory'
    [FAIL_CHANGE_RIGHTS]='failed to change user rights'
);

# external hardware platforms
declare -ga extPlatforms=(
    'usbHdd'
    'usbFlash'
);

# external usb hdd platform
declare -gA usbHdd=(
    [store]='6fa86c00-11e9-470b-8441-ddbfdb172bde'
    [recovery]='801379be-e3e7-4200-963e-f627a35e6c68'
    [name]='USB Hard Drive Disk'
);

# external usb flash platform
declare -gA usbFlash=(
    [store]='ac3d1382-c98a-4133-a52f-edcedd2f7910'
    [recovery]='980ac95d-5e53-40e8-9ba1-c8b5538bbd3a'
    [name]='USB Flash Drive'
);

# internal hardware platforms
declare -ga intPlatforms=(
    'notebook'
    'desktop'
    'vm'
);

# internal notebook platform
declare -gA notebook=(
    [hw]='6bb29f2e1e1f4a2e82d57f5db07b46aa'
    [root]='0e7cf068-09c9-42cc-b9de-d8b83633bd0e'
    [boot]='3769-DEF8'
    [home]='d3f0279b-a740-48cc-a118-83666b828c85'
    [user]=1000
    [name]='SATA Hard Drive Disk'
);

# internal desktop platform
declare -gA desktop=(
    [hw]='6ffbe13075134f048186af5d2db766ff'
    [root]='69863c14-c6d7-4536-8a15-858e5ef5701d'
    [boot]='C6EB-942C'
    [home]='66f91c76-ffb3-4f9e-8387-283952186eb3'
    [user]=1000
    [name]='NVMe Solid-State Drive'
);

# internal virtual platform
declare -gA vm=(
    [hw]='91303e3ef8e64b8dbea461642ef5e7f5'
    [root]='38ccd535-396b-444c-adcc-c55f6fd6c2ca'
    [boot]='8688-D47A'
    [home]='3724792d-829c-4c39-9831-573a762ca9ab'
    [user]=1000
    [name]='Virtual Hard Drive Disk'
);

# mount order
declare -ga mountOrder=(
    'store'
    'root'
    'boot'
    'home'
);

# mount points
local intStore='/media/int-store';
local extStore='/media/ext-store';
declare -gA mounts=(
    [store]="$extStore"
    [root]="$intStore"
    [boot]="$intStore/boot/efi"
    [home]="$intStore/home"
);

# file paths
declare -gA paths=(
    [ext]="$extStore/[hw]"
    [int]="[user]/backup"
);

# file names
declare -gA files=(
    [uuid]='uuid'
    [backup]='system-backup.tar.bz2'
    [descr]='descr.txt'
    [checksum]='checksum.sha256'
    [broken]='broken'
);

# application defaults
declare -gA appDefaults=(
    [title]='--------------------------[ System Recovery Utility ]--------------------------'
    [storage]=2
    [timeout]=3
    [action]=0
    [headDelim]='-----------------------------------------------------------------------'
    [padding]="    "
)

# action headers
declare -gA actionHeaders=(
    [backup]='create system backup'
    [restore]='restore system backup'
    [remove]='remove system backup'
    [copy]='copy system backup'
    [storage]='select storage drive'
    [exit]='exit from application'
    [error]='application error'
    [action]='select action'
);

# action order
declare -ga actionOrder=(
    'backup'
    'restore'
    'remove'
    'copy'
    'storage'
    'exit'
);

# storage order
declare -ga storageOrder=(
    'ext'
    'int'
    'both'
);

# storage type
declare -gA storageTypes=(
    [ext]='external'
    [int]='internal'
    [both]='external and internal drive'
);

# storage order
declare -gA displayMsg=(
    [SET_SELECT]='type number and press enter for selection'
    [SELECTED_STORAGE]='selected storage:'
    [USED_STORAGE]='currently used storage:'
    [SET_DESCR]='type description and press enter'
    [SET_EXIT]='type n for continue or press enter to exit'
    [WANT_EXIT]='do you want to exit from application?'
    [WARN_SELECT]='incorrect selection, default value will be used'
    [APP_ERROR]='application error'
    [PRESS_BREAK]='pressing break key combination'
    [BY_DEFAULT]='by default'
    [IS_SUCCESS]='successful'
    [IS_CANCEL]='canceled'
    [GB_FREE]='GB free'
);
