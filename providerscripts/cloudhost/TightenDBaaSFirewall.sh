#!/bin/sh

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
    dbaas="`${HOME}/providerscripts/utilities/ExtractConfigValues.sh "DATABASEDBaaSINSTALLATIONTYPE" "stripped"`"
  
    cluster_id="`/bin/echo ${dbaas} | /usr/bin/awk '{print $NF}'`"

    if ( [ "`/usr/local/bin/doctl databases list | /bin/grep ${cluster_id}`" != "" ] )
    then
        /usr//local/bin/doctl databases firewalls append ${cluster_id} --rule ip_addr:${ip}
    fi
fi

if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
    dbaas="`${HOME}/providerscripts/utilities/ExtractConfigValues.sh "DATABASEDBaaSINSTALLATIONTYPE" "stripped"`"
    zone="`/bin/echo ${dbaas} | /usr/bin/awk '{print $4}'`"
    database_name="`/bin/echo ${dbaas} | /usr/bin/awk '{print $6}'`"
    ips="`/bin/ls ${HOME}/config/webserverpublicips`"
    ips="`/bin/echo ${ips} | /bin/tr '\n' ',' | /bin/sed 's/,$//g'`"
    
    if ( [ "`/bin/echo ${dbaas} | /bin/grep ' pg '`" != "" ] )
    then
        /usr/bin/exo dbaas update -z ${zone}  ${database_name} --pg-ip-filter=${ips}
    elif ( [ "`/bin/echo ${dbaas} | /bin/grep ' mysql '`" != "" ] )
    then
        /usr/bin/exo dbaas update -z ${zone}  ${database_name} --mysql-ip-filter=${ips}
    fi
fi
