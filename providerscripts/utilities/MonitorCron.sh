#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 11/08/2021
# Description: If our machine doesn't have much memory, then, cron can have difficulty running
# so we monitor for it and send an email to the system administrator
#######################################################################################
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


while ( [ 1 ] )
do
   if ( [ "`/bin/cat /var/log/syslog | /bin/grep -i CRON | /bin/grep fork | /bin/grep error`" != "" ] )
   then
      /bin/sed -i '/.*error.*fork.*/d' /var/log/syslog  
      ${HOME}/providerscripts/email/SendEmail.sh "CRITICAL: CRON NOT RUNNING" "It looks like the machine with IP address: `${HOME}/providerscripts/utilities/GetPublicIP.sh` is low on memory and therefore cron is not running"
   fi
   /bin/sleep 60
done
