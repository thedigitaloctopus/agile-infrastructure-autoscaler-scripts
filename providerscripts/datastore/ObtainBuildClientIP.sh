if ( [ ! -d ${HOME}/runtime/BUILDCLIENTIP ] )
then
    /bin/mkdir ${HOME}/runtime/BUILDCLIENTIP
fi

if ( [ "`/bin/ls ${HOME}/runtime/BUILDCLIENTIP/*`" != "" ] && [ -f ${HOME}/runtime/BUILDCLIENTUPDATED ] )
then
    exit
fi
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
/usr/bin/s3cmd get s3://adt-${BUILD_IDENTIFIER}/* ${HOME}/runtime/BUILDCLIENTIP
BUILD_CLIENT_IP="`/bin/ls ${HOME}/runtime/BUILDCLIENTIP/* | /usr/bin/awk -F'/' '{print $NF}' | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`"
${HOME}/providerscripts/utilities/StoreConfigValue.sh "BUILDCLIENTIP" "${BUILD_CLIENT_IP}"
/bin/touch ${HOME}/runtime/BUILDCLIENTUPDATED 
