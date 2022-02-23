#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 11/08/2021
# Description: I have seen s3fs become unresponsive during testing. This is a cludge
# which monitors if the S3FS filesystem has become unresponsive (which hopefully never happens)
# but, if it does we do an emergency reboot to clear it out and keep the server online
# which is a better option than having our S3FS hosed. 
#######################################################################################
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
########################################################################################
########################################################################################
#set -x

if ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh ENABLEEFS:1`" = "1" ] )
then
   exit
fi

if ( [ "`/usr/bin/awk '{print int(($1%3600)/60)}' /proc/uptime`" -lt "3" ] )
then
    exit
fi

count=0

/bin/sleep 10

while ( [ "${count}" -lt "5" ] )
do
    if ( [ -f ${HOME}/runtime/PERFORMING_S3FS_CHECK ] && [ ! -f ${HOME}/runtime/MONITOR_S3FS ] )
    then
        /bin/rm ${HOME}/runtime/PERFORMING_S3FS_CHECK ${HOME}/runtime/MONITOR_S3FS
        exit
    else
        if ( [ -f ${HOME}/runtime/PERFORMING_S3FS_CHECK ] && [ -f ${HOME}/runtime/MONITOR_S3FS ] && [ "${count}" = "4" ] )
        then
            /bin/rm ${HOME}/runtime/PERFORMING_S3FS_CHECK ${HOME}/runtime/MONITOR_S3FS
            /usr/bin/umount -f ${HOME}/config
            if ( [ "$?" != "0" ] )
            then
                /bin/echo "${0} `/bin/date`: Emergency reboot has happened because s3fs looks to have become unresponsive which hoses us if we don't reboot" >> ${HOME}/logs/UnresponsiveS3FSLog.dat
                /usr/sbin/shutdown -r now
            else
                /bin/echo "${0} `/bin/date`: Have had to remount the config directory" >> ${HOME}/logs/UnresponsiveS3FSLog.dat
                ${HOME}/providerscripts/datastore/SetupConfig.sh
            fi
        fi
    fi
    /bin/sleep 10
    count="`/usr/bin/expr ${count} + 1`"
done
