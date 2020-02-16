    #!/bin/sh
    
    /bin/echo "${0} `/bin/date`: Building a new machine from a snapshot" >> ${HOME}/logs/MonitoringWebserverBuildLog.log

    #If we got to here, then the server has been built from a snapshot.
    /usr/bin/touch ${HOME}/config/bootedwebserverips/${private_ip}

    #We want to make sure that our server has spawned correctly from our snapshot so give it plenty of time to connect. If the connection fails
    #then, as I have seen, something has gone wrong with spawning from a snapshot, so destroy the machine and the next run of the autoscaler
    #will spawn a fresh one, hopefully, without issue
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=30 -o ConnectionAttempts=20 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p ${SSH_PORT} ${SERVER_USER}@${ip} "exit"

    if ( [ "$?" != "0" ] )
    then
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=30 -o ConnectionAttempts=20 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p ${SSH_PORT} ${SERVER_USER}@${ip} "exit"
    fi

    if ( [ "$?" != "0" ] )
    then
        /bin/echo "${0} `/bin/date` : ${ip} is being destroyed because it couldn't be connected to after spawning it from a snapshot" >> ${HOME}/logs/MonitoringLog.log
        ${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
        
        DBaaS_DBSECURITYGROUP="`/bin/ls ${HOME}/.ssh/DBaaSDBSECURITYGROUP:* | /usr/bin/awk -F':' '{print $NF}'`"
        if ( [ "${DBaaS_DBSECURITYGROUP}" != "" ] )
        then
            IP_TO_DENY="${ip}"
            . ${HOME}/providerscripts/server/DenyDBAccess.sh
        fi
        
        INMEMORYCACHING_SECURITY_GROUP="`/bin/ls ${HOME}/.ssh/INMEMORYCACHINGSECURITYGROUP:* | /usr/bin/awk -F':' '{print $NF}'`"
        INMEMORYCACHING_PORT="`/bin/ls ${HOME}/.ssh/INMEMORYCACHINGPORT:* | /usr/bin/awk -F':' '{print $NF}'`"

        if ( [ "${INMEMORYCACHING_SECURITY_GROUP}" != "" ] )
        then
            IP_TO_DENY="${ip}"
            . ${HOME}/providerscripts/server/DenyCachingAccess.sh
        fi

        /bin/rm ${HOME}/config/beingbuiltips/${private_ip}
        /bin/rm ${HOME}/runtime/autoscalelock.file
        exit
    fi

    #Our snapshot built machine will have "frozen" config settings from when it was snapshotted. These will likely be different
    #For example, the ip addresses will be different for the machines, so, we need to purge the bits of configuration that need
    #to be updated and replace it with fresh stuff
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} -p ${SSH_PORT} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /bin/rm -f /home/${SERVER_USER}/.ssh/BUILDARCHIVECHOICE:* /home/${SERVER_USER}/.ssh/MYIP:* /home/${SERVER_USER}/.ssh/MYPUBLICIP:* /home/${SERVER_USER}/runtime/NETCONFIGURED /home/${FULL_SNAPSHOT_ID}/runtime/SSHTUNNELCONFIGURED /home/${FULL_SNAPSHOT_ID}/runtime/APPLICATION_CONFIGURATION_PREPARED /home/${FULL_SNAPSHOT_ID}/runtime/APPLICATION_DB_CONFIGURED /home/${FULL_SNAPSHOT_ID}/runtime/*.lock"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} -p ${SSH_PORT} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /bin/touch /home/${SERVER_USER}/.ssh/BUILDARCHIVECHOICE:${BUILD_ARCHIVE} /home/${SERVER_USER}/.ssh/MYIP:${private_ip} /home/${SERVER_USER}/.ssh/MYPUBLICIP:${ip}"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} -p ${SSH_PORT} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /home/${SERVER_USER}/providerscripts/utilities/RefreshNetworking.sh"

    #If we have deployed to use DBaaS-secured, then we need to have an ssh tunnel setup.
    #For scaling purposes we may have multiple remote proxy machines with our DB provider and so
    #We allocate usage of these proxy machines to our webservers in a road robin fashion.
    #In other words, if there are 3 ssh proxy machines runnning remotely, then for us,
    # webserver 1 would use remote proxy 1
    # webserver 2 would use remote proxy 2
    # webserver 3 would use remote proxy 3
    # webserver 4 would use remote proxy 1
    # webserver 5 would use remote proxy 2
    # and so on so, here is where we define the index for which proxy machine to use

    proxyips="`/bin/ls ${HOME}/.ssh/DBaaSREMOTESSHPROXYIP:* | /usr/bin/awk -F':' '{$1=""}1'`"
    if ( [ "${proxyips}" != "" ] )
    then
        noproxyips="`/bin/echo "${proxyips}" | /usr/bin/wc -w`"
        index="`/usr/bin/expr ${SERVER_NUMBER} % ${noproxyips} 2>/dev/null`"
        index="`/usr/bin/expr ${index} + 1`"
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} -p ${SSH_PORT} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /bin/rm /home/${SERVER_USER}/.ssh/DBaaSREMOTESSHPROXYIPINDEX:* /home/${SERVER_USER}/.ssh/DBaaSREMOTESSHPROXYIP:*"
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} -p ${SSH_PORT} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /bin/touch /home/${SERVER_USER}/.ssh/DBaaSREMOTESSHPROXYIPINDEX:${index} /home/${SERVER_USER}/.ssh/DBaaSREMOTESSHPROXYIP:`/bin/echo ${proxyips} | /bin/sed 's/ /:/g'`"
    fi
    
    /usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/InitialSyncFromWebrootTunnel.sh"
    /usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/applicationscripts/SyncLatestApplication.sh ${APPLICATION_REPOSITORY_PROVIDER} ${APPLICATION_REPOSITORY_USERNAME} ${APPLICATION_REPOSITORY_PASSWORD} ${APPLICATION_REPOSITORY_OWNER} ${BUILD_ARCHIVE} ${DATASTORE_CHOICE} ${BUILD_IDENTIFIER} ${WEBSITE_NAME}"

    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} -p ${SSH_PORT} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /bin/touch /home/${SERVER_USER}/.ssh/AUTOSCALED"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} -p ${SSH_PORT} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /sbin/shutdown -r now"
fi
