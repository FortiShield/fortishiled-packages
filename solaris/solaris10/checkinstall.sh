#!/bin/sh
# checkinstall script for fortishield-agent
# Fortishield, Inc 2015

expected_platform="ARCH"
platform=`uname -p`
if [ ${platform} != ${expected_platform} ]; then
        echo "This package must be installed on ${expected_platform}"
        exit
fi
exit 0
