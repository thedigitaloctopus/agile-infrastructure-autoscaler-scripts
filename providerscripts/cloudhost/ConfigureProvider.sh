#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script will copy the configuration for the cloudhost provider to
# the machine specified by ip
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

CLOUDHOST="${1}"
BUILD_IDENTIFIER="${2}"
ALGORITHM="${3}"
IP="${4}"
SERVER_USER="${5}"

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
    /bin/echo "${0} `/bin/date`: Configuring cloudtools (tugboat) for webserver with IP: ${IP}" >> ${HOME}/logs/MonitoringLog.log
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${IP} "/bin/mkdir -p /home/${SERVER_USER}/.config/doctl"
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.config/doctl/config.yaml ${SERVER_USER}@${IP}:${HOME}/.config/doctl/config.yaml
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${IP} "/bin/chmod 400 ${HOME}/.config/doctl/config.yaml"
fi
if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
    /bin/echo "${0} `/bin/date`: Configuring cloudtools (cloudstack) for webserver with IP: ${IP}" >> ${HOME}/logs/MonitoringLog.log
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.cloudstack.ini ${SERVER_USER}@${IP}:${HOME}/.cloudstack.ini
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${IP} "/bin/chmod 400 ${HOME}/.cloudstack.ini"
fi
if ( [ "${CLOUDHOST}" = "linode" ] )
then
    /bin/echo "${0} `/bin/date`: Configuring cloudtools (linodecli) for webserver with IP: ${IP}" >> ${HOME}/logs/MonitoringLog.log
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.config/linode-cli ${SERVER_USER}@${IP}:${HOME}/.config/linode-cli
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${IP} "/bin/chmod 400 ${HOME}/.config/linode-cli"
fi
if ( [ "${CLOUDHOST}" = "vultr" ] )
then
    /bin/echo "${0} `/bin/date`: Configuring cloudtools (vultr) for webserver with IP: ${IP}" >> ${HOME}/logs/MonitoringLog.log
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/VULTRAPIKEY:* ${SERVER_USER}@${IP}:${HOME}/.ssh
fi

if ( [ "${CLOUDHOST}" = "aws" ] )
then
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${IP} "/bin/mkdir -p /home/${SERVER_USER}/.aws"
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.aws/config ${SERVER_USER}@${IP}:/home/${SERVER_USER}/.aws/config
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${IP} "/bin/chmod 400 /home/${SERVER_USER}/.aws/config"
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.aws/credentials ${SERVER_USER}@${IP}:/home/${SERVER_USER}/.aws/credentials
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${IP} "/bin/chmod 400 /home/${SERVER_USER}/.aws/credentials"
fi





