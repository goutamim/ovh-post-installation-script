#!/usr/bin/env bash

# set timezone
timedatectl set-timezone America/Los_Angeles

# Change ssh port to 2022
sed -i -E  "s/^#?Port 22/Port 2022/g" /etc/ssh/sshd_config

# Add "UseDNS no"
sed -i -E  "s/^#?UseDNS no/UseDNS no/g" /etc/ssh/sshd_config

#disk partition creation
disks=$(lshw -class disk -short|grep disk |awk '{print $2}')
count=0  							#count variable to make a partition on sda diffrently
for i in $disks
do
    count=$[$count +1]
    echo $i
    if [ $count -eq 1 ]
      then
	      #start_freespace to get the start of the free space 
	      start_freespace=$(parted "$i" unit s print free |grep Free |tail -1 | awk '{print $1}')
	      start=${start_freespace::-1}
	      #echo $start
	      #creating partition on  disk
	      (echo n; echo p; echo "$start"; echo " ";echo t;echo "";echo 8e;echo w) |fdisk $i
      else
	      (echo n; echo p; echo ""; echo "";echo "";echo yes;echo t;echo 8e;echo w) |fdisk $i
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
grep vg_data /etc/fstab
if [[ $? -ne 0 ]];
then
echo "/dev/vg_data/data       /data   ext4    errors=remount-ro,discard       0       1" >> /etc/fstab
fi

#mounting
mount -a
