#!/bin/sh
#######################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script will delete a DNS record to the dns provider for a server
# based on its ip address
########################################################################################
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
#####################################################################################
#####################################################################################
#set -x

home="`/bin/cat /home/homedir.dat`"
domainurl="`${home}/providerscripts/utilities/ExtractConfigValue.sh 'WEBSITEURL' | /usr/bin/cut -d'.' -f2-`"
recordid="${2}"
dns="${5}"

if ( [ "${dns}" = "digitalocean" ] )
then
    /usr/local/bin/doctl compute domain records list ${domainurl} | /bin/grep ${recordid} | /usr/bin/awk '{print $1}'
    /usr/local/bin/doctl compute domain records delete --force ${domainurl} ${recordid}
fi

zoneid="${1}"
recordid="${2}"
email="${3}"
authkey="${4}"
dns="${5}"

if ( [ "${dns}" = "cloudflare" ] )
then
    /bin/echo "${0} `/bin/date`: Deleting record for recordid ${recordid} from dns" >> ${HOME}/logs/MonitoringLog.log
    /usr/bin/curl -X DELETE "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records/${recordid}" -H "X-Auth-Email: ${email}"  -H "X-Auth-Key: ${authkey}" -H "Content-Type: application/json"
fi

recordid="${2}"
authkey="${4}"
dns="${5}"
domainurl="`${home}/providerscripts/utilities/ExtractConfigValue.sh 'WEBSITEURL' | /usr/bin/cut -d'.' -f2-`"

if ( [ "${dns}" = "exoscale" ] )
then
    /usr/bin/curl  -H "X-DNS-Token: ${authkey}"  -H 'Accept: application/json' -X DELETE  https://api.exoscale.com/dns/v1/domains/${domainurl}/records/${recordid}
fi

