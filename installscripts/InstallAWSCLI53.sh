#!/bin/sh
######################################################################################################
# Description: This script will install the AWS CLI 53 tool
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
    download_link="`/usr/bin/curl https://github.com/barnybug/cli53/releases/latest/ | /bin/sed 's/^[^"]*"//g' | /bin/sed 's/".*$//g'`/cli53-linux-amd64"
    /usr/bin/wget ${download_link}
    /bin/mv cli53-linux-amd64 /usr/local/bin/cli53
    /bin/chmod +x /usr/local/bin/cli5
fi

if ( [ "${BUILD_OS}" = "debian" ] )
then
    download_link="`/usr/bin/curl https://github.com/barnybug/cli53/releases/latest/ | /bin/sed 's/^[^"]*"//g' | /bin/sed 's/".*$//g'`/cli53-linux-amd64"
    /usr/bin/wget ${download_link}
    /bin/mv cli53-linux-amd64 /usr/local/bin/cli53
    /bin/chmod +x /usr/local/bin/cli5
fi
