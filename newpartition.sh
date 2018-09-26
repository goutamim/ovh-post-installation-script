#!/usr/bin/env bash

#disk partition creation
disks=$(lshw -class disk -short|grep disk |awk '{print $2}')
for i in $disks
do
    echo "making partion on this disk $i"
    fdisk -l $i |grep "Device"
    if [[ $? -eq 0 ]];
    then

             #creating partition on disk with  existing partition
             start_freespace=$(parted "$i" unit s print free |grep Free |tail -1 | awk '{print $1}')
             start=${start_freespace::-1}
             (echo n; echo p; echo "$start"; echo ""; echo t; echo "";echo 8e;echo w) |fdisk $i
     else
             #creating partition on disk with no partition
             (echo n; echo p; echo ""; echo "";echo "";echo t;echo 8e;echo w) |fdisk $i
    fi
done

#physical volume creation
freepartiton=$(fdisk -l |grep "Linux LVM"|awk '{print $1}')
pvcreate $freepartiton

#volumegroup creation
vgcreate  vg_data $freepartition

#logical volume creation
lvcreate --name data -l 100%FREE vg_data

#creating file system of type ext4
mkfs.ext4  /dev/vg_data/data -F

#appending a line to a /etc/fstab file ,if it doesnt exist
grep vg_data
if [[ $? -ne 0 ]];
then
echo "/dev/vg_data/data       /data   ext4    errors=remount-ro,discard       0       1" >> /etc/fstab
fi

#mounting
mount -a
