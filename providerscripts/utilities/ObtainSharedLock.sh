#!/bin/sh
##########################################################################################################
# Author: Peter Winter
# Date  : 04/07/2016
# Description : When I was using S3FS, I wanted to use it as a lock mechanism at times, in other words,
# write a file to S3FS on one machine and test for its existence on another. What I found though was that
# when I removed the lock file on one machine it would still be listed from other machines in other words
# the filesystem change wasn't be reflected across machines. This is how I decided to work around it
# by testing in the S3 bucket directly for the files existence. 
##########################################################################################################
# License Agreement:
# This file is part of The Agile Deployment Toolkit.
# The Agile Deployment Toolkit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# The Agile Deployment Toolkit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with The Agile Deployment Toolkit.  If not, see <http://www.gnu.org/licenses/>.
#######################################################################################################
#######################################################################################################
#set -x

export HOME="`/bin/cat /home/homedir.dat`"

WEBSITE_URL="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'WEBSITEURL'`"

configbucket="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{ for(i = 1; i <= NF; i++) { print $i; } }' | /usr/bin/cut -c1-3 | /usr/bin/tr '\n' '-' | /bin/sed 's/-//g'`"
configbucket="${configbucket}-config"

lock="${1}"

#Put in a small sleep to conteract race conditions a bit
/bin/sleep `/usr/bin/awk -v min=0 -v max=30 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'`

if ( [ "`/usr/bin/mount | /bin/grep config | /bin/grep s3fs`" != "" ] )
then
    if ( [ "`/usr/bin/s3cmd ls s3://${configbucket}/${lock}`" = "" ] )
    then
        /bin/touch ${HOME}/config/${lock}
        /bin/echo "1"
    else
        /bin/echo "0"
    fi
else   #This is if we are using EFS which doesn't have this problem
    /bin/touch ${HOME}/config/${lock}
    /bin/echo "1"
fi
