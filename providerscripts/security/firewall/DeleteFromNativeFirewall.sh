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
set -x

export HOME=`/bin/cat /home/homedir.dat`


if ( [ -f ${HOME}/DROPLET ] )
then
    :
fi

if ( [ -f ${HOME}/EXOSCALE ] )
then
    if ( [ "${1}" != "" ]  && [ "${2}" != "" ] )
    then
        port="${1}"
        ip="${2}"
        id="`/usr/bin/exo -O json compute security-group show adt | jq --argjson tmp_port "$port" --arg tmp_ip "${ip}/32" '(.ingress_rules[] | select (.start_port == $tmp_port) | select (.network == $tmp_ip) | .id)' | /bin/sed 's/"//g'`"
        /usr/bin/exo  compute security-group rule delete -f adt ${id}
    fi
fi

if ( [ -f ${HOME}/LINODE ] )
then
    :
fi

if ( [ -f ${HOME}/VULTR ] )
then
   while ( [ -f ${HOME}/config/FIREWALL-UPDATING ] )
   do
       /bin/sleep 10
   done
       
   /bin/touch ${HOME}/config/FIREWALL-UPDATING
   
   export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
   firewall_id="`/usr/bin/vultr firewall group list | /usr/bin/tail -n +2 | /bin/grep -w 'adt$' | /usr/bin/awk '{print $1}'`"
           
   if ( [ "${firewall_id}" != "" ] )
   do
       rule_nos="`/usr/bin/vultr firewall rule list ${firewall_id} | /bin/grep ${1} | /bin/sed '1d' | sed -n '/======/q;p' | /usr/bin/awk '{print $1}' | /usr/bin/tr '\n' ' '`"
       for rule_no in ${rule_nos}
       do
           /usr/bin/vultr firewall rule delete ${firewall_id} ${rule_no}
       done
   done
   
   /bin/rm ${HOME}/config/FIREWALL-UPDATING
fi

if ( [ -f ${HOME}/AWS ] )
then
    :
fi
