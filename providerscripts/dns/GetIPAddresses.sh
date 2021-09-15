#!/bin/sh
##########################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script will get all the record ip addresses of the DNS record specified
# on the dns provider
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
##########################################################################################
##########################################################################################
#set -x

websiteurl="${2}"
domainurl="`/bin/echo ${2} | /usr/bin/cut -d'.' -f2-`"
subdomain="`/bin/echo ${2} | /usr/bin/awk -F'.' '{print $1}'`"
dns="${5}"

if ( [ "${dns}" = "digitalocean" ] )
then
    /usr/local/bin/doctl compute domain records list ${domainurl} | /bin/grep ${subdomain} | /usr/bin/awk '{print $4}'
fi


zoneid="${1}"
websiteurl="${2}"
email="${3}"
authkey="${4}"
dns="${5}"

if ( [ "${dns}" = "cloudflare" ] )
then
    /bin/echo "${0} `/bin/date`: Getting ip addresses for ${websiteurl} from dns provider" >> ${HOME}/logs/MonitoringLog.log
    /usr/bin/curl -X GET "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records?type=A&name=${websiteurl}&page=1&per_page=20&order=type&direction=desc&match=all" -H "X-Auth-Email: ${email}" -H "X-Auth-Key: ${authkey}" -H "Content-Type: application/json" | /usr/bin/jq '.result[].content' | /bin/sed 's/"//g'
fi

domainurl="`/bin/echo ${2} | /usr/bin/cut -d'.' -f2-`"
subdomain="`/bin/echo ${2} | /usr/bin/awk -F'.' '{print $1}'`"
authkey="${4}"
dns="${5}"

if ( [ "${dns}" = "exoscale" ] )
then
    /usr/bin/exo -O json dns show ${domainurl} | /usr/bin/jq --arg tmp_subdomain "${subdomain}"  '.[] | select (.name == $tmp_subdomain ) | .content' | /bin/sed 's/"//g'
    
    #Alternative
    #/usr/bin/curl  -H "X-DNS-Token: ${authkey}" -H 'Accept: application/json' https://api.exoscale.com/dns/v1/domains/${domainurl}/records | /usr/bin/jq --arg tmp_subdomain "${subdomain}"  '.[].record | select (.name == $tmp_subdomain ) | .content' | /bin/sed 's/"//g'
fi

