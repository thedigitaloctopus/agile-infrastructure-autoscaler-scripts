#!/bin/sh


WEBSITE_URL="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'WEBSITEURL'`"

configbucket="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{ for(i = 1; i <= NF; i++) { print $i; } }' | /usr/bin/cut -c1-3 | /usr/bin/tr '\n' '-' | /bin/sed 's/-//g'`"
configbucket="${configbucket}-config"

lock="${1}"

if ( [ "`/usr/bin/s3cmd ls s3://${configbucket}/${lock}`" = "" ] )
then
    /bin/touch ${HOME}/config/${lock}
    echo "1"
else
    echo "0"
fi
