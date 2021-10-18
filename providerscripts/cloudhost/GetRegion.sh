#!/bin/sh
#############################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script will get the region that the infrastructure is to be deployed to
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
#############################################################################################
#############################################################################################
#set -x

region="`/bin/echo ${1} | /usr/bin/tr '[:upper:]' '[:lower:]'`"
cloudhost=${2}

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
    /bin/echo ${1}
fi
if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
    regions="`/usr/local/bin/cs listZones | /usr/bin/jq '.zone[].name' | /bin/sed 's/"//g'`"
    if ( [ "`/bin/echo ${regions} | /bin/grep ${region}`" = "" ] )
    then
        /bin/echo "Sorry, that's not a valid region, please try again"
        read region
    fi
    /usr/local/bin/cs listZones | /usr/bin/jq '.zone[].id' > /tmp/listofregionids
    /usr/local/bin/cs listZones | /usr/bin/jq '.zone[].name' > /tmp/listofregionnames

    region_index="`/bin/cat -n /tmp/listofregionnames | /bin/grep ${region} | /usr/bin/awk '{print $1}'`"
    region="`/bin/sed "${region_index}q;d" /tmp/listofregionids`"
    /bin/echo ${region} | /bin/sed 's/"//g'
fi
if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
    /bin/echo ${1}
fi

if ( [ -f ${HOME}/VULTR ] && [ "${cloudhost}" = "vultr" ] )
then
    export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
    region="`/bin/echo ${region} | /usr/bin/tr '[:lower:]' '[:upper:]'`"
    /bin/sleep 1
    regionid="`/usr/bin/vultr regions | /bin/grep ${region} | /usr/bin/awk '{print $1}'`"

    if ( [ "${regionid}" != "" ] )
    then
        /bin/echo ${regionid}
    fi
fi

if ( [ "${cloudhost}" = "aws" ] )
then
    /bin/echo ${1}
fi




