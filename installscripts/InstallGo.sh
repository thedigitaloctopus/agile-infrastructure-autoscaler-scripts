#!/bin/sh
######################################################################################################
# Description: This script will install lego
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

if ( [ "${BUILD_OS}" = "ubuntu" ] )
then
    /usr/bin/curl -O -s https://storage.googleapis.com/golang/go1.13.linux-amd64.tar.gz
    /bin/tar -xf go1.13.linux-amd64.tar.gz
    /bin/rm go1.13.linux-amd64.tar.gz
    /bin/mv go /usr/local
fi

if ( [ "${BUILD_OS}" = "debian" ] )
then
    /usr/bin/curl -O -s https://storage.googleapis.com/golang/go1.13.linux-amd64.tar.gz
    /bin/tar -xf go1.13.linux-amd64.tar.gz
    /bin/rm go1.13.linux-amd64.tar.gz
    /bin/mv go /usr/local
fi
