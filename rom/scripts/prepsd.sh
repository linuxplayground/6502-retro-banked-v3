#!/bin/bash

sudo diskutil unmount /dev/disk2s1
sudo fdisk -i -a dos /dev/disk2
sudo newfs_msdos -v 6502 -F 32  /dev/disk2s1
sudo diskutil mount -mountpoint ~/mnt /dev/disk2s1
cp -r ~/temp/* ~/mnt/
sudo diskutil unmount /dev/disk2s1

