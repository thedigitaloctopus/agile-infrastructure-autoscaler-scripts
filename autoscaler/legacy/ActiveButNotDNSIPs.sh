#!/bin/sh
##################################################################################################################################
# Description: This script will list the ip addresses of webservers that are active and booted, but that do not have their IP
# addresses registered with the DNS provider. That is all it does. It is up to other scripts to use the IP addresses it generates.
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

if ( [ ! -f ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
    exit
fi

CLOUDHOST="`/bin/ls ${HOME}/.ssh/CLOUDHOST:* | /usr/bin/awk -F':' '{print $NF}'`"
#Get a list of the ip addresses of active webservers
activeips="`${HOME}/autoscaler/GetActiveWebserverIPs.sh`"

#Get a list of ip addresses that have been added to the DNS provider
dnsips="`${HOME}/autoscaler/GetDNSIPs.sh`"
activebutnotdnsips=""

#Find any ips which are active but are not yet added to the DNS provider
for ip in ${activeips}
do
    publicip="`${HOME}/providerscripts/server/GetServerIPAddressesByPrivateIP.sh ${ip} ${CLOUDHOST}`"
    if ( [ "`/bin/echo ${dnsips} | /bin/grep ${publicip}`" = "" ] || [ "${dnsips}" = "" ] )
    then
        if ( [ ! -f ${HOME}/config/shuttingdownwebserverips/${publicip} ] )
        then
            activebutnotdnsips=${activebutnotdnsips}${publicip}" "
        fi
    fi
done

#Return a list of active but not on the DNS system IP addresses
/bin/echo "${0} `/bin/date`: The following servers are online but are not being accelerated: ${activebutnotdnsips}" >> ${HOME}/logs/MonitoringLog.log
/bin/echo ${activebutnotdnsips}

