#!/bin/bash

users=( admin kibanaserver kibanaro logstash readall snapshotrestore )
api_users=( fortishield fortishield-wui )

echo '::group:: Change indexer password, password providing it.'

bash fortishield-passwords-tool.sh -u admin -p LN*X1v.VNtCZ5sESEtLfijPAd39LXGAI
if curl -s -XGET https://localhost:9200/ -u admin:LN*X1v.VNtCZ5sESEtLfijPAd39LXGAI -k -w %{http_code} | grep "401"; then
    exit 1
fi
echo '::endgroup::'

echo '::group:: Change indexer password without providing it.'

indx_pass="$(bash fortishield-passwords-tool.sh -u admin | awk '/admin/{ print $NF }' | tr -d \' )"
if curl -s -XGET https://localhost:9200/ -u admin:"${indx_pass}" -k -w %{http_code} | grep "401"; then
    exit 1
fi

echo '::endgroup::'

echo '::group:: Change all passwords except Fortishield API ones.'

mapfile -t pass < <(bash fortishield-passwords-tool.sh -a | awk '{ print $NF }' | sed \$d | sed '1d' )
for i in "${!users[@]}"; do
    if curl -s -XGET https://localhost:9200/ -u "${users[i]}":"${pass[i]}" -k -w %{http_code} | grep "401"; then
        exit 1
    fi
done

echo '::endgroup::'

echo '::group:: Change all passwords.'

fortishield_pass="$(cat fortishield-install-files/fortishield-passwords.txt | awk "/username: 'fortishield'/{getline;print;}" | awk '{ print $2 }' | tr -d \' )"

mapfile -t passall < <(bash fortishield-passwords-tool.sh -a -au fortishield -ap "${fortishield_pass}" | awk '{ print $NF }' | sed \$d ) 
passindexer=("${passall[@]:0:6}")
passapi=("${passall[@]:(-2)}")

for i in "${!users[@]}"; do
    if curl -s -XGET https://localhost:9200/ -u "${users[i]}":"${passindexer[i]}" -k -w %{http_code} | grep "401"; then
        exit 1
    fi
done

for i in "${!api_users[@]}"; do
    if curl -s -u "${api_users[i]}":"${passapi[i]}" -w "%{http_code}" -k -X POST "https://localhost:55000/security/user/authenticate" | grep "401"; then
        exit 1
    fi
done

echo '::endgroup::'

echo '::group:: Change single Fortishield API user.'

bash fortishield-passwords-tool.sh -au fortishield -ap "${passapi[0]}" -u fortishield -p BkJt92r*ndzN.CkCYWn?d7i5Z7EaUt63 -A 
    if curl -s -w "%{http_code}" -u fortishield:BkJt92r*ndzN.CkCYWn?d7i5Z7EaUt63 -k -X POST "https://localhost:55000/security/user/authenticate" | grep "401"; then
        exit 1
    fi
echo '::endgroup::'

echo '::group:: Change all passwords except Fortishield API ones using a file.'

mapfile -t passfile < <(bash fortishield-passwords-tool.sh -f fortishield-install-files/fortishield-passwords.txt | awk '{ print $NF }' | sed \$d | sed '1d' )
for i in "${!users[@]}"; do
    if curl -s -XGET https://localhost:9200/ -u "${users[i]}":"${passfile[i]}" -k -w %{http_code} | grep "401"; then
        exit 1
    fi
done
echo '::endgroup::'

echo '::group:: Change all passwords from a file.'
mapfile -t passallf < <(bash fortishield-passwords-tool.sh -f fortishield-install-files/fortishield-passwords.txt -au fortishield -ap BkJt92r*ndzN.CkCYWn?d7i5Z7EaUt63 | awk '{ print $NF }' | sed \$d ) 
passindexerf=("${passallf[@]:0:6}")
passapif=("${passallf[@]:(-2)}")

for i in "${!users[@]}"; do
    if curl -s -XGET https://localhost:9200/ -u "${users[i]}":"${passindexerf[i]}" -k -w %{http_code} | grep "401"; then
        exit 1
    fi
done

for i in "${!api_users[@]}"; do
    if curl -s -u "${api_users[i]}":"${passapif[i]}" -w "%{http_code}" -k -X POST "https://localhost:55000/security/user/authenticate" | grep "401"; then
        exit 1
    fi
done

echo '::endgroup::'
