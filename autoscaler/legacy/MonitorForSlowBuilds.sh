####################################################################################################################################
# Description: Building a webserver is reasonably complex, it's conceivable that from time to time something could go wrong. We
# consider any build which takes longer than 30 minutes to be a slow build and we destroy the machine which will automatically
# ensure that fresh attempt is made at building a webserver.
# Author: Peter Winter
# Date: 12/01/2017
####################################################################################################################################
#!/bin/sh

#If the toolkit isn't fully installed, we don't want to do anything
if ( [ ! -f ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
    exit
fi

CLOUDHOST="`/bin/ls ${HOME}/.ssh/CLOUDHOST:* | /usr/bin/awk -F':' '{print $NF}'`"
BUILD_IDENTIFIER="`/bin/ls ${HOME}/.ssh/BUILDIDENTIFIER:* | /usr/bin/awk -F':' '{print $NF}'`"
ALGORITHM="`/bin/ls ${HOME}/.ssh/ALGORITHM:* | /usr/bin/awk -F':' '{print $NF}'`"

#So, when a webserver is built, we set the 'being built' flag. This is a secondary check to the NOTACTIVE flag, but basically
#a machine is given 30 minutes to built and then we consider it a slow build and something must be wrong, so, we destroy it

for ip in `/usr/bin/find ${HOME}/config/beingbuiltips/* -mmin +30`
do
    strippedip="`/bin/echo ${ip} | /usr/bin/awk -F'/' '{print $NF}'`"
    if ( [ "`${HOME}/providerscripts/server/GetServerName.sh ${strippedip} ${CLOUDHOST} | grep webserver`" != "" ] )
    then
        /bin/echo "${0} `/bin/date`: Server with ip: ${strippedip} has been marked as slow to build and is being destroyed" >> ${HOME}/logs/MonitoringLog.log
        ${HOME}/providerscripts/server/DestroyServer.sh ${strippedip} ${CLOUDHOST}
    fi
    /bin/rm ${ip}
done
