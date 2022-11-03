#!/usr/bin/env bash

# ------ [ System Recovery Utility ] -----
# ----------------------------------------
#        shell command line utility
#      project source code repository:
# https://github.com/d-efimov/sys-recovery
# open source software © 2022 Denis Efimov
# ----------------------------------------

# -------------- [ MODULE ] --------------
#       configuration data structures
# ----------------------------------------

# global runtime variables
declare -g cwd;
declare -gA storages;
declare -gA storagePaths;
declare -gA storageNames;

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
    [hw]=''
    [root]=''
    [boot]=''
    [home]=''
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

declare -gA vm=(
    [hw]='91303e3ef8e64b8dbea461642ef5e7f5'
    [root]='38ccd535-396b-444c-adcc-c55f6fd6c2ca'
    [boot]='8688-D47A'
    [home]='3724792d-829c-4c39-9831-573a762ca9ab'
    [user]=1000
    [name]='Virtual Hard Drive Disk'
);

# mount points
declare -gA mounts=(
    [root]='/media/int-store'
    [boot]="/media/int-store/boot/efi"
    [home]="/media/int-store/home"
    [store]='/media/ext-store'
);

# file paths
declare -gA paths=(
    [ext]="${mounts[store]}/[hw]"
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

# selected storage
declare -g defaultStorage=3;

# display settings
declare -g appName='System Recovery Utility';
declare -g displayTimeout=4;
