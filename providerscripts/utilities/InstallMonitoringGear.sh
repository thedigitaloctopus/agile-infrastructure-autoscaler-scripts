#!/bin/sh
######################################################################################
# Author: Peter Winter
# Date :  07/07/2016
# Description: This will install additional software for your current cloudhost (if available)
# to enhance the monitoring capabilities of your system. You might be able to set alerts
# and so on to tell you if a machine is getting saturated for some reason
#####################################################################################
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
#######################################################################################
#######################################################################################
#set -x

CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
    /usr/bin/curl -sSL https://repos.insights.digitalocean.com/install.sh | /usr/bin/sudo bash
fi
if ( [ "${CLOUDHOST}" = "linode" ] )
then
    :
fi
if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
    :
fi
if ( [ "${CLOUDHOST}" = "vultr" ] )
then
    :
fi
