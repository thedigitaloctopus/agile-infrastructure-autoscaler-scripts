#!/bin/bash
########################################################################################
# Description: This script is called repeatedly from cron and refreshes the scaling profile
# configuration file so that it is recognised by s3fs
# Author: Peter Winter
# Date: 12/01/2017
########################################################################################
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
#########################################################################################
#########################################################################################
#set -x

if ( [ ! -f ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
    exit
fi

lockfile=${HOME}/runtime/autoscaleprofilelock.file

if ( [ ! -f ${lockfile} ] )
then
    /usr/bin/touch ${lockfile}
    /bin/echo "${0} `/bin/date`: Performing scaling from cron" >> ${HOME}/logs/MonitoringLog.log
    ${HOME}/autoscaler/RefreshScalingProfile.sh
    /bin/rm ${lockfile}
fi
