#!/bin/sh
###############################################################################################
# Description: This script will install tugboat
# Author: Peter Winter
# Date: 12/01/2017
###############################################################################################
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
################################################################################################
################################################################################################

if ( [ "${1}" != "" ] )
then
    BUILDOS="${1}"
fi

if ( [ "${BUILDOS}" = "ubuntu" ] )
then
    latest_doctl_version="`/usr/bin/curl https://github.com/digitalocean/doctl/releases | /bin/grep releases | /bin/grep download | /bin/grep doctl | /bin/grep href | /bin/grep tar.gz | /bin/sed 's/.*\/v//g' | /usr/bin/awk -F'/' '{print $1}' | /usr/bin/head -1`"
    /usr/bin/curl -sL https://github.com/digitalocean/doctl/releases/download/v${latest_doctl_version}/doctl-${latest_doctl_version}-linux-amd64.tar.gz | /bin/tar -xzv
    /bin/mv doctl /usr/local/bin
fi

if ( [ "${BUILDOS}" = "debian" ] )
then
    latest_doctl_version="`/usr/bin/curl https://github.com/digitalocean/doctl/releases | /bin/grep releases | /bin/grep download | /bin/grep doctl | /bin/grep href | /bin/grep tar.gz | /bin/sed 's/.*\/v//g' | /usr/bin/awk -F'/' '{print $1}' | /usr/bin/head -1`"
    /usr/bin/curl -sL https://github.com/digitalocean/doctl/releases/download/v${latest_doctl_version}/doctl-${latest_doctl_version}-linux-amd64.tar.gz | /bin/tar -xzv
    /bin/mv doctl /usr/local/bin
fi

