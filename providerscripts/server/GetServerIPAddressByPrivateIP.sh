#!/bin/sh
##############################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script gets a machine's private ip based on its public ip
###############################################################################################
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

ip="${1}"
cloudhost="${2}"
if ( [ "`/bin/echo ${ip} | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`" = "" ] )
then
    exit
fi


if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
    ip="`/usr/local/bin/doctl compute droplet list | /bin/grep ${ip} | /usr/bin/awk '{print $3}'`"
    count="0"
    while ( [ "${ip}" = "" ] && [ "${count}" -lt "10" ] )
    do
        /bin/echo "${0} `/bin/date` : failed in an attempt to get server ip address, trying again ...." >> ${HOME}/logs/MonitoringLog.log
        ip="`/usr/local/bin/doctl compute droplet list | /bin/grep ${ip} | /usr/bin/awk '{print $3}'`"
        count="`/usr/bin/expr ${count} + 1`"
        /bin/sleep 5
    done

    if ( [ "${count}" = "10" ] )
    then
        /bin/echo "${0} `/bin/date` : failed in an attempt to get ip address too many times, giving up ...." >> ${HOME}/logs/MonitoringLog.log
    else
        /bin/echo ${ip}
    fi
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
    vmid="`/usr/local/bin/cs listNics | jq --arg tmp_private_ip "${ip}" '(.nic[] | select(.isdefault == false and .ipaddress == $tmp_private_ip) | .virtualmachineid)' | /bin/sed 's/"//g'`"
    ipaddress="`/usr/local/bin/cs listVirtualMachines | /usr/bin/jq --arg tmp_id "${vmid}" '(.virtualmachine[] | select(.id == $tmp_id) | .publicip)' | /bin/sed 's/"//g'`"
    /bin/echo ${ipaddress}
fi

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
    /usr/local/bin/linode-cli linodes list --text | /bin/grep ${ip} | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | /bin/grep -v "192.168"
fi

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
    export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
    /bin/sleep 1
    #Clonk
    #ids="`/usr/bin/vultr servers | /usr/bin/awk '{print $1}' | /bin/sed 's/SUBID//g'`"
    #for id in ${ids}
    #do
    #    /bin/sleep 1
    #    if ( [ "`/usr/bin/vultr server show ${id} | /bin/grep "Internal IP:" | /usr/bin/awk '{print $3}'`" = "${ip}" ] )
    #    then
    #        /bin/sleep 1
    #        /usr/bin/vultr server show ${id} | /bin/grep "^IP:" | /usr/bin/awk '{print $2}'
    #        break
    #    fi
    #done
    #Official
    ids="`/usr/bin/vultr instance list | /bin/grep webserver | /usr/bin/awk '{print $1}'`"

    for id in ${ids}
    do
        if ( [ "`/usr/bin/vultr instance get ${id} | /bin/grep "INTERNAL IP" | /usr/bin/awk '{print $NF}'`" = "${ip}" ] )
        then
            /usr/bin/vultr instance list | /bin/grep ${id} | /usr/bin/awk '{print $2}'
            break
        fi
    done
fi

if ( [ -f ${HOME}/AWS ] || [ "${cloudhost}" = "aws" ] )
then  
    /usr/bin/aws ec2 describe-instances --filter "Name=instance-state-name,Values=running" | /usr/bin/jq '.Reservations[].Instances[] | .PublicIpAddress + " " +.PrivateIpAddress' | /bin/sed 's/\"//g' | /bin/grep ${ip} | /usr/bin/awk '{print $2}' 
fi
