# SPDX-License-Identifier: MIT
# Define the tags for OBS and build script builds:
#!BuildTag: %%TAGPREFIX%%/kvm:latest
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
              libvirt-client \
              libvirt-daemon-config-network \
              libvirt-daemon-qemu \
              netcat-openbsd \
              nftables \
              qemu-hw-usb-redirect \
              qemu-tools \
              qemu-x86 \
              socat \
              tar \
              timezone \
              vim-small \
              virt-install \
              shadow \
  && zypper clean --all

# FIXME: Modular daemons don't always respect /etc/libvirt/libvirtd.conf
#RUN echo -e 'unix_sock_group = "libvirt"\nunix_sock_ro_perm = "0777"\nunix_sock_rw_perms = "0770"' >> /etc/libvirt/libvirtd.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
COPY container /container
RUN chmod +x /container/{virsh,virt-install,virt-install-demo.sh,label-install,label-uninstall,kvm-container-host-service}

#RUN useradd -rmN -s /bin/bash -u 1000 -G libvirt tester
#USER tester:libvirt

ENTRYPOINT [ "/entrypoint.sh" ]

