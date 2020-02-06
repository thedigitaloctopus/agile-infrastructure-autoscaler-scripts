#!/bin/bash
#####################################################################################
# Description: This script is called from cron andsets up the firewall. It is called
# repeatedly as it knows which rules it expects to be active. If a particular rule is
# inactive, it attempts to activate it thus makeing sure the firewall is always configured
# and active for us.
# Author: Peter Winter
# Date: 12/01/2017
######################################################################################
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

lockfile=${HOME}/runtime/firewalllock.file

if ( [ ! -f ${lockfile} ] )
then
    /usr/bin/touch ${lockfile}
    ${HOME}/security/SetupFirewall.sh
    /bin/rm ${lockfile}
else
    /bin/echo "script already running"
fi
