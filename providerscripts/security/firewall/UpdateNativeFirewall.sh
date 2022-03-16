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
BUILD_CLIENT_IP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDCLIENTIP'`"
CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"
ENABLE_EFS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ENABLEEFS'`"
DATABASE_INSTALLATION_TYPE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DATABASEINSTALLATIONTYPE'`"


if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "INSTALLEDSUCCESSFULLY"`" = "0" ] )
then
   exit
fi

if ( [ -f ${HOME}/DROPLET ] )
then    
    if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "FIREWALL-UPDATING"`" = "0" ] )
    then
       
        autoscaler_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh autoscaler ${CLOUDHOST}`"
        webserver_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh webserver ${CLOUDHOST}`"
        database_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh database ${CLOUDHOST}`"
        machine_ips="${autoscaler_ips} ${webserver_ips} ${database_ips}"
    
        autoscaler_private_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh autoscaler ${CLOUDHOST}`"
        webserver_private_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh webserver ${CLOUDHOST}`"
        database_private_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh database ${CLOUDHOST}`"
        machine_private_ips="${autoscaler_private_ips} ${webserver_private_ips} ${database_private_ips}"
    
        allips="${machine_ips} ${machine_private_ips} ${BUILD_CLIENT_IP}"
  
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
           done
       else
           standard_rules=${standard_rules}"protocol:tcp,ports:443,address:0.0.0.0/0 "    
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
       
       ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "FIREWALL-UPDATING"
   fi
fi

if ( [ -f ${HOME}/EXOSCALE ] )
then   
    if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "FIREWALL-UPDATING"`" = "0" ] )
    then
       # /bin/touch ${HOME}/config/FIREWALL-UPDATING
       
        autoscaler_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh autoscaler ${CLOUDHOST}`"
        webserver_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh webserver ${CLOUDHOST}`"
        database_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh database ${CLOUDHOST}`"
        machine_ips="${autoscaler_ips} ${webserver_ips} ${database_ips}"
    
        autoscaler_private_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh autoscaler ${CLOUDHOST}`"
        webserver_private_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh webserver ${CLOUDHOST}`"
        database_private_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh database ${CLOUDHOST}`"
        machine_private_ips="${autoscaler_private_ips} ${webserver_private_ips} ${database_private_ips}"
    
        allips="${machine_ips} ${machine_private_ips} ${BUILD_CLIENT_IP}"

        for ip in ${allips}
        do
           /usr/bin/exo compute security-group rule add adt --network ${ip}/32 --port ${SSH_PORT} 2>/dev/null
           /usr/bin/exo compute security-group rule add adt --network ${ip}/32 --port ${DB_PORT} 2>/dev/null
           /usr/bin/exo compute security-group rule add adt --network ${ip}/32 --port 22 2>/dev/null
       done

       . ${HOME}/providerscripts/security/firewall/GetProxyDNSIPs.sh
                                
       if ( [ "${alldnsproxyips}" != "" ] )
       then
           for ip in ${alldnsproxyips}
           do
               /usr/bin/exo compute security-group rule add adt --network ${ip} --port 443
           done
       else
           /usr/bin/exo compute security-group rule add adt --network 0.0.0.0/0 --port 443
       fi
       
       ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "FIREWALL-UPDATING"
   fi
fi

if ( [ -f ${HOME}/LINODE ] )
then
    if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "FIREWALL-UPDATING"`" = "0" ] )
    then    
        autoscaler_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh autoscaler ${CLOUDHOST}`"
        webserver_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh webserver ${CLOUDHOST}`"
        database_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh database ${CLOUDHOST}`"
        machine_ips="${autoscaler_ips} ${webserver_ips} ${database_ips}"
    
        autoscaler_private_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh autoscaler ${CLOUDHOST}`"
        webserver_private_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh webserver ${CLOUDHOST}`"
        database_private_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh database ${CLOUDHOST}`"
        machine_private_ips="${autoscaler_private_ips} ${webserver_private_ips} ${database_private_ips}"
    
        allips="${machine_ips} ${machine_private_ips} ${BUILD_CLIENT_IP}"
    
        firewall_id="`/usr/local/bin/linode-cli --json firewalls list | jq '.[] | select (.label == "adt" ).id'`"
    
        iplist=""
        for ip in ${allips}
        do
            iplist=$iplist"\"${ip}/32\","
        done
    
        iplist="`/bin/echo ${iplist} | /bin/sed 's/,$//g' | /bin/sed 's/"/\\"/g'`"
        rules=${rules}"{\"addresses\":{\"ipv4\":[${iplist}]},\"action\":\"ACCEPT\",\"protocol\":\"TCP\",\"ports\":\"${SSH_PORT},${DB_PORT},22\"},"

        rules="[`/bin/echo ${rules} | /bin/sed 's/,$//g'`,"
 
        . ${HOME}/providerscripts/security/firewall/GetProxyDNSIPs.sh
                                
        if ( [ "${alldnsproxyips}" != "" ] )
        then
            standard_rules="{\"addresses\":{\"ipv4\":[${alldnsproxyips}]},\"action\":\"ACCEPT\",\"protocol\":\"TCP\",\"ports\":\"443,80\"},{\"addresses\":{\"ipv4\":[\"0.0.0.0/0\"]},\"action\":\"ACCEPT\",\"protocol\":\"ICMP\"}]"
        else
            standard_rules="{\"addresses\":{\"ipv4\":[\"0.0.0.0/0\"]},\"action\":\"ACCEPT\",\"protocol\":\"TCP\",\"ports\":\"443,80\"},{\"addresses\":{\"ipv4\":[\"0.0.0.0/0\"]},\"action\":\"ACCEPT\",\"protocol\":\"ICMP\"}]"   
        fi
        #allrules="${rules}${build_machine_rules}${standard_rules}"
        allrules="${rules}${standard_rules}"
        /usr/local/bin/linode-cli firewalls rules-update --inbound  "${allrules}" ${firewall_id}
    
        autoscaler_ids="`${HOME}/providerscripts/server/ListServerIDs.sh autoscaler ${CLOUDHOST}`"
        webserver_ids="`${HOME}/providerscripts/server/ListServerIDs.sh webserver ${CLOUDHOST}`"
        database_ids="`${HOME}/providerscripts/server/ListServerIDs.sh database ${CLOUDHOST}`"
        machine_ids="${autoscaler_ids} ${webserver_ids} ${database_ids}"
        machine_ids="`/bin/echo ${machine_ids} | /usr/bin/tr '\n' ' '`"
        
        for machine_id in ${machine_ids}
        do
            /usr/local/bin/linode-cli firewalls device-create --id ${machine_id} --type linode ${firewall_id} 2>/dev/null #Redirect to null in case already added
        done
        
       ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "FIREWALL-UPDATING"
   fi

fi


if ( [ -f ${HOME}/VULTR ] )
then
    if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "FIREWALL-UPDATING"`" = "0" ] )
    then   
        export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
        firewall_id="`/usr/bin/vultr firewall group list | /usr/bin/tail -n +2 | /bin/grep -w 'adt$' | /usr/bin/awk '{print $1}'`"
   
        rule_nos="`/usr/bin/vultr firewall rule list ${firewall_id} | /usr/bin/awk '{print $1,$4}' | /bin/grep 22$ | /usr/bin/awk '{print $1}' | /usr/bin/tr '\n' ' '`"
       
        for rule_no in ${rule_nos}
        do
            /usr/bin/vultr firewall rule delete ${firewall_id} ${rule_no}
        done
          
   
        if ( [ "${firewall_id}" = "" ] )
        then
            firewall_id="`/usr/bin/vultr firewall group create | /usr/bin/tail -n +2 | /usr/bin/awk '{print $1}'`"  
            /usr/bin/vultr firewall group update ${firewall_id} "adt"
        fi
   
        . ${HOME}/providerscripts/security/firewall/GetProxyDNSIPs.sh

        if ( [ "${alldnsproxyips}" != "" ] )
        then
            # I couldn't get this command to work, it was giving an error message so it is commented out and the command below used instead which is not ideal
            #  /usr/bin/vultr firewall rule create --id ${firewall_id} --protocol tcp --port 443 --size 32 --type v4 --source cloudflare
            /usr/bin/vultr firewall rule create --id ${firewall_id} --port 443 --protocol tcp --size 32 --type v4 -s 0.0.0.0/0
            /usr/bin/vultr firewall rule create --id ${firewall_id} --protocol icmp --size 32 --type v4 -s 0.0.0.0/0
        else 
            /usr/bin/vultr firewall rule create --id ${firewall_id} --port 443 --protocol tcp --size 32 --type v4 -s 0.0.0.0/0
            /usr/bin/vultr firewall rule create --id ${firewall_id} --protocol icmp --size 32 --type v4 -s 0.0.0.0/0
        fi

        autoscaler_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh autoscaler ${CLOUDHOST}`"
        webserver_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh webserver ${CLOUDHOST}`"
        database_ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh database ${CLOUDHOST}`"
        machine_ips="${autoscaler_ips} ${webserver_ips} ${database_ips} ${BUILD_CLIENT_IP}"
       
        for machine_ip in ${machine_ips}
        do              
            if ( [ "`/bin/echo ${webserver_ips} | /bin/grep ${machine_ip}`" != "" ] || [ "`/bin/echo ${autoscaler_ips} | /bin/grep ${machine_ip}`" != "" ] )
            then
                 /usr/bin/vultr firewall rule create --id ${firewall_id} --port ${SSH_PORT} --protocol tcp --size 32 --type v4 -s ${machine_ip}
                 /usr/bin/vultr firewall rule create --id ${firewall_id} --port ${DB_PORT} --protocol tcp --size 32 --type v4 -s ${machine_ip}
            fi
          
            if ( [ "`/bin/echo ${autoscaler_ips} | /bin/grep ${machine_ip}`" != "" ] )
            then
                 /usr/bin/vultr firewall rule create --id ${firewall_id} --port 22 --protocol tcp --size 32 --type v4 -s ${machine_ip}
            fi   
        done
       
        /usr/bin/vultr firewall rule create --id ${firewall_id} --port ${SSH_PORT} --protocol tcp --size 32 --type v4 -s ${BUILD_CLIENT_IP}
       
        autoscaler_private_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh autoscaler ${CLOUDHOST}`"
        webserver_private_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh webserver ${CLOUDHOST}`"
        database_private_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh database ${CLOUDHOST}`"
        machine_private_ips="${autoscaler_private_ips} ${webserver_private_ips} ${database_private_ips}"
       
        for machine_private_ip in ${machine_private_ips}
        do                         
            if ( [ "`/bin/echo ${webserver_private_ips} | /bin/grep ${machine_private_ip}`" != "" ] || [ "`/bin/echo ${autoscaler_private_ips} | /bin/grep ${machine_private_ip}`" != "" ] )
            then
                 /usr/bin/vultr firewall rule create --id ${firewall_id} --port ${SSH_PORT} --protocol tcp --size 32 --type v4 -s ${machine_private_ip}
                 /usr/bin/vultr firewall rule create --id ${firewall_id} --port ${DB_PORT} --protocol tcp --size 32 --type v4 -s ${machine_private_ip}
            fi
           
            if ( [ "`/bin/echo ${autoscaler_private_ips} | /bin/grep ${machine_private_ip}`" != "" ] )
            then
                /usr/bin/vultr firewall rule create --id ${firewall_id} --port 22 --protocol tcp --size 32 --type v4 -s ${machine_private_ip}
            fi    
       done
       
       /usr/bin/vultr firewall rule create --id ${firewall_id} --port ${SSH_PORT} --protocol tcp --size 32 --type v4 -s ${BUILD_CLIENT_IP}
 
       autoscaler_ids="`${HOME}/providerscripts/server/ListServerIDs.sh autoscaler ${CLOUDHOST}`"
       webserver_ids="`${HOME}/providerscripts/server/ListServerIDs.sh webserver ${CLOUDHOST}`"
       database_ids="`${HOME}/providerscripts/server/ListServerIDs.sh database ${CLOUDHOST}`"
       machine_ids="${autoscaler_ids} ${webserver_ids} ${database_ids}"
       machine_ids="`/bin/echo ${machine_ids} | /usr/bin/tr '\n' ' '`"

       for machine_id in ${machine_ids}
       do
           /usr/bin/vultr instance update-firewall-group -f ${firewall_id} -i ${machine_id}
       done
        
       ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "FIREWALL-UPDATING"
   fi
fi

if ( [ -f ${HOME}/AWS ] )
then
    if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "FIREWALL-UPDATING"`" = "0" ] )
    then
        interface="`/usr/bin/curl --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/`"
        subnet_id="`/usr/bin/curl --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/${interface}/subnet-id`"
        vpc_id="`/usr/bin/curl --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/${interface}/vpc-id`"

        security_group_id="`/usr/bin/aws ec2 describe-security-groups | /usr/bin/jq '.SecurityGroups[] | .GroupName + " " + .GroupId' | /bin/grep AgileDeploymentToolkitSecurityGroup | /bin/sed 's/\"//g' | /usr/bin/awk '{print $NF}'`"

        if ( [ "${security_group_id}" = "" ] )
        then
            /usr/bin/aws ec2 create-security-group --description "This is the security group for your agile deployment toolkit server machines" --group-name "AgileDeploymentToolkitSecurityGroup" --vpc-id=${vpc_id}
            security_group_id="`/usr/bin/aws ec2 describe-security-groups | /usr/bin/jq '.SecurityGroups[] | .GroupName + " " + .GroupId' | /bin/grep  AgileDeploymentToolkitSecurityGroup | /bin/sed 's/\"//g' | /usr/bin/awk '{print $NF}'`"
        fi
        
        security_group_id1="`/usr/bin/aws ec2 describe-security-groups | /usr/bin/jq '.SecurityGroups[] | .GroupName + " " + .GroupId' | /bin/grep AgileDeploymentToolkitWebserversSecurityGroup | /bin/sed 's/\"//g' | /usr/bin/awk '{print $NF}'`"

        if ( [ "${security_group_id1}" = "" ] )
        then
            /usr/bin/aws ec2 create-security-group --description "This is the security group for your agile deployment toolkit webserver machines" --group-name "AgileDeploymentToolkitWebserversSecurityGroup" --vpc-id=${vpc_id}
            security_group_id1="`/usr/bin/aws ec2 describe-security-groups | /usr/bin/jq '.SecurityGroups[] | .GroupName + " " + .GroupId' | /bin/grep  AgileDeploymentToolkitWebserversSecurityGroup | /bin/sed 's/\"//g' | /usr/bin/awk '{print $NF}'`"
        fi
        
        /usr/bin/aws ec2 authorize-security-group-ingress --group-id ${security_group_id1} --protocol tcp --port ${SSH_PORT} --source-group ${security_group_id}    
        /usr/bin/aws ec2 authorize-security-group-ingress --group-id ${security_group_id1} --protocol tcp --port ${DB_PORT} --source-group ${security_group_id}    
        /usr/bin/aws ec2 authorize-security-group-ingress --group-id ${security_group_id1} --protocol tcp --port 22 --source-group ${security_group_id}    

        /usr/bin/aws ec2 authorize-security-group-ingress --group-id ${security_group_id} --protocol tcp --port ${SSH_PORT} --source-group ${security_group_id1}    
        /usr/bin/aws ec2 authorize-security-group-ingress --group-id ${security_group_id} --protocol tcp --port ${DB_PORT} --source-group ${security_group_id1}    
        /usr/bin/aws ec2 authorize-security-group-ingress --group-id ${security_group_id} --protocol tcp --port 22 --source-group ${security_group_id1} 
        
       . ${HOME}/providerscripts/security/firewall/GetProxyDNSIPs.sh
                                
       if ( [ "${alldnsproxyips}" != "" ] )
       then
           for ip in ${alldnsproxyips}
           do
               /usr/bin/aws ec2 authorize-security-group-ingress --group-id ${security_group_id} --ip-permissions IpProtocol=tcp,FromPort=443,ToPort=443,IpRanges="[{CidrIp=${ip}}]" 2>/dev/null
           done
       else
           /usr/bin/aws ec2 authorize-security-group-ingress --group-id ${security_group_id} --ip-permissions IpProtocol=tcp,FromPort=443,ToPort=443,IpRanges="[{CidrIp=0.0.0.0/0}]" 2>/dev/null
       fi
       
       /usr/bin/aws ec2 authorize-security-group-ingress --group-id ${security_group_id} --ip-permissions IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges='[{CidrIp=0.0.0.0/0}]'
  
       if ( [ "${ENABLE_EFS}" = "1" ] )
       then
           /usr/bin/aws ec2 authorize-security-group-ingress --group-id ${security_group_id} --protocol tcp --source-group ${security_group_id} --port 2049 --cidr 0.0.0.0/0
       fi
       
       ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "FIREWALL-UPDATING"
   fi
fi
