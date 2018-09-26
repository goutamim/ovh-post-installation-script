#!/usr/bin/env bash

# set timezone
timedatectl set-timezone America/Los_Angeles

# Change ssh port to 2022
sed -i -E  "s/^#?Port 22/Port 2022/g" /etc/ssh/sshd_config

# Add "UseDNS no"
sed -i -E  "s/^#?UseDNS no/UseDNS no/g" /etc/ssh/sshd_config

#restart sshd service
systemctl restart sshd

#disk partition creation
disks=$(lsblk -l | grep disk | awk '{print $1}')

for i in $disks
do
   
    echo "creating partion on disk /dev/$i"
    fdisk -l /dev/$i |grep "Device"
    if [[ $? -eq 0 ]];
      then
	      #start_freespace to get the start of the free space 
	      start_freespace=$(parted "/dev/$i" unit s print free |grep Free |tail -1 | awk '{print $1}')
	      start=${start_freespace::-1}
	      #echo $start
	      #creating partition on  disk
	      (echo n; echo p; echo "$start"; echo " ";echo t;echo "";echo 8e;echo w) |fdisk /dev/$i
      else
	      (echo n; echo p; echo ""; echo "";echo "";echo t;echo 8e;echo w) |fdisk /dev/$i
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

#creating directory 
mkdir -p /data

#mounting
mount -a
