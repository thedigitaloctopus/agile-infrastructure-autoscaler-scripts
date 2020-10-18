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

/usr/bin/find ${HOME}/runtime -name "UNRESPONSIVE:*" -type f -mmin +20 -delete
/usr/bin/find ${HOME}/runtime -name "POTENTIALORPHAN:*" -type f -mmin +20 -delete

#This function makes checks, as best it can, to see if the webserver is up and active. We test serveral times to prevent one
#off errors
iswebserverup ()
{
    loop="0"
    while ( [ "${loop}" -lt "5" ] )
    do
        if ( [ -f ${HOME}/.ssh/APPLICATIONLANGUAGE:PHP ] )
        then
            file="index.php"
        else
            file=""
        fi
	
        test1="`/usr/bin/wget --timeout=10 --tries=3 --spider --no-check-certificate https://${ip}/${file}`" 
	   
       #cludge because of wordpress problem with particular app
        if ( [ -f ${HOME}/.ssh/APPLICATION:wordpress ] )
        then
	        test2="`/usr/bin/wget --timeout=10 --tries=3 --spider --no-check-certificate https://${ip}/wp-login.php`"
        fi
	    status1="0"
	    status2="0"

	    exec $test1
	    if ( [ "$?" = "0" ] )
	    then
            status1="1"
        fi

	   exec $test2
	   if ( [ "$?" = "0" ] )
	    then
            status2="1"
        fi

	    if ( [ "${status1}" ] || [ "${status2}" ] )
        then
            break
        else
            /bin/sleep 2
            loop="`/usr/bin/expr ${loop} + 1`"
        fi

    done

    if ( [ "${loop}" = "5" ] )
    then
        if ( [ ! -f ${HOME}/runtime/UNRESPONSIVE:${ip}:1 ] )
        then
            /bin/touch ${HOME}/runtime/UNRESPONSIVE:${ip}:1
    elif ( [ ! -f ${HOME}/runtime/UNRESPONSIVE:${ip}:2 ] )
        then
            /bin/touch ${HOME}/runtime/UNRESPONSIVE:${ip}:2
    elif ( [ ! -f ${HOME}/runtime/UNRESPONSIVE:${ip}:3 ] )
        then
            /bin/touch ${HOME}/runtime/UNRESPONSIVE:${ip}:3
        fi
        /bin/echo "0"
    else
        /bin/echo "1"
    fi
}

if ( [ ! -f ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
    exit
fi

#get a list of all ip addresses which we consider should be active
allliveips="`${HOME}/autoscaler/GetDNSIPs.sh`"

CLOUDHOST="`/bin/ls ${HOME}/.ssh/CLOUDHOST:* | /usr/bin/awk -F':' '{print $NF}'`"
BUILD_IDENTIFIER="`/bin/ls ${HOME}/.ssh/BUILDIDENTIFIER:* | /usr/bin/awk -F':' '{print $NF}'`"
ALGORITHM="`/bin/ls ${HOME}/.ssh/ALGORITHM:* | /usr/bin/awk -F':' '{print $NF}'`"
SERVER_USER="`/bin/ls ${HOME}/.ssh/SERVERUSER:* | /usr/bin/awk -F':' '{print $NF}'`"
SERVER_USER_PASSWORD="`/bin/ls ${HOME}/.ssh/SERVERUSERPASSWORD:* | /usr/bin/awk -F':' '{print $NF}'`"
SSH_PORT="`/bin/ls ${HOME}/.ssh/SSH_PORT:* | /usr/bin/awk -F':' '{print $NF}'`"
SUDO=" DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "

for ip in ${allliveips}
do
    if ( [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/ls ${HOME}/runtime/WEBSERVER_READY"`" = "" ] ||  [ "`iswebserverup`" -eq "0" ] )
    then
        if ( [ ! -f ${HOME}/runtime/UNRESPONSIVE:${ip}:3 ] )
        then
            continue
        else
            /bin/rm ${HOME}/runtime/UNRESPONSIVE:${ip}:*
        fi
        /bin/echo "${0} `/bin/date`: ################################################################" >> ${HOME}/logs/UnresponsiveWebservers.log
        /bin/echo "${0} `/bin/date`: Webserver with ip address: ${ip} is being marked as unresponsive" >> ${HOME}/logs/UnresponsiveWebservers.log
        ${HOME}/providerscripts/email/SendEmail.sh "UNRESPONSIVE WEBSERVER" "One of your deployed webservers with IP address: ${ip} has been marked as unresponsive.  It's IP address has been removed from the DNS provider but the machine itself has been shutdown and destroyed. Depending on your scaling configuration another machine will be provisioned to take  the place of the machine that has been terminated."
        /bin/echo "${0} `/bin/date`: Webserver with ip address: ${ip} is having it's ip address removed from the DNS system" >> ${HOME}/logs/UnresponsiveWebservers.log
        ${HOME}/autoscaler/RemoveIPFromDNS.sh ${ip}

        /bin/touch ${HOME}/runtime/IPREMOVED:${ip}
        #I found that for (probably the TTL) of the DNS system after the record is removed, the DNS system still tries to route
        #requests to the server even though the record has been deleted. After the TTL has expired things are OK, however,
        #If the TTL is 2 minutes and we shutdown the appropriate server 20 seconds after the record is removed, then we may
        #get errors because the server isn't up to service the still routed requests as we have shut it down. So, it's dirty, but, assuming a TTL
        #of 2 minutes, if we sleep for a while before we destroy anything, then, we can be sure that no requests will be routed to our
        #terminated machine. Clear? If there is a longer TTL on the record, this could be a problem and the sleep here would have
        #to be increased here to prevent errors on scaledown

        /bin/sleep 300

        /bin/echo "${0} `/bin/date`: Webserver with ip address: ${ip} is being shutdown" >> ${HOME}/logs/UnresponsiveWebservers.log
        /usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${SUDO} ${HOME}/providerscripts/utilities/ShutdownThisWebserver.sh"
        /bin/echo "${0} `/bin/date`: Webserver with ip address: ${ip} is being destroyed" >> ${HOME}/logs/UnresponsiveWebservers.log
        /bin/echo "${0} `/bin/date` : ${ip} is being destroyed because it was unresponsive" >> ${HOME}/logs/MonitoringLog.log
        ${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
        
        DBaaS_DBSECURITYGROUP="`/bin/ls ${HOME}/.ssh/DBaaSDBSECURITYGROUP:* | /usr/bin/awk -F':' '{print $NF}'`"
        if ( [ "${DBaaS_DBSECURITYGROUP}" != "" ] )
        then
            IP_TO_DENY="${ip}"
            . ${HOME}/providerscripts/server/DenyDBAccess.sh
        fi
        
        INMEMORYCACHING_SECURITY_GROUP="`/bin/ls ${HOME}/.ssh/INMEMORYCACHINGSECURITYGROUP:* | /usr/bin/awk -F':' '{print $NF}'`"
        INMEMORYCACHING_PORT="`/bin/ls ${HOME}/.ssh/INMEMORYCACHINGPORT:* | /usr/bin/awk -F':' '{print $NF}'`"

        if ( [ "${INMEMORYCACHING_SECURITY_GROUP}" != "" ] )
        then
            IP_TO_DENY="${ip}"
            . ${HOME}/providerscripts/server/DenyCachingAccess.sh
        fi
        
        /bin/rm ${HOME}/runtime/IPREMOVED:${ip}
        /bin/rm ${HOME}/config/beingbuiltips/`${HOME}/providerscripts/server/GetServerPrivateIPAddressByIP.sh ${ip}`
    fi
done

allips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "webserver" ${CLOUDHOST}`"

for ip in ${allips}
do
    /bin/echo "Adding ${ip}"
    if ( [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/ls ${HOME}/runtime/WEBSERVER_READY"`" != "" ] && [ "`iswebserverup`" -eq "1" ] && [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=15 -o ConnectionAttempts=15 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${SUDO} ${HOME}/providerscripts/utilities/AreAssetsMounted.sh"`" = "MOUNTED" ] )
    then
        ${HOME}/autoscaler/AddIPToDNS.sh ${ip}
    fi
done

potentialorphans=""

for ip in ${allips}
do
    if ( [ "`/bin/echo ${allliveips} | /bin/grep ${ip}`" = "" ] )
    then
        potentialorphans="${potentialorphans} ${ip}"
    fi
done

orphans=""

beingbuilt="`/bin/ls ${HOME}/config/beingbuiltips/`"

for ip in ${potentialorphans}
do
    if ( [ "`/bin/echo ${beingbuilt} | /bin/grep ${ip}`" = "" ] )
    then
        orphans="${orphans} ${ip}"
    fi
done

if ( [ "${orphans}" != "" ] )
then
    for ip in ${orphans}
    do
        if ( [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/ls ${HOME}/runtime/WEBSERVER_READY"`" = "" ] ||  [ "`iswebserverup`" -eq "0" ] )
        then
            if ( [ ! -f ${HOME}/runtime/POTENTIALORPHAN:${ip}:1 ] )
            then
                /bin/touch ${HOME}/runtime/POTENTIALORPHAN:${ip}:1
        elif ( [ ! -f ${HOME}/runtime/POTENTIALORPHAN:${ip}:2 ] )
            then
                /bin/touch ${HOME}/runtime/POTENTIALORPHAN:${ip}:2
        elif ( [ ! -f ${HOME}/runtime/POTENTIALORPHAN:${ip}:3 ] )
            then
                /bin/touch ${HOME}/runtime/POTENTIALORPHAN:${ip}:3
            fi

            if ( [ ! -f ${HOME}/runtime/POTENTIALORPHAN:${ip}:3 ] )
            then
                continue
            else
                /bin/rm ${HOME}/runtime/POTENTIALORPHAN:${ip}:*
            fi
            
            /bin/echo "${0} `/bin/date`: Orphaned webserver with ip address: ${ip} is being destroyed" >> ${HOME}/logs/UnresponsiveWebservers.log
            /bin/echo "${0} `/bin/date` : ${ip} is being destroyed because it was considered orphaned from the DNS system" >> ${HOME}/logs/MonitoringLog.log

            ${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
            DBaaS_DBSECURITYGROUP="`/bin/ls ${HOME}/.ssh/DBaaSDBSECURITYGROUP:* | /usr/bin/awk -F':' '{print $NF}'`"
            if ( [ "${DBaaS_DBSECURITYGROUP}" != "" ] ) 
            then
                IP_TO_DENY="${ip}"
                . ${HOME}/providerscripts/server/DenyDBAccess.sh
            fi
            
            INMEMORYCACHING_SECURITY_GROUP="`/bin/ls ${HOME}/.ssh/INMEMORYCACHINGSECURITYGROUP:* | /usr/bin/awk -F':' '{print $NF}'`"
            INMEMORYCACHING_PORT="`/bin/ls ${HOME}/.ssh/INMEMORYCACHINGPORT:* | /usr/bin/awk -F':' '{print $NF}'`"

            if ( [ "${INMEMORYCACHING_SECURITY_GROUP}" != "" ] )
            then
                IP_TO_DENY="${ip}"
                . ${HOME}/providerscripts/server/DenyCachingAccess.sh 
            fi
        fi
    done
fi

