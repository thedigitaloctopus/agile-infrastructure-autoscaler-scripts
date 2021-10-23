#!/bin/sh
##################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script will list the server ids of machines of a particular type
###################################################################################
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
######################################################################################
######################################################################################
#set -x

instance_type="${1}"
cloudhost="${2}"

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
    serverids="`/usr/local/bin/doctl compute droplet list | /bin/grep ${instance_type} | /usr/bin/awk '{print $1}'`"
    count="0"
    while ( [ "${serverids}" = "" ] && [ "${count}" -lt "10" ] )
    do
        /bin/echo "${0} `/bin/date` : failed in an attempt to get serverids address, trying again ...." >> ${HOME}/logs/MonitoringLog.log
        serverids="`/usr/local/bin/doctl compute droplet list | /bin/grep ${instance_type} | /usr/bin/awk '{print $1}'`"
        count="`/usr/bin/expr ${count} + 1`"
        /bin/sleep 5
    done
    if ( [ "${count}" -eq "10" ] )
    then
        /bin/echo "${0} `/bin/date` : failed in an attempt to get server ids too many times, giving up ...." >> ${HOME}/logs/MonitoringLog.log
    else
        /bin/echo ${serverids}
    fi
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
    /usr/local/bin/cs listVirtualMachines | /usr/bin/jq --arg tmp_instance_type "${instance_type}" '(.virtualmachine[] | select(.displayname | contains($tmp_instance_type)) | .id)' | /bin/sed 's/"//g'
fi

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
    /usr/local/bin/linode-cli linodes list --text | /bin/grep -v id | /bin/grep "${instance_type}" | /usr/bin/awk '{print $1}'
fi

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
    export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
    /bin/sleep 1
    #Clonk
    #/usr/bin/vultr server list |  /bin/grep ${instance_type} | /usr/bin/awk '{print $1}' | /bin/sed 's/SUBID//g' | /bin/sed '/^$/d'
    #Official
    /usr/bin/vultr instance list | /bin/grep ${instance_type} | /usr/bin/awk '{print $1}' | /bin/grep ".*-.*-.*-"
fi

if ( [ -f ${HOME}/AWS ] || [ "${cloudhost}" = "aws" ] )
then
    /usr/bin/aws ec2 describe-instances --filter "Name=tag:descriptiveName,Values=*${instance_type}*" "Name=instance-state-name,Values=running" | /usr/bin/jq ".Reservations[].Instances[].InstanceId" | /bin/sed 's/\"//g'
fi





