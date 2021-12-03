 #!/bin/bash
########################################################################################
# Author: Peter Winter
# Date  : 12/07/2021
# Description : This will apply any native firewalling if necessary
########################################################################################
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
#########################################################################################
#########################################################################################
#set -x

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
    :
fi

if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
    /usr/bin/exo compute security-group rule add adt --network ${1}/32 --port ${2}    
fi

if ( [ "${CLOUDHOST}" = "linode" ] )
then
    :
fi

if ( [ "${CLOUDHOST}" = "vultr" ] )
then
    :
fi

if ( [ "${CLOUDHOST}" = "aws" ] )
then
    :
fi
