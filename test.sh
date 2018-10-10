#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
nc='\033[0m'

echo -e "---------------------timezone,dns,port check---------------------"
timedatectl | grep "Time zone: America/Los_Angeles" >> /dev/null
if [[ $? -eq 0 ]];then echo -e  "Time zone:America/Los_Angeles set ${green}successfully${nc}\n";else echo -e  "Time zone:not set to America/Los_Angeles ,${red}unsuccessfull${nc}\n";fi

grep -e "\<Port 2022\>" /etc/ssh/sshd_config  >> /dev/null
if [[ $? -eq 0 ]];then echo -e "Port:2022 set ${green}successfully${nc}\n";else echo -e " Port not set to 2022,${red}unsuccessfull${nc}\n";fi

grep -e "UseDNS no" /etc/ssh/sshd_config >> /dev/null
if [[ $? -eq 0 ]];then echo -e "UseDNS:no set ${green}successfully${nc}\n";else  echo -e " useDNS not set to no ,${red}unsuccessfull${nc}\n";fi

echo -e  "---------------------listing all the disks---------------------"
disks=$(lsblk -l | grep disk | awk '{print $1}')
echo  $disks
diskcount=$(lsblk -l | grep disk | awk '{print $1}'|wc -l)

echo -e  "---------------------lvm partitions created---------------------"
lvmcount=$(fdisk -l |grep "Linux LVM"|wc -l)
if [ $diskcount -eq $lvmcount ];then echo -e "lvm created on the  following disks,${green}successfully${nc}\n";fdisk -l |grep "Linux LVM";else echo -e " lvm partition not created on $diskcount  disks, ${red}unsuccessfull${nc}\n";fdisk -l |grep "Linux LVM";fi
echo -e "---------------------PV LV VG created---------------------"

pvcount=0
for i in $disks
do
        pvdisplay |grep " PV Name               /dev/$i" >> /dev/null; if [[ $? -eq 0 ]];then ((pvcount++));fi
done

if [ $pvcount -eq $diskcount ];then echo -e "pv created on $diskcount disks, ${green}successfully${nc}\n";pvdisplay |grep "PV Name";else echo -e "pv not created on $diskcount disks, ${red}unsuccessfull${nc}\n";fi


vgname=$(vgdisplay |grep "VG Name               vg_data"|awk '{print $3}')
if [[ $? -eq 0 ]];then echo -e "vg created with name $vgname, ${green}successfully${nc}\n";else echo -e "vg not created, ${red}unsuccessfull${nc}\n";fi

lvname=$(lvdisplay |grep "LV Name                data" |awk '{print $3}')
if [[ $? -eq 0 ]];then echo -e "lv created with name $lvname,${green}successfully${nc}\n";else echo -e "lv not created,${red}unsuccessfull${nc}\n";fi

echo -e "--------------------- data folder is creation check--------------------"
find / -maxdepth 1 -type d -name data  >> /dev/null
if [[ $? -eq 0 ]];then echo -e "folder data created ${green}successfully${nc}\n";else echo -e "folder data not created,${red}unsuccessfull${nc}\n";fi

echo -e "--------------------- line added in  a /etc/fstab file check ---------------------"
grep vg_data /etc/fstab  >> /dev/null
if [[ $? -eq 0 ]];then echo -e "line addes  in a /etc/file ${green}successfully${nc}\n";else echo -e "line not added, ${red}unsuccessfull${nc}\n";fi


echo -e "---------------------vg mount check---------------------"
findmnt|grep vg_data >> /dev/null
if [[ $? -eq 0 ]];then echo -e " vg mounted,${green}successfully${nc}\n";else echo -e " vg not mounted,${red}unsuccessfull${nc}\n";fi
