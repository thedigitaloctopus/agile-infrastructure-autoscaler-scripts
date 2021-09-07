/bin/mkdir /tmp/BUILDCLIENTIP
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
/usr/bin/s3cmd get s3://adt-${BUILD_IDENTIFIER}/* /tmp/BUILDCLIENTIP
