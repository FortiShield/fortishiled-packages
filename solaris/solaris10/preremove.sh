#!/bin/sh
# preremove script for fortishield-agent
# Fortishield, Inc 2015

control_binary="fortishield-control"

if [ ! -f /var/ossec/bin/${control_binary} ]; then
  control_binary="ossec-control"
fi

/var/ossec/bin/${control_binary} stop
