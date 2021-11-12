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
