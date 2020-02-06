#!/bin/sh
###########################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script will get a record id from the dns provider based on ip address
###########################################################################################
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
#######################################################################################
#######################################################################################
#set -x

zoneid="${1}"
websiteurl="${2}"
ip="${3}"
email="${4}"
authkey="${5}"
dns="${6}"

if ( [ "${dns}" = "cloudflare" ] )
then
    /bin/echo "${0} `/bin/date`: Getting record id from for websiteurl : ${websiteurl} and ip: ${ip} from the dns provider" >> ${HOME}/logs/MonitoringLog.log
    /usr/bin/curl -X GET "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records?type=A&name=${websiteurl}&content=${ip}&page=1&per_page=20&order=type&direction=desc&match=all" -H "X-Auth-Email: ${email}" -H "X-Auth-Key: ${authkey}" -H "Content-Type: application/json" | /usr/bin/jq '.result[].id' | /bin/sed 's/"//g'
fi

region="`/bin/ls ${HOME}/.ssh/DNSREGION:* | /usr/bin/awk -F':' '{print $NF}'`"
websiteurl="`/bin/echo ${2} | /usr/bin/cut -d'.' -f2-`"
ip="${3}"
username="${4}"
apikey="${5}"
dns="${6}"

if ( [ "${dns}" = "rackspace" ] )
then
    token="`/usr/bin/curl -s -X POST https://identity.api.rackspacecloud.com/v2.0/tokens -H "Content-Type: application/json" -d '{ "auth": { "RAX-KSKEY:apiKeyCredentials": { "username": "'${username}'", "apiKey": "'${apikey}'" } } }' | /usr/bin/python -m json.tool | /usr/bin/jq ".access.token.id" | /bin/sed 's/"//g'`"
    endpoint="`/usr/bin/curl -s -X POST https://identity.api.rackspacecloud.com/v2.0/tokens -H "Content-Type: application/json" -d '{ "auth": { "RAX-KSKEY:apiKeyCredentials": { "username": "'${username}'", "apiKey": "'${apikey}'" } } }' | /usr/bin/python -m json.tool | /usr/bin/jq ".access.serviceCatalog[].endpoints[].publicURL" | /bin/sed 's/"//g' | /bin/grep ${region} | /bin/grep dns`"
    domainid="`/usr/bin/curl -X GET -H "X-Auth-Token:${token}" -H "Accept:application/json" "${endpoint}/domains" | /usr/bin/python -m json.tool | /usr/bin/jq '.domains[] | select(.name=="'${websiteurl}'") | .id'`"
    id="`/usr/bin/curl -X GET -H "X-Auth-Token: ${token}" -H "Content-Type:application/json" "${endpoint}/domains/${domainid}/records" | /usr/bin/python -m json.tool | /usr/bin/jq '.records[] | select(.data=="'${ip}'") | .id' | /bin/sed 's/"//g'`"
    /bin/echo ${id}
fi

