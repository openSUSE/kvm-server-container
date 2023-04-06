# SPDX-License-Identifier: MIT
# Define the tags for OBS and build script builds:
#!BuildTag: %%TAGPREFIX%%/kvm:%%PKG_VERSION%%
#!BuildTag: %%TAGPREFIX%%/kvm:%%PKG_VERSION%%-%RELEASE%

FROM opensuse/tumbleweed

LABEL INSTALL="/usr/bin/podman run --env IMAGE=IMAGE --rm --privileged -v /:/host IMAGE /bin/bash /container/label-install"
LABEL UNINSTALL="/usr/bin/podman run --env IMAGE=IMAGE --rm --privileged -v /:/host IMAGE /bin/bash /container/label-uninstall"
LABEL UPDATE="/usr/bin/podman run --env IMAGE=IMAGE --replace --pull=newer --privileged -v /:/host --name kvm-container-update IMAGE /bin/bash /container/label-install"
LABEL SERVICE-ENABLE="/usr/local/bin/kvm-container-host-service enable"
LABEL SERVICE-DISABLE="/usr/local/bin/kvm-container-host-service disable"

# Mandatory labels for the build service:
#   https://en.opensuse.org/Building_derived_containers
# labelprefix=%%LABELPREFIX%%
LABEL org.opencontainers.image.title="KVM container"
LABEL org.opencontainers.image.description="Container for the KVM virtualization stack"
LABEL org.opencontainers.image.created="%BUILDTIME%"
LABEL org.opencontainers.image.version="%%PKG_VERSION%%.%RELEASE%"
LABEL org.opencontainers.image.url="https://build.opensuse.org/package/show/SUSE:ALP:Workloads/kvm-container"
LABEL org.openbuildservice.disturl="%DISTURL%"
LABEL org.opensuse.reference="%%REGISTRY%%/%%TAGPREFIX%%/kvm:%%PKG_VERSION%%.%RELEASE%"
LABEL org.openbuildservice.disturl="%DISTURL%"
LABEL com.suse.supportlevel="techpreview"
LABEL com.suse.eula="beta"
LABEL com.suse.image-type="application"
LABEL com.suse.release-stage="prototype"
# endlabelprefix

RUN zypper install --no-recommends -y \
              iptables \
              libvirt-client-qemu \
              libvirt-daemon-lock \
              libvirt-daemon-log \
              libvirt-daemon-proxy \
              libvirt-daemon-config-network \
              libvirt-daemon-config-nwfilter \
              libvirt-daemon-driver-network \
              libvirt-daemon-driver-nodedev \
              libvirt-daemon-driver-nwfilter \
              libvirt-daemon-driver-qemu \
              libvirt-daemon-driver-secret \
              libvirt-daemon-driver-storage \
              libvirt-daemon-plugin-lockd \
              netcat-openbsd \
              nftables \
              python3-lxml \
              python3-pvirsh \
              python3-virt-scenario \
              qemu-hw-usb-redirect \
              qemu-tools \
              qemu-x86 \
              qemu-hw-display-qxl \
              qemu-hw-display-virtio-vga \
              qemu-hw-usb-host \
              qemu-hw-usb-smartcard \
              qemu-hw-display-virtio-gpu \
              qemu-hw-display-virtio-gpu-pci \
              qemu-audio-alsa \
              qemu-audio-dbus \
              qemu-audio-jack \
              qemu-audio-oss \
              qemu-audio-pa \
              qemu-audio-spice \
              qemu-sgabios \
              qemu-vgabios \
              qemu-seabios \
              qemu-chardev-spice \
              qemu-ovmf-x86_64 \
              qemu-ipxe \
              qemu-block-curl \
              qemu-block-dmg \
              qemu-block-iscsi \
              qemu-block-nfs \
              qemu-block-rbd \
              qemu-block-ssh \
              socat \
              tar \
              timezone \
              vim-small \
              virt-install \
              shadow
#!ArchExclusiveLine: x86_64
RUN zypper install --no-recommends -y sevctl
RUN zypper clean --all

# FIXME: Modular daemons don't always respect /etc/libvirt/libvirtd.conf
#RUN echo -e 'unix_sock_group = "libvirt"\nunix_sock_ro_perm = "0777"\nunix_sock_rw_perms = "0770"' >> /etc/libvirt/libvirtd.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
COPY container /container
RUN chmod +x /container/{kvm-container-host-service,label-install,label-uninstall,pvirsh,qemu-img,virt-install,virt-install-demo.sh,virsh,virt-scenario,virt-xml-validate}

#RUN useradd -rmN -s /bin/bash -u 1000 -G libvirt tester
#USER tester:libvirt

ENTRYPOINT [ "/entrypoint.sh" ]

