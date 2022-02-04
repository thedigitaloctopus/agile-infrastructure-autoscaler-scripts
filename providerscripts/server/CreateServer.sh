#!/bin/sh
######################################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script spins up a machine of the specified size, name and so on on our chosen provider
# There are two distinct ways that a machine can be built.
# 1) A regular build
# 2) From pre-existing snapshots.
# It depends on whether the provider supports snapshots as to whether we can use option 2 or not
#######################################################################################################
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

os_choice="${1}"
region="${2}"
server_size="${3}"
server_name="${4}"
key_id="${5}"
cloudhost="${6}"

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
    snapshotid="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SNAPSHOTID'`"

    if ( [ "${snapshotid}" = "" ] )
    then
        ${HOME}/providerscripts/utilities/StoreConfigValue.sh 'SNAPAUTOSCALE' '0'
    fi

    #Digital ocean supports snapshots so, we test to see if we want to use them
    if ( [ "S{snapshotid}" != "" ] && [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh SNAPAUTOSCALE:1`" = "1" ] )
    then
        #If we get to here, then we are building from a snapshot and we pass the snapshotid in as the oschoice parameter
        snapshotid="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SNAPSHOTID'`"

        os_choice="${snapshotid}"
        key_id="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'KEYID'`"
        
        /usr/local/bin/doctl compute droplet create "${server_name}" --size "${server_size}" --image "${os_choice}"  --region "${region}" --ssh-keys "${key_id}" --enable-private-networking
        #We pass back a string as a token to say that we built from a snapshot
        /bin/echo "SNAPPED"
elif ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh SNAPAUTOSCALE:1`" = "0" ] )
    then
        #If we are here, then it is a regular build process
        #We know that if this fails, it will be called again so no need for checks
        /bin/echo "${0} `/bin/date`: Building a new webserver using the standard build method" >> ${HOME}/logs/MonitoringLog.log
        /usr/local/bin/doctl compute droplet create "${server_name}" --size "${server_size}" --image "${os_choice}"  --region "${region}" --ssh-keys "${key_id}" --enable-private-networking

        #Pass back a token to say it was a standard build
        /bin/echo "STANDARD"
    else
        #If we get to here, then something was somehow wrong and we were unable to build the server
        /bin/echo "${0} `/bin/date`: There was a 'missed' attempt to build a webserver" >> ${HOME}/logs/MonitoringLog.log
        /bin/echo "MISSED"
    fi
fi

template_id="${1}"
zone_id="${2}"
service_offering_id="${3}"
server_name="${4}"
key_pair="${5}"
cloudhost="${6}"

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
    #Exoscale doesn't support suitable snapshoting so, we just do a regular build
    #We know that if this fails, it will be called again so no need for checks
    /bin/echo "${0} `/bin/date`: Building a new server" >> ${HOME}/logs/MonitoringLog.log

    snapshot_id="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SNAPSHOTID'`"

    if ( [ "${snapshot_id}" = "" ] && [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh SNAPAUTOSCALE:1`" = "0" ] )
    then
        template_id="`/bin/echo "${template_id}" | /bin/sed "s/'//g"`"
        /bin/echo "STANDARD"
    else
        template_id="${snapshot_id}"
        /bin/echo "SNAPPED"
    fi

    case ${service_offering_id} in
        b6cd1ff5-3a2f-4e9d-a4d1-8988c1191fe8 ) disksize="10"
            break ;;
        b6e9d1e8-89fc-4db3-aaa4-9b4c5b1d0844 ) disksize="50"
            break ;;
        cf99499-7f59-4138-9427-a09db13af2bc ) disksize="100"
            break ;;
        350dc5ea-fe6d-42ba-b6c0-efb8b75617ad ) disksize="200"
            break ;;
        a216b0d1-370f-4e21-a0eb-3dfc6302b564 ) disksize="400"
            break ;;
    esac
   
   zone_name="`/usr/local/bin/cs listZones | jq --arg tmp_zone_id "${zone_id}" '(.zone[] | select(.id == $tmp_zone_id ) | .name)' | /bin/sed 's/"//g'`"
   network_offering_id="`/usr/local/bin/cs listNetworkOfferings | jq '(.networkoffering[] | select(.name == "PrivNet" and .state == "Enabled" and .guestiptype == "Isolated" )  | .id)' | /bin/sed 's/"//g'`"
  
   if ( [ "${network_offering_id}" != "" ] )
   then 
        private_network_id="`/usr/local/bin/cs listNetworks | jq --arg tmp_zone_id "${zone_id}" --arg tmp_zonename "${zone_name}" '(.network[] | select(.zonename == $tmp_zonename and .name == "adt" and .zoneid == $tmp_zone_id ) | .id)' | /bin/sed 's/"//g'`"
   fi
   
   while ( [ "${private_network_id}" = "" ] )
   do
       private_network_id="`/usr/local/bin/cs createNetwork displaytext="AgileDeploymentToolkit" name="adt" networkofferingid="${network_offering_id}" zoneid="${zone_id}" startip="10.0.0.10" endip="10.0.0.40" netmask="255.255.255.0" | jq '.network.id' | /bin/sed 's/"//g'`"
       /bin/sleep 5
   done

    vmid="`/usr/local/bin/cs deployVirtualMachine templateid="${template_id}" securitygroupnames="adt" zoneid="${zone_id}" serviceofferingid="${service_offering_id}" name="${server_name}" keyPair="${key_pair}" rootdisksize="${disksize}" | jq '.virtualmachine.id' | /bin/sed 's/"//g'`"
    /usr/local/bin/cs addNicToVirtualMachine networkid="${private_network_id}" virtualmachineid="${vmid}"    
fi

distribution="${1}"
location="${2}"
server_size="${3}"
server_name="`/bin/echo ${4} | /usr/bin/cut -c -32`"
key="${5}"
cloudhost="${6}"
username="${7}"
password="${8}"

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
    if ( [ "${password}" = "" ] )
    then
        password="156432wdfpdaiI"
    fi
   
    snapshot_id="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SNAPSHOTID'`"

    if ( [ "${snapshot_id}" = "" ] )
    then
        ${HOME}/providerscripts/utilities/StoreConfigValue.sh 'SNAPAUTOSCALE' '0'
    fi

    #Linode supports snapshots, so decide if we are building from a snapshot
    if ( [ "${snapshot_id}" != "" ] && [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh SNAPAUTOSCALE:1`" = "1" ] )
    then
        #If we are here, then we are building from a snapshot, so, get the snapshot id and pass it in to the server create command
        #Note 164 is a special os id to say that we are building from a snapshot and not a standard image
        snapshot_id="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SNAPSHOTID'`"

        /usr/local/bin/linode-cli linodes create --root_pass ${password} --region ${location} --image "private/${snapshot_id}" --type ${server_size} --group "Agile Deployment Toolkit" --label "${server_name}"
        server_id="`/usr/local/bin/linode-cli linodes list --text --label ${server_name} | /bin/grep -v 'id' | /usr/bin/awk '{print $1}'`"
        /usr/local/bin/linode-cli linodes ip-add ${server_id} --type ipv4 --public false
        /bin/echo "SNAPPED"
    else
        if ( [ "`/bin/echo ${distribution} | /bin/grep 'Ubuntu 20.04'`" != "" ] )
        then
            /usr/local/bin/linode-cli linodes create --root_pass ${password} --region ${location} --image linode/ubuntu20.04 --type ${server_size} --group "Agile Deployment Toolkit" --label "${server_name}"
            server_id="`/usr/local/bin/linode-cli linodes list --text --label ${server_name} | /bin/grep -v 'id' | /usr/bin/awk '{print $1}'`"
            /usr/local/bin/linode-cli linodes ip-add ${server_id} --type ipv4 --public false
        elif ( [ "`/bin/echo ${distribution} | /bin/grep 'Debian 10'`" != "" ] )
        then
            /usr/local/bin/linode-cli linodes create --root_pass ${password} --region ${location} --image linode/debian10 --type ${server_size} --group "Agile Deployment Toolkit" --label "${server_name}"
            server_id="`/usr/local/bin/linode-cli linodes list --text --label ${server_name} | /bin/grep -v 'id' | /usr/bin/awk '{print $1}'`"
            /usr/local/bin/linode-cli linodes ip-add ${server_id} --type ipv4 --public false
        elif ( [ "`/bin/echo ${distribution} | /bin/grep 'Debian 11'`" != "" ] )
        then
            /usr/local/bin/linode-cli linodes create --root_pass ${password} --region ${location} --image linode/debian11 --type ${server_size} --group "Agile Deployment Toolkit" --label "${server_name}"
            server_id="`/usr/local/bin/linode-cli linodes list --text --label ${server_name} | /bin/grep -v 'id' | /usr/bin/awk '{print $1}'`"
            /usr/local/bin/linode-cli linodes ip-add ${server_id} --type ipv4 --public false
        fi
    fi
fi

os_choice="${1}"
region="${2}"
server_plan="${3}"
server_name="${4}"
key_id="${5}"
cloudhost="${6}"

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
    export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
    snapshot_id="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SNAPSHOTID'`"

    if ( [ "${snapshot_id}" = "" ] )
    then
        ${HOME}/providerscripts/utilities/StoreConfigValue.sh 'SNAPAUTOSCALE' '0'
    fi

    #Vultr supports snapshots, so decide if we are building from a snapshot
    if ( [ "${snapshot_id}" != "" ] && [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh SNAPAUTOSCALE:1`" = "1" ] )
    then
        #If we are here, then we are building from a snapshot, so, get the snapshot id and pass it in to the server create command
        #Note 164 is a special os id to say that we are building from a snapshot and not a standard image
        snapshot_id="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SNAPSHOTID'`"
        
        #Clonk
        #/usr/bin/vultr server create --name="${server_name}" --region="${region}" --plan="${server_plan}" --os="164" --private-networking=true --ipv6=false -k ${key_id} --snapshot="${snapshot_id}"
        
       #Official
       /usr/bin/vultr instance create --label="${server_name}" --region="${region}" --plan="${server_plan}" --private-network=true --ipv6=false -s ${key_id} --snapshot="${snapshot_id}"
        
        #Pass back a token to say we built from a snapshot
        /bin/echo "SNAPPED"
    else
        #If we are here, then we are doing a regular build
        /bin/echo "${0} `/bin/date`: Building a new server" >> ${HOME}/logs/MonitoringLog.log
        /bin/sleep 1
        os_choice="`/usr/bin/vultr os list | /bin/grep "${os_choice}" | /usr/bin/awk '{print $1}'`"
        /bin/sleep 1
        #Clonk
        #/usr/bin/vultr server create --name="${server_name}"  --region=${region} --plan=${server_plan} --os=${os_choice} --private-networking=true --ipv6=false -k ${key_id}
        #if ( [ "$?" = "0" ] )
        #then
        #    /bin/sleep 120
        #fi
        #Official
        /usr/bin/vultr instance create --label="${server_name}" --region="${region}" --plan="${server_plan}" --os="${os_choice}" --private-network=true --ipv6=false -s ${key_id}
        if ( [ "$?" = "0" ] )
        then
            /bin/sleep 120
        fi
    fi
fi

os_choice="`/bin/echo ${1} | tr -d \'`"
region="${2}"
server_size="${3}"
server_name="${4}"
key_id="${5}"
cloudhost="${6}"

if ( [ -f ${HOME}/AWS ] || [ "${cloudhost}" = "aws" ] )
then
    subnet_id="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SUBNETID'`"
    vpc_id="`/usr/bin/aws ec2 describe-subnets | /usr/bin/jq '.Subnets[] | .SubnetId + " " + .VpcId' | /bin/sed 's/\"//g' | /bin/grep ${subnet_id}  | /usr/bin/awk '{print $2}'`"
 #   security_group_id="`/usr/bin/aws ec2 describe-security-groups | /usr/bin/jq '.SecurityGroups[] | .GroupName + " " + .GroupId' | /bin/grep AgileDeploymentToolkitSecurityGroup | /bin/sed 's/\"//g' | /usr/bin/awk '{print $NF}'`"

   # if ( [ "${security_group_id}" = "" ] )
 #   then
        /usr/bin/aws ec2 delete-security-group --group-name AgileDeploymentToolkitSecurityGroup
        /usr/bin/aws ec2 create-security-group --description "This is the security group for your agile deployment toolkit" --group-name "AgileDeploymentToolkitSecurityGroup" --vpc-id=${vpc_id}
        security_group_id="`/usr/bin/aws ec2 describe-security-groups | /usr/bin/jq '.SecurityGroups[] | .GroupName + " " + .GroupId' | /bin/grep AgileDeploymentToolkitSecurityGroup | /bin/sed 's/\"//g' | /usr/bin/awk '{print $NF}'`"
 #   fi

    /usr/bin/aws ec2 authorize-security-group-ingress --group-id ${security_group_id} --ip-permissions IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges='[{CidrIp=0.0.0.0/0}]'
    /usr/bin/aws ec2 authorize-security-group-ingress --group-id ${security_group_id} --ip-permissions IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges='[{CidrIp=0.0.0.0/0}]'
  
    snapshot_id="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SNAPSHOTID'`"
    
    if ( [ "${snapshot_id}" = "" ] )
    then
        ${HOME}/providerscripts/utilities/StoreConfigValue.sh 'SNAPAUTOSCALE' '0'
    fi
   
    if ( [ "${snapshot_id}" != "" ] && [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh SNAPAUTOSCALE:1`" = "1" ] )
    then
        /usr/bin/aws ec2 run-instances --count 1 --instance-type ${server_size} --key-name ${key_id} --tag-specifications "ResourceType=instance,Tags=[{Key=descriptiveName,Value=${server_name}}]" --subnet-id ${subnet_id} --security-group-ids ${security_group_id} --image-id ${snapshot_id}
        /bin/echo "SNAPPED"
    else
        /usr/bin/aws ec2 run-instances --image-id ${os_choice} --count 1 --instance-type ${server_size} --key-name ${key_id} --tag-specifications "ResourceType=instance,Tags=[{Key=descriptiveName,Value=${server_name}}]" --subnet-id ${subnet_id} --security-group-ids ${security_group_id}
    fi
fi
