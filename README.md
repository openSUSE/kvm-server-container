# What's inside

This container provides a kvm toolstack inside a container.

* `Dockerfile` with the definition of the kvm container
currently based on the openSUSE Tumbleweed BCI image.
Installs qemu, libvirt, virt-install and some additional tools
* `kvm-server.conf` contains environment variables used during deployment
* `kvm-server-manage` is a script to manage the deployment of the kvm container and the required libvirt services
* `virt-install-demo.sh` is a demo script to quickly install a test VM
* `default_network.xml` contains a deafult network configuration for the container and its workloads

# Current deployments

For each of the commands below, replace `<registry_path>` with one of the following:

* `registry.opensuse.org/suse/alp/workloads/tumbleweed_containerfiles/suse/alp/workloads/kvm-server` - The latest stable release deployed to the SUSE ALP distribution (Default)
* `registry.opensuse.org/virtualization/containerfile/suse/alp/workloads/kvm-server` - The latest development branch of the kvm server container
* `<custom-registry-path>` - Path to your OBS home project registry, local registy, or external registry

# How to get a working kvm server container

## Prepare your host system
```
# podman container runlabel install <registry_path>:latest
```
> Note: All commands to be run as root

## Deploy the container

```
# kvm-server-manage enable
```
This will first start the container, then will deploy the libvirt services inside the container.
If the container is already running, only the services will be restarted

## Verify the deployment

```
# kvm-server-manage verify
```
This will verify successful deployment of the container and all required services

## Install the test VM

```
# virt-install-demo.sh
```

# Local VM management
Any virtualization client packages can be installed on the host and should work out of the box

Alternatively, refer to the [KVM Client Container](https://github.com/openSUSE/kvm-client-container) for containerized client tooling

# Remote VM management
Ensure ssh access is configured between the client machine (running virsh or virt-manager locally) and the container host (where the kvm server container was deployed), then:
```
virsh -c "qemu+ssh://root@CONTAINER_HOST/system"
```
Optionally with an ssh key:
```
virsh -c "qemu+ssh://root@CONTAINER_HOST/system?keyfile=<local_path_to_private_key>"
```

# VM access 
Ensure a serial console or VNC server is configured with `virt-install` during installation or by modifying the libvirt xml with `virsh edit`
## Attach via serial console
```
# virsh console <vm_name>
```

## Attach via VNC

### Local VNC client
* Find configured VNC port: `virsh vncdisplay <vm_name>`
* Establish VNC connection: `vncviewer localhost:<vnc_port>`

### Remote VNC client
* Ensure the VM was created with a VNC server which is configured to listen on `0.0.0.0` or any of the host's external-facing IPs, preferably with a password
    * `virt-install ... --graphics vnc,listen=0.0.0.0,port=5950,password=<vnc_password>`
* Find configured VNC port: `virsh vncdisplay <vm_name>`
* Establish VNC connection from client: `vncviewer <host_ip>:<vnc_host_port>` 

### Remote VNC client over SSH
* Ensure SSH access is configured between the client machine and the container host
* Ensure the VM was created with a VNC server which is configured to only listen on `localhost`
    * `virt-install ... --graphics vnc,listen=127.0.0.1,port=5950`
* Find configured VNC port: `virsh -c "qemu+ssh://root@CONTAINER_HOST/system" vncdisplay <vm_name>`
* Create a port-forwarded ssh tunnel: 
`ssh -NL <vnc_client_port>:127.0.0.1:<vnc_host_port> <ip_of_container_host>`
    * If the client also has a VNC server running on port `5900`, then `<vnc_client_port>` must be port 5901 and above
* Establish VNC connection from client: `vncviewer 127.0.0.1:<vnc_client_port>`

# Restart the container

```
# kvm-server-manage restart
```
A fresh deployment of the container and all required services
If the container is already running, all running VMs will be stopped and the container will be restarted
 
# Stop the container
```
# kvm-server-manage stop
```
This will stop all services, stop the container, and stop any running VMs. The container, along with the services, will be started again upon the next host boot or [Restart](README.md#restart-the-container) the container as desired
> Note using `podman stop` is not advised. Since the container lifecycle is managed by systemd, this will only cause the container to re-exec but none of the container's libvirt services will be restarted

# Update the container
First stop the container with `kvm-server-manage stop`, then: 
```
# sudo podman container runlabel update <registry_path>
```
This will update to the latest container image including updated virtualization components

# Disable the container
```
# kvm-server-manage disable
```
This will stop all libvirt service in the container, stop the container, and disable the service from running on the next reboot. Nothing is uninstalled from the host. [Redeploy](README.md#deploy-the-container) as desired. 

# Uninstall the kvm server container
```
# sudo podman container runlabel uninstall <registry_path>
```

# Warning

This code is only provided for experimentation.
