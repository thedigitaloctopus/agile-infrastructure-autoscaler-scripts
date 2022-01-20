#!/bin/sh

if ( [ "${CLOUDHOST}" = "vultr" ] )
then
    if ( [ "`/usr/bin/vultr instance list | /bin/grep UUID`" != "" ] )
    then
        #because vultr cloudhost doesn't let you destroy machines until they have been running for 5 mins or more
        /bin/sleep 300
        /bin/echo "${0} `/bin/date` : ${ip} is being destroyed because it couldn't be connected to after spawning it from a snapshot" >> ${HOME}/logs/${logdir}/MonitoringLog.log
        ${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
    fi
fi
