#!/bin/bash
# aginies@suse.com
# quick script to manage the container

if [ -f /etc/kvm-container-functions ] ; then
    . /etc/kvm-container-functions
elif [ -f `pwd`/kvm-container-functions ]; then
    echo "Found local version of kvm-container-functions"
    export CONF="`pwd`/kvm-container.conf"
    . "`pwd`/kvm-container-functions"
else
    echo "! need /etc/kvm-container-functions; Exiting";
    exit 1
fi
check_load_config_file

create_container_host_network() {
mkdir -p ${DATA}
mkdir -p ${LIBVIRTDQEMU}/networks
mkdir -p ${VARRUNLIBVIRT}
podman create \
    --name ${CONTAINER_NAME} \
    --privileged --init \
    --cgroupns host \
    --network host \
    --volume ${LIBVIRTDQEMU}:/etc/libvirt/qemu \
    --volume ${DATA}:${BACKING_DIR} \
    --volume ${VARRUNLIBVIRT}:${VARRUNLIBBVIRT} \
    ${IMAGE}
}

run_container() {
podman run \
    --name ${CONTAINER_NAME} \
    --rm -ti \
    --privileged --init \
    --volume ${LIBVIRTDQEMU}:/etc/libvirt/qemu \
    --volume ${DATA}:${BACKING_DIR} \
    --volume ${VARRUNLIBVIRT}:${VARRUNLIBBVIRT} \
    --entrypoint bash \
    ${IMAGE}
}

check_kernel() {
    TEST=`rpm -qa | grep "kernel-default-[0-9]\.*"`
    if [ -z "${TEST}" ]; then
	cat <<EOF
	!! WARNING !!

	You are not running on kernel-default

	Please install it and reboot:
transactional-update pkg in kernel-default

EOF
    exit 1
    fi
}

info() {
cat <<EOF 
Configuration file: ${CONF}
#####################################################
CONTAINER_NAME: '${CONTAINER_NAME}'
IMAGE: '${IMAGE}'
DATA: '${DATA}'
BACKING_DIR: '${BACKING_DIR}'
BACKING_FORMAT: ${BACKING_FORMAT}
BACKING_STORE: '${BACKING_DIR}/${APPLIANCE}.${BACKING_FORMAT}'
DISK SIZE: ${DISKSIZE}
VM MEMORY: ${VMMEMORY}
VCPU: ${VCPU}
DOMAIN: '${DOMAIN}'
#####################################################
EOF
}

check_kernel
if [ -z "$1" ]; then
info
echo "

First ARG is mandatory:
$0 [create|start|stop|rm|rmcache|run|deletevm|bash|virsh|virtm|logs|build]


DEPLOYMENT:
create
    Pull the image and create the container automatically
    host network will be used

install
    install needed files on the host to manage '${CONTAINER_NAME}' container
    (in /usr/local/bin and /etc)

start
    Start the container '${CONTAINER_NAME}'

REMOVAL:
uninstall
    uninstall all needed files on the host to manage '${CONTAINER_NAME}' container

stop
    stop the container '${CONTAINER_NAME}'

rm
    delete the container '${CONTAINER_NAME}'

rmcache
    remove the container image in cache ${IMAGE}

USAGE:
virsh
    run virsh command inside '${CONTAINER_NAME}'
    if there is arg it will be run inside the container
    and will not go inside the container

virtm
    launch virt-manager

run
    podman run container '${CONTAINER_NAME}'

bash 
    go with bash command inside '${CONTAINER_NAME}'

info
    display some information about container and VM configuration

DEBUG:
logs
    see log of container '${CONTAINER_NAME}'

build
    build a local image of this container
    (localhost/kvmlocal)

VM management:
deletevm
    delete '${DOMAIN}' VM

demovm
    will create a VM with the virt-install-demo.sh script
    (automatic creation of a small VM ${APPLIANCE})
    (The VM disk will be only ${DISKSIZE}) 
 "
 exit 1
fi

delete_bridge() {
  ip link show ${BRIDGEIF}
  if [ "$?" = 0 ] ; then
	echo "Deleting previous ${BRIDGEIF} bridge interface"
	ip link delete ${BRIDGEIF}
  else
	echo "No previous ${BRIDGEIF} to delete"
  fi
}

###########
# MAIN
###########
set -uxo pipefail

case $1 in
    start)
	# be sure the previous bridge is deleted to avoid conflict
	delete_bridge
	podman start ${CONTAINER_NAME}
	sleep 1
	podman ps | grep ${CONTAINER_NAME}
    ;;
    stop)
	podman stop ${CONTAINER_NAME}
	# delete the bridge interface
	delete_bridge
	podman ps | grep ${CONTAINER_NAME}
    ;;
    rm)
    set +e
    podman stop ${CONTAINER_NAME}
    podman rm ${CONTAINER_NAME}
    ;;
    create)
    create_container_host_network
    ;;
    run)
    run_container
    ;;
    rmcache)
    podman rmi ${IMAGE}
    ;;
    logs)
    podman logs ${CONTAINER_NAME}
    ;;
    demovm)
    virt-install-demo.sh
    ;;
    deletevm)
    set +xeu
    podman exec -ti libvirtd virsh list --all
    echo "Which VM to delete?"
    read VMTODELETE
    if [ -z "$VMTODELETE" ]; then
    echo "You must specify a VM to delete, exiting"
    exit 1
    else
    podman exec -ti ${CONTAINER_NAME} virsh destroy ${VMTODELETE}
    podman exec -ti ${CONTAINER_NAME} virsh undefine --nvram ${VMTODELETE}
    fi
    ;;
    bash)
    set +e
    podman exec -ti ${CONTAINER_NAME} $@
    ;;
    virsh)
    set +eu
    virsh.sh
    # podman exec -ti ${CONTAINER_NAME} virsh ${@:2}
    ;;    
    debug)
    $0 build
    $0 rm
    $0 create
    $0 start
    echo "Container READY"
    podman container runlabel virt-manager ${IMAGE}
    ;;
    virtm)
    podman container runlabel virt-manager ${IMAGE}
    ;;
    info)
    info
    ;;
    build)
    podman build --tag kvmlocal .
    ;;
    install)
    podman run --env IMAGE=${IMAGE} --rm --privileged -v /:/host ${IMAGE} /bin/bash /container/label-install
    # workaround to not break the doc
    ln -sf /usr/local/bin/virt-install-demo.sh /usr/local/bin/virt-install.sh
    ;;
    uninstall)
    podman run --env IMAGE=${IMAGE} --rm --privileged -v /:/host ${IMAGE} /bin/bash /container/label-uninstall
    rm /usr/local/bin/virt-install.sh
    # delete the bridge interface
    delete_bridge
    ;;
esac
