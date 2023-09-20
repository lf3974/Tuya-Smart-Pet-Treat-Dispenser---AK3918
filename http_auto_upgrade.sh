#!/bin/sh

wifi_dev="wlan0"
file_path="/tmp"
sys_img="sys.img"
sys_md5="sys_md5.txt"
uImage="uImage"
uImage_md5="uImage_md5.txt"
http_ip_and_port="http://192.168.7.11:8088"
http_server_addr="$http_ip_and_port/$PRODUCT_MODE"

ver_str=`cat /mnt/config/jiake_version.txt | grep "version=" | awk -F "version=" '{print $2}'`
ver_len=${#ver_str}
product_type_len=$(($ver_len-3))
ver_num_len=$(($ver_len-2))
ver_num=${ver_str:$ver_num_len}
product_type=${ver_str:0:$product_type_len}
upgrade_wifi_name="upgrade_"$product_type

while true
do
    # wait for driver ready. #
    ret=`ifconfig | grep $wifi_dev`
    if [ "$ret" = ""  ];then
        ifconfig $wifi_dev up
    else
        break
    fi
    sleep 0.3
done

# check and connect to the special ssid. #
ret=`iwlist $wifi_dev scan | grep $upgrade_wifi_name`
if [ "$ret" != ""  ];then
    upgrade_ssid=`echo ${ret#*\"}`
    upgrade_ssid=`echo ${upgrade_ssid%%\"*}`
else
    echo "no scan upgrade wifi ssid"
    exit
fi

wifi_ver_num=`echo $upgrade_ssid | awk -F $upgrade_wifi_name"." '{print $2}'`
# compare firmware version #
if [ "$wifi_ver_num" -eq "$ver_num" ];then
    echo "no need to upgrade firmware version"
    exit
fi

wpa_passphrase "$upgrade_ssid" 12345678 > /tmp/wpa_conf

# execute led ctrl shell #
http_upgrade_led_ctrl.sh &

# connect to WiFi network #
wifi_mode_switch.sh STA $wifi_dev visible_ssid
`touch "$file_path/connect_wifi_success"`

# get file path #
cd $file_path

# download system #
wget -t 3 -T 30 -P $file_path $http_server_addr/$sys_img
if [ $? = 0  ];then
    echo "wget sys ok"
    wget -t 3 -T 30 -P $file_path $http_server_addr/$sys_md5
else
    echo "wget sys failed"
fi

# download uImage #
wget -t 3 -T 30 -P $file_path $http_server_addr/$uImage
if [ $? = 0  ];then
    echo "wget uImage ok"
    wget -t 3 -T 30 -P $file_path $http_server_addr/$uImage_md5
else
    echo "wget uImage failed"
fi

# upgrade uImage #
if [ -e "$file_path/$uImage" ];then
    local_md5=`md5sum $file_path/$uImage | awk -F ' ' '{print $1}'`
    get_md5=`cat $file_path/$uImage_md5`
    if [ "$local_md5" = "$get_md5" ];then
        echo "upgrade uImage now"
        updater local KERNEL=/tmp/uImage
        `touch "$file_path/upgrade_ok"`
        echo "upgrade uImage success"
    else
        echo "uImage md5 is error"
        `touch "$file_path/upgrade_failed"`
    fi
fi

# upgrade sys #
if [ -e "$file_path/$sys_img" ];then
    local_md5=`md5sum $file_path/$sys_img | awk -F ' ' '{print $1}'`
    get_md5=`cat $file_path/$sys_md5`
    if [ "$local_md5" = "$get_md5" ];then
        echo "upgrade sys now"
        updater local A=/tmp/sys.img
        `touch "$file_path/upgrade_ok"`
        echo "upgrade sys success"
    else
        echo "sys md5 is error"
        `rm "$file_path/upgrade_ok"`
        `touch "$file_path/upgrade_failed"`
    fi
fi

if [ ! -e "$file_path/$sys_img" ] && [ ! -e "$file_path/$uImage" ];then
    echo "upgrade file isn't exist"
    `touch "$file_path/upgrade_failed"`
fi

# device waiting for reboot #
while true
do
    sleep 3
done
