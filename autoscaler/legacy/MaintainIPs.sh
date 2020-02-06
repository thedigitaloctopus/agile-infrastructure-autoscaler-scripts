#!/bin/sh
##################################################################################################################################
# Description: This is the wrapper script, called from cron to coordinate the IP address manipulation for the webservers
# Author: Peter Winter
# Date: 12/01/2017
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

#Only if the toolkit is fully installed...
if ( [ -f  ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
    #Get the list of ip addresses which are in the DNS system but are not actually active
    ips="`${HOME}/autoscaler/DNSButNotActiveIPs.sh`"
    #Remove these ips from the DNS system
    for ip in ${ips}
    do
        ${HOME}/autoscaler/RemoveIPFromDNS.sh ${ip}
    done
    #Get a list of ip addresses which are active but are not in the DNS system
    ips="`${HOME}/autoscaler/ActiveButNotDNSIPs.sh`"
    for ip in ${ips}
    do
        #Add the active webservers to the DNS system
        ${HOME}/autoscaler/AddIPToDNS.sh ${ip}
    done
fi


