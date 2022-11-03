#!/usr/bin/env bash

# ------ [ System Recovery Utility ] -----
# ----------------------------------------
#        shell command line utility
#      project source code repository:
# https://github.com/d-efimov/sys-recovery
# open source software © 2022 Denis Efimov
# ----------------------------------------

# -------------- [ MODULE ] --------------
#           system backup actions
# ----------------------------------------

# create system backup
function createBackup {
    displayHeader 'Create System Backup';

    cd "$intMountRoot" 2> /dev/null || exitProcess "$intMountRoot $FAIL_CHANGE_DIR" 1;
}

# select system backup
function selectBackup {
    displayHeader 'Select System Backup';
}

# restore system backup
function restoreBackup {
   displayHeader 'Restore System Backup';

   cd "$intMountRoot" 2> /dev/null || exitProcess "$intMountRoot $FAIL_CHANGE_DIR" 1;
}

# remove system backup
function removeBackup {
    displayHeader 'Remove System Backup';
}

# copy system backup
function copyBackup {
    displayHeader 'Copy System Backup';
}

# get hash
function getHash {
    true;
}

# verify hash
function verifyHash {
    true;
}
