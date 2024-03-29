#!/bin/sh
############################################################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script destroys a machine based on ip address
########################################################################################################################
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

OUT_FILE="firewall-remove-out-`/bin/date | /bin/sed 's/ //g'`"
exec 1>>${HOME}/logs/firewall/${OUT_FILE}
ERR_FILE="firewall-remove-err-`/bin/date | /bin/sed 's/ //g'`"
exec 2>>${HOME}/logs/firewall/${ERR_FILE}

server_ip="${1}"
cloudhost="${2}"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
algorithm="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ALGORITHM'`"
if ( [ "${3}" = "" ] )
then
    private_server_ip="`${HOME}/providerscripts/server/GetServerPrivateIPAddressByIP.sh ${server_ip} ${cloudhost}`"
else 
    private_server_ip="${3}"
fi
SSH_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SSHPORT'`"
DB_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DBPORT'`"


if ( [ "`/bin/echo ${server_ip} | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`" = "" ] )
then
    exit
fi

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
    #This will destroy a server with the given ip address and cleanup all the associated configuration settings
    if ( [ "${server_ip}" != "" ] )
    then
    
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverips/${private_server_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverpublicips/${server_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "bootedwebserverips/${private_server_ip}"

        server_id="`/usr/local/bin/doctl compute droplet list | /bin/grep ${server_ip} | /usr/bin/awk '{print $1}'`"

        count="0"
        while ( [ "${count}" -lt "10" ] )
        do
            /bin/echo "${0} `/bin/date` : failed in an attempt to get the server name, trying again ...." >> ${HOME}/logs/MonitoringLog.log
            /usr/local/bin/doctl -force compute droplet delete ${server_id}
            if ( [ "$?" != "0" ] )
            then
                count="`/usr/bin/expr ${count} + 1`"
                /bin/sleep 5
            else
                break
            fi
        done


        if ( [ "${count}" -eq "10" ] )
        then
            /bin/echo "${0} `/bin/date` : failed in an attempt to get the server name too many times, giving up ...." >> ${HOME}/logs/MonitoringLog.log
        else
            /bin/echo "${0} `/bin/date`: Destroyed a server with name ${server_name}" >> ${HOME}/logs/MonitoringLog.log
            
            ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverips/${private_server_ip}"
            ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverpublicips/${server_ip}"
            ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "bootedwebserverips/${private_server_ip}"
        
            /bin/touch ${HOME}/runtime/FIREWALL-REFRESH
        fi
    fi
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
    if ( [ "${server_ip}" != "" ] )
    then
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverips/${private_server_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverpublicips/${server_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "bootedwebserverips/${private_server_ip}"
        
        server_id="`/usr/local/bin/cs listVirtualMachines | jq --arg tmp_ip_address "${server_ip}" '(.virtualmachine[] | select(.nic[].ipaddress == $tmp_ip_address) | .id)' | /bin/sed 's/\"//g'`"
        /usr/local/bin/cs destroyVirtualMachine id="${server_id}"
        /bin/echo "${0} `/bin/date`: Destroyed a server with id ${server_id}" >> ${HOME}/logs/MonitoringLog.log
        
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverips/${private_server_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverpublicips/${server_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "bootedwebserverips/${private_server_ip}"

        ${HOME}/providerscripts/security/firewall/DeleteFromNativeFirewall.sh ${SSH_PORT} ${server_ip}
        ${HOME}/providerscripts/security/firewall/DeleteFromNativeFirewall.sh ${DB_PORT} ${server_ip}
        ${HOME}/providerscripts/security/firewall/DeleteFromNativeFirewall.sh ${SSH_PORT} ${private_server_ip}
        ${HOME}/providerscripts/security/firewall/DeleteFromNativeFirewall.sh ${DB_PORT} ${private_server_ip}
        ${HOME}/providerscripts/security/firewall/DeleteFromNativeFirewall.sh 22 ${server_ip}
        ${HOME}/providerscripts/security/firewall/DeleteFromNativeFirewall.sh 22 ${private_server_ip}
    fi
fi

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
    if ( [ "${server_ip}" != "" ] )
    then
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverips/${private_server_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverpublicips/${server_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "bootedwebserverips/${private_server_ip}"
        
        server_to_delete=""
        server_to_delete="`${HOME}/providerscripts/server/GetServerName.sh ${server_ip} 'linode'`"
        server_id="`/usr/local/bin/linode-cli linodes list --text --label ${server_to_delete} | /bin/grep -v "id" | /usr/bin/awk '{print $1}'`"
        /usr/local/bin/linode-cli linodes shutdown ${server_id}
        /usr/local/bin/linode-cli linodes delete ${server_id}
        /bin/echo "${0} `/bin/date`: Destroyed a server with name ${server_to_delete}" >> ${HOME}/logs/MonitoringLog.log
        
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverips/${private_server_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverpublicips/${server_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "bootedwebserverips/${private_server_ip}"
        
        ${HOME}/providerscripts/security/firewall/DeleteFromNativeFirewall.sh ${SSH_PORT} ${server_ip}
        ${HOME}/providerscripts/security/firewall/DeleteFromNativeFirewall.sh ${DB_PORT} ${server_ip}
        ${HOME}/providerscripts/security/firewall/DeleteFromNativeFirewall.sh ${SSH_PORT} ${private_server_ip}
        ${HOME}/providerscripts/security/firewall/DeleteFromNativeFirewall.sh ${DB_PORT} ${private_server_ip}
        ${HOME}/providerscripts/security/firewall/DeleteFromNativeFirewall.sh 22 ${server_ip}
        ${HOME}/providerscripts/security/firewall/DeleteFromNativeFirewall.sh 22 ${private_server_ip}
    fi
fi

#This will destroy a server by ip address and cleanup all associated configuration settings

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
    export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"

    if ( [ "${server_ip}" != "" ] )
    then
    
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverips/${private_server_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverpublicips/${server_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "bootedwebserverips/${private_server_ip}"

        /bin/sleep 1
        #Clonk
        #server_id="`/usr/bin/vultr server list | /bin/grep ${server_ip} | /usr/bin/awk '{print $1}'`"
        #Official
        server_id="`/usr/bin/vultr instance list | /bin/grep ${server_ip} | /usr/bin/awk '{print $1}'`"
        
        /bin/sleep 1

        #Clonk
        /usr/bin/vultr server delete ${server_id} --force=true
        #Official   
        /usr/bin/vultr instance delete ${server_id}

        /bin/echo "${0} `/bin/date`: Destroyed a server with id ${server_id}" >> ${HOME}/logs/MonitoringLog.log
        
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverips/${private_server_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverpublicips/${server_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "bootedwebserverips/${private_server_ip}"
        
        ${HOME}/providerscripts/security/firewall/DeleteFromNativeFirewall.sh ${server_ip}
        ${HOME}/providerscripts/security/firewall/DeleteFromNativeFirewall.sh ${private_server_ip}
    fi
fi

if ( [ -f ${HOME}/AWS ] || [ "${cloudhost}" = "aws" ] )
then
    if ( [ "${server_ip}" != "" ] )
    then
    
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverips/${private_server_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverpublicips/${server_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "bootedwebserverips/${private_server_ip}"

        #Instance initiated shutdown is set to "terminate" so the machine might already be gone if it has done a shutdown, but, if not, make sure
        instance_id="`/usr/bin/aws ec2 describe-instances | /usr/bin/jq '.Reservations[].Instances[] | .InstanceId + " " + .PublicIpAddress' | /bin/sed 's/\"//g' | /bin/grep ${server_ip} | /usr/bin/awk '{print $1}'`"
        if ( [ "${instance_id}" != "" ] )
        then
            /usr/bin/aws ec2 stop-instances --instance-ids ${instance_id}
            /usr/bin/aws ec2 terminate-instances --instance-ids ${instance_id}
        fi
        /bin/echo "${0} `/bin/date`: Destroyed a server with id ${instance_id}" >> ${HOME}/logs/MonitoringLog.log
        
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverips/${private_server_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverpublicips/${server_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "bootedwebserverips/${private_server_ip}"

    fi
fi
