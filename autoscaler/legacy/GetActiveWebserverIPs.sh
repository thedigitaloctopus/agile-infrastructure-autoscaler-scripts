#!/bin/sh
#################################################################################################################################
# Description: This script generates a list of IP addresses for active and booted webservers
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

#This function makes checks, as best it can, to see if the webserver is up and active. We test serveral times to prevent one
#off errors
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

CLOUDHOST="${2}"
BUILD_IDENTIFIER="`/bin/ls ${HOME}/.ssh/BUILDIDENTIFIER:* | /usr/bin/awk -F':' '{print $NF}'`"
ALGORITHM="`/bin/ls ${HOME}/.ssh | /bin/grep 'ALGORITHM' | /usr/bin/awk -F':' '{print $NF}'`"
SERVER_USER="`/bin/ls ${HOME}/.ssh/SERVERUSER:* | /usr/bin/awk -F':' '{print $NF}'`"
SSH_PORT="`/bin/ls ${HOME}/.ssh/SSH_PORT:* | /usr/bin/awk -F':' '{print $NF}'`"

#This gets us a list of all our webservers, active and online or not.
ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "webserver" ${CLOUDHOST}`"
activeips=""

#This checks that the webserver is up and running on the current machine
for ip in ${ips}
do
    if ( [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=5 -o ConnectionAttempts=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${HOME}/providerscripts/utilities/CheckServerAlive.sh"`" = "ALIVE" ] && [ "`iswebserverup`" = "1" ] && [ -f  ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
    then
        activeips=${activeips}${ip}" "
    fi
done

#Return a list of active webservers that also have a webserver (nginx, apache and so on) as being up and running and receiving requests
/bin/echo "${0} `/bin/date`: The following webservers are currently active: ${activeips}" >> ${HOME}/logs/MonitoringLog.log
/bin/echo ${activeips}
