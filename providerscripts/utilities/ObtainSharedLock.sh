#!/bin/sh

export HOME="`/bin/cat /home/homedir.dat`"

WEBSITE_URL="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'WEBSITEURL'`"

configbucket="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{ for(i = 1; i <= NF; i++) { print $i; } }' | /usr/bin/cut -c1-3 | /usr/bin/tr '\n' '-' | /bin/sed 's/-//g'`"
configbucket="${configbucket}-config"

lock="${1}"

#Put in a small sleep to conteract race conditions a bit
/bin/sleep `/usr/bin/awk -v min=0 -v max=30 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'`

if ( [ "`/usr/bin/s3cmd ls s3://${configbucket}/${lock}`" = "" ] )
then
    /bin/touch ${HOME}/config/${lock}
    /bin/echo "1"
else
    /bin/echo "0"
fi
