#!/bin/bash

# shortcut for podman runlabel calls
if [ ! -z "$2" ]; then
   if [ "$(basename "$2")" = "label-install" ] || 
      [ "$(basename "$2")" = "label-uninstall" ] || 
      [ "$(basename "$2")" = "virt-manager" ]; then
	    exec "$@"
	    exit 0
	else
	    echo "No parameter label-install, label-uninstall, virt-manager found"
	    echo $@
	fi
fi

exec "$@"
