if ( [ ! -d ${HOME}/runtime/BUILDCLIENTIP ] )
then
    /bin/mkdir ${HOME}/runtime/BUILDCLIENTIP
fi

if ( [ "`/bin/ls ${HOME}/runtime/BUILDCLIENTIP/*`" != "" ] && [ -f ${HOME}/runtime/BUILDCLIENTUPDATED ] )
then
    exit
fi

uptime="`/usr/bin/uptime | /usr/bin/awk -F ',' ' {print $1} ' | /usr/bin/awk ' {print $3} ' | /usr/bin/awk -F ':' ' {hrs=$1; min=$2; print
 hrs*60 + min} '`"
 
 if ( [ "${uptime}" -gt "15" ] )
 then
     exit
 fi
 
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
/bin/rm ${HOME}/runtime/BUILDCLIENTIP/*
/usr/bin/s3cmd get s3://adt-${BUILD_IDENTIFIER}/* ${HOME}/runtime/BUILDCLIENTIP
BUILD_CLIENT_IP="`/bin/ls ${HOME}/runtime/BUILDCLIENTIP/* | /usr/bin/awk -F'/' '{print $NF}' | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`"
OLD_BUILD_CLIENT_IP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDCLIENTIP'`"

if ( [ "${OLD_BUILD_CLIENT_IP}" != "${BUILD_CLIENT_IP}" ] )
then
    ${HOME}/providerscripts/utilities/StoreConfigValue.sh "BUILDCLIENTIP" "${BUILD_CLIENT_IP}"  
    /bin/touch ${HOME}/runtime/BUILDCLIENTUPDATED
fi
