if ( [ -f ${HOME}/runtime/BUILDCLIENTUPDATED ] )
then
    exit
fi

if ( [ -d /tmp/BUILDCLIENTIP ] )
then
    /bin/rm /tmp/BUILDCLIENTIP/*
fi
/bin/mkdir /tmp/BUILDCLIENTIP
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
/usr/bin/s3cmd get s3://adt-${BUILD_IDENTIFIER}/* /tmp/BUILDCLIENTIP
BUILD_CLIENT_IP="`/bin/ls /tmp/BUILDCLIENTIP/* | /usr/bin/awk -F'/' '{print $NF}' | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`"
OLD_BUILD_CLIENT_IP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDCLIENTIP'`"
if ( [ "${BUILD_CLIENT_IP}" != "${OLD_BUILD_CLIENT_IP}" ] )
then
    ${HOME}/providerscripts/utilities/StoreConfigValue.sh "BUILDCLIENTIP" "${BUILD_CLIENT_IP}"
    /bin/touch ${HOME}/runtime/BUILDCLIENTUPDATED
fi 
