#!/bin/sh
######################################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Refresh the private networking
#######################################################################################################
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
#/usr/sbin/ufw default allow incoming
#/usr/sbin/ufw default allow outgoing
#/usr/sbin/ufw --force enable
#We need to disable the firewall so that initial connections to the websever are allowed through.
#The firewall rules will be built up and applied within the first few minutes of the websever
#being online. If we don't disable the firewall to begin with, then, initial requests will be
#blocked leading to timeouts for the user.

BUILDOS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOS'`"
BUILDOSVERSION="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOSVERSION'`"
CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"

if ( [ "${CLOUDHOST}" = "vultr" ] )
then
    if ( [ "${BUILDOS}" = "ubuntu" ] )
    then
        if ( [ "${BUILDOSVERSION}" = "20.04" ] )
	then
	    ip="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'MYIP'`"
	    /bin/sed -i "s/addresses.*/addresses: [${ip}\/16]/" /etc/netplan/10-ens7.yaml
            if ( [ -f /etc/netplan/10-ens3.yaml ] )
            then
                /bin/echo "network:
  version: 2
  renderer: networkd
  ethernets:
    ens3:
      mtu: 1450
      dhcp4: yes
      addresses: [${ip}/16]" > /etc/netplan/10-ens3.yaml
             fi
            /usr/sbin/netplan apply
	fi
    fi
    if ( [ "${BUILDOS}" = "debian" ] )
    then
        if ( [ "${BUILDOSVERSION}" = "10" ] || [ "${BUILDOSVERSION}" = "11" ] )
            then
	    ip="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'MYIP'`"
            /bin/sed -i "s/address.*/address ${ip}/" /etc/network/interfaces
            /sbin/ifup ens7
        fi
    fi
fi

