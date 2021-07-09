#!/bin/sh
############################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script gets the number of servers of a particular type which are running
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
######################################################################################
######################################################################################
#set -x

server_type="${1}"
cloudhost="${2}"

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
    numberofservers="`/usr/local/bin/doctl compute droplet list | /bin/grep ${server_type} | /usr/bin/wc -l`"
    count="0"

    while ( [ "${numberofservers}" = "" ] && [ "${count}" -lt "10" ] )
    do
        /bin/echo "${0} `/bin/date` : failed in an attempt to get number of servers - trying again...." >> ${HOME}/logs/MonitoringLog.log
        numberofservers="`/usr/local/bin/doctl compute droplet list | /bin/grep ${server_type} | /usr/bin/wc -l`"
        count="`/usr/bin/expr ${count} + 1`"
        /bin/sleep 5
    done
    if ( [ "${count}" -eq "10" ] )
    then
        /bin/echo "${0} `/bin/date` : failed in an attempt to get number of servers too many times - giving up...." >> ${HOME}/logs/MonitoringLog.log
    else
        /bin/echo ${numberofservers}
    fi
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
    /usr/local/bin/cs listVirtualMachines | /usr/bin/jq --arg tmp_server_type "${server_type}" '(.virtualmachine[] | select(.displayname | contains($tmp_server_type)) | .id)' | /usr/bin/wc -l

#    numberofservers=""
#    numberofservers="`/usr/local/bin/cs listVirtualMachines | /usr/bin/jq ".virtualmachine[].displayname"  | /bin/grep -v 'null' | /bin/sed 's/\"//g' | /bin/grep "${server_type}\b" | /usr/bin/wc -l 2>/dev/null`"
#    count="0"

#    while ( [ "${numberofservers}" = "" ] && [ "${count}" -lt "10" ] )
 #   do
 #       /bin/echo "${0} `/bin/date` : failed in an attempt to get number of servers - trying again...." >> ${HOME}/logs/MonitoringLog.log
 #       numberofservers="`/usr/local/bin/cs listVirtualMachines | /usr/bin/jq ".virtualmachine[].displayname"  | /bin/grep -v 'null' | /bin/sed 's/\"//g' | /bin/grep "${server_type}\b" | /usr/bin/wc -l 2>/dev/null`"
  #      count="`/usr/bin/expr ${count} + 1`"
  #      /bin/sleep 5
  #  done

  #  if ( [ "${count}" -eq "10" ] )
  #  then
  #      /bin/echo "${0} `/bin/date` : failed in an attempt to get number of servers too many times - giving up...." >> ${HOME}/logs/MonitoringLog.log
  #  else
  #      /bin/echo ${numberofservers}
  #  fi
fi

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
    /usr/local/bin/linode-cli linodes list --text | /bin/grep "${server_type}" | /usr/bin/wc -l 2>/dev/null
fi

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
    export VULTR_API_KEY="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'VULTRAPIKEY'`"
    /bin/sleep 1
    server_type="`/bin/echo ${server_type} | /usr/bin/cut -c -25`"
    /usr/bin/vultr server list | /bin/grep ${server_type} | /usr/bin/awk '{print $3}' | /bin/sed 's/IP//g' | /bin/sed '/^$/d' | /usr/bin/wc -l
fi

if ( [ -f ${HOME}/AWS ] || [ "${cloudhost}" = "aws" ] )
then
    /usr/bin/aws ec2 describe-instances --filters "Name=instance-state-code,Values=16" "Name=instance-state-name,Values=running" | /usr/bin/jq ".Reservations[].Instances[].Tags[].Value" | /bin/grep ${server_type} | /usr/bin/wc -l
fi





