#!/bin/sh
##############################################################################################################################
# Description: This script will perform the autoscaling calculation and ergo spawn or destroy webservers
# Date: 18-11-2016
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

if ( [ ! -f ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
    exit
fi

DEVELOPMENT="`/bin/ls ${HOME}/.ssh/DEVELOPMENT:* | /usr/bin/awk -F':' '{print $NF}'`"
CLOUDHOST="`/bin/ls ${HOME}/.ssh/CLOUDHOST:* | /usr/bin/awk -F':' '{print $NF}'`"

#If this is a development build, autoscaling is disabled and non functional
if ( [ "${DEVELOPMENT}" = "1" ] )
then
    /bin/echo "${0} `/bin/date`: This deployment is in development mode, autoscaling will not work. During development, only one webserver is allowed." >> ${HOME}/logs/MonitoringLog.log
    exit
fi

# You can change these parameters to set minimum and maximum values for the number of servers to be built
MAX_WEBSERVERS="10"
MIN_WEBSERVERS="2"

#We never want to have less than 2 webservers running. If we have only one and there is a failure, then that is guaranteed
#downtime
if ( [ "${MIN_WEBSERVERS}" -le "1" ] )
then
    MIN_WEBSERVERS="2"
fi

#Remove any residual cpu aggregation files
for file in `/usr/bin/find ${HOME}/config/cpuaggregator/* -mmin +5`
do
    /bin/rm ${file}
done

#Aggregate all our CPU usage values from the webservers

/bin/cat ${HOME}/config/cpuaggregator/CPUAGGREGATOR5* > ${HOME}/cpuaggregator/CPUAGGREGATOR5
/bin/cat ${HOME}/config/cpuaggregator/CPUAGGREGATOR10* > ${HOME}/cpuaggregator/CPUAGGREGATOR10
/bin/cat ${HOME}/config/cpuaggregator/CPUAGGREGATOR15* > ${HOME}/cpuaggregator/CPUAGGREGATOR15
/bin/cat ${HOME}/config/cpuaggregator/CPUAGGREGATOR30* > ${HOME}/cpuaggregator/CPUAGGREGATOR30
/bin/cat ${HOME}/config/cpuaggregator/CPUAGGREGATOR60* > ${HOME}/cpuaggregator/CPUAGGREGATOR60

#Calculate the averages
CPU5TOTAL="`/usr/bin/awk '{s+=$1} END {print s}' ${HOME}/cpuaggregator/CPUAGGREGATOR5`"
NUMBER="`/usr/bin/wc -l < ${HOME}/cpuaggregator/CPUAGGREGATOR5`"
if ( [ "${NUMBER}" -lt "5" ] )
then
    NUMBER="5"
fi
CPU5TOTAL="`/usr/bin/printf "%.0f" ${CPU5TOTAL}`"
CPUAVERAGE5="`/usr/bin/expr ${CPU5TOTAL} / ${NUMBER}`"

CPU10TOTAL="`/usr/bin/awk '{s+=$1} END {print s}' ${HOME}/cpuaggregator/CPUAGGREGATOR10`"
NUMBER="`/usr/bin/wc -l < ${HOME}/cpuaggregator/CPUAGGREGATOR10`"
if ( [ "${NUMBER}" -lt "10" ] )
then
    NUMBER="10"
fi
CPU10TOTAL="`/usr/bin/printf "%.0f" ${CPU10TOTAL}`"
CPUAVERAGE10="`/usr/bin/expr ${CPU10TOTAL} / ${NUMBER}`"

CPU15TOTAL="`/usr/bin/awk '{s+=$1} END {print s}' ${HOME}/cpuaggregator/CPUAGGREGATOR15`"
NUMBER="`/usr/bin/wc -l < ${HOME}/cpuaggregator/CPUAGGREGATOR15`"
if ( [ "${NUMBER}" -lt "15" ] )
then
    NUMBER="15"
fi
CPU15TOTAL="`/usr/bin/printf "%.0f" ${CPU15TOTAL}`"
CPUAVERAGE15="`/usr/bin/expr ${CPU15TOTAL} / ${NUMBER}`"

CPU30TOTAL="`/usr/bin/awk '{s+=$1} END {print s}' ${HOME}/cpuaggregator/CPUAGGREGATOR30`"
NUMBER="`/usr/bin/wc -l < ${HOME}/cpuaggregator/CPUAGGREGATOR30`"
if ( [ "${NUMBER}" -lt "30" ] )
then
    NUMBER="30"
fi
CPU30TOTAL="`/usr/bin/printf "%.0f" ${CPU30TOTAL}`"
CPUAVERAGE30="`/usr/bin/expr ${CPU30TOTAL} / ${NUMBER}`"

CPU60TOTAL="`/usr/bin/awk '{s+=$1} END {print s}' ${HOME}/cpuaggregator/CPUAGGREGATOR60`"
NUMBER="`/usr/bin/wc -l < ${HOME}/cpuaggregator/CPUAGGREGATOR60`"
if ( [ "${NUMBER}" -lt "60" ] )
then
    NUMBER="60"
fi
CPU60TOTAL="`/usr/bin/printf "%.0f" ${CPU60TOTAL}`"
CPUAVERAGE60="`/usr/bin/expr ${CPU60TOTAL} / ${NUMBER}`"

/bin/echo "${0} `/bin/date`: CPU Average 60= " ${CPUAVERAGE60} >> ${HOME}/logs/MonitoringLog.log
/bin/echo "${0} `/bin/date`: CPU Average 30= " ${CPUAVERAGE30} >> ${HOME}/logs/MonitoringLog.log
/bin/echo "${0} `/bin/date`: CPU Average 15= " ${CPUAVERAGE15} >> ${HOME}/logs/MonitoringLog.log
/bin/echo "${0} `/bin/date`: CPU Average 10= " ${CPUAVERAGE10} >> ${HOME}/logs/MonitoringLog.log
/bin/echo "${0} `/bin/date`: CPU Average 5= " ${CPUAVERAGE5} >> ${HOME}/logs/MonitoringLog.log

if ( [ "${1}" = "lock" ] )
then

    #Determine how many machines are online and active and how many have been provisioned but are not yet active
    onlinewebservers="`${HOME}/autoscaler/HowManyWebserversAreRunningAndActive.sh ${CLOUDHOST}`"

    #I have seen cases where API calls unexpectedly fail, not sure why. In this case it is critical so, we give a few attempts to make sure
    #If the API call fails, then ${onlinewebservers} will be erroneously set to 0. So,
    count="0"
    while ( [ "${onlinewebservers}" = "0" ] && [ "${count}" -lt "3" ] )
    do
        onlinewebservers="`${HOME}/autoscaler/HowManyWebserversAreRunningAndActive.sh ${CLOUDHOST}`"
        /bin/sleep 5
        count="`/usr/bin/expr ${count} + 1`"
    done

    provisionedwebservers="`${HOME}/autoscaler/HowManyWebserversAreRunning.sh ${CLOUDHOST}`"

    #I have seen cases where API calls unexpectedly fail, not sure why. In this case it is critical so, we give a few attempts to make sure
    #If the API call fails, then ${onlinewebservers} will be erroneously set to 0. So,
    count="0"
    while ( [ "${provisionedwebservers}" = "0" ] && [ "${count}" -lt "3" ] )
    do
        provisionedwebservers="`${HOME}/autoscaler/HowManyWebserversAreRunning.sh ${CLOUDHOST}`"
        /bin/sleep 5
        count="`/usr/bin/expr ${count} + 1`"
    done


    /bin/echo "${0} `/bin/date`: Online Webservers= ${onlinewebservers} Provisioned Webservers= ${provisionedwebservers} MAX WEBSERVERS=${MAX_WEBSERVERS} MIN WEBSERVERS=${MIN_WEBSERVERS}" >> ${HOME}/logs/MonitoringLog.log

    #See if we are less than the minimum number of webservers, in which case, we will have to start a new one
    if ( [ "${provisionedwebservers}" -lt "${MIN_WEBSERVERS}" ] )
    then
        /bin/echo "${0} `/bin/date`: Building a new webserver because no of webservers (${provisionedwebservers})is less that minimum ${MIN_WEBSERVERS}" >> ${HOME}/logs/MonitoringLog.log
        ${HOME}/providerscripts/email/SendEmail.sh  "Autoscaling Event has been triggered, Scaling up" "Building a new webserver because no of webservers (${provisionedwebservers}) is less that minimum ${MIN_WEBSERVERS}"
        ${HOME}/autoscaler/BuildWebserver.sh &
        count="0"
        while ( [ "`${HOME}/autoscaler/HowManyWebserversAreRunning.sh ${CLOUDHOST}`" != "`/usr/bin/expr ${provisionedwebservers} + 1`" ] && [ "${count}" -lt "10" ] )
        do
            /bin/sleep 30
            count="`/usr/bin/expr ${count} + 1`"
        done
    fi

    #See if we need to scale down - scale down cautiously
    if (    [ "${CPUAVERAGE60}" -lt "60" ] && [ "${onlinewebservers}" -gt "${MIN_WEBSERVERS}" ] && [ "`/bin/cat ${HOME}/cpuaggregator/CPUAGGREGATOR60 | /usr/bin/wc -l`" -gt "58" ] )
    then
        /bin/echo "${0} `/bin/date`: Shutting down a webserver because CPU60 is less than 60" >> ${HOME}/logs/MonitoringLog.log
        ${HOME}/providerscripts/email/SendEmail.sh "Autoscaling event has been triggered, scaling down" "Autoscaling event has been triggered because CPU is less than 60%, scaling down..."
        ${HOME}/autoscaler/ShutdownAWebserver.sh
        exit
    fi

    if (    [ "${CPUAVERAGE30}" -lt "50" ] && [ "${onlinewebservers}" -gt "${MIN_WEBSERVERS}" ] && [ "`/bin/cat ${HOME}/cpuaggregator/CPUAGGREGATOR30 | /usr/bin/wc -l`" -gt "28" ] )
    then
        /bin/echo "${0} `/bin/date`: Shutting down a webserver because CPU30 is less than 50" >> ${HOME}/logs/MonitoringLog.log
        ${HOME}/providerscripts/email/SendEmail.sh "Autoscaling event has been triggered, scaling down" "Autoscaling event has been triggered because CPU is less than 50%, scaling down..."
        ${HOME}/autoscaler/ShutdownAWebserver.sh
        exit
    fi

    if (    [ "${CPUAVERAGE15}" -lt "40" ] && [ "${onlinewebservers}" -gt "${MIN_WEBSERVERS}" ] && [ "`/bin/cat ${HOME}/cpuaggregator/CPUAGGREGATOR15 | /usr/bin/wc -l`" -gt "13" ] )
    then
        /bin/echo "${0} `/bin/date`: Shutting down a webserver because CPU15 is less than 40" >> ${HOME}/logs/MonitoringLog.log
        ${HOME}/providerscripts/email/SendEmail.sh "Autoscaling event has been triggered, scaling down" "Autoscaling event has been triggered because CPU is less than 40%, scaling down..."
        ${HOME}/autoscaler/ShutdownAWebserver.sh
        exit
    fi

    if (    [ "${CPUAVERAGE10}" -lt "30" ] && [ "${onlinewebservers}" -gt "${MIN_WEBSERVERS}" ] && [ "`/bin/cat ${HOME}/cpuaggregator/CPUAGGREGATOR10 | /usr/bin/wc -l`" -gt "8" ] )
    then
        /bin/echo "${0} `/bin/date`: Shutting down a webserver because CPU10 is less than 30" >> ${HOME}/logs/MonitoringLog.log
        ${HOME}/providerscripts/email/SendEmail.sh "Autoscaling event has been triggered, scaling down" "Autoscaling event has been triggered because CPU is less than 30%, scaling down..."
        ${HOME}/autoscaler/ShutdownAWebserver.sh
        exit
    fi

    if (    [ "${CPUAVERAGE5}" -lt "20" ] && [ "${onlinewebservers}" -gt "${MIN_WEBSERVERS}" ] && [ "`/bin/cat ${HOME}/cpuaggregator/CPUAGGREGATOR5 | /usr/bin/wc -l`" -gt "3" ] )
    then
        /bin/echo "${0} `/bin/date`: Shutting down a webserver because CPU5 is less than 20" >> ${HOME}/logs/MonitoringLog.log
        ${HOME}/providerscripts/email/SendEmail.sh "Autoscaling event has been triggered, scaling down" "Autoscaling event has been triggered because CPU is less than 10%, scaling down..."
        ${HOME}/autoscaler/ShutdownAWebserver.sh
        exit
    fi

    #See if we need to scale up, scale up aggressively
    if ( [ "${CPUAVERAGE5}" -gt "80" ] && [ "${provisionedwebservers}" -lt "${MAX_WEBSERVERS}" ] )
    then
        /bin/echo "${0} `/bin/date`: Building a webserver because CPU5 is greater than 90" >> ${HOME}/logs/MonitoringLog.log
        ${HOME}/providerscripts/email/SendEmail.sh "Autoscaling event has been triggered, scaling up" "Building a webserver because CPU5 is greater than 90"
        ${HOME}/autoscaler/BuildWebserver.sh
elif ( [ "${CPUAVERAGE10}" -gt "70" ] && [ "${provisionedwebservers}" -lt "${MAX_WEBSERVERS}" ] )
    then
        /bin/echo "${0} `/bin/date`: Building a webserver because CPU10 is greater than 80" >> ${HOME}/logs/MonitoringLog.log
        ${HOME}/providerscripts/email/SendEmail.sh "Autoscaling event has been triggered, scaling up" "Building a webserver because CPU10 is greater than 80"
        ${HOME}/autoscaler/BuildWebserver.sh
elif ( [ "${CPUAVERAGE15}" -gt "60" ] && [ "${provisionedwebservers}" -lt "${MAX_WEBSERVERS}" ] )
    then
        /bin/echo "${0} `/bin/date`: Building a webserver because CPU15 is greater than 70" >> ${HOME}/logs/MonitoringLog.log
        ${HOME}/providerscripts/email/SendEmail.sh "Autoscaling event has been triggered, scaling up" "Building a webserver because CPU15 is greater than 70"
        ${HOME}/autoscaler/BuildWebserver.sh
    fi
fi
