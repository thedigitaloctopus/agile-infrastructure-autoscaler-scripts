#!/bin/sh
###################################################################################################################################
# Description: This script will return how many webservers are running and actively receiving connections
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

#If the toolkit isn't fully installed, we don't want to do anything
if ( [ ! -f ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
    exit
fi

#This function checks not only if a machine is booted, but also whether it's webserver is online and receiving requests
iswebserverup ()
{
    loop="0"
    while ( [ "${loop}" -lt "3" ] )
    do
        if ( [ "`/usr/bin/curl -I --max-time 5 --insecure https://${ip}:443/index.php | /bin/grep -E 'HTTP/2 200|200 OK|302 Found|301 Moved Permanently'`" = "" ] )
        then
            /bin/sleep 2
            loop="`/usr/bin/expr ${loop} + 1`"
        else
            break
        fi
    done

    if ( [ "${loop}" = "3" ] )
    then
        /bin/echo "0"
    else
        /bin/echo "1"
    fi
}

CLOUDHOST="${1}"
BUILD_IDENTIFIER="`/bin/ls ${HOME}/.ssh/BUILDIDENTIFIER:* | /usr/bin/awk -F':' '{print $NF}'`"
ALGORITHM="`/bin/ls ${HOME}/.ssh | /bin/grep 'ALGORITHM' | /usr/bin/awk -F':' '{print $NF}'`"
SERVER_USER="`/bin/ls ${HOME}/.ssh/SERVERUSER:* | /usr/bin/awk -F':' '{print $NF}'`"
SSH_PORT="`/bin/ls ${HOME}/.ssh/SSH_PORT:* | /usr/bin/awk -F':' '{print $NF}'`"

#This lists all the ip addresses of webservers on our current cloudhost, built or not
ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "webserver" ${CLOUDHOST}`"
noactiveips="0"

#Find out the number of webservers that are active and also online
for ip in ${ips}
do
    if ( [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=5 -o ConnectionAttempts=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${HOME}/providerscripts/utilities/CheckServerAlive.sh"`" = "ALIVE" ] && [ "`iswebserverup`" = "1" ] && [ -f  ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
    then
        noactiveips="`/usr/bin/expr ${noactiveips} + 1`"
        #We have found it too be active, so, we don't want it listed as inactive anymore, it it was, that is
        /bin/rm ${HOME}/config/bootedwebserverips/NOTACTIVE:${ip}
        #Check for webservers which have been inactive for more than 30 minutes, they must be, somehow, dead so this will destroy
        ${HOME}/autoscaler/MonitorForDeadWebservers.sh
    else
        if ( [ ! -f ${HOME}/config/bootedwebserverips/NOTACTIVE:${ip} ] )
        then
            #So, our machine isn't active, so mark it as not active, but only if it didn't exist already in our inactive list
            #because we don't want the timestamp on the file updated
            /bin/touch ${HOME}/config/bootedwebserverips/NOTACTIVE:${ip}
        fi
    fi
done
#Return the number of active webservers
/bin/echo ${noactiveips}
