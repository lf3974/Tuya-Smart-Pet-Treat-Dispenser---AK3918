#!/bin/sh

cp /usr/ipcam/bak/jiake_version.txt /mnt/config/

if [ ! -d "/mnt/config/record" ];then
    mkdir -p /mnt/config/record
fi

if [ -e "/mnt/config/tuya_config.txt" ];then
    echo "tuya_config.txt is exist"
else
    cp /usr/ipcam/bak/tuya_config.txt /mnt/config/
fi

if [ -e "/mnt/config/ucheck_mac.txt" ];then
    echo "ucheck_mac.txt is exist"
else
    cp /usr/ipcam/bak/ucheck_mac.txt /mnt/config/
fi

if [ ! -d "/mnt/config/dp_file_flag" ];then
    cp /usr/ipcam/bak/dev_config.ini /mnt/config/
    touch /mnt/config/no_network

    mkdir -p /mnt/config/dp_file_flag/
    touch /mnt/config/dp_file_flag/md_low_sensitivity_file
    touch /mnt/config/dp_file_flag/on_osd_file
    touch /mnt/config/dp_file_flag/on_light_led_file
fi

# create wifi error info folder 
mkdir -p /tmp/wifi_error_info/

if [ -e "/mnt/config/tmp_test.sh" ];then
    chmod 777 /mnt/config/tmp_test.sh
    /mnt/config/tmp_test.sh
fi

# upgrade firmware #
http_auto_upgrade.sh

product_wifi_scan.sh
if [ $? = 1 ];then
    echo "start main procedure"
    get_mcu_version
    feed_watchdog_daemon.sh &
    tuya_daemon.sh &
else
    echo "product test now"
fi
