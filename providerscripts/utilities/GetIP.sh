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

if ( [ -f ${HOME}/EXOSCALE ] )
then
    /usr/sbin/dhclient 1>/dev/null 2>/dev/null
fi

IP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'MYIP'`"
if ( [ "`/usr/bin/ip addr | /bin/grep ${IP}`" != "" ] )
then
    /bin/echo ${IP}
fi

BUILDOS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOS'`"
BUILDOSVERSION="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOSVERSION'`"



if ( [ -f ${HOME}/VULTR ] && [ ! -f ${HOME}/runtime/NETCONFIGURED ] )
then
    ip="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'MYIP'`"
    
    if ( [ "${BUILDOS}" = "debian" ] )
    then
        if ( [ "${BUILDOSVERSION}" = "10" ] )
        then
            /bin/echo "auto ens7
iface ens7 inet static
address ${ip}
netmask 255.255.0.0
            mtu 1450" >> /etc/network/interfaces
            /sbin/ifup --all
        fi
        if ( [ "${BUILDOSVERSION}" = "11" ] )
        then
            /bin/echo "auto enp6s0
iface enp6s0 inet static
address ${IP}
netmask 255.255.0.0
            mtu 1450" >> /etc/network/interfaces
            /sbin/ifup --all
        fi
elif ( [ "${BUILDOS}" = "ubuntu" ] )
    then
        if ( [ "${BUILDOSVERSION}" = "20.04" ]  )
        then
            mac="`/usr/bin/ip addr | /bin/grep "link" | /bin/grep "ether" | /usr/bin/tail -1 | /usr/bin/awk '{print $2}'`"
            /bin/echo "network:
  version: 2
  renderer: networkd
  ethernets:
    enp6s0:
      match:
        macaddress: ${mac}
      mtu: 1200
      dhcp4: no
      addresses: [${ip}/16]" > /etc/netplan/10-enp6s0.yaml
            /usr/sbin/netplan apply
        fi
    fi
    /bin/touch ${HOME}/runtime/NETCONFIGURED
fi
