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

if ( [ -f ${HOME}/DROPLET ] )
then
    :
fi

if ( [ -f ${HOME}/EXOSCALE ] )
then
    if ( [ "${2}" != "" ] )
    then
        /usr/bin/exo compute security-group rule add adt --network ${1}/32 --port 1-65535
    else
        /usr/bin/exo compute security-group rule add adt --network ${1}/32 ${2}
    fi
fi

if ( [ -f ${HOME}/LINODE ] )
then
    :
fi

if ( [ -f ${HOME}/VULTR ] )
then
    :
fi

if ( [ -f ${HOME}/AWS ] )
then
    :
fi
