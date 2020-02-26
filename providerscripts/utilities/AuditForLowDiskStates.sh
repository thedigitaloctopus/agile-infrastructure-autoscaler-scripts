######################################################################################################
# Description: This script monitors for low disk space and records it on the shared file system
# Author: Peter Winter
# Date: 05/04/2017
########################################################################################################
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

DISK="`/bin/df -k | grep "/$" | awk '{print $(NF-1)}' | /bin/sed 's/%//'`"
IP="`${HOME}/providerscripts/utilities/GetIP.sh`"

if ( [ ! -d ${HOME}/config/lowdiskaudit/autoscaler/${IP} ] )
then
    /bin/mkdir -p ${HOME}/config/lowdiskaudit/autoscaler/${IP}
fi

if ( [ "${DISK}" -gt "$1" ] )
then
    /bin/echo "LOW DISK state detected `/bin/date` VALUE: ${DISK} % in use" >> ${HOME}/config/lowdiskaudit/${IP}/lowdiskaudittrail.dat
    ${HOME}/providerscripts/email/SendEmail.sh "LOW DISK STATE DETECTED" "LOW DISK state detected `/bin/date` VALUE: ${DISK} % in use on machine with ip address: `${HOME}/providerscripts/utilities/GetPublicIP.sh`"
fi
