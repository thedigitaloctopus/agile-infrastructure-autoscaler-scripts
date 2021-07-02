#!/bin/sh
############################################################################################
# Description:  This script will 1) Create Webservers up to the defined number of webservers
#                                   required when there's not enough
#                                2) It will shutdown webservers to the defined number of
#                                   webservers when there's too many
# Author: Peter Winter
# Date: 12/01/2017
###########################################################################################
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

if ( [ -f ${HOME}/config/webrootsynctunnel/sync*purge ] || [ -f ${HOME}/config/webrootsynctunnel/switchoff* ] )
then
    exit
fi

#If there's an build processes hanging around from previous attempts, purge them so we are nice and clean
for pid in "`/bin/pgrep BuildWebserver`"
do
    /bin/kill ${pid}
done

#################################################ESSENTIAL#########################################################
#To configure how many websevers are deployed, you can edit the file at:  ${HOME}/config/scalingprofile/profile.cnf 
#################################################ESSENTIAL#########################################################

SCALING_MODE="static"

NO_WEBSERVERS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'NUMBERWS'`"

if ( [ ! -f ${HOME}/config/scalingprofile/profile.cnf ] )
then
    /bin/mkdir -p ${HOME}/config/scalingprofile
    /bin/touch ${HOME}/config/scalingprofile/profile.cnf
fi

if ( [ "`/bin/cat ${HOME}/config/scalingprofile/profile.cnf | /bin/grep "NO_WEBSERVERS"`" = "" ] || [ "`/bin/cat ${HOME}/config/scalingprofile/profile.cnf | /bin/grep "SCALING_MODE"`" = "" ] )
then
    /bin/echo  "SCALING_MODE=${SCALING_MODE}" > ${HOME}/config/scalingprofile/profile.cnf
    /bin/echo  "NO_WEBSERVERS=${NO_WEBSERVERS}" >> ${HOME}/config/scalingprofile/profile.cnf
fi

SCALING_MODE="`/bin/cat ${HOME}/config/scalingprofile/profile.cnf | /bin/grep "SCALING_MODE" | /usr/bin/awk -F'=' '{print $NF}'`"
NO_WEBSERVERS="`/bin/cat ${HOME}/config/scalingprofile/profile.cnf | /bin/grep "NO_WEBSERVERS" | /usr/bin/awk -F'=' '{print $NF}'`"

if ( [ "${SCALING_MODE}" != "static" ] )
then
    exit
fi

if ( [ ! -f ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
    exit
fi

CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
ALGORITHM="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ALGORITHM'`"
SSH_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SSH_PORT'`"
SERVER_USER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERUSER'`"
SERVER_USER_PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERUSERPASSWORD'`"

SUDO=" DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "

/bin/echo "${0} `/bin/date`: ##########################################################################" >> ${HOME}/logs/ScalingEventsLog.log

# Sometimes we get back a zero when it shouldn't be possibly because of a network glitch, so we try a few times to give us a good chance
# of getting it right
provisionedwebservers="`${HOME}/autoscaler/GetDNSIPs.sh | /usr/bin/wc -w`"
provisionedwebservers1="`${HOME}/autoscaler/GetDNSIPs.sh | /usr/bin/wc -w`"
provisionedwebservers2="`${HOME}/autoscaler/GetDNSIPs.sh | /usr/bin/wc -w`"
provisionedwebservers3="`${HOME}/autoscaler/GetDNSIPs.sh | /usr/bin/wc -w`"
provisionedwebservers4="`${HOME}/autoscaler/GetDNSIPs.sh | /usr/bin/wc -w`"

if (
    ( [ "${provisionedwebservers}" != "${provisionedwebservers1}" ] || [ "${provisionedwebservers}" != "${provisionedwebservers2}" ] || [ "${provisionedwebservers}" != "${provisionedwebservers3}" ] || [ "${provisionedwebservers}" != "${provisionedwebservers4}" ] ) ||
    ( [ "${provisionedwebservers1}" != "${provisionedwebservers}" ] || [ "${provisionedwebservers1}" != "${provisionedwebservers2}" ] || [ "${provisionedwebservers1}" != "${provisionedwebservers3}" ] || [ "${provisionedwebservers1}" != "${provisionedwebservers4}" ] ) ||
    ( [ "${provisionedwebservers2}" != "${provisionedwebservers}" ] || [ "${provisionedwebservers2}" != "${provisionedwebservers1}" ] || [ "${provisionedwebservers2}" != "${provisionedwebservers3}" ] || [ "${provisionedwebservers2}" != "${provisionedwebservers4}" ] ) ||
    ( [ "${provisionedwebservers3}" != "${provisionedwebservers}" ] || [ "${provisionedwebservers3}" != "${provisionedwebservers1}" ] || [ "${provisionedwebservers3}" != "${provisionedwebservers2}" ] || [ "${provisionedwebservers3}" != "${provisionedwebservers4}" ] ) ||
    ( [ "${provisionedwebservers4}" != "${provisionedwebservers}" ] || [ "${provisionedwebservers4}" != "${provisionedwebservers1}" ] || [ "${provisionedwebservers4}" != "${provisionedwebservers2}" ] || [ "${provisionedwebservers4}" != "${provisionedwebservers3}" ] ) ||
    ( [ "${provisionedwebservers}" = "" ] || [ "${provisionedwebservers1}" = "" ]  || [ "${provisionedwebservers2}" = "" ]  || [ "${provisionedwebservers3}" = "" ] || [ "${provisionedwebservers4}" = "" ] )
)
then
    exit
fi

#count="0"
#while ( [ "${provisionedwebservers}" = "0" ] && [ "${count}" -lt "5" ] )
#do
#    /bin/sleep 5
#    provisionedwebservers="`${HOME}/autoscaler/GetDNSIPs.sh | /usr/bin/wc -w`"
#    count="`/usr/bin/expr ${count} + 1`"
#done

/bin/echo "${0} `/bin/date`: ${provisionedwebservers} webservers are currently provisioned." >> ${HOME}/logs/ScalingEventsLog.log

#If we have fewer webservers than we require, build one
if (  [ "${provisionedwebservers}" != "" ] && [ "${provisionedwebservers}" -lt "${NO_WEBSERVERS}" ] )
then
    #It is possible that machine builds failed in which case we may have more servers running than are added to the DNS system
    #In this case, we don't want to keep building machines, so, check for it and exit
    #Any additional or unneccesary machines will be checked for and terminated by other scripts

    noallips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "webserver" ${CLOUDHOST} | /usr/bin/wc -l`"

    if ( [ "${noallips}" -lt "${NO_WEBSERVERS}" ] )
    then
        if ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh SNAPAUTOSCALE:1`" = "1" ] )
        then
            /bin/echo "${0} `/bin/date`: A new webserver is being provisioned (spun up) from a snapshot" >> ${HOME}/logs/ScalingEventsLog.log
            ${HOME}/autoscaler/BuildWebserver.sh
        else
            /bin/echo "${0} `/bin/date`: A new webserver is being provisioned as a regular build" >> ${HOME}/logs/ScalingEventsLog.log
            newip="`${HOME}/autoscaler/BuildWebserver.sh`"
            if ( [ "${newip}" != "" ] )
            then
                /bin/echo "${0} `/bin/date`:  Added the new IP ( ${newip} ) to the DNS system" >> ${HOME}/logs/ScalingEventsLog.log
                ${HOME}/providerscripts/email/SendEmail.sh "A WEBSERVER HAS BEEN DEPLOYED" "Webserver ( ${ip} ) has just been deployed and activated"
            fi
        fi
    fi
fi

#If we have more webservers than we need, probably due to a configuration seeing (NO_WEBSERVERS) being changed, then, shutdown
#the excess servers. Issue command repeatedly in case of network glitches, repeated attempts give us a good chance of getting it right
nowebservers="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "webserver" ${CLOUDHOST} | /usr/bin/wc -w`"
nowebservers1="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "webserver" ${CLOUDHOST} | /usr/bin/wc -w`"
nowebservers2="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "webserver" ${CLOUDHOST} | /usr/bin/wc -w`"
nowebservers3="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "webserver" ${CLOUDHOST} | /usr/bin/wc -w`"
nowebservers4="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "webserver" ${CLOUDHOST} | /usr/bin/wc -w`"

if (
    ( [ "${nowebservers}" != "${nowebservers1}" ] || [ "${nowebservers}" != "${nowebservers2}" ] || [ "${nowebservers}" != "${nowebservers3}" ] || [ "${nowebservers}" != "${nowebservers4}" ] ) ||
    ( [ "${nowebservers1}" != "${nowebservers}" ] || [ "${nowebservers1}" != "${nowebservers2}" ] || [ "${nowebservers1}" != "${nowebservers3}" ] || [ "${nowebservers1}" != "${nowebservers4}" ] ) ||
    ( [ "${nowebservers2}" != "${nowebservers}" ] || [ "${nowebservers2}" != "${nowebservers1}" ] || [ "${nowebservers2}" != "${nowebservers3}" ] || [ "${nowebservers2}" != "${nowebservers4}" ] ) ||
    ( [ "${nowebservers3}" != "${nowebservers}" ] || [ "${nowebservers3}" != "${nowebservers1}" ] || [ "${nowebservers3}" != "${nowebservers2}" ] || [ "${nowebservers3}" != "${nowebservers4}" ] ) ||
    ( [ "${nowebservers4}" != "${nowebservers}" ] || [ "${nowebservers4}" != "${nowebservers1}" ] || [ "${nowebservers4}" != "${nowebservers2}" ] || [ "${nowebservers4}" != "${nowebservers3}" ] )
)
then
    exit
fi

if ( [ "${nowebservers}" -gt "${NO_WEBSERVERS}" ] )
then
    /bin/echo "${0} `/bin/date`: More webservers are running than are required by the configuration" >> ${HOME}/logs/ScalingEventsLog.log
    /bin/echo "${0} `/bin/date`: There are ${nowebservers} runnning when only ${NO_WEBSERVERS} are required" >> ${HOME}/logs/ScalingEventsLog.log

    #we need to terminate an arbitrary webserver so get a list of candidate ones
    ipstokill="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "webserver" ${CLOUDHOST}`"
    count="1"
    while ( [ "${nowebservers}" -gt "${NO_WEBSERVERS}" ] )
    do
        ip="`/bin/echo ${ipstokill} | /usr/bin/cut -d " " -f ${count}`"
        /bin/touch ${HOME}/config/shuttingdownwebserverips/${ip}

        /bin/echo "${0} `/bin/date`: We have elected webserver ${ip} to shutdown" >> ${HOME}/logs/ScalingEventsLog.log

        if ( [ "`${HOME}/providerscripts/server/GetServerName.sh ${ip} ${CLOUDHOST} | grep webserver`" != "" ] )
        then
            /bin/echo "${0} `/bin/date`: Webserver ${ip} is having it's ip removed from the DNS service" >> ${HOME}/logs/ScalingEventsLog.log
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

            /bin/echo "${0} `/bin/date`: Webserver ${ip} is being cleanly shutdown" >> ${HOME}/logs/ScalingEventsLog.log
            /usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${SUDO} ${HOME}/providerscripts/utilities/ShutdownThisWebserver.sh"
            /bin/echo "${0} `/bin/date`: Webserver ${ip} is being destroyed" >> ${HOME}/logs/ScalingEventsLog.log
            /bin/echo "${0} `/bin/date` : ${ip} is being destroyed because it was excess to requirements" >> ${HOME}/logs/MonitoringLog.log
            ${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
            
            DBaaS_DBSECURITYGROUP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DBaaSDBSECURITYGROUP'`"

            if ( [ "${DBaaS_DBSECURITYGROUP}" != "" ] )
            then
                IP_TO_DENY="${ip}"
                . ${HOME}/providerscripts/server/DenyDBAccess.sh
            fi
            
            INMEMORYCACHING_SECURITY_GROUP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INMEMORYCACHINGSECURITYGROUP'`"
            INMEMORYCACHING_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INMEMORYCACHINGPORT'`"

            if ( [ "${INMEMORYCACHING_SECURITY_GROUP}" != "" ] )
            then
                IP_TO_DENY="${ip}"
                . ${HOME}/providerscripts/server/DenyCachingAccess.sh
            fi
            
            /bin/rm ${HOME}/runtime/IPREMOVED:${ip}
            ${HOME}/providerscripts/email/SendEmail.sh "A WEBSERVER HAS BEEN DESTROYED" "Webserver ( ${ip} ) has just been shutdown and destroyed"
        fi

        /bin/rm  ${HOME}/config/shuttingdownwebserverips/${ip}
        count="`/usr/bin/expr ${count} + 1`"
        nowebservers="`/usr/bin/expr ${nowebservers} - 1`"
        /bin/echo "${0} `/bin/date`: There are now ${nowebservers} running" >> ${HOME}/logs/ScalingEventsLog.log
        ${HOME}/providerscripts/email/SendEmail.sh "UPDATE IN NUMBER OF ACTIVE WEBSERVERS" "There is now ${nowebservers} webservers running"

    done
fi

