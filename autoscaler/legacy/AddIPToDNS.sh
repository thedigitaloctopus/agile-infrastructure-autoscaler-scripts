#!/bin/sh
#################################################################################################################################
# Description: This script will take an ip address as a parameter and using the AddRecord.sh script from the providerscripts
# adds the ip address to the DNS service provider.
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

WEBSITE_URL="`/bin/ls ${HOME}/.ssh/WEBSITEURL:* | /usr/bin/awk -F':' '{print $NF}'`"
DNS_CHOICE="`/bin/ls ${HOME}/.ssh/DNSCHOICE:* | /usr/bin/awk -F':' '{print $NF}'`"
DNS_SECURITY_KEY="`/bin/ls ${HOME}/.ssh/DNSSECURITYKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
DNS_USERNAME="`/bin/ls ${HOME}/.ssh/DNSUSERNAME:* | /usr/bin/awk -F':' '{print $NF}'`"

if ( [ ! -f ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
    exit
fi
#Get the ip address which has been passed as a parameter
ip="${1}"

#Add the ip address to the DNS provider. Once this is done, the webserver should be online then.
/bin/echo "${0} `/bin/date`: Adding IP: ${ip} to Cloudy " >> ${HOME}/logs/MonitoringLog.log
zonename="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{$1=""}1' | /bin/sed 's/^ //g' | /bin/sed 's/ /./g'`"
zoneid="`${HOME}/providerscripts/dns/GetZoneID.sh "${zonename}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${DNS_CHOICE}"`"
${HOME}/providerscripts/dns/AddRecord.sh "${zoneid}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${WEBSITE_URL}" "${ip}" "${DNS_CHOICE}"
/bin/echo "${0} `/bin/date`: Added IP ${ip} to dns" >> ${HOME}/logs/MonitoringLog.log
