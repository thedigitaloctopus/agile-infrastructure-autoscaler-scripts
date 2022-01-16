#!/bin/sh

BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"

/usr/bin/s3cmd --force get s3://authip-${BUILD_IDENTIFIER}/authorised-ips.dat /tmp
matched="1"
if ( [ -f ${HOME}/runtime/authorised-ips.dat ] )
then
    if ( [ "`/usr/bin/diff ${HOME}/runtime/authorised-ips.dat /tmp/authorised-ips.dat`" != "" ] )
    then
        /bin/cp /tmp/authorised-ips.dat ${HOME}/runtime
        matched="0"
    fi
else
    /bin/cp /tmp/authorised-ips.dat ${HOME}/runtime
    matched="0"
fi

${HOME}/providerscripts/security/firewall/UpdateNativeFirewall.sh
