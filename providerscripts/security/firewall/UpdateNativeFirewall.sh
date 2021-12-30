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
   # allips="`/bin/cat ${HOME}/runtime/ipsforfirewall`"

   # if ( [ "${2}" = "" ] )
   # then
   #     /usr/bin/exo compute security-group rule add adt --network ${1}/32 --port 1-65535
   # else
   #    /usr/bin/exo compute security-group rule add adt --network ${1}/32 --port ${2}
   #fi
    
  # for ip in ${allips}
  # do
    /usr/bin/exo compute security-group rule add adt --network ${1}/32 --port ${SSH_PORT}
    /usr/bin/exo compute security-group rule add adt --network ${1}/32 --port ${DB_PORT}
    /usr/bin/exo compute security-group rule add adt --network ${1}/32 --port 22
    /usr/bin/exo compute security-group rule add adt --network ${2}/32 --port ${SSH_PORT}
    /usr/bin/exo compute security-group rule add adt --network ${2}/32 --port ${DB_PORT}
    /usr/bin/exo compute security-group rule add adt --network ${2}/32 --port 22

  # done
   id=""
   id="`/usr/bin/exo -O json compute security-group show adt | jq --argjson tmp_port "443" '(.ingress_rules[] | select (.start_port == $tmp_port) | select (.network == "0.0.0.0/0") | .id)' | /bin/sed 's/"//g'`"
   if ( [ "${id}" = "" ] )
   then
       /usr/bin/exo compute security-group rule add adt --network 0.0.0.0/0 --port 443
   fi
   
   id=""
   id="`/usr/bin/exo -O json compute security-group show adt | jq --argjson tmp_port "80" '(.ingress_rules[] | select (.start_port == $tmp_port) | select (.network == "0.0.0.0/0") | .id)' | /bin/sed 's/"//g'`"
   if ( [ "${id}" = "" ] )
   then
       /usr/bin/exo compute security-group rule add adt --network 0.0.0.0/0 --port 80
   fi


    #Delete the general access rule, if it exists, that we setup during the build process

   # if ( [ "${2}" != "" ] && [ "${2}" != "443" ] && [ "${2}" != "80" ] )
   # then
   #     port="${2}"
   #     id="`/usr/bin/exo -O json compute security-group show adt | jq --argjson tmp_port "$port" '(.ingress_rules[] | select (.start_port == $tmp_port) | select (.network == "0.0.0.0/0") | .id)' | /bin/sed 's/"//g'`"
   #     /usr/bin/exo  compute security-group rule delete -f adt ${id}
   # fi
fi

if ( [ -f ${HOME}/LINODE ] )
then

    allips="`/bin/cat ${HOME}/runtime/ipsforfirewall`"
   # allproxyips="`/bin/cat ${HOME}/runtime/ipsforproxyserversfirewall`"
   # allips="${allips} ${allproxyips}"
    linode_id="`/usr/local/bin/linode-cli --json linodes list | jq --arg tmp_ip "${1}" '.[] | select (.ipv4 | tostring | contains ($tmp_ip))'.id`"
    firewall_id="`/usr/local/bin/linode-cli --json firewalls list | jq '.[] | select (.label == "adt" ).id'`"
    
    iplist=""
    for ip in ${allips}
    do
        iplist=$iplist"\"${ip}/32\","
    done
    iplist="`/bin/echo ${iplist} | /bin/sed 's/,$//g' | /bin/sed 's/"/\\"/g'`"
    rules=${rules}"{\"addresses\":{\"ipv4\":[${iplist}]},\"action\":\"ACCEPT\",\"protocol\":\"TCP\",\"ports\":\"${SSH_PORT},${DB_PORT},22\"},"

    rules="[`/bin/echo ${rules} | /bin/sed 's/,$//g'`,"
    firewall_build_machine_id="`/usr/local/bin/linode-cli --json firewalls list | jq '.[] | select (.label == "adt-build-machine" ).id'`"
    build_machine_rules="`/usr/local/bin/linode-cli --markdown firewalls rules-list ${firewall_build_machine_id}  | /bin/grep addresses | /usr/bin/awk -F'|' '{print $2}' | /bin/sed 's/ //g' | /usr/bin/tr "'" '"'`,"
        
   . ${BUILD_HOME}/providerscripts/security/firewall/GetProxyDNSIPs.sh
                                
    if ( [ "${alldnsproxyips}" = "" ] )
    then
        standard_rules="{\"addresses\":{\"ipv4\":[${alldnsproxyips}]},\"action\":\"ACCEPT\",\"protocol\":\"TCP\",\"ports\":\"443,80\"},{\"addresses\":{\"ipv4\":[\"0.0.0.0/0\"]},\"action\":\"ACCEPT\",\"protocol\":\"ICMP\"}]"
    else
        standard_rules="{\"addresses\":{\"ipv4\":[\"0.0.0.0/0\"]},\"action\":\"ACCEPT\",\"protocol\":\"TCP\",\"ports\":\"443,80\"},{\"addresses\":{\"ipv4\":[\"0.0.0.0/0\"]},\"action\":\"ACCEPT\",\"protocol\":\"ICMP\"}]"   
    fi
    allrules="${rules}${build_machine_rules}${standard_rules}"
    /usr/local/bin/linode-cli firewalls rules-update --inbound  "${allrules}" ${firewall_id}
    
        
    if ( [ "${linode_id}" != "" ] )
    then
         /usr/local/bin/linode-cli firewalls device-create --id ${linode_id} --type linode ${firewall_id} 2>/dev/null #Redirect to null in case already added
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