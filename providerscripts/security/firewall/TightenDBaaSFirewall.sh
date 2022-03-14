#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 13/06/2021
# Description : This will tighten the DBaaS firewall so that the DBaaS system is only
# accessible to IP addresses that we control. 
#######################################################################################
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

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
    dbaas="`${HOME}/providerscripts/utilities/ExtractConfigValues.sh "DATABASEDBaaSINSTALLATIONTYPE" "stripped"`"
  
    cluster_id="`/bin/echo ${dbaas} | /usr/bin/awk '{print $NF}'`"

    if ( [ "`/usr/local/bin/doctl databases list | /bin/grep ${cluster_id}`" != "" ] )
    then
        /usr/local/bin/doctl databases firewalls append ${cluster_id} --rule ip_addr:${ip}
    fi
fi

if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
    dbaas="`${HOME}/providerscripts/utilities/ExtractConfigValues.sh "DATABASEDBaaSINSTALLATIONTYPE" "stripped"`"
    zone="`/bin/echo ${dbaas} | /usr/bin/awk '{print $4}'`"
    database_name="`/bin/echo ${dbaas} | /usr/bin/awk '{print $6}'`"
    
    autoscaler_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh autoscaler ${CLOUDHOST}`"
    webserver_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh webserver ${CLOUDHOST}`"
    database_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh database ${CLOUDHOST}`"
    ips="${autoscaler_ips} ${webserver_ips} ${database_ips}"
    #ips="`/bin/ls ${HOME}/config/autoscalerpublicip`"
    #ips="${ips} `/bin/ls ${HOME}/config/webserverpublicips`"
    #ips="${ips} `/bin/ls ${HOME}/config/databasepublicip`"
    #ips="${ips} `/bin/ls ${HOME}/config/buildclientip`"
    ips="`/bin/echo ${ips} | /bin/sed 's/  / /g' | /bin/tr ' ' ',' | /bin/sed 's/,$//g'`"
    
    if ( [ "`/bin/echo ${dbaas} | /bin/grep ' pg '`" != "" ] )
    then
        /usr/bin/exo dbaas update -z ${zone}  ${database_name} --pg-ip-filter=${ips}
    elif ( [ "`/bin/echo ${dbaas} | /bin/grep ' mysql '`" != "" ] )
    then
        /usr/bin/exo dbaas update -z ${zone}  ${database_name} --mysql-ip-filter=${ips}
    fi
fi

if ( [ "${CLOUDHOST}" = "linode" ] )
then
    token="`/bin/grep token ${HOME}/.config/linode-cli | /usr/bin/awk '{print $NF}'`"
    label="`${HOME}/providerscripts/utilities/ExtractConfigValues.sh 'DATABASEDBaaSINSTALLATIONTYPE' | /usr/bin/awk -F':' '{print $7}'`"
    DATABASE_ID="`/usr/local/bin/linode-cli --json databases mysql-list | jq ".[] | select(.[\\"label\\"] | contains (\\"${label}\\")) | .id"`"
    autoscaler_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh autoscaler ${CLOUDHOST}`"
    webserver_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh webserver ${CLOUDHOST}`"
    database_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh database ${CLOUDHOST}`"

    ips="${autoscaler_ips} ${webserver_ips} ${database_ips}"

    for ip in ${ips}
    do
        newips=${newips}"\"${ip}/32\","
    done
    
    ips="`/bin/echo ${newips} | /bin/sed 's/,$//g'`"

    /usr/bin/curl -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" -X PUT -d "{ \"allow_list\": [ ${ips} ] }" https://api.linode.com/v4beta/databases/mysql/instances/${DATABASE_ID}

fi
