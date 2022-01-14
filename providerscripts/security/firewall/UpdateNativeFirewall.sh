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

if ( [ ! -d ${HOME}/logs/firewall ] )
then
    /bin/mkdir -p ${HOME}/logs/firewall
fi

OUT_FILE="firewall-build-out-`/bin/date | /bin/sed 's/ //g'`"
exec 1>>${HOME}/logs/firewall/${OUT_FILE}
ERR_FILE="firewall-build-err-`/bin/date | /bin/sed 's/ //g'`"
exec 2>>${HOME}/logs/firewall/${ERR_FILE}

SSH_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SSHPORT'`"
DB_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DBPORT'`"

if ( [ ! -f ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
   exit
fi

if ( [ -f ${HOME}/DROPLET ] )
then
    allips="`/bin/cat ${HOME}/runtime/ipsforfirewall`"

  #  if ( [ "${1}" != "" ] )
  #  then
  #      droplet_id="`/usr/local/bin/doctl compute droplet list | /bin/grep "${1}" | /usr/bin/awk '{print $1}' | /bin/sed 's/ //g'`"    
  #  else
  #      droplet_id="`/usr/local/bin/doctl compute droplet list | /usr/bin/awk '{print $1}' | /usr/bin/tail -n +2`"    
  #      droplet_id="`/bin/echo ${droplet_id} | /bin/sed 's/ /,/g'`"
  #  fi
  
    droplet_ids="`/usr/local/bin/doctl compute droplet list | /bin/grep 'autoscaler' | /usr/bin/awk '{print $1}' | /bin/sed 's/ //g'`"    
    droplet_ids="${droplet_ids} `/usr/local/bin/doctl compute droplet list | /bin/grep 'webserver' | /usr/bin/awk '{print $1}' | /bin/sed 's/ //g'`"    
    droplet_ids="${droplet_ids} `/usr/local/bin/doctl compute droplet list | /bin/grep 'database' | /usr/bin/awk '{print $1}' | /bin/sed 's/ //g'`" 

    droplet_ids="`/bin/echo ${droplet_ids} | /bin/sed 's/ $//g' | /bin/sed 's/ /,/g'`"

    firewall_id="`/usr/local/bin/doctl -o json compute firewall list | jq '.[] | select (.name == "adt" ).id' | /bin/sed 's/"//g'`"
    
    autoscaling_firewall_id="`/usr/local/bin/doctl -o json compute firewall list | jq '.[] | select (.name == "adt-autoscaling" ).id' | /bin/sed 's/"//g'`"
    
    iplist=""
    for ip in ${allips}
    do
        iplist=$iplist"\"${ip}/32\" "
    done

    iplist="`/bin/echo ${iplist} | /bin/sed 's/"/\\"/g'`"
    
    for ip in ${iplist}
    do
        rules=${rules}"protocol:tcp,ports:${SSH_PORT},address:${ip} "    
        rules=${rules}"protocol:tcp,ports:${DB_PORT},address:${ip} "   
        autoscalingrules=${autoscalingrules}"protocol:tcp,ports:22,address:${ip} " 
    done 

    rules="`/bin/echo ${rules} | /bin/sed 's/"//g'`"
    autoscalingrules="`/bin/echo ${autoscalingrules} | /bin/sed 's/"//g'`"

    if ( [ "${firewall_id}" = "" ] )
    then
        /usr/local/bin/doctl compute firewall create --name "adt" --outbound-rules "protocol:tcp,ports:all,address:0.0.0.0/0 protocol:udp,ports:all,address:0.0.0.0/0 protocol:icmp,address:0.0.0.0/0"
        firewall_id="`/usr/local/bin/doctl -o json compute firewall list | jq '.[] | select (.name == "adt" ).id' | /bin/sed 's/"//g'`"
    else
        /bin/echo "y" | /usr/local/bin/doctl compute firewall delete ${firewall_id}
        /usr/local/bin/doctl compute firewall create --name "adt" --outbound-rules "protocol:tcp,ports:all,address:0.0.0.0/0 protocol:udp,ports:all,address:0.0.0.0/0 protocol:icmp,address:0.0.0.0/0"
        firewall_id="`/usr/local/bin/doctl -o json compute firewall list | jq '.[] | select (.name == "adt" ).id' | /bin/sed 's/"//g'`"
    fi
    
    if ( [ "${autoscaling_firewall_id}" = "" ] )
    then
        /usr/local/bin/doctl compute firewall create --name "adt-autoscaling" --outbound-rules "protocol:tcp,ports:all,address:0.0.0.0/0 protocol:udp,ports:all,address:0.0.0.0/0 protocol:icmp,address:0.0.0.0/0"
        autoscaling_firewall_id="`/usr/local/bin/doctl -o json compute firewall list | jq '.[] | select (.name == "adt-autoscaling" ).id' | /bin/sed 's/"//g'`"
    else
        /bin/echo "y" | /usr/local/bin/doctl compute firewall delete ${autoscaling_firewall_id}
        /usr/local/bin/doctl compute firewall create --name "adt-autoscaling" --outbound-rules "protocol:tcp,ports:all,address:0.0.0.0/0 protocol:udp,ports:all,address:0.0.0.0/0 protocol:icmp,address:0.0.0.0/0"
        autoscaling_firewall_id="`/usr/local/bin/doctl -o json compute firewall list | jq '.[] | select (.name == "adt-autoscaling" ).id' | /bin/sed 's/"//g'`"
    fi

    /usr/local/bin/doctl compute firewall add-rules ${firewall_id} --inbound-rules "${rules}"
    /usr/local/bin/doctl compute firewall add-droplets ${firewall_id} --droplet-ids ${droplet_ids}
    
    /usr/local/bin/doctl compute firewall add-rules ${autoscaling_firewall_id} --inbound-rules "${autoscalingrules}"
    /usr/local/bin/doctl compute firewall add-droplets ${autoscaling_firewall_id} --droplet-ids ${droplet_ids}

   . ${HOME}/providerscripts/security/firewall/GetProxyDNSIPs.sh
   
   standard_rules=""

    if ( [ "${alldnsproxyips}" != "" ] )
    then
        for ip in ${alldnsproxyips}
        do
            standard_rules=${standard_rules}"protocol:tcp,ports:443,address:${ip} "    
        #    standard_rules=${standard_rules}"protocol:tcp,ports:80,address:${ip} "    
        done
    else
        standard_rules=${standard_rules}"protocol:tcp,ports:443,address:0.0.0.0/0 "    
        #standard_rules=${standard_rules}"protocol:tcp,ports:80,address:0.0.0.0/0 "    
    fi
    
    standard_rules=${standard_rules}"protocol:icmp,address:0.0.0.0/0 "    
    standard_rules="`/bin/echo ${standard_rules} | /bin/sed 's/\"//g'`"
 
    webserver_firewall_id="`/usr/local/bin/doctl -o json compute firewall list | jq '.[] | select (.name == "adt-webserver-machines" ).id' | /bin/sed 's/"//g'`"
    
    if ( [ "${webserver_firewall_id}" = "" ] )
    then
        /usr/local/bin/doctl compute firewall create --name "adt-webserver-machines" --outbound-rules "protocol:tcp,ports:all,address:0.0.0.0/0 protocol:udp,ports:all,address:0.0.0.0/0 protocol:icmp,address:0.0.0.0/0"
        webserver_firewall_id="`/usr/local/bin/doctl -o json compute firewall list | jq '.[] | select (.name == "adt-webserver-machines" ).id' | /bin/sed 's/"//g'`"
    fi
    
    droplet_ids="`/usr/local/bin/doctl compute droplet list | /bin/grep 'webserver' | /usr/bin/awk '{print $1}' | /bin/sed 's/ //g' | /usr/bin/tr '\n' ' '`"   
    
    droplet_ids="`/bin/echo ${droplet_ids} | /bin/sed 's/ $//g' | /bin/sed 's/ /,/g'`"


    /usr/local/bin/doctl compute firewall add-rules ${webserver_firewall_id} --inbound-rules "${standard_rules}"
    /usr/local/bin/doctl compute firewall add-droplets ${webserver_firewall_id} --droplet-ids ${droplet_ids}
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
        
   . ${HOME}/providerscripts/security/firewall/GetProxyDNSIPs.sh
                                
    if ( [ "${alldnsproxyips}" != "" ] )
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
#############################################################################################################################################################
###THERE IS A BASIC CODE OUTLINE HERE, BUT I DIDN'T REALISE THAT VULTR ONLY SUPPORTS A VPS MACHINE BEING ATTACHED TO 1 FIREWALL WHICH IS NO GOOD FOR MY NEEDS
###SO, NATIVE FIREWALL PROTECTION IS NOT SUPPORTED ON VULTR SERVER MACHINES, ALTHOUGH IT IS STILL USED ON THE BUILD MACHINE
#############################################################################################################################################################
#  export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
#  allips="`/bin/cat ${HOME}/runtime/ipsforfirewall`"
#
#    autoscaler_ips="`/usr/bin/vultr instance list | /bin/grep autoscaler | /usr/bin/awk '{print $2}'`"
#    autoscaling_firewall_id="`/usr/bin/vultr firewall group list | /usr/bin/tail -n +2 | /bin/grep -w 'adt-autoscaling' | /usr/bin/awk '{print $1}'`"
#
#    if ( [ "${autoscaling_firewall_id}" = "" ] )
#    then
#        autoscaling_firewall_id="`/usr/bin/vultr firewall group create | /usr/bin/tail -n +2 | /usr/bin/awk '{print $1}'`"  
#    else
#        /usr/bin/vultr firewall group delete ${autoscaling_firewall_id}
#        autoscaling_firewall_id="`/usr/bin/vultr firewall group create | /usr/bin/tail -n +2 | /usr/bin/awk '{print $1}'`"  
#    fi
#
#    /usr/bin/vultr firewall group update ${autoscaling_firewall_id} "adt-autoscaling"
#   
#    for ip in ${autoscaler_ips}
#    do
#        /usr/bin/vultr firewall rule create --id ${autoscaling_firewall_id} --port 22 --protocol tcp --size 32 --type v4 -s ${ip}/32
#    done
#
#    webserver_ids="`/usr/bin/vultr instance list | /bin/grep webserver | /usr/bin/awk '{print $1}' | /usr/bin/tr '\n' ' '`"
#
#   if ( [ "${webserver_ids}" != "" ] )
#   then
#       for webserver_id in ${webserver_ids}
#       do
#           /usr/bin/vultr instance update-firewall-group -f ${autoscaling_firewall_id} -i ${webserver_id}
#       done
#   fi
#
#   firewall_id="`/usr/bin/vultr firewall group list | /usr/bin/tail -n +2 | /bin/grep -w 'adt$' | /usr/bin/awk '{print $1}'`"
#
#    if ( [ "${firewall_id}" = "" ] )
#    then
#        firewall_id="`/usr/bin/vultr firewall group create | /usr/bin/tail -n +2 | /usr/bin/awk '{print $1}'`"
#    else
#        /usr/bin/vultr firewall group delete ${firewall_id}
#        firewall_id="`/usr/bin/vultr firewall group create | /usr/bin/tail -n +2 | /usr/bin/awk '{print $1}'`"
#    fi
#
#    /usr/bin/vultr firewall group update ${firewall_id} "adt"
#
#    autoscaler_ips="`/usr/bin/vultr instance list | /bin/grep autoscaler | /usr/bin/awk '{print $2}' | /usr/bin/tr '\n' ' '`"
#    webserver_ips="`/usr/bin/vultr instance list | /bin/grep webserver | /usr/bin/awk '{print $2}' | /usr/bin/tr '\n' ' '`"
#    database_ips="`/usr/bin/vultr instance list | /bin/grep database | /usr/bin/awk '{print $2}' | /usr/bin/tr '\n' ' '`"
#    machine_ips="${autoscaler_ips} ${webserver_ips} ${database_ips}"
#
#    firewall_build_machine_id="`/usr/bin/vultr firewall group list | /usr/bin/tail -n +2 | /bin/grep -w 'adt-build-machine' | /usr/bin/awk '{print $1}'`"
#    build_machine_rules="`/usr/bin/vultr firewall rule list ${firewall_build_machine_id} | /bin/grep -v icmp | /usr/bin/tail -n +2 | /usr/bin/head -n -2 | /usr/bin/awk 'BEGIN { OFS = ":"; } {print $4,$5}' | /bin/sed '/^:$/d'`"
#
#    for ip in ${machine_ips}
#    do
#       for rule in ${build_machine_rules}  
#       do
#          port="`/bin/echo ${rule} | /usr/bin/awk -F':' '{print $1}'`"
#          ip="`/bin/echo ${rule} | /usr/bin/awk -F':' '{print $2}'`"
#          /usr/bin/vultr firewall rule create --id ${firewall_id} --port ${port} --protocol tcp --size 32 --type v4 -s ${ip}
#       done
#
#       /usr/bin/vultr firewall rule create --id ${firewall_id} --port ${SSH_PORT} --protocol tcp --size 32 --type v4 -s ${ip}
#       /usr/bin/vultr firewall rule create --id ${firewall_id} --port ${DB_PORT} --protocol tcp --size 32 --type v4 -s ${ip}
#   done
#      
#   . ${HOME}/providerscripts/security/firewall/GetProxyDNSIPs.sh
#   
#    webserver_firewall_id="`/usr/bin/vultr firewall group list | /usr/bin/tail -n +2 | /bin/grep -w 'adt-webserver-machines' | /usr/bin/awk '{print $1}'`"
#
#    if ( [ "${webserver_firewall_id}" = "" ] )
#    then
#        webserver_firewall_id="`/usr/bin/vultr firewall group create | /usr/bin/tail -n +2 | /usr/bin/awk '{print $1}'`"  
#    else
#        /usr/bin/vultr firewall group delete ${webserver_firewall_id}
#        webserver_firewall_id="`/usr/bin/vultr firewall group create | /usr/bin/tail -n +2 | /usr/bin/awk '{print $1}'`"  
#    fi
#
#    /usr/bin/vultr firewall group update ${webserver_firewall_id} "adt-webserver-machines"
#
#    if ( [ "${alldnsproxyips}" = "" ] )
#    then
#       /usr/bin/vultr firewall rule create --id ${webserver_firewall_id} --port 443 --protocol tcp --size 32 --type v4 -s 0.0.0.0/0
#       /usr/bin/vultr firewall rule create --id ${webserver_firewall_id} --port 80 --protocol tcp --size 32 --type v4 -s 0.0.0.0/0
#       /usr/bin/vultr firewall rule create --id ${firewall_id} --protocol icmp --size 32 --type v4 -s 0.0.0.0/0
#    else 
#       for ip in ${alldnsproxyips}
#       do
#           /usr/bin/vultr firewall rule create --id ${webserver_firewall_id} --port 443 --protocol tcp --size 32 --type v4 -s ${ip}
#           /usr/bin/vultr firewall rule create --id ${webserver_firewall_id} --port 80 --protocol tcp --size 32 --type v4 -s ${ip}
#       done
#       /usr/bin/vultr firewall rule create --id ${firewall_id} --protocol icmp --size 32 --type v4 -s 0.0.0.0/0
#    fi
#
#    autoscaler_ids="`/usr/bin/vultr instance list | /bin/grep autoscaler | /usr/bin/awk '{print $1}' | /usr/bin/tr '\n' ' '`"
#    webserver_ids="`/usr/bin/vultr instance list | /bin/grep webserver | /usr/bin/awk '{print $1}' | /usr/bin/tr '\n' ' '`"
#    database_ids="`/usr/bin/vultr instance list | /bin/grep database | /usr/bin/awk '{print $1}' | /usr/bin/tr '\n' ' '`"
#    machine_ids="${autoscaler_ids} ${webserver_ids} ${database_ids}"
#
#    for webserver_id in ${webserver_ids}
#    do
#        /usr/bin/vultr instance update-firewall-group -f ${autoscaling_firewall_id} -i ${webserver_id}
#        /usr/bin/vultr instance update-firewall-group -f ${webserver_firewall_id} -i ${webserver_id}
#    done
#
#    for machine_id in ${machine_ids}
#    do
#        /usr/bin/vultr instance update-firewall-group -f ${firewall_id} -i ${machine_id}
#    done
#

fi

if ( [ -f ${HOME}/AWS ] )
then
    :
fi
