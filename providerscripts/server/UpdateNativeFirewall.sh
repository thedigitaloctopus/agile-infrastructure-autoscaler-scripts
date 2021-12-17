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

SSH_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SSHPORT'`"
DB_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DBPORT'`"

if ( [ -f ${HOME}/DROPLET ] )
then
    :
fi

if ( [ -f ${HOME}/EXOSCALE ] )
then
    if ( [ "${2}" = "" ] )
    then
        /usr/bin/exo compute security-group rule add adt --network ${1}/32 --port 1-65535
    else
        /usr/bin/exo compute security-group rule add adt --network ${1}/32 --port ${2}
    fi

    #Delete the general access rule, if it exists that we setup during the build process

    if ( [ "${2}" != "" ] && [ "${2}" != "443" ] && [ "${2}" != "80" ] )
    then
        port="${2}"
        id="`/usr/bin/exo -O json compute security-group show adt | jq --argjson tmp_port "$port" '(.ingress_rules[] | select (.start_port == $tmp_port) | select (.network == "0.0.0.0/0") | .id)' | /bin/sed 's/"//g'`"
        /usr/bin/exo  compute security-group rule delete -f adt ${id}
    fi
fi

if ( [ -f ${HOME}/LINODE ] )
then
    firewall_id="`/usr/local/bin/linode-cli --json firewalls list | jq '.[] | select (.label == "adt" ).id'`"

    ips="`/bin/ls ${HOME}/config/autoscalerip`"

    for ips in ${ips}
    do
        ip="`/bin/echo "${ip}" | /usr/bin/awk -F'.' '{print $1  "."  $2  ".0.0/32"}'`"
        ips=${ips}"${ip}:"
    done
    
    ips="`/bin/echo ${ips} | /bin/sed 's/:/ /g'`"
    
    for ip in ${ips}
    do
        rules=${rules}"{\"addresses\":{\"ipv4\":[\"${ip}\"]},\"action\":\"ACCEPT\",\"protocol\":\"TCP\",\"ports\":\"${SSH_PORT},${DB_PORT}\"},"
    done
   
    firewall_build_machine_id="`/usr/local/bin/linode-cli --json firewalls list | jq '.[] | select (.label == "adt-build-machine" ).id'`"
    build_machine_rules="`/usr/local/bin/linode-cli firewalls rules-list ${firewall_build_machine_id} | /bin/grep addresses | /usr/bin/awk -F'x' '{print $2}'`"
    
    rules=${rules},${build_machine_rules}",{\"addresses\":{\"ipv4\":[\"0.0.0.0/0\"]},\"action\":\"ACCEPT\",\"protocol\":\"TCP\",\"ports\":\"443,80,22\"},{\"addresses\":{\"ipv4\":[\"0.0.0.0/0\"]},\"action\":\"ACCEPT\",\"protocol\":\"ICMP\"}"   
    
    if ( [ "${ip}" != "" ] )
    then
       # /usr/local/bin/linode-cli firewalls rules-update --inbound  "[{\"addresses\":{\"ipv4\":[\"${ip}\"]},\"action\":\"ACCEPT\",\"protocol\":\"TCP\",\"ports\":\"${SSH_PORT},${DB_PORT}\"},{\"addresses\":{\"ipv4\":[\"0.0.0.0/0\"]},\"action\":\"ACCEPT\",\"protocol\":\"TCP\",\"ports\":\"443,80,22\"},{\"addresses\":{\"ipv4\":[\"0.0.0.0/0\"]},\"action\":\"ACCEPT\",\"protocol\":\"ICMP\"}]" ${firewall_id}
       
       /usr/local/bin/linode-cli firewalls rules-update --inbound  "[${rules}]" ${firewall_id}
    fi
    

fi

if ( [ -f ${HOME}/VULTR ] )
then
    :
fi

if ( [ -f ${HOME}/AWS ] )
then
    :
fi
