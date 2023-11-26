#!/usr/bin/env bash
#!/usr/bin/env bash

# Обнуление суперблоков
mdadm --zero-superblock --force /dev/sd{b,c,d,e,f,g}

# Создание RAID 10 из 6 дисков
mdadm --create --verbose /dev/md0 -l 10 -n 6 /dev/sd{b,c,d,e,f,g}

# Создание файла mdadm.conf , содержащий тип RAID массив и компоненты
mkdir /etc/mdadm
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf

# Создание таблицы разделов GPT на RAID
parted -s /dev/md0 mklabel gpt

# Создание 5 разделов
parted /dev/md0 mkpart primary ext4 0% 20%
parted /dev/md0 mkpart primary ext4 20% 40%
parted /dev/md0 mkpart primary ext4 40% 60%
parted /dev/md0 mkpart primary ext4 60% 80%
parted /dev/md0 mkpart primary ext4 80% 100%

# Создание файловых систем - ext4, на каждом разделе
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done

# Монтирование разделов в директории и заполнение fstab
mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do
    mount /dev/md0p$i /raid/part$i
    echo "/dev/md0p$i     /raid/part$i     ext4    defaults    0   0" >> /etc/fstab
done
