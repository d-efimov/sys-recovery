#!/usr/bin/env bash

# set directories paths
distDir='dist';
srcDir='src';

# exit from process
function exitProc {
    [ -n "$1" ] && echo "$1";
    local code;
    [ -z "$2" ] && code=0 || code="$2";
    exit "$code";
}

if [ -n "$1" ]; then
    # write source content
    [ -d "$distDir" ] || exitProc "$distDir not found" 1;
    [ -d "$srcDir" ] || exitProc "$srcDir not found" 1;
    rm -rf "${distDir:?}"/* 2> /dev/null || exitProc "$distDir failed to clean" 1;
    cp -rp "$srcDir"/* "$distDir" 2> /dev/null || exitProc "$distDir filed copy to dir" 1;

    # load modules
    moduleConf="$srcDir/modules/conf.sh";
    [ -f "$moduleConf" ] && source "$moduleConf" 2> /dev/null || exitProc "$moduleConf not found" 1;

    # set uuid file
    declare -n storage="$1" 2> /dev/null;
    [ ${#storage[@]} -eq 0 ] && exitProc 'storage name not found' 1;
    storageUuid="${storage[recovery]}";
    uuidFile="$distDir/${files[uuid]}";
    echo "$storageUuid" > "$uuidFile";
    [ -f "$uuidFile" ] || exitProc "$uuidFile file not found" 1;
    unset -n storage;

    exitProc "software successfully build to directory ./$distDir " 0;
else
    exitProc 'storage name not passed during file execution' 1;
fi
