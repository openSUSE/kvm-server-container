# What's inside

This container provides a kvm toolstack inside a container.

* `Dockerfile` with the definition of the kvm container
currently based on the openSUSE Tumbleweed BCI image.
Installs qemu, libvirt, virt-install and some additional tools
* `kvm-container.conf` contains environment variables used during deployment
* `kvm-container-manage` is a script to manage the deployment of the kvm container and the required libvirt services
* `virsh` is the wrapper on the host to use virsh command
* `virt-install-demo.sh` is a wrapper to quickly install a test VM
* `virt-install` is the wrapper on the host to virt-install
* `default_network.xml` contains a deafult network configuration for the container and its workloads

# Current deployments

For each of the commands below, replace `<registry_path>` with one of the following:

* `registry.opensuse.org/suse/alp/workloads/tumbleweed_containerfiles/suse/alp/workloads/kvm-modular-libvirt` - The latest stable release deployed to the SUSE ALP distribution (Default)
* `registry.opensuse.org/virtualization/containerfile/suse/alp/workloads/kvm-modular-libvirt` - The latest development branch of the kvm-container
* `<custom-registry-path>` - Path to your OBS home project registry, local registy, or external registry

# How to get a working kvm-container

## Prepare your host system
```
# podman container runlabel install <registry_path>:latest
```
> Note: Ensure the value of `IMAGE` in `/etc/kvm-container.conf` is the same as the registry path used for the installation

> Note: All commands to be run as root

## Deploy the container

```
# kvm-container-manage enable
```
This will first start the container, then will deploy the libvirt services inside the container.
If the container is already running, only the services will be restarted

## Verify the deployment

```
# kvm-container-manage verify
```
Verify successful deployment of the container and all required services

## Install the test VM

```
# virt-install-demo.sh
```

# Local VM management
`virsh` is passed through to the container so it can be used locally just as if libvirt were running on the host
```
# virsh list --all
```

# Remote VM management
Ensure ssh access is configured between the client machine (running virsh or virt-manger locally) and the container host (where the kvm-container was deployed), then:
```
virsh -c "qemu+ssh://root@YOURHOST/system"
```
Optionally with an ssh key:
```
virsh -c "qemu+ssh://root@YOURHOST/system?keyfile=<local_path_to_private_key>"
```

# Remote VM access 

## From the container's host machine (assuming the test VM and default VM network)
```
# vncviewer 192.168.10.1:5950
```

## From an external system
* Ensure ssh access is configured between the client machine and the container host
* Ensure the VM was created with a vnc server (i.e. `--graphics vnc,listen=0.0.0.0,port=5950` for the test VM)
* Create a port-forwarded ssh tunnel: `ssh -NL 5900:127.0.0.1:5900 <ip_of_container_host>`
* Establish vnc connection from client: `vncviewer 127.0.0.1::5900`

# Restart the container

```
# kvm-container-manage restart
```
A fresh deployment of the container and all required services
If the container is already running, all running VMs will be stopped and the container will be restarted
 
# Stop the container
```
# kvm-container-manage stop
```
This will stop all services, stop the container, and stop any running VMs. The container, along with the services, will be started again upon the next host boot or [Restart](README.md#restart-the-container) the container as desired
> Note using `podman stop` is not advised. Since the container lifecycle is managed by systemd, this will only cause the container to re-exec but none of the container's libvirt services will be restarted

# Update the container
First stop the container with `kvm-container-manage stop`, then: 
```
# sudo podman container runlabel update <registry_path>
```
This will update to the latest container image including updated virtualization components

# Disable the container
```
# kvm-container-manage disable
```
This will stop all libvirt service in the container, stop the container, and disable the service from running on the next reboot. Nothing is uninstalled from the host. [Redeploy](README.md#deploy-the-container) as desired. 

# Uninstall the kvm-container
```
# sudo podman container runlabel uninstall <registry_path>
```

# Warning

This code is only provided for experimentation.
