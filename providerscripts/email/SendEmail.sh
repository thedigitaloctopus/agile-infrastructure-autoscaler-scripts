#!/bin/sh
##########################################################################################
# Description : This script will send an email from the command line
# Date : 10-11-2016
# Author : Peter Winter
##########################################################################################
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
########################################################################################
########################################################################################
#set -x

subject="$1"
message="$2"
FROM_ADDRESS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SYSTEMFROMEMAILADDRESS'`"

if ( [ "${3}" != "" ] )
then
    TO_ADDRESS="${3}"
else
    TO_ADDRESS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SYSTEMTOEMAILADDRESS'`"
fi

USERNAME="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'EMAILUSERNAME'`"
PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'EMAILPASSWORD'`"
EMAIL_PROVIDER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'EMAILPROVIDER'`"

if ( [ "${EMAIL_PROVIDER}" = "1" ] )
then
    /bin/echo "${0} `/bin/date`: Email sent via sendpulse, subject : ${subject} to: ${TO_ADDRESS}" >> ${HOME}/logs/MonitoringLog.log
    /usr/bin/sendemail -o tls=no -f ${FROM_ADDRESS} -t ${TO_ADDRESS} -s smtp-pulse.com:2525 -xu ${USERNAME} -xp ${PASSWORD} -u "${subject} `/bin/date`" -m ${message}
fi
if ( [ "${EMAIL_PROVIDER}" = "2" ] )
then
    /bin/echo "${0} `/bin/date`: Email sent via gmail, subject : ${subject} to: ${TO_ADDRESS}" >> ${HOME}/logs/MonitoringLog.log
    /usr/bin/sendemail -o tls=yes -f ${FROM_ADDRESS} -t ${TO_ADDRESS} -s smtp.gmail.com:587 -xu ${USERNAME} -xp ${PASSWORD} -u "${subject} `/bin/date`" -m ${message}
fi
if ( [ "${EMAIL_PROVIDER}" = "3" ] )
then
    /usr/bin/sendemail -o tls=yes -f ${FROM_ADDRESS} -t ${TO_ADDRESS} -s email-smtp.eu-west-1.amazonaws.com -xu ${USERNAME} -xp ${PASSWORD} -u "${subject} `/bin/date`" -m ${message}
fi
