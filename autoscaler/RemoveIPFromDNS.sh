#!/bin/sh
################################################################################
#Description: This script will remove the IP address passed as a parameter from
#the IP addresses registered with the DNS provider
#Author: Peter Winter
#Date: 12/01/2017
#################################################################################
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
###############################################################################
###############################################################################
#set -x

#If the toolkit hasn't fully installed, we don't do anything
if ( [ ! -f ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
    exit
fi

WEBSITE_URL="`/bin/ls ${HOME}/.ssh/WEBSITEURL:* | /usr/bin/awk -F':' '{print $NF}'`"
DNS_CHOICE="`/bin/ls ${HOME}/.ssh/DNSCHOICE:* | /usr/bin/awk -F':' '{print $NF}'`"
DNS_SECURITY_KEY="`/bin/ls ${HOME}/.ssh/DNSSECURITYKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
DNS_USERNAME="`/bin/ls ${HOME}/.ssh/DNSUSERNAME:* | /usr/bin/awk -F':' '{print $NF}'`"
CLOUDHOST="`/bin/ls ${HOME}/.ssh/CLOUDHOST:* | /usr/bin/awk -F':' '{print $NF}'`"

ip="${1}"
private_ip="`${HOME}/providerscripts/server/GetServerPrivateIPAddressByIP.sh ${ip} ${CLOUDHOST}`"

/bin/rm ${HOME}/config/bootedwebserverips/${private_ip}
/bin/touch ${HOME}/config/shuttingdownwebserverips/${private_ip}

#remove the ip address which has been passed as a parameter from the DNS provider
zonename="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{$1=""}1' | /bin/sed 's/^ //g' | /bin/sed 's/ /./g'`"
zoneid="`${HOME}/providerscripts/dns/GetZoneID.sh "${zonename}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${DNS_CHOICE}"`"
recordid="`${HOME}/providerscripts/dns/GetRecordID.sh "${zoneid}" "${WEBSITE_URL}" "${ip}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${DNS_CHOICE}"`"

if ( [ "${recordid}" != "" ] )
then
    /bin/echo "${0} `/bin/date` ###################################################################################" >> ${HOME}/logs/RemovedDNSRecordsLog.log
    /bin/echo "${0} `/bin/date`: Removing record with id ${recordid} and ip ${ip} from the dns and email address ${DNS_USERNAME}" >> ${HOME}/logs/RemovedDNSRecordsLog.log
    ${HOME}/providerscripts/dns/DeleteRecord.sh "${zoneid}" "${recordid}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${DNS_CHOICE}"
fi
