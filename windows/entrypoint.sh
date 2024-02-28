#! /bin/bash

set -ex

BRANCH=$1
JOBS=$2
DEBUG=$3
REVISION=$4
TRUST_VERIFICATION=$5
CA_NAME=$6
ZIP_NAME="windows_agent_${REVISION}.zip"

URL_REPO=https://github.com/fortishield/fortishield/archive/${BRANCH}.zip

# Download the fortishield repository
wget -O fortishield.zip ${URL_REPO} && unzip fortishield.zip

# Compile the fortishield agent for Windows
FLAGS="-j ${JOBS} IMAGE_TRUST_CHECKS=${TRUST_VERIFICATION} CA_NAME=\"${CA_NAME}\" "

if [[ "${DEBUG}" = "yes" ]]; then
    FLAGS+="-d "
fi

bash -c "make -C /fortishield-*/src deps TARGET=winagent ${FLAGS}"
bash -c "make -C /fortishield-*/src TARGET=winagent ${FLAGS}"

rm -rf /fortishield-*/src/external

# Zip the compiled agent and move it to the shared folder
zip -r ${ZIP_NAME} fortishield-*
cp ${ZIP_NAME} /shared
