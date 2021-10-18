#!/bin/sh
#####################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script gets the server's name based on its ip address
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
########################################################################################
########################################################################################
#set -x

server_ip="${1}"
cloudhost="${2}"

if ( [ "`/bin/echo ${server_ip} | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`" = "" ] )
then
    exit
fi

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
    name="`/usr/local/bin/doctl compute droplet list | /bin/grep ${server_ip} | /usr/bin/awk '{print $2}'`"

    count="0"
    while ( [ "${name}" = "" ] && [ "${count}" -lt "10" ] )
    do
        /bin/echo "${0} `/bin/date` : failed in an attempt to get server name, trying again ...." >> ${HOME}/logs/MonitoringLog.log
        name="`/usr/local/bin/doctl compute droplet list | /bin/grep ${server_ip} | /usr/bin/awk '{print $2}'`"
        count="`/usr/bin/expr ${count} + 1`"
        /bin/sleep 5
    done

    if ( [ "${count}" -eq "10" ] )
    then
        /bin/echo "${0} `/bin/date` : failed in an attempt to get server name too many times, giving up ...." >> ${HOME}/logs/MonitoringLog.log
    else
        /bin/echo "${name}"
    fi
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
    /usr/local/bin/cs listVirtualMachines | jq --arg tmp_ip_address "${server_ip}" '(.virtualmachine[] | select(.nic[].ipaddress == $tmp_ip_address) | .displayname)' | /bin/sed 's/"//g'
fi

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
    /usr/local/bin/linode-cli --text linodes list | /bin/grep ${server_ip} | /bin/grep -v 'id' | /usr/bin/awk '{print $2}'
fi

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
    export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
    /bin/sleep 1
    /usr/bin/vultr server list | /bin/grep ${server_ip} | /usr/bin/awk '{print $4}' | /bin/sed 's/NAME//g' | /bin/sed '/^$/d'
fi


if ( [ -f ${HOME}/AWS ] || [ "${cloudhost}" = "aws" ] )
then
    /usr/bin/aws ec2 describe-instances | /usr/bin/jq '.Reservations[].Instances[] | .PublicIpAddress + " " + .Tags[].Key + " " + .Tags[].Value' | /bin/sed 's/\"//g' | /bin/grep "${server_ip}" | /usr/bin/awk '{print $NF}'
fi



