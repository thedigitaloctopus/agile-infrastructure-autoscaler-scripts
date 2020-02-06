#!/bin/sh
#############################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script lists all the available regions for the current cloudhost provider
#############################################################################################
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
###########################################################################################
###########################################################################################
#set -x

cloudhost=${1}

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
    /usr/local/bin/doctl compute region list | /usr/bin/awk '{print $1}' | /bin/sed -n '1!p'
fi
if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
    /usr/local/bin/cs listZones | /usr/bin/jq '.zone[].name' | /bin/sed 's/"//g'
fi
if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
    /usr/local/bin/linode-cli  --text regions list | /bin/grep -v "^id" | /usr/bin/awk '{print $1}'
fi
if (  [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
    export VULTR_API_KEY="`/bin/ls ${HOME}/.ssh/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
    /bin/sleep 1
    /usr/bin/vultr regions | /usr/bin/awk '{print $NF}' | /bin/sed 's/CODE//g'
fi
if ( [ "${cloudhost}" = "aws" ] )
then
    /usr/bin/aws ec2 describe-regions | /usr/bin/jq '.Regions[].RegionName' | /bin/sed 's/"//g'
fi



