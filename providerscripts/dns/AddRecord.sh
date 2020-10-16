#!/bin/sh
##################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script will add a DNS record to the dns provider for a server
# based on its ip address
##################################################################################
# License Agreement:
# This file is part of The Agile Deployment Toolkit.
# The Agile Deployment Toolkit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# The Agile Deployment Toolkit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with The Agile Deployment Toolkit.  If not, see <http://www.gnu.org/licenses/>.
####################################################################################
####################################################################################
#set -x

websiteurl="${4}"
domainurl="`/bin/echo ${4} | /usr/bin/cut -d'.' -f2-`"
subdomain="`/bin/echo ${4} | /usr/bin/awk -F'.' '{print $1}'`"
ip="${5}"
dns="${7}"

if ( [ "${dns}" = "digitalocean" ] )
then
    /usr/local/bin/doctl compute domain records create --record-type A --record-name ${subdomain} --record-data ${ip} ${domainurl}
fi


zoneid="${1}"
email="${2}"
authkey="${3}"
websiteurl="${4}"
ip="${5}"
dns="${6}"

if ( [ "${dns}" = "cloudflare" ] )
then
    /bin/echo "${0} `/bin/date`: Adding record to the dns for ip address: ${ip}" >> ${HOME}/logs/MonitoringLog.log
    /usr/bin/curl -X POST "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records" -H "X-Auth-Email: ${email}" -H "X-Auth-Key: ${authkey}" -H "Content-Type: application/json" --data "{\"type\":\"A\",\"name\":\"${websiteurl}\",\"content\":\"${ip}\",\"ttl\":120,\"proxiable\":true,\"proxied\":true,\"ttl\":120}"
fi

region="`/bin/ls ${HOME}/.ssh/DNSREGION:* | /usr/bin/awk -F':' '{print $NF}'`"
username="${2}"
apikey="${3}"
websiteurl="${4}"
ip="${5}"
dns="${6}"
rootdomain="`/bin/echo ${websiteurl} | /usr/bin/awk -F'.' '{$1="";print }' | /bin/sed 's/^ //' | sed 's/ /./g'`"

if ( [ "${dns}" = "rackspace" ] )
then
    token="`/usr/bin/curl -s -X POST https://identity.api.rackspacecloud.com/v2.0/tokens -H "Content-Type: application/json" -d '{ "auth": { "RAX-KSKEY:apiKeyCredentials": { "username": "'${username}'", "apiKey": "'${apikey}'" } } }' | /usr/bin/python -m json.tool | /usr/bin/jq ".access.token.id" | /bin/sed 's/"//g'`"
    endpoint="`/usr/bin/curl -s -X POST https://identity.api.rackspacecloud.com/v2.0/tokens -H "Content-Type: application/json" -d '{ "auth": { "RAX-KSKEY:apiKeyCredentials": { "username": "'${username}'", "apiKey": "'${apikey}'" } } }' | /usr/bin/python -m json.tool | /usr/bin/jq ".access.serviceCatalog[].endpoints[].publicURL" | /bin/sed 's/"//g' | /bin/grep ${region} | /bin/grep dns`"
    domainid="`/usr/bin/curl -X GET -H "X-Auth-Token:${token}" -H "Accept:application/json" "${endpoint}/domains" | /usr/bin/python -m json.tool | /usr/bin/jq '.domains[] | select(.name=="'${rootdomain}'") | .id'`"
    /usr/bin/curl -s -X POST $endpoint/domains/${domainid}/records -H "X-Auth-Token: $token" -H "Content-Type: application/json" -d '{ "records": [ { "name" : "'${websiteurl}'", "type" : "A", "data" : "'${ip}'", "ttl" : 300 } ] }' | python -m json.tool
fi
