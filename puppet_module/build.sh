#!/bin/bash
set -e

fortishield_branch=$1

download_sources() {
    if ! curl -L https://github.com/fortishield/fortishield-puppet/tarball/${fortishield_branch} | tar zx ; then
        echo "Error downloading the source code from GitHub."
        exit 1
    fi
    cd fortishield-*
}

build_module() {

    download_sources

    pdk build --force --target-dir=/tmp/output/

    exit 0
}

build_module
