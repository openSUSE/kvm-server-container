# What's inside

This container provide kvm toolstack inside a container.

* '''Dockerfile''' with the definition of the kvm container
** based on SLE15 SP4 BCI image suse/sle15:15.4 
** installs qemu, libvirt, virt-install and some additional tools
** Use the entrypoint.sh as ENTRYPOINT for the container
* '''kvm-base-container.conf''' file for which contains all VAR
* '''kvm-container-functions''' functions to check configuration
* '''VM_config.ign''' as an ignition file (not yet used as default image is an openstack one)
* '''kvm-container-manage.sh''' script to manage the container using podman
* '''virsh.sh''' is the wrapper on the host to use virsh command
* '''virt-install-demo.sh''' is a wrapper to quickly install a test VM
* '''virt-install''' is the wrapper on the host to virt-install
* '''virt-manager.sh''' is the virt-manager wrapper on the host
* The host network is the default one as podman network requires to publish port (which add complexity for VNC port and all VM)
* Default user inside the container is '''testuser''', password='''opensuse''', ssh port: 16022


# Usage of the the manage script

```# ./kvm-container-manage.sh
```

# How to get a working libvirtd container

## Prepare your host system

To be able to manage Virtual Machine, just use the '''runlabel install''' on the container image available on the registry.

```
# podman container runlabel install registry.opensuse.org/suse/alp/workloads/tumbleweed_containerfiles/suse/alp/workloads/kvm:latest
Trying to pull registry.opensuse.org/suse/alp/workloads/tumbleweed_containerfiles/suse/alp/workloads/kvm:latest...
Getting image source signatures
Copying blob e0a935ad0ff9 done  
Copying blob a9510fddaf27 done  
Copying config f31316e5ee done  
Writing manifest to image destination
Storing signatures
LABEL INSTALL
copy /container/kvm-container-manage.sh in /host/usr/local/bin/
'/container/kvm-container-manage.sh' -> '/host/usr/local/bin/kvm-container-manage.sh'
copy /container/virsh.sh in /host/usr/local/bin/
'/container/virsh.sh' -> '/host/usr/local/bin/virsh.sh'
copy /container/virt-install.sh in /host/usr/local/bin/
'/container/virt-install.sh' -> '/host/usr/local/bin/virt-install.sh'
copy /container/kvm-container.conf in /host/etc/
'/container/kvm-container.conf' -> '/host/etc/kvm-container.conf'
copy /container/kvm-container-functions in /host/etc/
'/container/kvm-container-functions' -> '/host/etc/kvm-container-functions'
.....

```

## Create the container

```# kvm-container-manage.sh create
Found local version of kvm-functions
using /etc/kvm-container.conf as configuration file
+ case $1 in
+ create_container
+ podman create --name kvm --tls-verify=false --network host registry.opensuse.org/suse/alp/workloads/tumbleweed_containerfiles/suse/alp/workloads/kvm:latest
Trying to pull registry.opensuse.org/suse/alp/workloads/tumbleweed_containerfiles/suse/alp/workloads/kvm:latest...
Getting image source signatures
Copying blob 516d2ff9c231 done  
Copying blob 01d99e9cadaf done  
Copying config 2698f55e87 done  
Writing manifest to image destination
Storing signatures
82dc879bc340e20f375cbb1ba67d60b2dd77c6e9029a8459fea318fe2b6639d7
```
 
## Start the container with kvm-server 

```
# kvm-container-manage.sh start
using /etc/kvm-container.conf as configuration file
+ case $1 in
+ podman start kvm
kvm
+ podman ps
CONTAINER ID  IMAGE                                                                               COMMAND     CREATED        STATUS                     PORTS       NAMES
b0580df381b0  registry.opensuse.org/suse/alp/workloads/tumbleweed_containerfiles/suse/alp/workloads/kvm:latest              3 seconds ago  Up Less than a second ago              kvm
```

## Install the VM

the '''virt-install.sh''' script should grab the OpenStack VM image openSUSE-Tumbleweed-JeOS.x86_64-OpenStack-Cloud.qcow2
```# virt-install.sh
++ pwd
+ '[' -f /root/SUSE:ALP:Workloads/kvm-container/kvm-container-functions ']'
++ pwd
+ . /root/SUSE:ALP:Workloads/kvm-container/kvm-container-functions
++ CONF=kvm-container.conf
+ check_load_config_file
+ '[' -f kvm-container.conf ']'
+ source kvm-container.conf
++ CONTAINER_NAME=libvirtd
++ IMAGE=registry.opensuse.org/suse/alp/workloads/tumbleweed_containerfiles/suse/alp/workloads/kvm:latest
++ DATA=./data
++ LIBVIRTDQEMU=./data/libvirt/qemu
++ APPLIANCE_MIRROR=https://download.opensuse.org/tumbleweed/appliances
++ APPLIANCE=openSUSE-Tumbleweed-JeOS.x86_64-OpenStack-Cloud
++ BACKING_DIR=/var/lib/libvirt/images
++ BACKING_FORMAT=qcow2
++ BACKING_STORE=/var/lib/libvirt/images/openSUSE-Tumbleweed-JeOS.x86_64-OpenStack-Cloud.qcow2
++ DOMAIN=Tumbleweed-JeOS
+ '[' '!' -f ./data/openSUSE-Tumbleweed-JeOS.x86_64-OpenStack-Cloud.qcow2 ']'
++ openssl rand -hex 5
+ RANDOMSTRING=5221fd7860
+ VMNAME=Tumbleweed-JeOS_5221fd7860
+ podman exec -ti libvirtd virt-install --connect qemu:///system --import --name Tumbleweed-JeOS_5221fd7860 --osinfo opensusetumbleweed --virt-type kvm --hvm --machine q35 --boot uefi --cpu host-passthrough --video vga --console pty,target_type=virtio --network network=sle_network --rng /dev/urandom --vcpu 4 --memory 4096 --cloud-init --disk size=6,backing_store=/var/lib/libvirt/images/openSUSE-Tumbleweed-JeOS.x86_64-OpenStack-Cloud.qcow2,backing_format=qcow2,bus=virtio,cache=none --graphics vnc,listen=0.0.0.0
WARNING  Defaulting to --cloud-init root-password-generate=yes,disable=yes

Starting install...
Password for first root login is: OPjQok1nlfKp5DRZ
Allocating 'Tumbleweed-JeOS_5221fd7860.qcow2'                                           |    0 B  00:00:00 ... 
Creating domain...                                                                      |    0 B  00:00:00     
Running text console command: virsh --connect qemu:///system console Tumbleweed-JeOS_5221fd7860
Connected to domain 'Tumbleweed-JeOS_5221fd7860'
Escape character is ^] (Ctrl + ])

Welcome to openSUSE Tumbleweed 20220919 - Kernel 5.19.8-1-default (hvc0).

eth0: 192.168.10.67 fe80::5054:ff:fe5a:c416


localhost login: 
```

To quit the console, the shortcut key is: '''crtl + ]'''


# Play around with the VM
```
# kvm-container-manage.sh virsh list --all
+ case $1 in
+ set +eu
+ podman exec -ti libvirtd virsh list --all
 Id   Name                         State
--------------------------------------------
 1    Tumbleweed-JeOS_186c8cac70   running
 2    Tumbleweed-JeOS_5221fd7860   running

# virsh.sh list
+ podman exec -ti libvirtd virsh list
 Id   Name                         State
--------------------------------------------
 1    Tumbleweed-JeOS_186c8cac70   running
 2    Tumbleweed-JeOS_5221fd7860   running

```

## Connect to the VM from another host

### using virsh and ssh
* The default password for the user '''tester''' use is : "opensuse"
* The default port to access the container using ssh is '''16022'''
```
virsh -c qemu+ssh://tester@YOURHOST:16022/system
```

### using VNC
```
# vncviewer YOURHOST:590[0-9]
```
 
## Stop the libvirtd container
```
# kvm-container-manage.sh stop
+ case $1 in
+ podman stop libvirtd
libvirtd
+ ip link delete virbr0
+ podman ps
CONTAINER ID  IMAGE       COMMAND     CREATED     STATUS      PORTS       NAMES
```

# Uninstall needed files to manage the container

To remove management files from the host:
```
# kvm-container-manage.sh uninstall
Found local version of kvm-functions
using /root/home:aginies:branches:SUSE:ALP:Workloads/kvm-container/kvm-container.conf as configuration file
+ case $1 in
+ podman run --env IMAGE=registry.opensuse.org/suse/alp/workloads/tumbleweed_containerfiles/suse/alp/workloads/kvm:latest --rm --privileged -v /:/host registry.opensuse.org/suse/alp/workloads/tumbleweed_containerfiles/suse/alp/workloads/kvm:latest /bin/bash /container/label-uninstall
LABEL UNINSTALL: Removing all files
removed '/host/etc/kvm-container.conf'
removed '/host/etc/kvm-container-functions'
removed '/host/usr/local/bin/kvm-container-manage.sh'
removed '/host/usr/local/bin/virsh.sh'
removed '/host/usr/local/bin/virt-install.sh'
.....
```

# Warning

This code is only provided for experimentation.
