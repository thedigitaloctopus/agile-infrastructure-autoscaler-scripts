#!/bin/sh
#################################################################################################################################
# Description: If autoscaling finds that a webserver needs to be shutdown, then this script is called to action the process.
# It should be noted that when scaling down, a webserver is chosen at random from the set of webservers and it is then shutdown.
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
BUILD_IDENTIFIER="`/bin/ls ${HOME}/.ssh/BUILDIDENTIFIER:* | /usr/bin/awk -F':' '{print $NF}'`"
ALGORITHM="`/bin/ls ${HOME}/.ssh/ALGORITHM:* | /usr/bin/awk -F':' '{print $NF}'`"
SERVER_USER="`/bin/ls ${HOME}/.ssh/SERVERUSER:* | /usr/bin/awk -F':' '{print $NF}'`"
ips="`${HOME}/autoscaler/GetActiveWebserverIPs.sh`"
SSH_PORT="`/bin/ls ${HOME}/.ssh/SSH_PORT:* | /usr/bin/awk -F':' '{print $NF}'`"


if ( [ "${ips}" != "" ] )
then
    ip="`/bin/echo ${ips} | /usr/bin/awk -F' ' '{print $1}'`"
    publicip="`${HOME}/providerscripts/server/GetServerIPAddressesByPrivateIP.sh ${ip} ${CLOUDHOST}`"
    /bin/touch ${HOME}/config/shuttingdownwebserverips/${publicip}

    if ( [ "`${HOME}/providerscripts/server/GetServerName.sh ${ip} ${CLOUDHOST} | grep webserver`" != "" ] )
    then
        ${HOME}/autoscaler/RemoveIPFromDNS.sh ${publicip}
        /bin/echo "${0} `/bin/date`: IP address ${publicip} is being removed from the dns provider" >> ${HOME}/logs/MonitoringLog.log
        /bin/sleep 1200
        /usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${HOME}/providerscripts/utilities/ShutdownThisWebserver.sh"
        /bin/echo "${0} `/bin/date`: Webserver with ip address: ${ip} is being destroyed" >> ${HOME}/logs/MonitoringLog.log
        ${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
    fi
    /bin/rm  ${HOME}/config/shuttingdownwebserverips/${publicip}
fi

