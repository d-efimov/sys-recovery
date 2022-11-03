#!/usr/bin/env bash

# set directories paths
mountDir="/media/recovery";
moduleDir='src/modules';
distDir='dist';

# exit from process
function exitProc {
    if [ -d "$mountDir" ]; then
        sudo umount -q "$mountDir" 2> /dev/null;
        sudo rmdir "$mountDir" 2> /dev/null;
    fi

    [ -n "$1" ] && echo "$1";

    local code;
    [ -z "$2" ] && code=0 || code="$2";
    exit "$code";
}

# load modules
declare -a modules=(
    "$moduleDir/utils.sh"
    "$moduleDir/conf.sh"
)

for module in "${modules[@]}"
do
    [ -f "$module" ] && source "$module" 2> /dev/null || exitProc "$module not found" 1;
done

# build software
./build.sh 'usbFlash' || exitProc "filed to build software" 1;

# set usb drive
[ -d "$distDir" ] || exitProc "$distDir not found" 1;
uuid="$(cat "$distDir/${files[uuid]}" 2> /dev/null)";
usbDev="$(deviceByUuid "$uuid")";
[ -b "$usbDev" ] || exitProc "$usbDev not found" 1;

# mount usb drive
if ! [ -d "$mountDir" ]; then
    sudo mkdir "$mountDir" 2> /dev/null || exitProc "$mountDir filed to create dir" 1;
fi

srcTarget="$usbDev $mountDir";
if ! [ "$(findmnt -o SOURCE,TARGET "$srcTarget" 2> /dev/null | grep -q "$mount")" ]; then
    sudo mount -o rw -t ext4 "$usbDev" "$mountDir" 2> /dev/null ||
        exitProc "$mountDir filed to mount dir" 1;
fi

# write content
sudo rm -rf "${mountDir:?}"/* 2> /dev/null || exitProc "$mountDir filed to clean dir" 1;
sudo cp -rp "$distDir"/* "$mountDir" 2> /dev/null || exitProc "$mountDir filed copy to dir" 1;
sudo chown -R root:root "$mountDir" 2> /dev/null || exitProc "$mountDir filed to change owner" 1;
sudo chmod -R g-w "$mountDir" 2> /dev/null || exitProc "$mountDir filed to change rights" 1;

# unmount usb drive
exitProc "software build successfully deployed to device $usbDev" 0;
