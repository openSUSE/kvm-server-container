#!/bin/bash

# shortcut for podman runlabel calls
if [ ! -z "$2" ]; then
   if [ "$(basename "$2")" = "label-install" ] || 
      [ "$(basename "$2")" = "label-uninstall" ]; then
	    exec "$@"
	    exit 0
	else
	    echo "No parameter label-install, label-uninstall found"
	    echo $@
	fi
fi

exec "$@"
