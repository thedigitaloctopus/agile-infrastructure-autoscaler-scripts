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

#################################################ESSENTIAL#########################################################
#To configure how many websevers are deployed, you can edit the file at:  ${HOME}/config/scalingprofile/profile.cnf 
#################################################ESSENTIAL#########################################################

SCALING_MODE="`/bin/cat ${HOME}/config/scalingprofile/profile.cnf | /bin/grep "SCALING_MODE" | /usr/bin/awk -F'=' '{print $NF}'`"
NO_WEBSERVERS="`/bin/cat ${HOME}/config/scalingprofile/profile.cnf | /bin/grep "NO_WEBSERVERS" | /usr/bin/awk -F'=' '{print $NF}'`"

if ( [ "${SCALING_MODE}" != "dynamic" ] )
then
    exit
fi

if ( [ ! -f ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
    exit
fi

/bin/echo "${0} `/bin/date`: ##########################################################################" >> ${HOME}/logs/ScalingEventsLog.log

instanceid="`/usr/bin/aws ec2 describe-instances --filters "Name=tag:ScalingType,Values=Dynamic" | /usr/bin/jq '.Reservations[].Instances[].InstanceId$
if ( [ "${instanceid}" != "" ] )
then
    newip="`${HOME}/autoscaler/BuildWebserver.sh`"
fi

if ( [ "${newip}" != "" ] )
then
    /bin/echo "${0} `/bin/date`:  Added the new IP ( ${newip} ) to the DNS system" >> ${HOME}/logs/ScalingEventsLog.log
    ${HOME}/providerscripts/email/SendEmail.sh "A WEBSERVER HAS BEEN DEPLOYED" "Webserver ( ${ip} ) has just been deployed and activated"
fi


