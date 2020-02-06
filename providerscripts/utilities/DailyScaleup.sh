#!/bin/sh
###############################################################################################
# Author: Peter Winter
# Date  : 04/07/2016
# Description : This script can be used to scale up the number of webservers, just call it from crontab
################################################################################################
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
###########################################################################################
###########################################################################################
#set -x

/bin/echo "${0} `/bin/date`: Running daily scale up. Scaling up to ..... $1 servers" >> ${HOME}/logs/MonitoringLog.log
/bin/sed -i "/^NO_WEBSERVERS=/c\NO_WEBSERVERS=$1" ${HOME}/autoscaler/PerformScaling.sh


