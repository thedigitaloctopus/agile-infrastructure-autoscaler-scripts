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

server_ip="${1}"
cloudhost="${2}"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
algorithm="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ALGORITHM'`"
private_server_ip="`${HOME}/providerscripts/server/GetServerPrivateIPAddressByIP.sh ${server_ip} ${cloudhost}`"

if ( [ "`/bin/echo ${server_ip} | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`" = "" ] )
then
    exit
fi

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
    #This will destroy a server with the given ip address and cleanup all the associated configuration settings
    if ( [ "${server_ip}" != "" ] )
    then
        /bin/rm ${HOME}/config/webserverips/${private_server_ip}
        /bin/rm ${HOME}/config/webserverpublicips/${server_ip}
        /bin/rm ${HOME}/config/bootedwebserverips/${private_server_ip}
        /bin/rm ${HOME}/config/webserveripcouples/*${server_ip}*

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
            /bin/rm ${HOME}/config/webserverips/${private_server_ip}
            /bin/rm ${HOME}/config/webserverpublicips/${server_ip}
            /bin/rm ${HOME}/config/bootedwebserverips/${private_server_ip}
            /bin/rm ${HOME}/config/webserveripcouples/*${serverip}*
        fi
    fi
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
    #This will destroy a server by ip address and cleanup all the associated configuration settings
    if ( [ "${server_ip}" != "" ] )
    then
        /bin/rm ${HOME}/config/webserverips/${private_server_ip}
        /bin/rm ${HOME}/config/webserverpublicips/${server_ip}
        /bin/rm ${HOME}/config/bootedwebserverips/${private_server_ip}
        /bin/rm ${HOME}/config/webserveripcouples/*${server_ip}*
        machine_id=""
        index="`/usr/local/bin/cs listVirtualMachines | /usr/bin/jq ".virtualmachine[].nic[].ipaddress,.virtualmachine[].id"  | /bin/grep -v 'null' | /bin/sed 's/\"//g' | /usr/bin/tee ${HOME}/runtime/machineIDs | /bin/grep -n ${server_ip} | /usr/bin/cut -f1 -d:`"
        nomachines="`/bin/cat ${HOME}/runtime/machineIDs | /bin/grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | /usr/bin/wc -l`"
        id_index="`/usr/bin/expr ${index} + ${nomachines}`"
        machine_id="`/bin/sed "${id_index}!d" ${HOME}/runtime/machineIDs`"

        count="0"
        while ( [ "${machine_id}" = "" ] && [ "${count}" -lt "10" ] )
        do
            /bin/echo "${0} `/bin/date` : failed in an attempt to get the machine id, trying again ...." >> ${HOME}/logs/MonitoringLog.log
            index="`/usr/local/bin/cs listVirtualMachines | /usr/bin/jq ".virtualmachine[].nic[].ipaddress,.virtualmachine[].id"  | /bin/grep -v 'null' | /bin/sed 's/\"//g' | /usr/bin/tee ${HOME}/runtime/machineIDs | /bin/grep -n ${ip} | /usr/bin/cut -f1 -d:`"
            nomachines="`/bin/cat ${HOME}/runtime/machineIDs | /bin/grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | /usr/bin/wc -l`"
            id_index="`/usr/bin/expr ${index} + ${nomachines}`"
            machine_id="`/bin/sed "${id_index}!d" ${HOME}/runtime/machineIDs`"
            count="`/usr/bin/expr ${count} + 1`"
        done

        if ( [ "${count}" -eq "10" ] )
        then
            /bin/echo "${0} `/bin/date` : failed in an attempt to get the machine id too many times, giving up ...." >> ${HOME}/logs/MonitoringLog.log
        else
            if ( [ "${machine_id}" != "" ] )
            then
                /usr/local/bin/cs destroyVirtualMachine id="${machine_id}"
                /bin/echo "${0} `/bin/date`: Destroyed a server with id ${machine_id}" >> ${HOME}/logs/MonitoringLog.log
                /bin/rm ${HOME}/config/webserverips/${private_server_ip}
                /bin/rm ${HOME}/config/webserverpublicips/${server_ip}
                /bin/rm ${HOME}/config/bootedwebserverips/${private_server_ip}
                /bin/rm ${HOME}/config/webserveripcouples/*${server_ip}*
            else
                /bin/echo "${0} `/bin/date` : Couldn't destroy a machine with ip ${ip}, giving up ...." >> ${HOME}/logs/MonitoringLog.log
            fi
        fi
    fi
fi

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
    if ( [ "${server_ip}" != "" ] )
    then
        /bin/rm ${HOME}/config/webserverips/${private_server_ip}
        /bin/rm ${HOME}/config/webserverpublicips/${server_ip}
        /bin/rm ${HOME}/config/bootedwebserverips/${private_server_ip}
        /bin/rm ${HOME}/config/webserveripcouples/*${server_ip}*
        server_to_delete=""
        server_to_delete="`${HOME}/providerscripts/server/GetServerName.sh ${server_ip} 'linode'`"
        server_id="`/usr/local/bin/linode-cli linodes list --text --label ${server_to_delete} | /bin/grep -v "id" | /usr/bin/awk '{print $1}'`"
        if ( [ "`/bin/echo ${server_to_delete} | /bin/grep 'webserver'`" != "" ] )
        then
            /usr/local/bin/linode-cli linodes shutdown ${server_id}
            /usr/local/bin/linode-cli linodes delete ${server_id}
            /bin/echo "${0} `/bin/date`: Destroyed a server with name ${server_to_delete}" >> ${HOME}/logs/MonitoringLog.log
            /bin/rm ${HOME}/config/webserverips/${private_server_ip}
            /bin/rm ${HOME}/config/webserverpublicips/${server_ip}
            /bin/rm ${HOME}/config/bootedwebserverips/${private_server_ip}
            /bin/rm ${HOME}/config/webserveripcouples/*${server_ip}*
        else
            /bin/echo "${0} `/bin/date` : This script is only for Destroying Webservers, refused to destroy server with ip: ${server_ip}" >> ${HOME}/logs/MonitoringLog.log
        fi
    fi
fi

#This will destroy a server by ip address and cleanup all associated configuration settings

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
    export VULTR_API_KEY="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'VULTRAPIKEY'`"

    if ( [ "${server_ip}" != "" ] )
    then
        /bin/rm ${HOME}/config/webserverips/${private_server_ip}
        /bin/rm ${HOME}/config/webserverpublicips/${server_ip}
        /bin/rm ${HOME}/config/bootedwebserverips/${private_server_ip}
        /bin/rm ${HOME}/config/webserveripcouples/*${server_ip}*

        /bin/sleep 1
        server_id="`/usr/bin/vultr server list | /bin/grep ${server_ip} | /usr/bin/awk '{print $1}'`"
        /bin/sleep 1

        /usr/bin/vultr server delete ${server_id} --force=true

        /bin/echo "${0} `/bin/date`: Destroyed a server with id ${server_id}" >> ${HOME}/logs/MonitoringLog.log
        /bin/rm ${HOME}/config/webserverips/${private_server_ip}
        /bin/rm ${HOME}/config/webserverpublicips/${server_ip}
        /bin/rm ${HOME}/config/bootedwebserverips/${private_server_ip}
        /bin/rm ${HOME}/config/webserveripcouples/*${server_ip}*
    else
        /bin/echo "${0} `/bin/date` : This script is only for Destroying Webservers, refused to destroy server with ip: ${server_ip}" >> ${HOME}/logs/MonitoringLog.log
    fi
fi

if ( [ -f ${HOME}/AWS ] || [ "${cloudhost}" = "aws" ] )
then
    if ( [ "${server_ip}" != "" ] )
    then
        /bin/rm ${HOME}/config/webserverips/${private_server_ip}
        /bin/rm ${HOME}/config/webserverpublicips/${server_ip}
        /bin/rm ${HOME}/config/bootedwebserverips/${private_server_ip}
        /bin/rm ${HOME}/config/webserveripcouples/*${server_ip}*

        instance_id="`/usr/bin/aws ec2 describe-instances | /usr/bin/jq '.Reservations[].Instances[] | .InstanceId + " " + .PublicIpAddress' | /bin/sed 's/\"//g' | /bin/grep ${server_ip} | /usr/bin/awk '{print $1}'`"
        /usr/bin/aws ec2 stop-instances --instance-ids ${instance_id}
        /usr/bin/aws ec2 terminate-instances --instance-ids ${instance_id}

        /bin/echo "${0} `/bin/date`: Destroyed a server with id ${instance_id}" >> ${HOME}/logs/MonitoringLog.log
        /bin/rm ${HOME}/config/webserverips/${private_server_ip}
        /bin/rm ${HOME}/config/webserverpublicips/${server_ip}
        /bin/rm ${HOME}/config/bootedwebserverips/${private_server_ip}
        /bin/rm ${HOME}/config/webserveripcouples/*${server_ip}*
    else
        /bin/echo "${0} `/bin/date` : This script is only for Destroying Webservers, refused to destroy server with ip: ${server_ip}" >> ${HOME}/logs/MonitoringLog.log
    fi
fi
