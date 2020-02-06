#!/bin/sh
####################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : Deletes a pair of SSH keys from the cloudhost provider
####################################################################################
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
###################################################################################
###################################################################################
#set -x

key_name="${1}"
token="${2}"
cloudhost="${3}"

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
    ids="`/usr/bin/curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" "https://api.digitalocean.com/v2/account/keys" | /usr/bin/awk '{
n = split($0, t, ",")
for (i = 0; ++i <= n;)
print t[i]
    }' | /bin/grep "\(id\|name\)" | /bin/sed 'N;s/\n/ /' | /bin/grep "${key_name}" | /usr/bin/awk -F':' '{print $2}' | /bin/sed 's/ .*//g'`"

    #Delete the keys we had from 'old' builds so that our fresh keys are used instead
    for id in ${ids}
    do
        /usr/bin/curl -X DELETE -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" "https://api.digitalocean.com/v2/account/keys/${id}"
    done
fi
if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
    /usr/local/bin/cs deleteSSHKeyPair name="${key_name}"
fi
if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
    :
fi
if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
    export VULTR_API_KEY="`/bin/ls ${HOME}/.ssh/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
    /bin/sleep 1
    for key_id in `/usr/bin/vultr sshkeys | /usr/bin/awk '{print $1}'`
    do
        /bin/sleep 1
        /usr/bin/vultr sshkey delete ${key_id}
    done
fi

if ( [ "${cloudhost}" = "aws" ] )
then
    /usr/bin/aws ec2 delete-key-pair --key-name ${key_name}
fi






