#!/bin/sh

## Stop and remove application
sudo /Library/Ossec/bin/fortishield-control stop
sudo /bin/rm -r /Library/Ossec*

## stop and unload dispatcher
/bin/launchctl unload /Library/LaunchDaemons/com.fortishield.agent.plist

# remove launchdaemons
/bin/rm -f /Library/LaunchDaemons/com.fortishield.agent.plist

## remove StartupItems
/bin/rm -rf /Library/StartupItems/FORTISHIELD

## Remove User and Groups
/usr/bin/dscl . -delete "/Users/fortishield"
/usr/bin/dscl . -delete "/Groups/fortishield"

/usr/sbin/pkgutil --forget com.fortishield.pkg.fortishield-agent
/usr/sbin/pkgutil --forget com.fortishield.pkg.fortishield-agent-etc

# In case it was installed via Puppet pkgdmg provider

if [ -e /var/db/.puppet_pkgdmg_installed_fortishield-agent ]; then
    rm -f /var/db/.puppet_pkgdmg_installed_fortishield-agent
fi

echo
echo "Fortishield agent correctly removed from the system."
echo

exit 0
