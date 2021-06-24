#!/bin/sh
#####################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script will get a list of server ips based on a name/type
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
#########################################################################################
#########################################################################################
#set -x

server_type="$1"
cloudhost="$2"

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
    server_type="`/bin/echo ${server_type} | /bin/sed 's/\*//g'`"
    /usr/local/bin/doctl compute droplet list | /bin/grep ".*${server_type}" | /usr/bin/awk '{print $3}'
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
       #ORIGINAL /usr/local/bin/cs listVirtualMachines | /usr/bin/jq '.virtualmachine[] | .nic[].ipaddress + " " + .displayname' | /bin/grep ".*${server_type}" | /bin/sed 's/"//g' | /usr/bin/awk '{print $1}'
     display_name="${server_type}"
     ip="`/usr/local/bin/cs listVirtualMachines | /usr/bin/jq --arg tmp_display_name "${display_name}" '(.virtualmachine[] | select(.displayname == $tmp_display_name) | .publicip)' | /bin/sed 's/"//g'`"
     /bin/echo ${ip}
fi

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
    /usr/local/bin/linode-cli linodes list --text | /bin/grep ${server_type} | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | /bin/grep -v "192.168"
fi

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
    export VULTR_API_KEY="`/bin/ls ${HOME}/.ssh/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
    /bin/sleep 1
    server_type="`/bin/echo ${server_type} | /usr/bin/cut -c -25`"
    /usr/bin/vultr server list | /bin/grep ".*${server_type}" | /usr/bin/awk '{print $3}' | /bin/sed 's/IP//g' | /bin/sed '/^$/d'
fi

if ( [ -f ${HOME}/AWS ] || [ "${cloudhost}" = "aws" ] )
then
    /usr/bin/aws ec2 describe-instances --filter "Name=tag:descriptiveName,Values=${server_type}*" "Name=instance-state-name,Values=running" | /usr/bin/jq '.Reservations[].Instances[].PublicIpAddress' | /bin/sed 's/\"//g'
fi


