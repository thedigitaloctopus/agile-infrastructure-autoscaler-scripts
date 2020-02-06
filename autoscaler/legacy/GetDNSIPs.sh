#!/bin/sh
##################################################################################################################################
# Description: This script will get a list of ip addresses registered with the DNS provider for the specified domain
# Author: Peter Winter
# Date: 12/01/2017
########################################################################################################################
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
#######################################################################################################
#######################################################################################################
#set -x

#If the toolkit isn't fully installed yet, we don't want to do anything
if ( [ ! -f ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
    exit
fi

WEBSITE_URL="`/bin/ls ${HOME}/.ssh/WEBSITEURL:* | /usr/bin/awk -F':' '{print $NF}'`"
ALGORITHM="`/bin/ls ${HOME}/.ssh | /bin/grep 'ALGORITHM' | /usr/bin/awk -F':' '{print $NF}'`"
CLOUDHOST="`${HOME}/providerscripts/cloudhost/GetCloudhost.sh`"
DNS_CHOICE="`/bin/ls ${HOME}/.ssh/DNSCHOICE:* | /usr/bin/awk -F':' '{print $NF}'`"
DNS_SECURITY_KEY="`/bin/ls ${HOME}/.ssh/DNSSECURITYKEY:* |
/usr/bin/awk -F':' '{print $NF}'`"
DNS_USERNAME="`/bin/ls ${HOME}/.ssh/DNSUSERNAME:* | /usr/bin/awk -F':' '{print $NF}'`"
zonename="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{$1=""}1' | /bin/sed 's/^ //g' | /bin/sed 's/ /./g'`"
zoneid="`${HOME}/providerscripts/dns/GetZoneID.sh "${zonename}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${DNS_CHOICE}"`"

dnsips=""
#Iterate across all the ip addresses registered with the dns provider
for ip in `${HOME}/providerscripts/dns/GetIPAddresses.sh "${zoneid}" "${WEBSITE_URL}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${DNS_CHOICE}"`
do
    dnsips=${dnsips}${ip}" "
done

#Return a list of ip addresses registered with the DNS provider
/bin/echo "${0} `/bin/date`: Currently dns ip addresses are: ${dnsips}" >> ${HOME}/logs/MonitoringLog.log
/bin/echo ${dnsips}
