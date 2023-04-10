# What's inside

This container provides a kvm toolstack inside a container.

* '''Dockerfile''' with the definition of the kvm container
currently based on the openSUSE Tumbleweed BCI image.
Installs qemu, libvirt, virt-install and some additional tools
* '''kvm-container.conf''' contains environment variables used during deployment
* '''kvm-container-functions''' functions to check configuration
* '''kvm-container-host-service''' is a script to deploy the kvm container and the libvirt daemons through their systemd services
* '''virsh''' is the wrapper on the host to use virsh command
* '''virt-install-demo.sh''' is a wrapper to quickly install a test VM
* '''virt-install''' is the wrapper on the host to virt-install
* '''default_network.xml''' contains a deafult network configuration for the container and its workloads

# How to get a working libvirtd container

## Prepare your host system
```
# podman container runlabel install registry.opensuse.org/suse/alp/workloads/tumbleweed_containerfiles/suse/alp/workloads/kvm-systemd:latest
```
> Note: systemd units are currently installed to the host administrator's systemd directory (`/etc/systemd/system/`) since the root filesystem is mounted read-only on an ALP system

> Note: All commands to be run as root

## Deploy the container

```
# podman container runlabel service-enable registry.opensuse.org/suse/alp/workloads/tumbleweed_containerfiles/suse/alp/workloads/kvm-systemd:latest
```
This will first start the container, then will use the installed systemd units to deploy the libvirt daemons inside the container
 
## Install the test VM

```
# virt-install-demo.sh
```

# Local VM management
`/usr/local/bin/virsh` is passed through to the container so it can be used locally just as if libvirt were running on the host
```
# virsh list --all
```

# Remote VM management

## Using SSH
TODO. However it is possible to ssh into the container's host machine and use `virsh` as is the case with local VM management
<!---* The default password for the user '''tester''' use is : "opensuse"
* The default port to access the container using ssh is '''16022'''
```
virsh -c qemu+ssh://tester@YOURHOST:16022/system
```
-->
## Using VNC - from the container's host machine
```
# vncviewer 192.168.10.1:5950
```

# Stop the container
```
# systemctl stop kvm-container-meta.service
```
> Note using `podman stop` is not advised. Since the container lifecycle is managed by systemd, this will only cause the container to re-exec but none of the container's libvirt services will be restarted

# Update the container
First stop the container with `systemctl stop kvm-container-meta.service`, then: 
```
# sudo podman runlabel update registry.opensuse.org/suse/alp/workloads/tumbleweed_containerfiles/suse/alp/workloads/kvm-systemd
```
This will update to the latest container image including updated virtualization components

# Disable containerized libvirt services
```
# sudo podman runlabel service-disable registry.opensuse.org/suse/alp/workloads/tumbleweed_containerfiles/suse/alp/workloads/kvm-systemd
```
This will stop all libvirt service in the container, stop the container, and disable the service from running on the next reboot. Nothing is uninstalled from the host. [Redeploy](README.md#deploy-the-container) as desired. 

# Uninstall the kvm-container
```
# sudo podman runlabel uninstall registry.opensuse.org/suse/alp/workloads/tumbleweed_containerfiles/suse/alp/workloads/kvm-systemd
```

# Warning

This code is only provided for experimentation.
