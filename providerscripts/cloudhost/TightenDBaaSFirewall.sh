#!/bin/sh

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
    dbaas="`${HOME}/providerscripts/utilities/ExtractConfigValues.sh "DATABASEDBaaSINSTALLATIONTYPE" "stripped"`"
  
    if ( [ "`/bin/echo ${dbaas} | /bin/grep DBAAS`" != "" ] )
    then
        cluster_id"`/bin/echo ${dbaas} | /usr/bin/awk '{print $NF}'`"
        /local/bin/doctl databases firewalls append ${cluster_id} --rule ip_addr:${ip}
    fi
fi
