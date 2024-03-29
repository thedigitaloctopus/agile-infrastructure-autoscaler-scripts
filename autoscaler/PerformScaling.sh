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

if ( [ "`${HOME}/providerscripts/utilities/TimeSinceInstallation.sh`" -lt "20" ] && [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh AUTOSCALE`" != "1" ] )
then
    exit
fi

logdate="`/usr/bin/date | /usr/bin/awk '{print $1 $2 $3 $NF}'`"
logdir="scaling-events-${logdate}"

if ( [ ! -d ${HOME}/logs/${logdir} ] )
then
    /bin/mkdir -p ${HOME}/logs/${logdir}
fi

if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "syncpurge"`" = "1" ] || [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "switchoffscalingpriortosyncpurge"`" = "1" ] )
then
    exit
fi

if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "SWITCHOFFSCALING"`" = "1" ] )
then
    exit
fi

#If there's an build processes hanging around from previous attempts, purge them so we are nice and clean
if ( [ -f ${HOME}/runtime/buildingwebserver.lock ] )
then
    if ( [ "`/usr/bin/find ${HOME}/runtime/buildingwebserver.lock -type f -mmin +26`" != "" ] )
    then
        for pid in "`/bin/pgrep BuildWebserver`"
        do
            if ( [ "${pid}" != "" ] )
            then
                /bin/kill -9 ${pid}
            fi
        done
        /bin/rm ${HOME}/runtime/buildingwebserver.lock
    else
       exit
    fi
fi

#################################################ESSENTIAL#########################################################
#To configure how many websevers are deployed, you can edit the file at:  ${HOME}/config/scalingprofile/profile.cnf 
#################################################ESSENTIAL#########################################################

SCALING_MODE="static"
NO_WEBSERVERS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'NUMBERWS'`"

if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "scalingprofile/profile.cnf"`" = "0" ] )
then
    /bin/echo  "SCALING_MODE=${SCALING_MODE}" > /tmp/profile.cnf
    /bin/echo  "NO_WEBSERVERS=${NO_WEBSERVERS}" >> /tmp/profile.cnf  
    ${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh profile.cnf "scalingprofile/profile.cnf"
    /bin/rm /tmp/profile.cnf
fi

if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "INSTALLEDSUCCESSFULLY"`" = "0" ] )
then
    exit
fi

${HOME}/providerscripts/datastore/configwrapper/GetFromConfigDatastore.sh "scalingprofile/profile.cnf"

if ( [ -f /tmp/profile.cnf ] )
then
    SCALING_MODE="`/bin/grep -a "SCALING_MODE" /tmp/profile.cnf | /usr/bin/awk -F'=' '{print $NF}'`"
    NO_WEBSERVERS="`/bin/grep -a "NO_WEBSERVERS" /tmp/profile.cnf | /usr/bin/awk -F'=' '{print $NF}'`"
else
    SCALING_MODE="static"
    NO_WEBSERVERS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'NUMBERWS'`"
    /bin/echo "${0} `/bin/date`: NO SCALING CONFIG FOUND USING DEFAULT SCALING VALUE OF ${NO_WEBSERVERS}" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
    ${HOME}/providerscripts/email/SendEmail.sh "NO SCALING CONFIG FOUND" "Defaulting back to the default number of webservers: ${NO_WEBSERVERS}"
fi

${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh profile.cnf "scalingprofile/profile.cnf"

/bin/rm /tmp/profile.cnf

if ( [ "${SCALING_MODE}" = "static" ] && [ "${NO_WEBSERVERS}" != "" ] )
then
    ${HOME}/providerscripts/utilities/StoreConfigValue.sh 'NUMBERWS' "${NO_WEBSERVERS}"
elif ( [ "${SCALING_MODE}" = "" ] || [ "${NO_WEBSERVERS}" = "" ] )
then
    #For some reason, the scaling config isn't available so, default back to the default value
    SCALING_MODE="static"
    NO_WEBSERVERS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'NUMBERWS'`"
    /bin/echo "${0} `/bin/date`: NO SCALING CONFIG FOUND USING DEFAULT SCALING VALUE OF ${NO_WEBSERVERS}" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
    ${HOME}/providerscripts/email/SendEmail.sh "NO SCALING CONFIG FOUND" "Defaulting back to the default number of webservers: ${NO_WEBSERVERS}"
fi

/bin/echo  "SCALING_MODE=${SCALING_MODE}" > ./profile.cnf
/bin/echo  "NO_WEBSERVERS=${NO_WEBSERVERS}" >> ./profile.cnf  
${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh profile.cnf "scalingprofile/profile.cnf"
${HOME}/providerscripts/utilities/StoreConfigValue.sh 'NUMBERWS' "${NO_WEBSERVERS}"

if ( [ "${SCALING_MODE}" != "static" ] )
then
    exit
fi

#We don't want less than 2 webservers so, if somehow, webservers is set to less than 2 default it to 2 to be on the safe side. 
if ( [ "${NO_WEBSERVERS}" -lt "2" ] )
then
    NO_WEBSERVERS="2"
fi

CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
ALGORITHM="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ALGORITHM'`"
SSH_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SSHPORT'`"
SERVER_USER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERUSER'`"
SERVER_USER_PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERUSERPASSWORD'`"

SUDO=" DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "

/bin/echo "${0} `/bin/date`: ##########################################################################" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log

#When there are multiple autoscaler, say 4, we need to put in a contention period so that we don't start 4 websevers when we only need 1.
#Might not be completely fail safe, but, if extra machines are spun up the system will find out and shut them down later on. 

autoscaler_ip="`${HOME}/providerscripts/utilities/GetPublicIP.sh`"
autoscaler_no="`${HOME}/providerscripts/server/GetServerName.sh ${autoscaler_ip} ${CLOUDHOST} | /usr/bin/awk -F'-' '{print $1}'`"

contentionperiod="`/usr/bin/expr ${autoscaler_no} \* 26`"

/bin/sleep ${contentionperiod}

# Sometimes we get back a zero when it shouldn't be possibly because of a network glitch, so we try a few times to give us a good chance
# of getting it right
noprovisionedwebservers="`${HOME}/autoscaler/GetDNSIPs.sh | /usr/bin/wc -w`"
noallips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "webserver" ${CLOUDHOST} | /usr/bin/tr '\n' ' ' | /usr/bin/wc -w`"

/bin/echo "${0} `/bin/date`: ${noprovisionedwebservers} webservers are currently provisioned and live." >> ${HOME}/logs/${logdir}/ScalingEventsLog.log

#If we have fewer webservers than we require, build one, if there's no webservers running it means something is wrong so prevent scaling actions
if ( [ "${noallips}" -lt "${NO_WEBSERVERS}" ] )
then
    #It is possible that machine builds failed in which case we may have more servers running than are added to the DNS system
    #In this case, we don't want to keep building machines, so, check for it and exit
    #Any additional or unneccesary machines will be checked for and terminated by other scripts
    
    autoscaler_ip="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'MYPUBLICIP'`"
    autoscaler_name="`${HOME}/providerscripts/server/GetServerName.sh ${autoscaler_ip} ${CLOUDHOST}`"
    autoscaler_no="`/bin/echo ${autoscaler_name} | /usr/bin/awk -F'-' '{print $1}'`"
    
    #The reason for this sleep period is that when we build from multiple autoscalers we might build too many machines so sleep for multiples of 20 based on autoscaler number
    /bin/echo "${0} `/bin/date`: total no of webservers needed is: ${NO_WEBSERVERS}" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
    /bin/echo "${0} `/bin/date`: no of webservers (live) is: ${noprovisionedwebservers}" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
    /bin/echo "${0} `/bin/date`: no of webservers (booting and live) is: ${noallips} " >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
    booting="`/usr/bin/expr ${noallips} - ${noprovisionedwebservers}`"
    /bin/echo "${0} `/bin/date`: no of webservers that are booting is: ${booting} " >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
    need_booting="`/usr/bin/expr ${NO_WEBSERVERS} - ${noprovisionedwebservers}`"
    /bin/echo "${0} `/bin/date`: total no of webservers that still need booting initiation is: `/usr/bin/expr ${need_booting} - ${booting}`" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
    /bin/echo "${0} `/bin/date`: `/usr/bin/expr ${need_booting} - ${booting}` webservers are still needed out of a total of ${need_booting} that need booting " >> ${HOME}/logs/${logdir}/ScalingEventsLog.log

    if ( [ "${noallips}" -lt "${NO_WEBSERVERS}" ] )
    then
        if ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh SNAPAUTOSCALE:1`" = "1" ] )
        then
            /bin/echo "${0} `/bin/date`: I have calculated that a webserver needs booting so am booting a new one from a snapshot" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
            /bin/touch ${HOME}/runtime/buildingwebserver.lock
            newip="`${HOME}/autoscaler/BuildWebserver.sh`"
            /bin/rm ${HOME}/runtime/buildingwebserver.lock
           # /bin/echo "${0} `/bin/date`:  Rebooting autoscaler before next scaling event so that memory doesn't run out which sometimes happens on small machines" >> ${HOME}/logs/ScalingEventsLog.log
           # /usr/sbin/shutdown -r now
        else
            /bin/echo "${0} `/bin/date`: I have calculated that a webserver needs booting so am booting a new one as a regular build (not a snapshot)" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
            /bin/touch ${HOME}/runtime/buildingwebserver.lock
            newip="`${HOME}/autoscaler/BuildWebserver.sh`"
            /bin/rm ${HOME}/runtime/buildingwebserver.lock
        fi
        if ( [ "${newip}" != "" ] )
        then
            /bin/echo "${0} `/bin/date`:  Added the new IP for the webserver( ${newip} ) to the DNS system" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
            ${HOME}/providerscripts/email/SendEmail.sh "A WEBSERVER HAS BEEN DEPLOYED" "Webserver ( ${ip} ) has just been deployed and activated"
        fi   
        /bin/echo "${0} `/bin/date`: Rebooting autoscaler before next scaling event so that memory doesn't run out which sometimes happens on small machines" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
        /usr/sbin/shutdown -r now
    fi
fi

#If we have more webservers than we need, probably due to a configuration seeing (NO_WEBSERVERS) being changed, then, shutdown
#the excess servers. Issue command repeatedly in case of network glitches, repeated attempts give us a good chance of getting it right
nowebservers="`${HOME}/autoscaler/GetDNSIPs.sh | /usr/bin/wc -w`"

if ( [ "${nowebservers}" -gt "${NO_WEBSERVERS}" ] )
then
    /bin/echo "${0} `/bin/date`: More webservers are running than are required by the configuration" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
    /bin/echo "${0} `/bin/date`: There are ${nowebservers} runnning when only ${NO_WEBSERVERS} are required" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
    
    /bin/touch ${HOME}/runtime/SWITCHOFFDEADORALIVE.lock
    /bin/touch ${HOME}/runtime/SWITCHOFFPURGEDETACHEDIPS.lock

    ipstokill="`${HOME}/autoscaler/GetDNSIPs.sh`"
    count="1"
    while ( [ "${nowebservers}" -gt "${NO_WEBSERVERS}" ] )
    do
        ip="`/bin/echo ${ipstokill} | /usr/bin/cut -d " " -f ${count}`"
        private_ip="`${HOME}/providerscripts/server/GetServerPrivateIPAddressByIP.sh ${ip} ${cloudhost}`"

        ${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${ip} shuttingdownwebserverips/${ip}
        /bin/echo "${0} `/bin/date`: We have elected webserver ${ip} to shutdown" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
        webserver_name="`${HOME}/providerscripts/server/GetServerName.sh ${ip} ${CLOUDHOST} | grep webserver`"
        
        if ( [ "${webserver_name}" != "" ] )
        then
            /bin/echo "${0} `/bin/date`: Webserver ${ip} is having its ip removed from the DNS service" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
            ${HOME}/autoscaler/RemoveIPFromDNS.sh ${ip}

            /bin/touch ${HOME}/runtime/IPREMOVED:${ip}
            #I found that for (probably the TTL) of the DNS system after the record is removed, the DNS system still tries to route
            #requests to the server even though the record has been deleted. After the TTL has expired things are OK, however,
            #If the TTL is 2 minutes and we shutdown the appropriate server 20 seconds after the record is removed, then we may
            #get errors because the server isn't up to service the still routed requests as we have shut it down. So, it's dirty, but, assuming a TTL
            #of 2 minutes, if we sleep for a while before we destroy anything, then, we can be sure that no requests will be routed to our
            #terminated machine. Clear? If there is a longer TTL on the record, this could be a problem and the sleep here would have
            #to be increased here to prevent errors on scaledown
            
            /bin/echo "${0} `/bin/date`: Pausing for 120 seconds to make sure the DNS system has cleared itself" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
            
            /bin/sleep 120

            /bin/echo "${0} `/bin/date`: Webserver ${ip} is being shutdown" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log       
       
            /usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${SUDO} /bin/touch ${HOME}/runtime/MARKEDFORSHUTDOWN"
            while ( [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${SUDO} /bin/ls ${HOME}/runtime/MARKEDFORSHUTDOWN"`" != "" ] )
            do
                /bin/echo "${0} `/bin/date`: Monitoring for webserver ${ip} to have completed application backup and shutdown following shutdown initiation as a scaling event" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
                /bin/sleep 30
            done
            
            count1="0"
            while ( [ "`/usr/bin/ping -c 3 ${ip} | /bin/grep '100% packet loss'`"  = "" ] && [ "${count1}" -lt "9" ] )
            do
                /bin/echo "${0} `/bin/date`: Waiting for webserver ${ip} to become unresponsive after shutdown" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
                /bin/sleep 26
                count1="`/usr/bin/expr ${count1} + 1`"
            done
           
            if ( [ "${count1}" = "5" ] )
            then
                /bin/echo "${0} `/bin/date`: There seems to have been some trouble getting webserver ${ip} to shutdown" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
                /bin/echo "${0} `/bin/date`: I am going to destroy it anyway and hope for the best..." >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
            else     
                /bin/echo "${0} `/bin/date`: Webserver ${ip} has been cleanly shutdown getting ready to destroy the virtual machine" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
                /bin/sleep 5
            fi
            /bin/echo "${0} `/bin/date`: Webserver ${ip} is being destroyed" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
            /bin/echo "${0} `/bin/date`: ${ip} has been destroyed because it was excess to the defined scaling requirements" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
            ${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST} ${private_ip}
            
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
            ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "shuttingdownwebserverips/${ip}"
            count="`/usr/bin/expr ${count} + 1`"
            nowebservers="`${HOME}/autoscaler/GetDNSIPs.sh | /usr/bin/wc -w`"
            
            /bin/echo "${0} #############################################################################" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
            /bin/echo "${0} `/bin/date`: There is now ${nowebservers} webservers running" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
            /bin/echo "${0} #############################################################################" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log

            ${HOME}/providerscripts/email/SendEmail.sh "UPDATE IN NUMBER OF ACTIVE WEBSERVERS" "There is now ${nowebservers} webservers running"
        else
            #If we have multiple autoscalers its possible that an IP that we are processing has been shutdown by another autoscaler so if we can't find a machine
            #name for that IP address assume it has been shutdown and treat it as if we had shut it down ourselves in terms of our iterating. 
            count="`/usr/bin/expr ${count} + 1`"
            nowebservers="`${HOME}/autoscaler/GetDNSIPs.sh | /usr/bin/wc -w`"
            /bin/echo "${0} `/bin/date`: Couldn't find the name for webserver ${ip} its most likely already been shutdown for some other reason" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
        fi
        
        if ( [ -f ${HOME}/runtime/SWITCHOFFDEADORALIVE.lock ] )
        then
            /bin/rm ${HOME}/runtime/SWITCHOFFDEADORALIVE.lock 
        fi
        
        if ( [ -f ${HOME}/runtime/SWITCHOFFPURGEDETACHEDIPS.lock ] )
        then
            /bin/rm ${HOME}/runtime/SWITCHOFFPURGEDETACHEDIPS.lock
        fi
    done
fi
