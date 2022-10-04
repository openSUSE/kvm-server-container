#!/bin/bash

#set -exuo pipefail

USER=tester
HOMEUSER=/home/${USER}
PS1NAME=VIRTU_BASE_CONTAINER
HPS1="\e[1;34m[\t]\e[1;31m \u@\h \e[1;32m${PS1NAME} \e[1;34m\w \e[m \n\e[1;31m#\e[m "


# substitute root user by tester (not really secure but better...)
create_user() {
    useradd --system -m -N -s /bin/bash -u 1000 ${USER} -G libvirt
    mkdir -p ${HOMEUSER}/.ssh
    touch ${HOMEUSER}/.ssh/authorized_keys
    chmod 700 ${HOMEUSER}/.ssh
    chmod 600 ${HOMEUSER}/.ssh/authorized_keys
    sed -i 's/1000/0/g' /etc/passwd 
    echo "export PS1='${HPS1}'" >> ${HOMEUSER}/.bashrc
    chown -R ${USER} ${HOMEUSER}

    # Simple password for tester user
    passwd tester <<EOF
opensuse
opensuse
EOF
    pwconv
}

# No permit to login as root
# default port for ssh container access is 16022
configure_ssh() {
    echo -e "Port 16022\nPermitEmptyPasswords no\nPermitRootLogin no" >> /etc/ssh/sshd_config
    /usr/sbin/sshd-gen-keys-start
    /usr/sbin/sshd -t -f /etc/ssh/sshd_config
    /usr/sbin/sshd -f /etc/ssh/sshd_config
}

# shortcut for podman runlabel calls
if [ ! -z "$2" ];then
	if [ $(basename "$2") = 'label-install' ] || [ $(basename "$2") = 'label-uninstall' ];then
	    exec "$@"
	    exit 0
	elif [ $(basename "$2") = 'virt-manager' ];then
		exec "$@"
		exit 0
	else
	    echo "No parameter label-install, label-uninstall, virt-manager found"
	    echo $@
	fi
fi


if [ ! -e /etc/passwd ]; then
   touch /etc/passwd
fi
TEST=`grep tester /etc/passwd`
if [ -z "$TEST" ]; then
    create_user
else
    echo "User already present, skipping..."
fi

if [ ! -e /etc/ssh/sshd_config ]; then
   mkdir -p /etc/ssh
   touch /etc/ssh/sshd_config
fi
TEST=`grep 16022 /etc/ssh/sshd_config`
if [ -z "$TEST" ]; then
    configure_ssh
else
    echo "SSH already configured, skipping..."
fi


# Adjust PS1 for root user
if [ ! -f "/root/.bashrc" ]; then
    echo "export PS1='${HPS1}'" >> /root/.bashrc
else
    echo "PS1 for root already set, skipping..."
fi

LIBVIRTNET="/etc/libvirt/qemu/networks/sle_network.xml"
if [ ! -f ${LIBVIRTNET} ]; then
   ip link delete virbr0
# create a sle_network for the VM
# PLEASE use virbr0 or adjust kvm-container.conf
    cat > ${LIBVIRTNET} <<EOF
<network>
  <name>sle_network</name>
  <uuid>f243d94b-bd5b-415d-b4c7-ccb78ec3dc9e</uuid>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:d0:61:e9'/>
  <ip address='192.168.10.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.10.2' end='192.168.10.254'/>
    </dhcp>
  </ip>
</network>
EOF
else
   echo "libvirtd sle_network already created, skipping..."
fi

virtlogd --daemon
libvirtd --listen --daemon 
virsh net-start sle_network


# use for devel
sleep infinity
