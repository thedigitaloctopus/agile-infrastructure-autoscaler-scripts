#!/bin/sh
############################################################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : Gets the private ip address of the machine. In certain cases, it also refreshes or reinitialises
# the private networking.
###############################################################################################################################
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

/bin/ls ${HOME}/.ssh/MYIP:* | /usr/bin/awk -F':' '{print $NF}'
BUILDOS="`/bin/ls ${HOME}/.ssh/BUILDOS:* | /usr/bin/awk -F':' '{print $NF}'`"
BUILDOSVERSION="`/bin/ls ${HOME}/.ssh/BUILDOSVERSION:* | /usr/bin/awk -F':' '{print $NF}'`"

if ( [ -f ${HOME}/VULTR ] && [ ! -f ${HOME}/runtime/NETCONFIGURED ] )
then
    ip="`/bin/ls ${HOME}/.ssh/MYIP:* | /usr/bin/awk -F':' '{print $NF}'`"

    if ( [ "${BUILDOS}" = "debian" ] )
    then
        if ( [ "${BUILDOSVERSION}" = "9" ] || [ "${BUILDOSVERSION}" = "10" ] )
        then
            /bin/echo "auto ens7
iface ens7 inet static
address ${ip}
netmask 255.255.0.0
            mtu 1450" >> /etc/network/interfaces
            /sbin/ifup --all
        fi
elif ( [ "${BUILDOS}" = "ubuntu" ] )
    then
        if ( [ "${BUILDOSVERSION}" = "18.04" ] || [ "${BUILDOSVERSION}" = "19.04" ] )
        then
            /bin/echo "network:
  version: 2
  renderer: networkd
  ethernets:
    ens7:
      mtu: 1450
      dhcp4: no
      addresses: [${ip}/16]" >> /etc/netplan/10-ens7.yaml
            /usr/sbin/netplan apply
        fi
    fi
    /bin/touch ${HOME}/runtime/NETCONFIGURED
fi
