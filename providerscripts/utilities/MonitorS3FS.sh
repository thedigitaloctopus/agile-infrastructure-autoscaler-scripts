#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 11/08/2021
# Description: I have seen s3fs become unresponsive during testing. This is a cludge
# which monitors if the S3FS filesystem has become unresponsive. If the file 
# ${HOME}/runtime/MONITOR_S3FS doesn't get removed, then, we know we need to act because
# S3FS has become unresponsive
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

/bin/touch ${HOME}/runtime/PERFORMING_S3FS_CHECK 
/bin/touch ${HOME}/runtime/MONITOR_S3FS

#If this command times out then it means S3FS is having problems
/bin/ls ${HOME}/config

#If the above command times out, we will never get to here so the monitoring file won't be deleted and we can check for that in another script

/bin/rm ${HOME}/runtime/MONITOR_S3FS
