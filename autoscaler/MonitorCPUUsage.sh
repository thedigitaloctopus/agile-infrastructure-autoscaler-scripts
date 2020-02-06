#!/bin/sh
############################################################################################
# Description: This script will monitor for high CPU usage on our webservers and send out
# emails to the registered email address when it is. Each webserver does some work to find
# out how much of its CPU is being used and persists it to the shared file system. It is this
# reporting that this script picks up on to assess whether CPU usage is too high and send out
# a notification to tell us as such.
# found to be so
# Date: 18-11-2016
# Author: Peter Winter
##############################################################################################
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

/bin/echo "${0} =================================CPU USAGE===================================" >> ${HOME}/logs/CPUUtilisationLog.log
/bin/echo "${0} `/bin/date`: CPU Average 60= " ${CPUAVERAGE60} >> ${HOME}/logs/CPUUtilisationLog.log
/bin/echo "${0} `/bin/date`: CPU Average 30= " ${CPUAVERAGE30} >> ${HOME}/logs/CPUUtilisationLog.log
/bin/echo "${0} `/bin/date`: CPU Average 15= " ${CPUAVERAGE15} >> ${HOME}/logs/CPUUtilisationLog.log
/bin/echo "${0} `/bin/date`: CPU Average 10= " ${CPUAVERAGE10} >> ${HOME}/logs/CPUUtilisationLog.log
/bin/echo "${0} `/bin/date`: CPU Average 5= " ${CPUAVERAGE5} >> ${HOME}/logs/CPUUtilisationLog.log
/bin/echo "${0} =================================CPU USAGE====================================" >> ${HOME}/logs/CPUUtilisationLog.log

if ( [ "${CPUAVERAGE60}" -gt "60" ] )
then
    ${HOME}/providerscripts/email/SendEmail.sh "WARNING: CPU USAGE" "It has been detected that CPU usages is high. You may want to add additional webservers to your configuration"
fi

if ( [ "${CPUAVERAGE30}" -gt "65" ] )
then
    ${HOME}/providerscripts/email/SendEmail.sh "WARNING: CPU USAGE" "It has been detected that CPU usages is high. You may want to add additional webservers to your configuration"
fi

if ( [ "${CPUAVERAGE15}" -gt "70" ] )
then
    ${HOME}/providerscripts/email/SendEmail.sh "WARNING: CPU USAGE" "It has been detected that CPU usages is high. You may want to add additional webservers to your configuration"
fi

if ( [ "${CPUAVERAGE10}" -gt "80" ] )
then
    ${HOME}/providerscripts/email/SendEmail.sh "WARNING: CPU USAGE" "It has been detected that CPU usages is high. You may want to add additional webservers to your configuration"
fi

if ( [ "${CPUAVERAGE5}" -gt "85" ] )
then
    ${HOME}/providerscripts/email/SendEmail.sh "WARNING: CPU USAGE" "It has been detected that CPU usages is high. You may want to add additional webservers to your configuration"
fi
