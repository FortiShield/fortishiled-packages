#!/bin/sh
# uninstall script for fortishield-agent
# Fortishield, Inc 2015

control_binary="fortishield-control"

if [ ! -f /var/ossec/bin/${control_binary} ]; then
  control_binary="ossec-control"
fi

## Stop and remove application
/var/ossec/bin/${control_binary} stop
rm -rf /var/ossec/

## stop and unload dispatcher
#/bin/launchctl unload /Library/LaunchDaemons/com.fortishield.agent.plist

# remove launchdaemons
rm -f /etc/init.d/fortishield-agent
rm -rf /etc/rc2.d/S97fortishield-agent
rm -rf /etc/rc3.d/S97fortishield-agent

## Remove User and Groups
userdel fortishield 2> /dev/null
groupdel fortishield 2> /dev/null

exit 0
