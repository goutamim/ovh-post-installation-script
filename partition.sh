#!/bin/bash

# set timezone
timedatectl set-timezone America/Los_Angeles

# Change ssh port to 2022
sed -i -E  "s/^#?Port 22/Port 2022/g" /etc/ssh/sshd_config

# Add "UseDNS no"
sed -i -E  "s/^#?UseDNS no/UseDNS no/g" /etc/ssh/sshd_config

#restart sshd service
systemctl restart sshd

#-------------------------------deletion of existing lv,vg,pv---------------------------------------------


#delete any existing lvs
lvdisplay |grep "LV Path"
if [[ $? -eq 0 ]];
then
        lvdisplay |grep "LV Path" | awk '{print $3}'|xargs umount
        lvdisplay |grep "LV Path" | awk '{print $3}'|xargs lvremove -f
fi


#deletes any existing vgs
vgdisplay |grep "VG Name"
if [[ $? -eq 0 ]];
then
        vgdisplay |grep "VG Name"|awk '{print $3}'| xargs vgremove
fi



#delete any existing pvs
pvdisplay |grep "PV Name"
if [[ $? -eq 0 ]];
then
        pvdisplay |grep "PV Name"|awk '{print $3}'|xargs pvremove
fi


#---------------------------------------disk partiton------------------------------------------------------------

#disk partition creation
disks=$(lsblk -l | grep disk | awk '{print $1}')

for i in $disks
do

    echo "creating partion on disk /dev/$i"
    #check if already there is a partition on disk.
    fdisk -l /dev/$i |grep "Device"
    if [[ $? -eq 0 ]];
      then
              fdisk -l /dev/$i |grep "Linux LVM"
              if [[ $? -ne 0 ]];
              then
                      #start_freespace to get the start of the free space
                      start_freespace=$(parted "/dev/$i" unit s print free |grep Free |tail -1 | awk '{print $1}')
                      start=${start_freespace::-1}
                      #echo $start
                      #creating partition on  disk of type Linux LVM
                      (echo n; echo " "; echo "$start"; echo " ";echo t;echo " ";echo 31;echo w) |fdisk /dev/$i
              fi

      else
              (echo n; echo p; echo " "; echo " ";echo " ";echo t;echo 8e;echo w) |fdisk /dev/$i
    fi
done
#reboot should be done.The kernel still uses the old partitions. The new table will be used at the next reboot.
#reboot not required.
#reboot and then do the physical,logical volume,volume group creation.
#------------------------------------------creation of pv,vg,lv---------------------------------------------------
#physical volume creation
freepartition=$(fdisk -l |grep "Linux LVM"|awk '{print $1}')
pvcreate $freepartition -f


#volumegroup creation
vgcreate vg_data $freepartition

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

#------------------------------------------hostrename---------------------------------------------------
read -p "Enter the name for the soyoustarthost:" hostname
hostnamectl set-hostname $hostname
echo "please reboot the host to take effect of changes made to hostname"
soyoustart_post_installtion_script.sh
Raw
  1
  2
  3
  4
  5
  6
  7
  8
  9
 10
 11
 12
 13
 14
 15
 16
 17
 18
 19
 20
 21
 22
 23
 24
 25
 26
 27
 28
 29
 30
 31
 32
 33
 34
 35
 36
 37
 38
 39
 40
 41
 42
 43
 44
 45
 46
 47
 48
 49
 50
 51
 52
 53
 54
 55
 56
 57
 58
 59
 60
 61
 62
 63
 64
 65
 66
 67
 68
 69
 70
 71
 72
 73
 74
 75
 76
 77
 78
 79
 80
 81
 82
 83
 84
 85
 86
 87
 88
 89
 90
 91
 92
 93
 94
 95
 96
 97
 98
 99
100
101
102
103
104
#!/bin/bash

# set timezone
timedatectl set-timezone America/Los_Angeles

# Change ssh port to 2022
sed -i -E  "s/^#?Port 22/Port 2022/g" /etc/ssh/sshd_config

# Add "UseDNS no"
sed -i -E  "s/^#?UseDNS no/UseDNS no/g" /etc/ssh/sshd_config

#restart sshd service
systemctl restart sshd

#-------------------------------deletion of existing lv,vg,pv---------------------------------------------


#delete any existing lvs
lvdisplay |grep "LV Path"
if [[ $? -eq 0 ]];
then
        lvdisplay |grep "LV Path" | awk '{print $3}'|xargs umount
        lvdisplay |grep "LV Path" | awk '{print $3}'|xargs lvremove -f
fi


#deletes any existing vgs
vgdisplay |grep "VG Name"
if [[ $? -eq 0 ]];
then
        vgdisplay |grep "VG Name"|awk '{print $3}'| xargs vgremove
fi



#delete any existing pvs
pvdisplay |grep "PV Name"
if [[ $? -eq 0 ]];
then
        pvdisplay |grep "PV Name"|awk '{print $3}'|xargs pvremove
fi


#---------------------------------------disk partiton------------------------------------------------------------

#disk partition creation
disks=$(lsblk -l | grep disk | awk '{print $1}')

for i in $disks
do

    echo "creating partion on disk /dev/$i"
    fdisk -l /dev/$i |grep "Device"
    if [[ $? -eq 0 ]];
      then
              fdisk -l /dev/$i |grep "Linux LVM"
              if [[ $? -ne 0 ]];
              then
                      #start_freespace to get the start of the free space
                      start_freespace=$(parted "/dev/$i" unit s print free |grep Free |tail -1 | awk '{print $1}')
                      start=${start_freespace::-1}
                      #echo $start
                      #creating partition on  disk
                      (echo n; echo p; echo "$start"; echo " ";echo t;echo " ";echo 8e;echo w) |fdisk /dev/$i
              fi

      else
              (echo n; echo p; echo " "; echo " ";echo " ";echo t;echo 8e;echo w) |fdisk /dev/$i
    fi
done

#------------------------------------------creation of pv,vg,lv---------------------------------------------------
#physical volume creation
freepartition=$(fdisk -l |grep "Linux LVM"|awk '{print $1}')
#option -fff is required for reinstalltion with different OS. example xenOS  to ubuntuos
pvcreate $freepartition -fff


#volumegroup creation
vgcreate vg_data $freepartition

#logical volume creationmkfs.ext4  /dev/vg_data/data -F
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

#------------------------------------------hostrename---------------------------------------------------
#read -p "Enter the name for the soyoustarthost:" hostname
#hostnamectl set-hostname $hostname
#echo "please reboot the host to take effect of changes made to hostname"
