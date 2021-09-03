#!/bin/sh
#########################################################################################################
# Description:  This script will moitor for and shutdown webservers that have become unresponsive
# It also persistently adds the ip addresses of machines that it considers to be online to the dns
# service provider. You might think, why add an ip address when it is already added which is mostly what
# this does, but, on occassion, I have seen correct code fail to add an ip address to a DNS provider for
# some reason unknown, so, if we keep adding it we know that whenever there is a machine avaiable and online
# we will do our utmost as soon as we can to have its ip active on the DNS service provider.
# Hence, the name of the script. If an ip addresses is found to be dead and unresposive, for some reason,
# it is removed from th DNS service provider. If it is found to be alive and well, it is added to the dns
# service provider.
# Author: Peter Winter
# Date: 12/01/2017
##########################################################################################################
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

#Don't start killing stuff until we have settled down post build (relevant when bulding from snapshots in particular)
if ( [ "`/bin/cat /proc/uptime | /usr/bin/awk '{print $1}' | /bin/sed 's/\..*//g'`" -lt "1500" ] )
then
    exit
fi

status="down"

iswebserverup ()
{
    count="0"

    if ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh APPLICATIONLANGUAGE:PHP`" = "1" ] )
    then
        file="index.php"
    elif ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh APPLICATION:wordpress`" = "1" ] )
    then
        file="wp-login.php"
    else
        file=""
    fi

    while ( [ "${count}" != "6" ] && [ "${status}" = "down" ] )
    do
        if ( [ "`/usr/bin/curl --insecure -I "https://${1}:443/${file}" 2>&1 | /bin/grep \"HTTP\" | /bin/grep -w \"200\|301\"`" ] ) 
        then
            status="up"
        else
            count="`/usr/bin/expr ${count} + 1`"
            /bin/sleep 5
        fi
   done

    if ( [ "${status}" = "up" ] )
    then
       echo "up"
    else
       echo "down"
    fi
}

if ( [ ! -f ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
    exit
fi

CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
ALGORITHM="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ALGORITHM'`"
SERVER_USER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERUSER'`"
SERVER_USER_PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERUSERPASSWORD'`"
SSH_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SSHPORT'`"
SUDO=" DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "

no_attempts="4"

allliveips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh webserver ${CLOUDHOST}`"

for ip in ${allliveips}
do
    if ( [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/ls ${HOME}/runtime/WEBSERVER_READY"`" != "" ] &&  [ "`iswebserverup ${ip}`" = "up" ] )
    then
        ${HOME}/autoscaler/AddIPToDNS.sh ${ip}
        /bin/sed -i "/${ip}/d" ${HOME}/runtime/POTENTIALLY_DOWN.log
    else
        if ( [ "${status}" = "down" ] )
        then
            /bin/echo "POTENTIALLY DOWN ${ip}" >> ${HOME}/runtime/POTENTIALLY_DOWN.log
        else
                :
                #MOST LIKELY STILL BOOTING
        fi
    fi

    downip=""
    if ( [ -f ${HOME}/runtime/POTENTIALLY_DOWN.log ] && [ "`/bin/grep ${ip} ${HOME}/runtime/POTENTIALLY_DOWN.log | /usr/bin/wc -l`" -gt "${no_attempts}" ] )
    then
        downip="${ip}"
    fi

    if ( [ "${downip}" != "" ] )
    then
        /bin/echo "IP ADDRESS ${downip} is DOWN"
        /bin/sed -i "/${downip}/d" ${HOME}/runtime/POTENTIALLY_DOWN.log

        /bin/echo "${0} `/bin/date`: ################################################################" >> ${HOME}/logs/UnresponsiveWebservers.log
        /bin/echo "${0} `/bin/date`: Webserver with ip address: ${downip} is being marked as unresponsive" >> ${HOME}/logs/UnresponsiveWebservers.log
        ${HOME}/providerscripts/email/SendEmail.sh "UNRESPONSIVE WEBSERVER" "One of your deployed webservers with IP address: ${downip} has been marked as unresponsive.  It's IP address has been removed from the DNS provider but the machine itself has been shutdown and destroyed. Depending on your scaling configuration another machine will be provisioned to take  the place of the machine that has been terminated."
        /bin/echo "${0} `/bin/date`: Webserver with ip address: ${downip} is having it's ip address removed from the DNS system" >> ${HOME}/logs/UnresponsiveWebservers.log
        ${HOME}/autoscaler/RemoveIPFromDNS.sh ${downip}

        /bin/sleep 300

        /bin/echo "${0} `/bin/date`: Webserver with ip address: ${downip} is being shutdown" >> ${HOME}/logs/UnresponsiveWebservers.log
        /usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${downip} "${SUDO} ${HOME}/providerscripts/utilities/ShutdownThisWebserver.sh"
        /bin/echo "${0} `/bin/date`: Webserver with ip address: ${downip} is being destroyed" >> ${HOME}/logs/UnresponsiveWebservers.log
        /bin/echo "${0} `/bin/date` : ${downip} is being destroyed because it was unresponsive" >> ${HOME}/logs/MonitoringLog.log
        ${HOME}/providerscripts/server/DestroyServer.sh ${downip} ${CLOUDHOST}
        
        DBaaS_DBSECURITYGROUP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DBaaSDBSECURITYGROUP'`"

        if ( [ "${DBaaS_DBSECURITYGROUP}" != "" ] )
        then
            IP_TO_DENY="${downip}"
            . ${HOME}/providerscripts/server/DenyDBAccess.sh
        fi
        
        INMEMORYCACHING_SECURITY_GROUP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INMEMORYCACHINGSECURITYGROUP'`"
        INMEMORYCACHING_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INMEMORYCACHINGPORT'`"

        if ( [ "${INMEMORYCACHING_SECURITY_GROUP}" != "" ] )
        then
            IP_TO_DENY="${downip}"
            . ${HOME}/providerscripts/server/DenyCachingAccess.sh
        fi
        
        /bin/rm ${HOME}/config/beingbuiltips/`${HOME}/providerscripts/server/GetServerPrivateIPAddressByIP.sh ${downip}`
    fi
done
