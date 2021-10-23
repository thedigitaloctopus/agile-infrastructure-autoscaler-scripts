#!/bin/sh
###########################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script will list available machine sizes based on cloudhost provider
###########################################################################################
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
############################################################################################
############################################################################################
#set -x

cloudhost=${1}
BUILDOS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOS'`"
BUILDOSVERSION="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOSVERSION'`"


if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
    /usr/local/bin/doctl compute size list | /usr/bin/awk '{print $1}' | /bin/sed -n '1!p'
fi
if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
    if ( [ "${BUILDOS}" = "ubuntu" ] )
    then
        /bin/echo "10G 50G 200G 300G 400G"

elif ( [ "${BUILDOS}" = "debian" ] )
    then
        /bin/echo "10G 50G 200G 300G 400G"
    fi
fi

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
    /bin/echo "g6-nanode-1 g6-standard-1 g6-standard-2 g6-standard-4 g6-standard-6 g6-standard-8 g6-standard-16 g6-standard-20 g6-standard-24 g6-standard-32"
fi

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
    export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
    /bin/sleep 1
    #Clonk
    #/usr/bin/vultr plans | /usr/bin/awk '{print $2}' | /bin/sed 's/NAME//g'
    #Official
    /usr/bin/vultr plans list | /bin/grep vc2 | /usr/bin/awk '{print $1}'
fi
if ( [ "${cloudhost}" = "aws" ] )
then
    # We can't get the instance types via the cli, so, lets just offer a subset manually:
    /bin/echo "t2.micro t2.small t2.medium t2.large t2.xlarge t2.2xlarge"
fi
