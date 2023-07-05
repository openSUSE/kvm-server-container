# SPDX-License-Identifier: MIT
# Define the tags for OBS and build script builds:
#!BuildTag: %%TAGPREFIX%%/kvm-modular-libvirt:latest
#!BuildTag: %%TAGPREFIX%%/kvm-modular-libvirt:%%PKG_VERSION%%
#!BuildTag: %%TAGPREFIX%%/kvm-modular-libvirt:%%PKG_VERSION%%-%RELEASE%

FROM opensuse/tumbleweed

LABEL INSTALL="/usr/bin/podman run --env IMAGE=IMAGE --rm --privileged -v /:/host IMAGE /bin/bash /container/label-install"
LABEL UNINSTALL="/usr/bin/podman run --env IMAGE=IMAGE --rm --privileged -v /:/host IMAGE /bin/bash /container/label-uninstall"
LABEL UPDATE="/usr/bin/podman run --env IMAGE=IMAGE --replace --pull=newer --privileged -v /:/host --name kvm-container-update IMAGE /bin/bash /container/label-install"

# Mandatory labels for the build service:
#   https://en.opensuse.org/Building_derived_containers
# labelprefix=%%LABELPREFIX%%
LABEL org.opencontainers.image.title="KVM container"
LABEL org.opencontainers.image.description="Container for the KVM virtualization stack"
LABEL org.opencontainers.image.created="%BUILDTIME%"
LABEL org.opencontainers.image.version="%%PKG_VERSION%%.%RELEASE%"
LABEL org.opencontainers.image.url="https://build.opensuse.org/package/show/SUSE:ALP:Workloads/kvm-container-modular-libvirt"
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
              libvirt-daemon-qemu \
              nftables \
              qemu-audio-spice \
              qemu-block-curl \
              qemu-block-iscsi \
              qemu-block-nfs \
              qemu-block-ssh \
              qemu-chardev-spice \
              qemu-hw-usb-redirect \
              qemu-hw-display-qxl \
              qemu-hw-usb-host \
              qemu-hw-display-virtio-gpu \
              qemu-hw-display-virtio-gpu-pci \
              qemu-ipxe \
              qemu-ovmf-x86_64 \
              qemu-seabios \
              qemu-vgabios \
              qemu-x86 \
              socat \
              shadow
#!ArchExclusiveLine: x86_64
RUN if [ $(uname -m) = "x86_64" ]; then zypper install --no-recommends -y sevctl; fi
RUN zypper clean --all

COPY container /container
RUN chmod +x /container/{kvm-container-manage,label-install,label-uninstall,virt-install-demo.sh}

CMD [ "echo", "Running the KVM container directly is not supported. Please refer to instructions at https://github.com/Fuzzy-Math/kvm-container for instructions on how to deploy the kvm container" ]

