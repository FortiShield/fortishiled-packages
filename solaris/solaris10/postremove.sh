#!/bin/sh
# postremove script for fortishield-agent
# Fortishield, Inc 2015

if getent passwd fortishield > /dev/null 2>&1; then
  userdel fortishield
fi

if getent group fortishield > /dev/null 2>&1; then
  groupdel fortishield
fi
