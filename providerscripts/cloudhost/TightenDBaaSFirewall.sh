  
  db_ass="`${HOME}/providerscripts/utilities/ExtractConfigValues.sh 
  
  /usr/local/bin/doctl databases firewalls append ${cluster_id} --rule ip_addr:${WSIP}  
