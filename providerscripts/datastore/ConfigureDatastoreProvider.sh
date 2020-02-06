#!/bin/sh
######################################################################################
# Author: Peter Winter
# Date  : 13/07/2016
# Description : This script will copy our parameterised datastore config file for our
# provider over to our machine
######################################################################################
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
#####################################################################################
#####################################################################################
#set -x

datastore_provider="${1}"
ip="${2}"
CLOUDHOST="${3}"
BUILD_IDENTIFIER="${4}"
ALGORITHM="${5}"
SERVER_USER="${6}"
SERVER_USER_PASSWORD="`/bin/ls ${HOME}/.ssh/SERVERUSERPASSWORD:* | /usr/bin/awk -F':' '{print $NF}'`"

if ( [ "${datastore_provider}" = "amazonS3" ] || [ "${datastore_provider}" = "digitalocean" ] || [ "${datastore_provider}" = "exoscale" ] ||  [ "${datastore_provider}" = "linode" ] || [ "${datastore_provider}" = "vultr" ] )
then
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.s3cfg ${SERVER_USER}@${ip}:${HOME}/.s3cfg
    /bin/echo "${0} `/bin/date`: Configuration set for datastore provider for server with ip address ${ip}" >> ${HOME}/logs/MonitoringLog.log
fi



