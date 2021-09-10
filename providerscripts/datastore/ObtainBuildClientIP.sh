if ( [ -d /tmp/BUILDCLIENTIP ] )
then
    /bin/rm /tmp/BUILDCLIENTIP/*
fi
/bin/mkdir /tmp/BUILDCLIENTIP
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
/usr/bin/s3cmd get s3://adt-${BUILD_IDENTIFIER}/* /tmp/BUILDCLIENTIP
BUILD_CLIENT_IP="`/bin/ls /tmp/BUILDCLIENTIP/*`"
${HOME}/providerscripts/utilities/StoreConfigValue.sh "BUILDCLIENTIP" "${BUILD_CLIENT_IP}"
