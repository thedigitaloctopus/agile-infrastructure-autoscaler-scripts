#!/bin/sh
#############################################################################
# Description: This script makes sure that a DNS zone exists for our domain.
# Author: Peter Winter
# Date: 12/01/2017
#############################################################################
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
##############################################################################
##############################################################################
#set -x

if ( [ "${dns}" = "cloudflare" ] )
then
    :
fi

region="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DNSREGION'`"
username="${1}"
apikey="${2}"
websiteurl="`/bin/echo ${3} | /usr/bin/cut -d'.' -f2-`"
dns="${4}"

if ( [ "${dns}" = "rackspace" ] )
then
    token="`/usr/bin/curl -s -X POST https://identity.api.rackspacecloud.com/v2.0/tokens -H "Content-Type: application/json" -d '{ "auth": { "RAX-KSKEY:apiKeyCredentials": { "username": "'${username}'", "apiKey": "'${apikey}'" } } }' | /usr/bin/python -m json.tool | /usr/bin/jq ".access.token.id" | /bin/sed 's/"//g'`"
    endpoint="`/usr/bin/curl -s -X POST https://identity.api.rackspacecloud.com/v2.0/tokens -H "Content-Type: application/json" -d '{ "auth": { "RAX-KSKEY:apiKeyCredentials": { "username": "'${username}'", "apiKey": "'${apikey}'" } } }' | /usr/bin/python -m json.tool | /usr/bin/jq ".access.serviceCatalog[].endpoints[].publicURL" | /bin/sed 's/"//g' | /bin/grep ${region} | /bin/grep dns`"
    /usr/bin/curl -X POST ${endpoint}/domains -H "X-Auth-Token: ${token}" -H "Content-Type: application/json" -d '{ "domains" : [ { "name" : "'${websiteurl}'", "comment" : "Root level for '${websiteurl}'", "subdomains" : { "domains" : [] }, "ttl" : 300 , "emailAddress" : "webmaster@'${websiteurl}'" } ] }' | python -m json.tool
fi
~
~
