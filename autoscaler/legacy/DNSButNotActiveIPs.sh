#!/bin/sh
##################################################################################################################################
# Description: This script will list the DNS A records which are set for the specified domain but there is no active webserver
# for that ip address. It simply returns a list of IP addresses which are registered with the DNS service provider but do not
# correspond to an active and booted webserver. That's all it does, it is up to other scripts to work out what to do with the list
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

#If the toolkit hasn't been fully installed, we don't want to do anything
if ( [ ! -f ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
    exit
fi

CLOUDHOST="`/bin/ls ${HOME}/.ssh/CLOUDHOST:* | /usr/bin/awk -F':' '{print $NF}'`"
ALGORITHM="`/bin/ls ${HOME}/.ssh/ALGORITHM:* | /usr/bin/awk -F':' '{print $NF}'`"
BUILD_IDENTIFIER="`/bin/ls ${HOME}/.ssh/BUILDIDENTIFIER:* | /usr/bin/awk -F':' '{print $NF}'`"
SERVER_USER="`/bin/ls ${HOME}/.ssh/SERVERUSER:* | /usr/bin/awk -F':' '{print $NF}'`"
SSH_PORT="`/bin/ls ${HOME}/.ssh/SSH_PORT:* | /usr/bin/awk -F':' '{print $NF}'`"

#Get a list of ip addresses for active webservers
activeips="`${HOME}/autoscaler/GetActiveWebserverIPs.sh`"
#Get a list of ip addresses that are on the DNS provider
dnsips="`${HOME}/autoscaler/GetDNSIPs.sh`"
notonlineips=""

#Get a list of ip addresses which are listed in the DNS but are not active webservers
for publicip in ${dnsips}
do
    ip="`${HOME}/providerscripts/server/GetServerPrivateIPAddressesByIP.sh ${publicip} ${CLOUDHOST}`"
    if ( [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=5 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "DEBIAN_FRONTEND=noninteractive /bin/ls /home/${SERVER_USER}/runtime/JUST_BOOTED"`" != "/home/${SERVER_USER}/runtime/JUST_BOOTED" ] )
    then
        if ( [ "`/bin/echo ${activeips} | /bin/grep ${ip}`" = "" ] )
        then
            notonlineips=${notonlineips}${publicip}" "
        fi
    fi
done

#Return the list of ip addresses in the DNS provider that do not have an active webserver to route requests to. This might happen
#if somehow a machine is hard reset or something. We would have an ip address with nothing to route to if this were the case
/bin/echo "${0} `/bin/date`: The following servers have dns records but are not online: ${notonlineips}" >> ${HOME}/logs/MonitoringLog.log
/bin/echo ${notonlineips}



