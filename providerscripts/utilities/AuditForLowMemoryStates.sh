#######################################################################################################
# Description: This script will monitor for low memory states and record them on the shared filesystem
# Author: Peter Winter
# 05/04/2017
#######################################################################################################
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
#!/bin/sh

MEMORY="`/bin/cat /proc/meminfo | grep MemFree | /usr/bin/awk '{print $2}'`"
IP="`${HOME}/providerscripts/utilities/GetIP.sh`"

if ( [ ! -d ${HOME}/config/lowmemoryaudit/autoscaler/${IP} ] )
then
    /bin/mkdir -p ${HOME}/config/lowmemoryaudit/autoscaler/${IP}
fi

if ( [ "${MEMORY}" -lt "$1" ] )
then
    /bin/echo "LOW MEMORY state detected `/bin/date` VALUE: ${MEMORY} KB remaining" >> ${HOME}/config/lowmemoryaudit/${IP}/lowmemoryaudittrail.dat
    ${HOME}/providerscripts/email/SendEmail.sh "LOW MEMORY STATE DETECTED" "LOW MEMORY state detected `/bin/date` VALUE: ${MEMORY} KB remaining on machine with ip address: `${HOME}/providerscripts/utilities/GetPublicIP.sh`"
fi
