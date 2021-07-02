#!/bin/sh
##########################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script will get the SSHKKeyID from the cloudhost
##########################################################################################
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
##########################################################################################
##########################################################################################
#set -x

public_key_name="${1}"
cloudhost="${2}"

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
    /usr/local/bin/doctl compute ssh-key list | /bin/grep "${public_key_name}" | /usr/bin/awk '{print $1}'
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
    /bin/echo ${public_key_name}
fi
if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
    /usr/local/bin/linode-cli --text sshkeys list | /bin/grep "${public_key_name}" | /usr/bin/awk '{print $1}'
fi
if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
    export VULTR_API_KEY="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'VULTRAPIKEY'`"
    public_key_name="`/bin/echo ${public_key_name} | /usr/bin/cut -c 1-30`"
    /bin/sleep 1
    /usr/bin/vultr sshkey list | /bin/grep "${public_key_name}" | /usr/bin/awk '{print $1}'
fi

if ( [ "${cloudhost}" = "aws" ] )
then
    /bin/echo ${public_key_name}
fi





