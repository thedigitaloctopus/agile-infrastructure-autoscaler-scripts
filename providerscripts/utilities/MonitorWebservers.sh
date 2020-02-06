#!/bin/sh
################################################################################################################################
# Description: This script will monitor for an alive and responsive webserver.
# Date: 10-11-2016
# Author: Peter Winter
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
BUILD_IDENTIFIER="`/bin/ls ${HOME}/.ssh/BUILDIDENTIFIER:* | /usr/bin/awk -F':' '{print $NF}'`"
z="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{$1=""}1' | /bin/sed 's/^ //g' | /bin/sed 's/ /./g'`"
ALGORITHM="`/bin/ls ${HOME}/.ssh | /bin/grep 'ALGORITHM' | /usr/bin/awk -F':' '{print $NF}'`"
CLOUDHOST="`${HOME}/providerscripts/cloudhost/GetCloudhost.sh`"
DNS_CHOICE="`/bin/ls ${HOME}/.ssh/DNSCHOICE:* | /usr/bin/awk -F':' '{print $NF}'`"
DNS_SECURITY_KEY="`/bin/ls ${HOME}/.ssh/DNSSECURITYKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
DNS_USERNAME="`/bin/ls ${HOME}/.ssh/DNSUSERNAME:* | /usr/bin/awk -F':' '{print $NF}'`"
SERVER_USER="`/bin/ls ${HOME}/.ssh/SERVERUSER:* | /usr/bin/awk -F':' '{print $NF}'`"
SSH_PORT="`/bin/ls ${HOME}/.ssh/SSH_PORT:* | /usr/bin/awk -F':' '{print $NF}'`"


iswebserverup ()
{
    loop="0"
    while ( [ "${loop}" -lt "5" ] )
    do
        if ( [ "`/usr/bin/curl -I --max-time 240 --insecure https://${ip}:443/index.php | /bin/grep -E 'HTTP/2 200|HTTP/2 301|200 OK|302 Found|301 Moved Permanently'`" = "" ] )
        then
            /bin/sleep 2
            loop="`/usr/bin/expr ${loop} + 1`"
        else
            break
        fi
    done
    if ( [ "${loop}" = "5" ] )
    then
        /bin/echo "0"
    else
        /bin/echo "1"
    fi
}

ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh webserver ${CLOUDHOST}`"

for ip in ${ips}
do
    if ( [ "`/bin/echo ${ip} | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`" = "" ] )
    then
        continue
    fi

    count="0"
    alive=""

    while ( [ "${alive}" != "/home/${SERVER_USER}/runtime/WEBSERVER_READY" ] && [ "${count}" -lt "10" ] )
    do
        count="`/usr/bin/expr ${count} + 1`"
        /bin/sleep 5
        alive="`/usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "DEBIAN_FRONTEND=noninteractive /bin/ls /home/${SERVER_USER}/runtime/WEBSERVER_READY"`"
    done

    if ( [ "${alive}" = "/home/${SERVER_USER}/runtime/WEBSERVER_READY" ] && [ "`iswebserverup`" = "0" ] && [ -f  ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
    then
        justbooted="`/usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "DEBIAN_FRONTEND=noninteractive /bin/ls /home/${SERVER_USER}/runtime/JUST_BOOTED"`"

        if ( [ "${justbooted}" = "/home/${SERVER_USER}/runtime/JUST_BOOTED" ] )
        then
            exit
        fi

        /bin/echo "${0} `/bin/date`: Found that a webserver is unresponsive, removing its IP from the dns provider" >> ${HOME}/logs/MonitoringLog.log
        ${HOME}/autoscaler/RemoveIPFromDNS.sh ${ip}
    fi
done
