#!/bin/sh
###########################################################################################
# Description: This script will monitor for slow webserver builds. This can happen sometimes
# because of networking or some other reason, so we just terminate the slow machine and the
# autoscaling mechansim will spawn another one for us.
# Date: 18-11-2016
# Author: Peter Winter
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

if ( [ ! -f ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
    exit
fi

CLOUDHOST="`/bin/ls ${HOME}/.ssh/CLOUDHOST:* | /usr/bin/awk -F':' '{print $NF}'`"

#So, when a webserver is built, we set the 'being built' flag. Basically a machine is given 30 minutes to be built and then we consider it a
#slow build and something must be wrong, so, we destroy it

for ip in `/usr/bin/find ${HOME}/config/beingbuiltips/* -mmin +30`
do
    strippedip="`/bin/echo ${ip} | /usr/bin/awk -F'/' '{print $NF}'`"
    /bin/echo "${0} `/bin/date`: #####################################################################################" >> ${HOME}/logs/SlowBuildsLog.log
    /bin/echo "${0} `/bin/date`: Server with ip: ${strippedip} has been marked as slow to build and is being destroyed" >> ${HOME}/logs/SlowBuildsLog.log
    /bin/echo "${0} `/bin/date`: ****IT LOOKS LIKE THIS BUILD FAILED AND WAS TERMINATED FOR BEING SLUGGISH *****" >> ${HOME}/logs/MonitoringWebserverBuildLog.log
    /bin/echo "${0} `/bin/date`: ****DO NOT FRET, A NEW MACHINE WILL BE SPUN UP AND THE BUILD PROCESS REPEATED *****" >> ${HOME}/logs/MonitoringWebserverBuildLog.log
    ${HOME}/providerscripts/email/SendEmail.sh "WEBSERVER ${strippedip} IS A SLOW BUILD" "For some reason, ${strippedip} was a slow build (took more than 30 minutes) and has been terminated"

    ip="`${HOME}/providerscripts/server/GetServerIPAddressByPrivateIP.sh ${strippedip} ${CLOUDHOST}`"
    ${HOME}/autoscaler/RemoveIPFromDNS.sh ${ip}
    /bin/echo "${0} `/bin/date` : ${ip} is being destroyed because it was a slow build" >> ${HOME}/logs/MonitoringLog.log
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
    
    /bin/rm ${HOME}/config/beingbuiltips/${strippedip}
    /bin/rm ${HOME}/runtime/autoscalelock.file
done
