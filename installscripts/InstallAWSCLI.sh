#!/bin/sh
###############################################################################################
# Description: This script will install AWS cli
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
    /usr/bin/apt-get install unzip
    /usr/bin/curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    /usr/bin/unzip awscliv2.zip
    ./aws/install
    /usr/bin/ln -s /usr/local/bin/aws /usr/bin/aws
    #/usr/bin/apt-get -qq -y install awscli
    #/usr/bin/unlink /usr/local/bin/aws
    #/usr/bin/ln -s /usr/bin/aws /usr/local/bin/aws
fi

if ( [ "${BUILDOS}" = "debian" ] )
then
    /usr/bin/apt-get install unzip
    /usr/bin/curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    /usr/bin/unzip awscliv2.zip
    ./aws/install
    /usr/bin/ln -s /usr/local/bin/aws /usr/bin/aws
    #/usr/bin/apt-get -qq -y install awscli
    #/usr/bin/unlink /usr/local/bin/aws
    #/usr/bin/ln -s /usr/bin/aws /usr/local/bin/aws
fi
