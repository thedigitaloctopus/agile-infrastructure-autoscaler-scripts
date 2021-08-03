#!/bin/sh
######################################################################################################
# Description: This script will install the exo utility
# Author: Peter Winter
# Date: 17/01/2017
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
#set -x

if ( [ "${1}" != "" ] )
then
    BUILD_OS="${1}"
fi

/bin/mkdir exo_unpack

if ( [ "${BUILD_OS}" = "ubuntu" ] )
then
    exo_version="`/usr/bin/curl https://github.com/exoscale/cli/releases | /bin/grep releases | /bin/grep exoscale-cli | /usr/bin/tac | /usr/bin/head -1 | /bin/sed "s/.*exoscale-cli_//g" | /usr/bin/awk -F'_' '{print $1}'`"
    /usr/bin/wget https://github.com/exoscale/cli/releases/download/v${exo_version}/exoscale-cli_${exo_version}_linux_amd64.tar.gz
    /usr/bin/tar xvfz exoscale-cli*tar.gz -C ./exo_unpack
    /bin/mv ./exo_unpack/exo /usr/bin
    /bin/rm -r ./exo_unpack
fi

if ( [ "${BUILD_OS}" = "debian" ] )
then
    exo_version="`/usr/bin/curl https://github.com/exoscale/cli/releases | /bin/grep releases | /bin/grep exoscale-cli | /usr/bin/tac | /usr/bin/head -1 | /bin/sed "s/.*exoscale-cli_//g" | /usr/bin/awk -F'_' '{print $1}'`"
    /usr/bin/wget https://github.com/exoscale/cli/releases/download/v${exo_version}/exoscale-cli_${exo_version}_linux_amd64.tar.gz
    /usr/bin/tar xvfz exoscale-cli*tar.gz -C ./exo_unpack
    /bin/mv ./exo_unpack/exo /usr/bin
    /bin/rm -r ./exo_unpack
fi
