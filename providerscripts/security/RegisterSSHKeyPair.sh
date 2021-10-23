#!/bin/sh
#######################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : Registers the SSH key pair we have generated with the cloudhost provider
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
#######################################################################################
#######################################################################################
#set -x

key_name="${1}"
token="${2}"
key_substance="${3}"
cloudhost="${4}"

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
    /usr/bin/curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" -d '{"name":"'"${key_name}"'","public_key":"'"${key_substance}"'"}' "https://api.digitalocean.com/v2/account/keys"

    if ( [ "$?" != "0" ] )
    then
        /bin/echo "Invalid token mate, try again"
        exit
    fi

    if ( [ "`/usr/bin/curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" "https://api.digitalocean.com/v2/account/keys" | /usr/bin/awk '{
n = split($0, t, ",")
for (i = 0; ++i <= n;)
print t[i]
}' | /bin/grep "\(id\|name\)" | /bin/sed 'N;s/\n/ /' | /bin/grep "${key_name}" | /usr/bin/wc -l`" != "1" ] )
    then
        /bin/echo ""
        /bin/echo "There's more than one key with the name ${key_name} in the digital ocean account you are using please remove them all manually"
        exit
    fi
fi
        
if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
    /usr/local/bin/cs registerSSHKeyPair name="${key_name}" publicKey="${key_substance}"
fi
        
if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
    /usr/local/bin/linode-cli sshkeys create --label "${key_name}" --ssh_key="${key_substance}"
fi
        
if ( [ -f /root/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
    export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
    /bin/sleep 1
    
    #Clonk
    #/usr/bin/vultr sshkey create -n "${key_name}" -k "${key_substance}"
    
    #Official
    /usr/bin/vultr ssh-key create -n "${key_name}" -k "${key_substance}"
fi

if ( [ "${cloudhost}" = "aws" ] )
then
    /usr/bin/aws ec2 import-key-pair --key-name "${key_name}" --public-key-material "${key_substance}"
fi




