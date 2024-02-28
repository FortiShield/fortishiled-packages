#!/usr/bin/env bash
set -euo pipefail
base_dir="$(cd "$(dirname "$BASH_SOURCE")"; pwd -P; cd - >/dev/null;)"
source "${base_dir}"/bach.sh

@setup-test {
    @ignore common_logger
}

function load-installCommon_getConfig() {
    @load_function "${base_dir}/installCommon.sh" installCommon_getConfig
}

test-ASSERT-FAIL-01-installCommon_getConfig-no-args() {
    load-installCommon_getConfig
    installCommon_getConfig
}

test-ASSERT-FAIL-02-installCommon_getConfig-one-argument() {
    load-installCommon_getConfig
    installCommon_getConfig "elasticsearch"
}

test-03-installCommon_getConfig() {
    load-installCommon_getConfig
    @mocktrue echo certificate/config_aio.yml
    @mock sed 's|/|_|g;s|.yml||' === @out "certificate_config_aio"
    @mock echo === @echo "Hello World"
    installCommon_getConfig certificate/config_aio.yml ./config.yml
}

test-03-installCommon_getConfig-assert() {
    eval "echo \"\${config_file_certificate_config_aio}\""

}

test-04-installCommon_getConfig-error() {
    load-installCommon_getConfig
    @mocktrue echo certificate/config_aio.yml
    @mock sed 's|/|_|g;s|.yml||' === @out "certificate_config_aio"
    @mock echo === @echo ""
    installCommon_getConfig certificate/config_aio.yml ./config.yml
}

test-04-installCommon_getConfig-error-assert() {
    installCommon_rollBack
    exit 1
}

function load-installCommon_installPrerequisites() {
    @load_function "${base_dir}/installCommon.sh" installCommon_installPrerequisites
}

test-05-installCommon_installPrerequisites-yum-no-openssl() {
    @mock command -v openssl === @false
    load-installCommon_installPrerequisites
    sys_type="yum"
    debug=""
    installCommon_installPrerequisites
}

test-05-installCommon_installPrerequisites-yum-no-openssl-assert() {
    yum install curl unzip wget libcap tar gnupg openssl -y
}

test-06-installCommon_installPrerequisites-yum() {
    @mock command -v openssl === @echo /usr/bin/openssl
    load-installCommon_installPrerequisites
    sys_type="yum"
    debug=""
    installCommon_installPrerequisites
}

test-06-installCommon_installPrerequisites-yum-assert() {
    yum install curl unzip wget libcap tar gnupg -y
}


test-07-installCommon_installPrerequisites-apt-no-openssl() {
    @mock command -v openssl === @false
    load-installCommon_installPrerequisites
    sys_type="apt-get"
    debug=""
    installCommon_installPrerequisites
}

test-07-installCommon_installPrerequisites-apt-no-openssl-assert() {
    apt update -q
    apt install apt-transport-https curl unzip wget libcap2-bin tar software-properties-common gnupg openssl -y
}

test-08-installCommon_installPrerequisites-apt() {
    @mock command -v openssl === @out /usr/bin/openssl
    load-installCommon_installPrerequisites
    sys_type="apt-get"
    debug=""
    installCommon_installPrerequisites
}

test-08-installCommon_installPrerequisites-apt-assert() {
    apt update -q
    apt install apt-transport-https curl unzip wget libcap2-bin tar software-properties-common gnupg -y
}

function load-installCommon_addFortishieldRepo() {
    @load_function "${base_dir}/installCommon.sh" installCommon_addFortishieldRepo
}

test-09-installCommon_addFortishieldRepo-yum() {
    load-installCommon_addFortishieldRepo
    development=1
    sys_type="yum"
    debug=""
    repogpg=""
    releasever=""
    @mocktrue echo -e '[fortishield]\ngpgcheck=1\ngpgkey=\nenabled=1\nname=EL-${releasever} - Fortishield\nbaseurl=/yum/\nprotect=1'
    @mocktrue tee /etc/yum.repos.d/fortishield.repo
    installCommon_addFortishieldRepo
}

test-09-installCommon_addFortishieldRepo-yum-assert() {
    rm -f /etc/yum.repos.d/fortishield.repo
    rpm --import
}


test-10-installCommon_addFortishieldRepo-apt() {
    load-installCommon_addFortishieldRepo
    development=1
    sys_type="apt-get"
    debug=""
    repogpg=""
    releasever=""
    @rm /etc/yum.repos.d/fortishield.repo
    @rm /etc/zypp/repos.d/fortishield.repo
    @rm /etc/apt/sources.list.d/fortishield.list
    @mocktrue curl -s --max-time 300
    @mocktrue apt-key add -
    @mocktrue echo "deb /apt/  main"
    @mocktrue tee /etc/apt/sources.list.d/fortishield.list
    installCommon_addFortishieldRepo
}

test-10-installCommon_addFortishieldRepo-apt-assert() {
    rm -f /etc/apt/sources.list.d/fortishield.list
    apt-get update -q
}

test-11-installCommon_addFortishieldRepo-apt-file-present() {
    load-installCommon_addFortishieldRepo
    development=""
    @mkdir -p /etc/yum.repos.d
    @touch /etc/yum.repos.d/fortishield.repo
    installCommon_addFortishieldRepo
    @assert-success
    @rm /etc/yum.repos.d/fortishield.repo
}

test-12-installCommon_addFortishieldRepo-yum-file-present() {
    load-installCommon_addFortishieldRepo
    development=""
    @mkdir -p /etc/apt/sources.list.d/
    @touch /etc/apt/sources.list.d/fortishield.list
    installCommon_addFortishieldRepo
    @assert-success
    @rm /etc/apt/sources.list.d/fortishield.list
}

function load-installCommon_restoreFortishieldrepo() {
    @load_function "${base_dir}/installCommon.sh" installCommon_restoreFortishieldrepo
}

test-13-installCommon_restoreFortishieldrepo-no-dev() {
    load-installCommon_restoreFortishieldrepo
    development=""
    installCommon_restoreFortishieldrepo
    @assert-success
}

test-14-installCommon_restoreFortishieldrepo-yum() {
    load-installCommon_restoreFortishieldrepo
    development="1"
    sys_type="yum"
    @mkdir -p /etc/yum.repos.d
    @touch /etc/yum.repos.d/fortishield.repo
    installCommon_restoreFortishieldrepo
    @rm /etc/yum.repos.d/fortishield.repo
}

test-14-installCommon_restoreFortishieldrepo-yum-assert() {
    sed -i 's/-dev//g' /etc/yum.repos.d/fortishield.repo
    sed -i 's/pre-release/4.x/g' /etc/yum.repos.d/fortishield.repo
    sed -i 's/unstable/stable/g' /etc/yum.repos.d/fortishield.repo
}

test-15-installCommon_restoreFortishieldrepo-apt() {
    load-installCommon_restoreFortishieldrepo
    development="1"
    sys_type="apt-get"
    @mkdir -p /etc/apt/sources.list.d/
    @touch /etc/apt/sources.list.d/fortishield.list
    installCommon_restoreFortishieldrepo
    @rm /etc/apt/sources.list.d/fortishield.list
}

test-15-installCommon_restoreFortishieldrepo-apt-assert() {
    sed -i 's/-dev//g' /etc/apt/sources.list.d/fortishield.list
    sed -i 's/pre-release/4.x/g' /etc/apt/sources.list.d/fortishield.list
    sed -i 's/unstable/stable/g' /etc/apt/sources.list.d/fortishield.list
}


test-16-installCommon_restoreFortishieldrepo-yum-no-file() {
    load-installCommon_restoreFortishieldrepo
    development="1"
    sys_type="yum"
    installCommon_restoreFortishieldrepo
}

test-16-installCommon_restoreFortishieldrepo-yum-no-file-assert() {
    sed -i 's/-dev//g'
    sed -i 's/pre-release/4.x/g'
    sed -i 's/unstable/stable/g'
}

test-17-installCommon_restoreFortishieldrepo-apt-no-file() {
    load-installCommon_restoreFortishieldrepo
    development="1"
    sys_type="yum"
    installCommon_restoreFortishieldrepo
}

test-17-installCommon_restoreFortishieldrepo-apt-no-file-assert() {
    sed -i 's/-dev//g'
    sed -i 's/pre-release/4.x/g'
    sed -i 's/unstable/stable/g'
}

function load-installCommon_createClusterKey {
    @load_function "${base_dir}/installCommon.sh" installCommon_createClusterKey
}

test-18-installCommon_createClusterKey() {
    load-installCommon_createClusterKey
    base_path=/tmp
    @mkdir -p /tmp/certs
    @touch /tmp/certs/clusterkey
    @mocktrue openssl rand -hex 16
    installCommon_createClusterKey
    @assert-success
    @rm /tmp/certs/clusterkey
}

function load-installCommon_rollBack {
    @load_function "${base_dir}/installCommon.sh" installCommon_rollBack
}

test-19-installCommon_rollBack-aio-all-installed-yum() {
    load-installCommon_rollBack
    indexer_installed=1
    fortishield_installed=1
    dashboard_installed=1
    filebeat_installed=1
    fortishield_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="yum"
    debug=
    AIO=1
    installCommon_rollBack
}

test-19-installCommon_rollBack-aio-all-installed-yum-assert() {

    yum remove fortishield-manager -y

    rm -rf /var/ossec/

    yum remove fortishield-indexer -y

    rm -rf /var/lib/fortishield-indexer/
    rm -rf /usr/share/fortishield-indexer/
    rm -rf /etc/fortishield-indexer/

    yum remove filebeat -y

    rm -rf /var/lib/filebeat/
    rm -rf /usr/share/filebeat/
    rm -rf /etc/filebeat/

    yum remove fortishield-dashboard -y

    rm -rf /var/lib/fortishield-dashboard/
    rm -rf /usr/share/fortishield-dashboard/
    rm -rf /etc/fortishield-dashboard/
    rm -rf /run/fortishield-dashboard/

    rm  -rf /var/log/fortishield-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/fortishield-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/fortishield-dashboard.service /etc/systemd/system/fortishield-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-20-installCommon_rollBack-aio-all-installed-apt() {
    load-installCommon_rollBack
    indexer_installed=1
    fortishield_installed=1
    dashboard_installed=1
    filebeat_installed=1
    fortishield_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="apt-get"
    debug=
    AIO=1
    installCommon_rollBack
}

test-20-installCommon_rollBack-aio-all-installed-apt-assert() {
    apt remove --purge fortishield-manager -y

    rm -rf /var/ossec/

    apt remove --purge ^fortishield-indexer -y

    rm -rf /var/lib/fortishield-indexer/
    rm -rf /usr/share/fortishield-indexer/
    rm -rf /etc/fortishield-indexer/

    apt remove --purge filebeat -y

    rm -rf /var/lib/filebeat/
    rm -rf /usr/share/filebeat/
    rm -rf /etc/filebeat/

    apt remove --purge fortishield-dashboard -y

    rm -rf /var/lib/fortishield-dashboard/
    rm -rf /usr/share/fortishield-dashboard/
    rm -rf /etc/fortishield-dashboard/
    rm -rf /run/fortishield-dashboard/

    rm  -rf /var/log/fortishield-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/fortishield-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/fortishield-dashboard.service /etc/systemd/system/fortishield-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-21-installCommon_rollBack-indexer-installation-all-installed-yum() {
    load-installCommon_rollBack
    indexer_installed=1
    fortishield_installed=1
    dashboard_installed=1
    filebeat_installed=1
    fortishield_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="yum"
    debug=
    indexer=1
    installCommon_rollBack
}

test-21-installCommon_rollBack-indexer-installation-all-installed-yum-assert() {
    yum remove fortishield-indexer -y

    rm -rf /var/lib/fortishield-indexer/
    rm -rf /usr/share/fortishield-indexer/
    rm -rf /etc/fortishield-indexer/

    rm  -rf /var/log/fortishield-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/fortishield-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/fortishield-dashboard.service /etc/systemd/system/fortishield-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-22-installCommon_rollBack-indexer-installation-all-installed-apt() {
    load-installCommon_rollBack
    indexer_installed=1
    fortishield_installed=1
    dashboard_installed=1
    filebeat_installed=1
    fortishield_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="apt-get"
    debug=
    indexer=1
    installCommon_rollBack
}

test-22-installCommon_rollBack-indexer-installation-all-installed-apt-assert() {
    apt remove --purge ^fortishield-indexer -y

    rm -rf /var/lib/fortishield-indexer/
    rm -rf /usr/share/fortishield-indexer/
    rm -rf /etc/fortishield-indexer/

    rm  -rf /var/log/fortishield-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/fortishield-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/fortishield-dashboard.service /etc/systemd/system/fortishield-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-23-installCommon_rollBack-fortishield-installation-all-installed-yum() {
    load-installCommon_rollBack
    indexer_installed=1
    fortishield_installed=1
    dashboard_installed=1
    filebeat_installed=1
    fortishield_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="yum"
    debug=
    fortishield=1
    installCommon_rollBack
}

test-23-installCommon_rollBack-fortishield-installation-all-installed-yum-assert() {
    yum remove fortishield-manager -y

    rm -rf /var/ossec/

    yum remove filebeat -y

    rm -rf /var/lib/filebeat/
    rm -rf /usr/share/filebeat/
    rm -rf /etc/filebeat/

    rm  -rf /var/log/fortishield-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/fortishield-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/fortishield-dashboard.service /etc/systemd/system/fortishield-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-24-installCommon_rollBack-fortishield-installation-all-installed-apt() {
    load-installCommon_rollBack
    indexer_installed=1
    fortishield_installed=1
    dashboard_installed=1
    filebeat_installed=1
    fortishield_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="apt-get"
    debug=
    fortishield=1
    installCommon_rollBack
}

test-24-installCommon_rollBack-fortishield-installation-all-installed-apt-assert() {
    apt remove --purge fortishield-manager -y

    rm -rf /var/ossec/

    apt remove --purge filebeat -y

    rm -rf /var/lib/filebeat/
    rm -rf /usr/share/filebeat/
    rm -rf /etc/filebeat/

    rm  -rf /var/log/fortishield-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/fortishield-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/fortishield-dashboard.service /etc/systemd/system/fortishield-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-25-installCommon_rollBack-dashboard-installation-all-installed-yum() {
    load-installCommon_rollBack
    indexer_installed=1
    fortishield_installed=1
    dashboard_installed=1
    filebeat_installed=1
    fortishield_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="yum"
    debug=
    dashboard=1
    installCommon_rollBack
}

test-25-installCommon_rollBack-dashboard-installation-all-installed-yum-assert() {
    yum remove fortishield-dashboard -y

    rm -rf /var/lib/fortishield-dashboard/
    rm -rf /usr/share/fortishield-dashboard/
    rm -rf /etc/fortishield-dashboard/
    rm -rf /run/fortishield-dashboard/

    rm  -rf /var/log/fortishield-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/fortishield-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/fortishield-dashboard.service /etc/systemd/system/fortishield-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-26-installCommon_rollBack-dashboard-installation-all-installed-apt() {
    load-installCommon_rollBack
    indexer_installed=1
    fortishield_installed=1
    dashboard_installed=1
    filebeat_installed=1
    fortishield_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="apt-get"
    debug=
    dashboard=1
    installCommon_rollBack
}

test-26-installCommon_rollBack-dashboard-installation-all-installed-apt-assert() {
    apt remove --purge fortishield-dashboard -y

    rm -rf /var/lib/fortishield-dashboard/
    rm -rf /usr/share/fortishield-dashboard/
    rm -rf /etc/fortishield-dashboard/
    rm -rf /run/fortishield-dashboard/

    rm  -rf /var/log/fortishield-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/fortishield-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/fortishield-dashboard.service /etc/systemd/system/fortishield-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-27-installCommon_rollBack-aio-nothing-installed() {
    load-installCommon_rollBack
    indexer_installed=
    fortishield_installed=
    dashboard_installed=
    filebeat_installed=
    fortishield_remaining_files=
    indexer_remaining_files=
    dashboard_remaining_files=
    filebeat_remaining_files=
    sys_type="yum"
    debug=
    AIO=1
    installCommon_rollBack
    @assert-success
}

test-28-installCommon_rollBack-aio-all-remaining-files-yum() {
    load-installCommon_rollBack
    indexer_installed=
    fortishield_installed=
    dashboard_installed=
    filebeat_installed=
    fortishield_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="yum"
    debug=
    AIO=1
    installCommon_rollBack
}

test-28-installCommon_rollBack-aio-all-remaining-files-yum-assert() {
    rm -rf /var/ossec/

    rm -rf /var/lib/fortishield-indexer/
    rm -rf /usr/share/fortishield-indexer/
    rm -rf /etc/fortishield-indexer/

    rm -rf /var/lib/filebeat/
    rm -rf /usr/share/filebeat/
    rm -rf /etc/filebeat/

    rm -rf /var/lib/fortishield-dashboard/
    rm -rf /usr/share/fortishield-dashboard/
    rm -rf /etc/fortishield-dashboard/
    rm -rf /run/fortishield-dashboard/

    rm  -rf /var/log/fortishield-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/fortishield-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/fortishield-dashboard.service /etc/systemd/system/fortishield-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-29-installCommon_rollBack-aio-all-remaining-files-apt() {
    load-installCommon_rollBack
    indexer_installed=
    fortishield_installed=
    dashboard_installed=
    filebeat_installed=
    fortishield_remaining_files=1
    indexer_remaining_files=1
    dashboard_remaining_files=1
    filebeat_remaining_files=1
    sys_type="apt-get"
    debug=
    AIO=1
    installCommon_rollBack
}

test-29-installCommon_rollBack-aio-all-remaining-files-apt-assert() {
    rm -rf /var/ossec/

    rm -rf /var/lib/fortishield-indexer/
    rm -rf /usr/share/fortishield-indexer/
    rm -rf /etc/fortishield-indexer/

    rm -rf /var/lib/filebeat/
    rm -rf /usr/share/filebeat/
    rm -rf /etc/filebeat/

    rm -rf /var/lib/fortishield-dashboard/
    rm -rf /usr/share/fortishield-dashboard/
    rm -rf /etc/fortishield-dashboard/
    rm -rf /run/fortishield-dashboard/

    rm  -rf /var/log/fortishield-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/fortishield-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/fortishield-dashboard.service /etc/systemd/system/fortishield-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-30-installCommon_rollBack-nothing-installed-remove-yum-repo() {
    load-installCommon_rollBack
    @mkdir -p /etc/yum.repos.d
    @touch /etc/yum.repos.d/fortishield.repo
    installCommon_rollBack
    @rm /etc/yum.repos.d/fortishield.repo
}

test-30-installCommon_rollBack-nothing-installed-remove-yum-repo-assert() {
    rm /etc/yum.repos.d/fortishield.repo

    rm  -rf /var/log/fortishield-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/fortishield-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/fortishield-dashboard.service /etc/systemd/system/fortishield-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-31-installCommon_rollBack-nothing-installed-remove-apt-repo() {
    load-installCommon_rollBack
    @mkdir -p /etc/apt/sources.list.d
    @touch /etc/apt/sources.list.d/fortishield.list
    installCommon_rollBack
    @rm /etc/apt/sources.list.d/fortishield.list
}

test-31-installCommon_rollBack-nothing-installed-remove-apt-repo-assert() {
    rm /etc/apt/sources.list.d/fortishield.list

    rm  -rf /var/log/fortishield-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/fortishield-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/fortishield-dashboard.service /etc/systemd/system/fortishield-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

test-32-installCommon_rollBack-nothing-installed-remove-files() {
    load-installCommon_rollBack
    @mkdir -p /var/log/elasticsearch/
    installCommon_rollBack
    @rmdir /var/log/elasticsearch
}

test-32-installCommon_rollBack-nothing-installed-remove-files-assert() {
    rm  -rf /var/log/fortishield-indexer/ /var/log/filebeat/ /etc/systemd/system/opensearch.service.wants/ /securityadmin_demo.sh /etc/systemd/system/multi-user.target.wants/fortishield-manager.service /etc/systemd/system/multi-user.target.wants/filebeat.service /etc/systemd/system/multi-user.target.wants/opensearch.service /etc/systemd/system/multi-user.target.wants/fortishield-dashboard.service /etc/systemd/system/fortishield-dashboard.service /lib/firewalld/services/dashboard.xml /lib/firewalld/services/opensearch.xml
}

function load-installCommon_createCertificates() {
    @load_function "${base_dir}/installCommon.sh" installCommon_createCertificates
}

test-33-installCommon_createCertificates-aio() {
    load-installCommon_createCertificates
    AIO=1
    base_path=/tmp
    installCommon_createCertificates
}

test-33-installCommon_createCertificates-aio-assert() {
    installCommon_getConfig certificate/config_aio.yml /tmp/config.yml

    cert_readConfig

    mkdir /tmp/certs

    cert_generateRootCAcertificate
    cert_generateAdmincertificate
    cert_generateIndexercertificates
    cert_generateFilebeatcertificates
    cert_generateDashboardcertificates
    cert_cleanFiles
}

test-34-installCommon_createCertificates-no-aio() {
    load-installCommon_createCertificates
    base_path=/tmp
    installCommon_createCertificates
}

test-34-installCommon_createCertificates-no-aio-assert() {

    cert_readConfig

    mkdir /tmp/certs

    cert_generateRootCAcertificate
    cert_generateAdmincertificate
    cert_generateIndexercertificates
    cert_generateFilebeatcertificates
    cert_generateDashboardcertificates
    cert_cleanFiles
}

function load-installCommon_changePasswords() {
    @load_function "${base_dir}/installCommon.sh" installCommon_changePasswords
}

test-ASSERT-FAIL-35-installCommon_changePasswords-no-tarfile() {
    load-installCommon_changePasswords
    tar_file=
    installCommon_changePasswords
}

test-36-installCommon_changePasswords-with-tarfile() {
    load-installCommon_changePasswords
    tar_file=tarfile.tar
    base_path=/tmp
    @touch $tar_file
    @mock tar -xf tarfile.tar -C /tmp fortishield-install-files/fortishield-passwords.txt === @touch /tmp/fortishield-passwords.txt
    installCommon_changePasswords
    @echo $changeall
    @rm /tmp/fortishield-passwords.txt
}

test-36-installCommon_changePasswords-with-tarfile-assert() {
    common_checkInstalled
    installCommon_readPasswordFileUsers
    passwords_changePassword
    rm -rf /tmp/fortishield-passwords.txt
    @echo
}

test-37-installCommon_changePasswords-with-tarfile-aio() {
    load-installCommon_changePasswords
    tar_file=tarfile.tar
    base_path=/tmp
    AIO=1
    @touch $tar_file
    @mock tar -xf tarfile.tar -C /tmp fortishield-install-files/fortishield-passwords.txt === @touch /tmp/fortishield-passwords.txt
    installCommon_changePasswords
    @echo $changeall
    @rm /tmp/fortishield-passwords.txt
}

test-37-installCommon_changePasswords-with-tarfile-aio-assert() {
    common_checkInstalled
    passwords_readUsers
    installCommon_readPasswordFileUsers
    passwords_getNetworkHost
    passwords_createBackUp
    passwords_generateHash
    passwords_changePassword
    passwords_runSecurityAdmin
    rm -rf /tmp/fortishield-passwords.txt
    @echo 1
}

test-38-installCommon_changePasswords-with-tarfile-start-elastic-cluster() {
    load-installCommon_changePasswords
    tar_file=tarfile.tar
    base_path=/tmp
    AIO=1
    @touch $tar_file
    @mock tar -xf tarfile.tar -C /tmp fortishield-install-files/fortishield-passwords.txt === @touch /tmp/fortishield-passwords.txt
    installCommon_changePasswords
    @echo $changeall
    @rm /tmp/fortishield-passwords.txt
}

test-38-installCommon_changePasswords-with-tarfile-start-elastic-cluster-assert() {
    common_checkInstalled
    passwords_readUsers
    installCommon_readPasswordFileUsers
    passwords_getNetworkHost
    passwords_createBackUp
    passwords_generateHash
    passwords_changePassword
    passwords_runSecurityAdmin
    rm -rf /tmp/fortishield-passwords.txt
    @echo 1
}

function load-installCommon_getPass() {
    @load_function "${base_dir}/installCommon.sh" installCommon_getPass
}

test-39-installCommon_getPass-no-args() {
    load-installCommon_getPass
    users=(kibanaserver admin)
    passwords=(kibanaserver_pass admin_pass)
    installCommon_getPass
    @echo $u_pass
}

test-39-installCommon_getPass-no-args-assert() {
    @echo
}

test-40-installCommon_getPass-admin() {
    load-installCommon_getPass
    users=(kibanaserver admin)
    passwords=(kibanaserver_pass admin_pass)
    installCommon_getPass admin
    @echo $u_pass
}

test-40-installCommon_getPass-admin-assert() {
    @echo admin_pass
}

function load-installCommon_startService() {
    @load_function "${base_dir}/installCommon.sh" installCommon_startService
}

test-ASSERT-FAIL-41-installCommon_startService-no-args() {
    load-installCommon_startService
    installCommon_startService
}

test-ASSERT-FAIL-42-installCommon_startService-no-service-manager() {
    load-installCommon_startService
    @mockfalse ps -e
    @mockfalse grep -E -q "^\ *1\ .*systemd$"
    @mockfalse grep -E -q "^\ *1\ .*init$"
    @rm /etc/init.d/fortishield
    installCommon_startService fortishield-manager
}

test-43-installCommon_startService-systemd() {
    load-installCommon_startService
    @mockfalse ps -e === @out
    @mocktrue grep -E -q "^\ *1\ .*systemd$"
    @mockfalse grep -E -q "^\ *1\ .*init$"
    installCommon_startService fortishield-manager
}

test-43-installCommon_startService-systemd-assert() {
    systemctl daemon-reload
    systemctl enable fortishield-manager.service
    systemctl start fortishield-manager.service
}

test-44-installCommon_startService-systemd-error() {
    load-installCommon_startService
    @mock ps -e === @out
    @mocktrue grep -E -q "^\ *1\ .*systemd$"
    @mockfalse grep -E -q "^\ *1\ .*init$"
    @mockfalse systemctl start fortishield-manager.service
    installCommon_startService fortishield-manager
}

test-44-installCommon_startService-systemd-error-assert() {
    systemctl daemon-reload
    systemctl enable fortishield-manager.service
    installCommon_rollBack
    exit 1
}

test-45-installCommon_startService-initd() {
    load-installCommon_startService
    @mock ps -e === @out
    @mockfalse grep -E -q "^\ *1\ .*systemd$"
    @mocktrue grep -E -q "^\ *1\ .*init$"
    @mkdir -p /etc/init.d
    @touch /etc/init.d/fortishield-manager
    @chmod +x /etc/init.d/fortishield-manager
    installCommon_startService fortishield-manager
    @rm /etc/init.d/fortishield-manager
}

test-45-installCommon_startService-initd-assert() {
    @mkdir -p /etc/init.d
    @touch /etc/init.d/fortishield-manager
    chkconfig fortishield-manager on
    service fortishield-manager start
    /etc/init.d/fortishield-manager start
    @rm /etc/init.d/fortishield-manager
}

test-46-installCommon_startService-initd-error() {
    load-installCommon_startService
    @mock ps -e === @out
    @mockfalse grep -E -q "^\ *1\ .*systemd$"
    @mocktrue grep -E -q "^\ *1\ .*init$"
    @mkdir -p /etc/init.d
    @touch /etc/init.d/fortishield-manager
    #/etc/init.d/fortishield-manager is not executable -> It will fail
    installCommon_startService fortishield-manager
    @rm /etc/init.d/fortishield-manager
}

test-46-installCommon_startService-initd-error-assert() {
    @mkdir -p /etc/init.d
    @touch /etc/init.d/fortishield-manager
    @chmod +x /etc/init.d/fortishield-manager
    chkconfig fortishield-manager on
    service fortishield-manager start
    /etc/init.d/fortishield-manager start
    installCommon_rollBack
    exit 1
    @rm /etc/init.d/fortishield-manager
}

test-47-installCommon_startService-rc.d/init.d() {
    load-installCommon_startService
    @mock ps -e === @out
    @mockfalse grep -E -q "^\ *1\ .*systemd$"
    @mockfalse grep -E -q "^\ *1\ .*init$"

    @mkdir -p /etc/rc.d/init.d
    @touch /etc/rc.d/init.d/fortishield-manager
    @chmod +x /etc/rc.d/init.d/fortishield-manager

    installCommon_startService fortishield-manager
    @rm /etc/rc.d/init.d/fortishield-manager
}

test-47-installCommon_startService-rc.d/init.d-assert() {
    @mkdir -p /etc/rc.d/init.d
    @touch /etc/rc.d/init.d/fortishield-manager
    @chmod +x /etc/rc.d/init.d/fortishield-manager
    /etc/rc.d/init.d/fortishield-manager start
    @rm /etc/rc.d/init.d/fortishield-manager
}

function load-installCommon_readPasswordFileUsers() {
    @load_function "${base_dir}/installCommon.sh" installCommon_readPasswordFileUsers
}

test-ASSERT-FAIL-48-installCommon_readPasswordFileUsers-file-incorrect() {
    load-installCommon_readPasswordFileUsers
    p_file=/tmp/passfile.yml
    @mock grep -Pzc '\A(User:\s*name:\s*\w+\s*password:\s*[A-Za-z0-9_\-]+\s*)+\Z' /tmp/passfile.yml === @echo 0
    installCommon_readPasswordFileUsers
}

test-49-installCommon_readPasswordFileUsers-changeall-correct() {
    load-installCommon_readPasswordFileUsers
    p_file=/tmp/passfile.yml
    @mock grep -Pzc '\A(User:\s*name:\s*\w+\s*password:\s*[A-Za-z0-9_\-]+\s*)+\Z' /tmp/passfile.yml === @echo 1
    @mock grep name: /tmp/passfile.yml === @echo fortishield kibanaserver
    @mock awk '{ print substr( $2, 1, length($2) ) }'
    @mock grep password: /tmp/passfile.yml === @echo fortishieldpassword kibanaserverpassword
    @mock awk '{ print substr( $2, 1, length($2) ) }'
    changeall=1
    users=( fortishield kibanaserver )
    installCommon_readPasswordFileUsers
    @echo ${fileusers[*]}
    @echo ${filepasswords[*]}
    @echo ${users[*]}
    @echo ${passwords[*]}
}

test-49-installCommon_readPasswordFileUsers-changeall-correct-assert() {
    @echo fortishield kibanaserver
    @echo fortishieldpassword kibanaserverpassword
    @echo fortishield kibanaserver
    @echo fortishieldpassword kibanaserverpassword
}

test-50-installCommon_readPasswordFileUsers-changeall-user-doesnt-exist() {
    load-installCommon_readPasswordFileUsers
    p_file=/tmp/passfile.yml
    @mock grep -Pzc '\A(User:\s*name:\s*\w+\s*password:\s*[A-Za-z0-9_\-]+\s*)+\Z' /tmp/passfile.yml === @echo 1
    @mock grep name: /tmp/passfile.yml === @out fortishield kibanaserver admin
    @mock awk '{ print substr( $2, 1, length($2) ) }'
    @mock grep password: /tmp/passfile.yml === @out fortishieldpassword kibanaserverpassword
    @mock awk '{ print substr( $2, 1, length($2) ) }'
    changeall=1
    users=( fortishield kibanaserver )
    installCommon_readPasswordFileUsers
    @echo ${fileusers[*]}
    @echo ${filepasswords[*]}
    @echo ${users[*]}
    @echo ${passwords[*]}
}

test-50-installCommon_readPasswordFileUsers-changeall-user-doesnt-exist-assert() {
    @echo fortishield kibanaserver admin
    @echo fortishieldpassword kibanaserverpassword
    @echo fortishield kibanaserver
    @echo fortishieldpassword kibanaserverpassword
}

test-51-installCommon_readPasswordFileUsers-no-changeall-kibana-correct() {
    load-installCommon_readPasswordFileUsers
    p_file=/tmp/passfile.yml
    @mock grep -Pzc '\A(User:\s*name:\s*\w+\s*password:\s*[A-Za-z0-9_\-]+\s*)+\Z' /tmp/passfile.yml === @echo 1
    @mock grep name: /tmp/passfile.yml === @out fortishield kibanaserver admin
    @mock awk '{ print substr( $2, 1, length($2) ) }'
    @mock grep password: /tmp/passfile.yml === @out fortishieldpassword kibanaserverpassword adminpassword
    @mock awk '{ print substr( $2, 1, length($2) ) }'
    changeall=
    dashboard_installed=1
    dashboard=1
    installCommon_readPasswordFileUsers
    @echo ${fileusers[*]}
    @echo ${filepasswords[*]}
    @echo ${users[*]}
    @echo ${passwords[*]}
}

test-51-installCommon_readPasswordFileUsers-no-changeall-kibana-correct-assert() {
    @echo fortishield kibanaserver admin
    @echo fortishieldpassword kibanaserverpassword adminpassword
    @echo kibanaserver admin
    @echo kibanaserverpassword adminpassword
}

test-52-installCommon_readPasswordFileUsers-no-changeall-filebeat-correct() {
    load-installCommon_readPasswordFileUsers
    p_file=/tmp/passfile.yml
    @mock grep -Pzc '\A(User:\s*name:\s*\w+\s*password:\s*[A-Za-z0-9_\-]+\s*)+\Z' /tmp/passfile.yml === @echo 1
    @mock grep name: /tmp/passfile.yml === @out fortishield kibanaserver admin
    @mock awk '{ print substr( $2, 1, length($2) ) }'
    @mock grep password: /tmp/passfile.yml === @out fortishieldpassword kibanaserverpassword adminpassword
    @mock awk '{ print substr( $2, 1, length($2) ) }'
    changeall=
    filebeat_installed=1
    fortishield=1
    installCommon_readPasswordFileUsers
    @echo ${fileusers[*]}
    @echo ${filepasswords[*]}
    @echo ${users[*]}
    @echo ${passwords[*]}
}

test-52-installCommon_readPasswordFileUsers-no-changeall-filebeat-correct-assert() {
    @echo fortishield kibanaserver admin
    @echo fortishieldpassword kibanaserverpassword adminpassword
    @echo admin
    @echo adminpassword
}

