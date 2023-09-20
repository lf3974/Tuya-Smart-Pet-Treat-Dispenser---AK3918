#!/bin/sh

# killall proces #
free_memory.sh

upgrade_uImage()
{
    if [ -e "/tmp/uImage" ];then
        echo "wait,upgrade uImage now !!"
        updater local KERNEL=/tmp/uImage
    else
        echo "/tmp/uImage is not exist !!"
    fi
    sleep 0.5
}

upgrade_filesystem()
{
    if [ -e "/tmp/sys.img" ];then
        echo "wait,upgrade now !!"
        burn_ok_led.sh upgrade_sys &
        upgrade_uImage
        updater local A=/tmp/sys.img
        echo "upgrade success,reboot now !!"
        sleep 1
        reboot
    else
        echo "/tmp/sys.img is not exist !!"
        reboot
    fi
}

upgrade_filesystem
