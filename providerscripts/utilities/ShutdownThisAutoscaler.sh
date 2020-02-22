#!/bin/sh
####################################################################################################################
# Author: Peter Winter
# Date:   07/06/2016
# Description : This script is used to shutdown the autoscaler. You can do any cleanup you want in this script
# but to ensure system consistency all shutdowns shoud done through this script rather than through the providers GUI interface
########################################################################################################################
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

/bin/echo "Shutting down an autoscaler instance. Please wait whilst I clean the place first."

/bin/rm ${HOME}/config/autoscalerip/`${HOME}/providerscripts/utilities/GetIP.sh`
${HOME}/providerscripts/email/SendEmail.sh "Shutting down the autoscaler" "Shutting down the autoscaler"
/bin/echo "${0} `/bin/date`: Shutting down the autoscaler" >> ${HOME}/logs/MonitoringLog.log
/usr/sbin/shutdown -h now
