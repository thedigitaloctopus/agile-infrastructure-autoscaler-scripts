#!/bin/sh
######################################################################################################
# Description: This script will install the s3fs system
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

if ( [ "${1}" != "" ] )
then
    BUILDOS="${1}"
fi

if ( [ "${BUILDOS}" = "ubuntu" ] )
then
    if ( [ ! -f /usr/bin/s3fs ] )
    then
        if ( [ "`${HOME}/providerscripts/utilities/CheckBuildStyle.sh 'S3FS:repo'`" = "1" ] )
        then
            /usr/bin/apt-get -qq -y install s3fs
        elif ( [ "`${HOME}/providerscripts/utilities/CheckBuildStyle.sh 'S3FS:source'`" = "1" ] )
        then
            /usr/bin/apt-get -qq -y install build-essential git libfuse-dev libcurl4-openssl-dev libxml2-dev mime-support automake libtool
            /usr/bin/apt-get -qq -y install pkg-config libssl-dev
            /usr/bin/git clone https://github.com/s3fs-fuse/s3fs-fuse
            cd s3fs-fuse/
            ./autogen.sh
            ./configure --prefix=/usr --with-openssl
            /usr/bin/make
            /usr/bin/make install
        fi
    fi
fi

if ( [ "${BUILDOS}" = "debian" ] )
then
    if ( [ ! -f /usr/bin/s3fs ] )
    then
        if ( [ "`${HOME}/providerscripts/utilities/CheckBuildStyle.sh 'S3FS:repo'`" = "1" ] )
        then
            /usr/bin/apt-get -qq -y install s3fs
        elif ( [ "`${HOME}/providerscripts/utilities/CheckBuildStyle.sh 'S3FS:source'`" = "1" ] )
        then
            /usr/bin/apt-get -qq -y install build-essential git libfuse-dev libcurl4-openssl-dev libxml2-dev mime-support automake libtool
            /usr/bin/apt-get -qq -y install pkg-config libssl-dev
            /usr/bin/git clone https://github.com/s3fs-fuse/s3fs-fuse
            cd s3fs-fuse/
            ./autogen.sh
            ./configure --prefix=/usr --with-openssl
            /usr/bin/make
            /usr/bin/make install
        fi
    fi
fi
