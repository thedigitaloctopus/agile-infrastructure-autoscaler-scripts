#####################################################################################################
#Description: This script will monitor for low CPU states and record them on the shared filesystem
#Author : Peter Winter
#Date: 05/04/2017
######################################################################################################
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

CPU="`/usr/bin/mpstat | /usr/bin/awk '{print $NF}' | grep -v idle | grep -v CPU | /bin/sed '/^$/d' | /bin/sed 's/\...//'`"
IP="`${HOME}/providerscripts/utilities/GetIP.sh`"

if ( [ ! -d ${HOME}/config/lowcpuaudit/autoscaler/${IP} ] )
then
    /bin/mkdir -p ${HOME}/config/lowcpuaudit/autoscaler/${IP}
fi

if ( [ "${CPU}" -lt "10" ] )
then
    /bin/echo "LOW CPU state detected `/bin/date` VALUE: ${CPU}% remaining" >> ${HOME}/config/lowcpuaudit/${IP}/lowcpuaudittrail.dat
    ${HOME}/providerscripts/email/SendEmail.sh "LOW CPU STATE DETECTED" "LOW CPU state detected `/bin/date` VALUE: ${CPU}% remaining on machine with ip address: `${HOME}/providerscripts/utilities/GetPublicIP.sh`"
fi
