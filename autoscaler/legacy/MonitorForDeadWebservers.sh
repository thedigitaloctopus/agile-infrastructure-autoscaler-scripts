#!/bin/sh
#########################################################################################################################
# Description: This script will destroy any dead webservers
# Author : Peter Winter
# Date: 07/03/2017
#########################################################################################################################
#set -x

CLOUDHOST="`/bin/ls ${HOME}/.ssh/CLOUDHOST:* | /usr/bin/awk -F':' '{print $NF}'`"

#If the toolkit is not fully built yet, then, don't do anything
if ( [ ! -f ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
    exit
fi

#The way we check for dead or webservers which have taken too long to build is through this flag which is set when a websever
#is marked as inactive or not online. If it is offline for more than 30 minutes, it must, surely, be dead, so destroy it
deadips=`/usr/bin/find ${HOME}/config/bootedwebserverips/ -mmin +30 -name "NOTACTIVE:*" -print | /bin/sed 's/.*NOTACTIVE://g'`

if ( [ "${deadips}" != "" ] )
then
    # Can do a dirty destroy as it is a dead webserver
    ip="`/bin/echo ${deadips} | /usr/bin/awk -F' ' '{print $1}'`"
    ${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
    #Make sure it is removed from our list of booted webservers
    /bin/rm ${HOME}/config/bootedwebserverips/*${ip}
fi
