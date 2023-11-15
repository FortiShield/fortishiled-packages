#!/bin/bash

# Wazuh package generator
# Copyright (C) 2021, Wazuh Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

current_path="$( cd $(dirname $0) ; pwd -P )"
architecture="amd64"
outdir="${current_path}/output"
revision="1"
build_docker="yes"
deb_amd64_builder="deb_dashboard_builder_amd64"
deb_builder_dockerfile="${current_path}/docker"
future="no"
base_cmd=""
app_url=""
plugin_main=""
plugin_updates=""
plugin_core=""
build_base="yes"

trap ctrl_c INT

clean() {
    exit_code=$1

    # Clean the files
    rm -rf ${dockerfile_path}/{*.sh,*.tar.gz,wazuh-*}

    exit ${exit_code}
}

ctrl_c() {
    clean 1
}

build_deb() {
    container_name="$1"
    dockerfile_path="$2"

    if [ "${app_url_reference}" ]; then
        app_url="${app_url_reference}"
    fi
    if [ "${plugin_main_reference}" ];then
        plugin_main="${plugin_main_reference}"
    fi
    if [ "${plugin_updates_reference}" ];then
        plugin_updates="${plugin_updates_reference}"
    fi
    if [ "${plugin_core_reference}" ];then
        plugin_core="${plugin_core_reference}"
    fi

    # Copy the necessary files
    cp ${current_path}/builder.sh ${dockerfile_path}

    if [ "${build_base}" == "yes" ];then
        # Base generation
        if [ "${future}" == "yes" ];then
            base_cmd+="--future "
        fi
        if [ "${reference}" ];then
            base_cmd+="--reference ${reference}"
        fi
        if [ "${app_url_reference}" ];then
            base_cmd+="--app-url ${app_url}/${plugin_main}"
        fi
        ../base/generate_base.sh -s ${outdir} -r ${revision} ${base_cmd}
    else
        if [ "${reference}" ];then
            version=$(curl -sL https://raw.githubusercontent.com/wazuh/wazuh-packages/${reference}/VERSION | cat)
        else
            version=$(cat ${current_path}/../../../VERSION)
        fi
        basefile="${outdir}/wazuh-dashboard-base-${version}-${revision}-linux-x64.tar.xz"
        if ! test -f "${basefile}"; then
            echo "Did not find expected Wazuh dashboard base file: ${basefile} in output path. Exiting..."
            exit 1
        fi
    fi

    # Build the Docker image
    if [[ ${build_docker} == "yes" ]]; then
        docker build -t ${container_name} ${dockerfile_path} || return 1
    fi

    # Build the Debian package with a Docker container
    volumes="-v ${outdir}/:/tmp:Z"
    if [ "${reference}" ];then
        docker run -t --rm ${volumes} \
            ${container_name} ${architecture} ${revision} \
            ${future} ${app_url} ${plugin_main} ${plugin_updates} ${plugin_core} ${reference} || return 1
    else
        docker run -t --rm ${volumes} \
            -v ${current_path}/../../..:/root:Z \
            ${container_name} ${architecture} ${revision} \
            ${future} ${app_url} ${plugin_main} ${plugin_updates} ${plugin_core}  || return 1
    fi

    echo "Package $(ls -Art ${outdir} | tail -n 1) added to ${outdir}."

    return 0
}

build() {
    build_name=""
    file_path=""
    if [ "${architecture}" = "x86_64" ] || [ "${architecture}" = "amd64" ]; then
        architecture="amd64"
        build_name="${deb_amd64_builder}"
        file_path="${deb_builder_dockerfile}/${architecture}"
    else
        echo "Invalid architecture. Choose: amd64 (x86_64 is accepted too)"
        return 1
    fi
    build_deb ${build_name} ${file_path} || return 1

    return 0
}

help() {
    echo -e ""
    echo -e "NAME"
    echo -e "        $(basename "$0") - Build Wazuh dashboard base file."
    echo -e ""
    echo -e "SYNOPSIS"
    echo -e "        $(basename "$0") -a | -m | -u | -c | -s | -b | -f | -r | -h"
    echo -e ""
    echo -e "DESCRIPTION"
    echo -e "        -a, --architecture <arch>"
    echo -e "                [Optional] Target architecture of the package [amd64]."
    echo -e ""
    echo -e "        -ar, --app-repo <url>"
    echo -e "                [Optional] URL where Wazuh plugins are located."
    echo -e ""
    echo -e "        -m, --main-app <name>"
    echo -e "                [Required by '-ar, --app-repo'] Wazuh main plugin filename located at the URL provided, must include ZIP extension."
    echo -e ""
    echo -e "        -u, --updates-app <name>"
    echo -e "                [Required by '-ar, --app-repo'] Wazuh Check Updates plugin filename located at the URL provided, must include ZIP extension."
    echo -e ""
    echo -e "        -c, --core-app <name>"
    echo -e "                [Required by '-ar, --app-repo'] Wazuh Core plugin filename located at the URL provided, must include ZIP extension."
    echo -e ""
    echo -e "        -b, --build-base <yes/no>"
    echo -e "                [Optional] Build a new base or use a existing one. By default, yes."
    echo -e ""
    echo -e "        -r, --revision <rev>"
    echo -e "                [Optional] Package revision. By default: 1."
    echo -e ""
    echo -e "        -s, --store <path>"
    echo -e "                [Optional] Set the destination path of package. By default, an output folder will be created."
    echo -e ""
    echo -e "        --reference <ref>"
    echo -e "                [Optional] wazuh-packages branch to download SPECs, not used by default."
    echo -e ""
    echo -e "        --dont-build-docker"
    echo -e "                [Optional] Locally built docker image will be used instead of generating a new one."
    echo -e ""
    echo -e "        --future"
    echo -e "                [Optional] Build test future package 99.99.0 Used for development purposes."
    echo -e ""
    echo -e "        -h, --help"
    echo -e "                Show this help."
    echo -e ""
    exit $1
}


main() {
    while [ -n "${1}" ]
    do
        case "${1}" in
        "-h"|"--help")
            help 0
            ;;
        "-a"|"--architecture")
            if [ -n "${2}" ]; then
                architecture="${2}"
                shift 2
            else
                help 1
            fi
            ;;
       "-ar"|"--app-repo")
            if [ -n "$2" ]; then
                app_url_reference="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "-m"|"--main-app-url")
            if [ -n "$2" ]; then
                plugin_main_reference="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "-u"|"--updates-app-url")
            if [ -n "$2" ]; then
                plugin_updates_reference="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "-c"|"--core-app-url")
            if [ -n "$2" ]; then
                plugin_core_reference="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "-b"|"--build-base")
            if [ -n "${2}" ]; then
                build_base="${2}"
                shift 2
            else
                help 1
            fi
            ;;
        "-r"|"--revision")
            if [ -n "${2}" ]; then
                revision="${2}"
                shift 2
            else
                help 1
            fi
            ;;
        "--reference")
            if [ -n "${2}" ]; then
                reference="${2}"
                shift 2
            else
                help 1
            fi
            ;;
        "--dont-build-docker")
            build_docker="no"
            shift 1
            ;;
        "--future")
            future="yes"
            shift 1
            ;;
        "-s"|"--store")
            if [ -n "${2}" ]; then
                outdir="${2}"
                shift 2
            else
                help 1
            fi
            ;;
        *)
            help 1
        esac
    done

    if [ ${app_url_reference} ] && [ ${plugin_main_reference} ] && [ ${plugin_updates_reference} ] && [ ${plugin_core_reference} ]; then
        echo "The Wazuh dashboard package will be created using the following plugins URLs:"
        echo "Wazuh main plugin: ${app_url_reference}/${plugin_main_reference}"
        echo "Wazuh Check Updates plugin: ${app_url_reference}/${plugin_updates_reference}"
        echo "Wazuh Core plugin: ${app_url_reference}/${plugin_core_reference}"
    elif [ ! ${app_url_reference} ] && [ ! ${plugin_main_reference} ] && [ ! ${plugin_updates_reference} ] && [ ! ${plugin_core_reference} ]; then
        echo "No Wazuh plugins have been defined, will use pre-release."
    else
        echo "The -ar, -m, -u, and -c options must be used together."
        exit 1
    fi

    build || clean 1

    clean 0
}

main "$@"
