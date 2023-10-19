#!/bin/bash

set -eo pipefail

if [ -z ${CONF} ]; then CONF=/etc/kvm-server.conf; fi
if [ -z ${DEFAULT_CONF} ]; then DEFAULT_CONF=/etc/default/kvm-server; fi

echo "using ${CONF} as configuration file"

# Check for read only root filesystem
BIN_INSTALL_PATH=$([[ -n $(awk '$2 ~ /\/$/ && $4 ~ /(^|,)ro($|,)/' /proc/mounts) ]] && echo "/usr/local/bin" || echo "/usr/bin")

check_load_config_file() {
if [ -f ${CONF} ]; then
    source ${CONF}
else
    echo "!! ${CONF} not found in path !!"
    exit 1
fi
if [ -e ${DEFAULT_CONF} ]; then
       source ${DEFAULT_CONF}
fi
}

get_disk_image() {
if [ ! -f ${DATA}/${APPLIANCE}.${BACKING_FORMAT} ]; then
	pushd ${DATA}
	curl -L -o ${DATA}/${APPLIANCE}.${BACKING_FORMAT} ${APPLIANCE_MIRROR}/${APPLIANCE}.${BACKING_FORMAT}
	popd
fi
}

start_default_network() {
   ${BIN_INSTALL_PATH}/virsh net-list --inactive --name | grep -qF "default_network" && ${BIN_INSTALL_PATH}/virsh net-start default_network || echo "default_network already started"
}

get_vm_name() {
   RANDOMSTRING=`openssl rand -hex 5`
   VMNAME=${DOMAIN}_${RANDOMSTRING}
}

# ignition is not used right now
#cp -v VM_config.ign ${DATA}

create_vm() {
${BIN_INSTALL_PATH}/virt-install \
    --connect qemu:///system \
    --import \
    --name ${VMNAME} \
    --osinfo opensusetumbleweed \
    --virt-type kvm --hvm \
    --machine q35 --boot uefi \
    --cpu host-passthrough \
    --video vga \
    --console pty,target.type=virtio \
    --autoconsole text \
    --network network=default_network \
    --rng /dev/urandom \
    --vcpu ${VCPU} --memory ${VMMEMORY} \
    --cloud-init \
    --disk path=${BACKING_STORE},bus=virtio,cache=none \
    --graphics vnc,listen=0.0.0.0,port=5950

# ignition needs another variant of image
#    --sysinfo type=fwcfg,entry0.name="opt/com.coreos/config",entry0.file="${BACKING_DIR}/VM_config.ign" \
}

check_load_config_file
get_disk_image
get_vm_name
start_default_network
create_vm
