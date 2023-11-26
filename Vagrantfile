# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :linuxraid10 => {
        :box_name => "centos/7",
        :ip_addr => '192.168.56.8',
	:disks => {
		:sata1 => {
			:dfile => './sata1.vdi',
			:size => 250,
			:port => 1
		},
		:sata2 => {
                        :dfile => './sata2.vdi',
                        :size => 250, # Megabytes
			:port => 2
		},
                :sata3 => {
                        :dfile => './sata3.vdi',
                        :size => 250,
                        :port => 3
                },
                :sata4 => {
                        :dfile => './sata4.vdi',
                        :size => 250, # Megabytes
                        :port => 4
                },
                :sata5 => {
                        :dfile => './sata5.vdi',
                        :size => 250, # Megabytes
                        :port => 5
                },
                :sata6 => {
                        :dfile => './sata6.vdi',
                        :size => 250, # Megabytes
                        :port => 6
                }

	}

		
  },
}

Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|

      config.vm.define boxname do |box|

          box.vm.box = boxconfig[:box_name]
          box.vm.host_name = boxname.to_s

          box.vm.network "private_network", ip: boxconfig[:ip_addr]

          box.vm.provider :virtualbox do |vb|
            	  vb.customize ["modifyvm", :id, "--memory", "1024"]
                  needsController = false
		  boxconfig[:disks].each do |dname, dconf|
			  unless File.exist?(dconf[:dfile])
				vb.customize ['createhd', '--filename', dconf[:dfile], '--variant', 'Fixed', '--size', dconf[:size]]
                                needsController =  true
                          end

		  end
                  if needsController == true
                     vb.customize ["storagectl", :id, "--name", "SATA", "--add", "sata" ]
                     boxconfig[:disks].each do |dname, dconf|
                         vb.customize ['storageattach', :id,  '--storagectl', 'SATA', '--port', dconf[:port], '--device', 0, '--type', 'hdd', '--medium', dconf[:dfile]]
                     end
                  end
          end
 	box.vm.provision "shell", inline: <<-SHELL
	    mkdir -p ~root/.ssh
            cp ~vagrant/.ssh/auth* ~root/.ssh
	    yum install -y mdadm smartmontools hdparm gdisk
	    sudo su
                # Обнуление суперблоков
            mdadm --zero-superblock --force /dev/sd{b,c,d,e,f,g}
                # Создание RAID 10 из 6 дисков
	        mdadm --create --verbose /dev/md0 -l 10 -n 6 /dev/sd{b,c,d,e,f,g}
                
                # Создание файла mdadm.conf , содержащий тип RAID массив и компоненты
	        mkdir /etc/mdadm
	        touch /etc/mdadm/  mdadm.conf
            echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
            mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
            cat mdadm.conf > /home/vagrant/mdadm.conf
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
            for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
	    for i in $(seq 1 5); do echo "/dev/md0p$i /raid/part$i  ext4  defaults 0 0"  >> /etc/fstab; done
  	SHELL

        end
  end
end
