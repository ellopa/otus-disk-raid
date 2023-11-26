### Дисковая подсистема 


### Увеличение количества дисков в Vagrantfile

- [Vagrantfile добавлены диски ](Vagrantfile_old)

### Собран RAID 10

-Просмотр блочных устройств для выбора массива

```
[vagrant@linuxraid ~]$ sudo lshw -short | grep disk
/0/100/1.1/0.0.0    /dev/sda  disk        42GB VBOX HARDDISK
/0/100/d/0          /dev/sdb  disk        262MB VBOX HARDDISK
/0/100/d/1          /dev/sdc  disk        262MB VBOX HARDDISK
/0/100/d/2          /dev/sdd  disk        262MB VBOX HARDDISK
/0/100/d/3          /dev/sde  disk        262MB VBOX HARDDISK
/0/100/d/4          /dev/sdf  disk        262MB VBOX HARDDISK
/0/100/d/5          /dev/sdg  disk        262MB VBOX HARDDISK
```
```
[vagrant@linuxraid ~]$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk 
`-sda1   8:1    0   40G  0 part /
sdb      8:16   0  250M  0 disk 
sdc      8:32   0  250M  0 disk 
sdd      8:48   0  250M  0 disk 
sde      8:64   0  250M  0 disk 
sdf      8:80   0  250M  0 disk 
sdg      8:96   0  250M  0 disk 
```
```
[vagrant@linuxraid ~]$ sudo -i
```
-Обнуляем суперблоки

```
[root@linuxraid ~]# mdadm --zero-superblock --force /dev/sd{b,c,d,e,f,g}
mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc
mdadm: Unrecognised md component device - /dev/sdd
mdadm: Unrecognised md component device - /dev/sde
mdadm: Unrecognised md component device - /dev/sdf
mdadm: Unrecognised md component device - /dev/sdg
```
-Создаём новый RAID-массив

```
[root@linuxraid ~]# mdadm --create --verbose /dev/md0 -l 10 -n 6 /dev/sd{b,c,d,e,f,g}
mdadm: layout defaults to n2
mdadm: layout defaults to n2
mdadm: chunk size defaults to 512K
mdadm: size set to 253952K
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
```
-Проверим, что RAID собрался корректно

```
[root@linuxraid ~]# cat /proc/mdstat
Personalities : [raid10] 
md0 : active raid10 sdg[5] sdf[4] sde[3] sdd[2] sdc[1] sdb[0]
      761856 blocks super 1.2 512K chunks 2 near-copies [6/6] [UUUUUU]
      
unused devices: <none>

[root@linuxraid ~]# mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Sun Nov 26 07:24:56 2023
        Raid Level : raid10
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 6
     Total Devices : 6
       Persistence : Superblock is persistent

       Update Time : Sun Nov 26 07:25:00 2023
             State : clean 
    Active Devices : 6
   Working Devices : 6
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : linuxraid:0  (local to host linuxraid)
              UUID : 90556b45:cf87085c:1d71dd41:59ea6c72
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       2       8       48        2      active sync set-A   /dev/sdd
       3       8       64        3      active sync set-B   /dev/sde
       4       8       80        4      active sync set-A   /dev/sdf
       5       8       96        5      active sync set-B   /dev/sdg
```
**Информация по выводимым параметрам:**
• Version - версия метаданных. 
• Creation Time - дата в время создания массива. 
• Raid Level - уровень RAID. 
• Array Size - объем дискового пространства для RAID. 
• Used Dev Size - используемый объем для устройств. 
• Raid Devices - количество используемых устройств для RAID. 
• Total Devices - количество добавленных в RAID устройств. 
• Update Time - дата и время последнего изменения массива. 
• State - текущее состояние. clean - все в порядке. 
• Active Devices - количество работающих в массиве устройств. 
• Working Devices - количество добавленных в массив устройств в рабочем состоянии. 
• Failed Devices - количество сбойных устройств. 
• Spare Devices - количество запасных устройств. 
• Consistency Policy - политика согласованности активного массива (при неожиданном сбое). По умолчанию используется resync - полная ресинхронизация после восстановления. Также могут быть bitmap, journal, ppl. 
• Name - имя компьютера. 
• UUID - идентификатор для массива. 
• Events - количество событий обновления. 
• Chunk Size (для RAID5) - размер блока в килобайтах, который пишется на разные диски. 

### Создание конфигурационного файла mdadm.conf
-Просмотр информации
```
[root@linuxraid ~]# mdadm --detail --scan --verbose
ARRAY /dev/md0 level=raid10 num-devices=6 metadata=1.2 name=linuxraid:0 UUID=90556b45:cf87085c:1d71dd41:59ea6c72
   devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf,/dev/sdg
```
-Создание файл mdadm.conf с описанием массива.

mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> \ /etc/mdadm/mdadm.conf

```
[root@linuxraid mdadm]# cat mdadm.conf
DEVICE partitions
ARRAY /dev/md0 level=raid10 num-devices=6 metadata=1.2 name=linuxraid:0 UUID=90556b45:cf87085c:1d71dd41:59ea6c72
```
### Сломать/починить RAID
-Искусственно перевод в состояние fail 

```
[root@linuxraid mdadm]# mdadm /dev/md0 --fail /dev/sde
mdadm: set /dev/sde faulty in /dev/md0
[root@linuxraid mdadm]# cat /proc/mdstat
Personalities : [raid10] 
md0 : active raid10 sdg[5] sdf[4] sde[3](F) sdd[2] sdc[1] sdb[0]
      761856 blocks super 1.2 512K chunks 2 near-copies [6/5] [UUU_UU]
```

```
[root@linuxraid mdadm]# mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Sun Nov 26 07:24:56 2023
        Raid Level : raid10
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 6
     Total Devices : 6
       Persistence : Superblock is persistent

       Update Time : Sun Nov 26 07:51:44 2023
             State : clean, degraded 
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 1
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : linuxraid:0  (local to host linuxraid)
              UUID : 90556b45:cf87085c:1d71dd41:59ea6c72
            Events : 19

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       2       8       48        2      active sync set-A   /dev/sdd
       -       0        0        3      removed
       4       8       80        4      active sync set-A   /dev/sdf
       5       8       96        5      active sync set-B   /dev/sdg

       3       8       64        -      faulty   /dev/sde
```
- Удаление "сломанного" диска из массива

```
[root@linuxraid mdadm]# mdadm /dev/md0 --remove /dev/sde
mdadm: hot removed /dev/sde from /dev/md0
```
- Добавление диска после замены

```
[root@linuxraid mdadm]# mdadm /dev/md0 --add /dev/sde
mdadm: added /dev/sde
```
- Проверка
```
mdadm -D /dev/md0

```
 Update Time : Sun Nov 26 07:55:01 2023
             State : clean 
    Active Devices : 6
   Working Devices : 6
    Failed Devices : 0
     Spare Devices : 0
          Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : linuxraid:0  (local to host linuxraid)
              UUID : 90556b45:cf87085c:1d71dd41:59ea6c72
            Events : 39

   Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       2       8       48        2      active sync set-A   /dev/sdd
       6       8       64        3      active sync set-B   /dev/sde
       4       8       80        4      active sync set-A   /dev/sdf
       5       8       96        5      active sync set-B   /dev/sdg
 ```
   
### Создать GPT-таблицу и 5 разделов, смонтировать их в системе

- Создание таблицы разделов GPT на RAID
```
parted -s /dev/md0 mklabel gpt
```
- Создание разделов на массиве

```
parted /dev/md0 mkpart primary ext4 0% 20%
parted /dev/md0 mkpart primary ext4 20% 40%
parted /dev/md0 mkpart primary ext4 40% 60%
parted /dev/md0 mkpart primary ext4 60% 80%
parted /dev/md0 mkpart primary ext4 80% 100%
```
- Создание файловых систем - ext4, на каждом разделе

```
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
```
- Монтирование разделов
```
mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
```
Проверяем:
```
[root@linuxraid mdadm]# df -h
Filesystem      Size  Used Avail Use% Mounted on
devtmpfs        489M     0  489M   0% /dev
tmpfs           496M     0  496M   0% /dev/shm
tmpfs           496M  6.8M  489M   2% /run
tmpfs           496M     0  496M   0% /sys/fs/cgroup
/dev/sda1        40G  4.7G   36G  12% /
tmpfs           100M     0  100M   0% /run/user/1000
tmpfs           100M     0  100M   0% /run/user/0
/dev/md0p1      139M  1.6M  127M   2% /raid/part1
/dev/md0p2      140M  1.6M  128M   2% /raid/part2
/dev/md0p3      142M  1.6M  130M   2% /raid/part3
/dev/md0p4      140M  1.6M  128M   2% /raid/part4
/dev/md0p5      139M  1.6M  127M   2% /raid/part5
 ```
 ```
[root@linuxraid mdadm]# lsblk -f
NAME      FSTYPE            LABEL       UUID                                 MOUNTPOINT
sda                                                                          
`-sda1    xfs                           1c419d6c-5064-4a2b-953c-05b2c67edb15 /
sdb       linux_raid_member linuxraid:0 90556b45-cf87-085c-1d71-dd4159ea6c72 
`-md0                                                                        
  |-md0p1 ext4                          bb649b92-153b-4cd2-8ad6-728fdc73f6dc /raid/part1
  |-md0p2 ext4                          626712dc-1227-471b-bec4-a3c89d108b8b /raid/part2
  |-md0p3 ext4                          95879f86-b048-4efc-a5e2-8a880bdae645 /raid/part3
  |-md0p4 ext4                          1de2ba73-d915-4981-8598-a51b57581ba1 /raid/part4
  `-md0p5 ext4                          7f301353-1abd-48fb-b52d-7cfe63adb9fb /raid/part5
sdc       linux_raid_member linuxraid:0 90556b45-cf87-085c-1d71-dd4159ea6c72 
`-md0                                                                        
  |-md0p1 ext4                          bb649b92-153b-4cd2-8ad6-728fdc73f6dc /raid/part1
  |-md0p2 ext4                          626712dc-1227-471b-bec4-a3c89d108b8b /raid/part2
  |-md0p3 ext4                          95879f86-b048-4efc-a5e2-8a880bdae645 /raid/part3
  |-md0p4 ext4                          1de2ba73-d915-4981-8598-a51b57581ba1 /raid/part4
  `-md0p5 ext4                          7f301353-1abd-48fb-b52d-7cfe63adb9fb /raid/part5
sdd       linux_raid_member linuxraid:0 90556b45-cf87-085c-1d71-dd4159ea6c72 
`-md0                                                                        
  |-md0p1 ext4                          bb649b92-153b-4cd2-8ad6-728fdc73f6dc /raid/part1
  |-md0p2 ext4                          626712dc-1227-471b-bec4-a3c89d108b8b /raid/part2
  |-md0p3 ext4                          95879f86-b048-4efc-a5e2-8a880bdae645 /raid/part3
  |-md0p4 ext4                          1de2ba73-d915-4981-8598-a51b57581ba1 /raid/part4
  `-md0p5 ext4                          7f301353-1abd-48fb-b52d-7cfe63adb9fb /raid/part5
sde       linux_raid_member linuxraid:0 90556b45-cf87-085c-1d71-dd4159ea6c72 
`-md0                                                                        
  |-md0p1 ext4                          bb649b92-153b-4cd2-8ad6-728fdc73f6dc /raid/part1
  |-md0p2 ext4                          626712dc-1227-471b-bec4-a3c89d108b8b /raid/part2
  |-md0p3 ext4                          95879f86-b048-4efc-a5e2-8a880bdae645 /raid/part3
  |-md0p4 ext4                          1de2ba73-d915-4981-8598-a51b57581ba1 /raid/part4
  `-md0p5 ext4                          7f301353-1abd-48fb-b52d-7cfe63adb9fb /raid/part5
sdf       linux_raid_member linuxraid:0 90556b45-cf87-085c-1d71-dd4159ea6c72 
`-md0                                                                        
  |-md0p1 ext4                          bb649b92-153b-4cd2-8ad6-728fdc73f6dc /raid/part1
  |-md0p2 ext4                          626712dc-1227-471b-bec4-a3c89d108b8b /raid/part2
  |-md0p3 ext4                          95879f86-b048-4efc-a5e2-8a880bdae645 /raid/part3
  |-md0p4 ext4                          1de2ba73-d915-4981-8598-a51b57581ba1 /raid/part4
  `-md0p5 ext4                          7f301353-1abd-48fb-b52d-7cfe63adb9fb /raid/part5
sdg       linux_raid_member linuxraid:0 90556b45-cf87-085c-1d71-dd4159ea6c72 
`-md0                                                                        
  |-md0p1 ext4                          bb649b92-153b-4cd2-8ad6-728fdc73f6dc /raid/part1
  |-md0p2 ext4                          626712dc-1227-471b-bec4-a3c89d108b8b /raid/part2
  |-md0p3 ext4                          95879f86-b048-4efc-a5e2-8a880bdae645 /raid/part3
  |-md0p4 ext4                          1de2ba73-d915-4981-8598-a51b57581ba1 /raid/part4
  `-md0p5 ext4                          7f301353-1abd-48fb-b52d-7cfe63adb9fb /raid/part5
```
 
### Создать Vagrantfile, который сразу собирает систему с подключенным рейдом
 
- [Vagrantfile, который сразу собирает систему с подключенным рейдом](Vagrantfile)
- [Скрипт для создания рейда, GPT, создания разделов и их монтирования](create_raid10.sh)
- [Конф.файл  для автосборки рейда при загрузке](mdadm.conf)

Поверка после развертывания
```
[vagrant@linuxraid10 ~]$ cat /proc/mdstat
Personalities : [raid10] 
md0 : active raid10 sdg[5] sdf[4] sde[3] sdd[2] sdc[1] sdb[0]
      761856 blocks super 1.2 512K chunks 2 near-copies [6/6] [UUUUUU]
      
unused devices: <none>

[vagrant@linuxraid10 ~]$ sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Sun Nov 26 10:25:33 2023
        Raid Level : raid10
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 6
     Total Devices : 6
       Persistence : Superblock is persistent

       Update Time : Sun Nov 26 10:26:09 2023
             State : clean 
    Active Devices : 6
   Working Devices : 6
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : linuxraid10:0  (local to host linuxraid10)
              UUID : c7f22b38:ee129deb:d539cbba:50f83c78
            Events : 21

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       2       8       48        2      active sync set-A   /dev/sdd
       3       8       64        3      active sync set-B   /dev/sde
       4       8       80        4      active sync set-A   /dev/sdf
       5       8       96        5      active sync set-B   /dev/sdg

vagrant@linuxraid10 ~]$ df -h
Filesystem      Size  Used Avail Use% Mounted on
devtmpfs        489M     0  489M   0% /dev
tmpfs           496M     0  496M   0% /dev/shm
tmpfs           496M  6.7M  489M   2% /run
tmpfs           496M     0  496M   0% /sys/fs/cgroup
/dev/sda1        40G  4.7G   36G  12% /
/dev/md0p1      139M  1.6M  127M   2% /raid/part1
/dev/md0p2      140M  1.6M  128M   2% /raid/part2
/dev/md0p3      142M  1.6M  130M   2% /raid/part3
/dev/md0p4      140M  1.6M  128M   2% /raid/part4
/dev/md0p5      139M  1.6M  127M   2% /raid/part5
tmpfs           100M     0  100M   0% /run/user/1000
```
