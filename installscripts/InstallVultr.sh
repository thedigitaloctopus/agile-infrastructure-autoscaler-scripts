#!/bin/sh
###############################################################################################
# Description: This script will install vultr toolkit
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
set -x

if ( [ "${1}" != "" ] )
then
    BUILD_OS="${1}"
fi

if ( [ "${BUILD_OS}" = "ubuntu" ] )
then
    /usr/local/go/bin/go get -u github.com/vultr/vultr-cli

    vultr=`/usr/bin/find / -name "vultr-cli" -print | /bin/grep -v github`

    /usr/bin/ln ${vultr} /usr/bin/vultr
    
   # latest="`/usr/bin/curl https://github.com/JamesClonk/vultr/releases/latest | /bin/sed 's/.*tag\///g' | /bin/sed 's/\".*//g' | /bin/sed 's/v//g'`"
   # /usr/bin/wget -O ${HOME}/vultrcli.tar.gz https://github.com/JamesClonk/vultr/releases/download/v${latest}/vultr_${latest}_Linux-64bit.tar.gz 
   # if ( [ ! -d ${HOME}/vultrcli ] )
   # then
   #     /bin/mkdir ${HOME}/vultrcli
   # fi
   # /bin/tar xvfz ${HOME}/vultrcli.tar.gz  -C ${HOME}/vultrcli
   # /bin/mv ${HOME}/vultrcli/vultr /usr/bin
   # /bin/rm -r ${HOME}/vultrcli
   # /bin/rm ${HOME}/vultrcli.tar.gz 
fi

if ( [ "${BUILD_OS}" = "debian" ] )
then
    /usr/local/go/bin/go get -u github.com/vultr/vultr-cli

    vultr=`/usr/bin/find / -name "vultr-cli" -print | /bin/grep -v github`

    /usr/bin/ln ${vultr} /usr/bin/vultr
    
   # latest="`/usr/bin/curl https://github.com/JamesClonk/vultr/releases/latest | /bin/sed 's/.*tag\///g' | /bin/sed 's/\".*//g' | /bin/sed 's/v//g'`"
   # /usr/bin/wget -O ${HOME}/vultrcli.tar.gz https://github.com/JamesClonk/vultr/releases/download/v${latest}/vultr_${latest}_Linux-64bit.tar.gz 
   # if ( [ ! -d ${HOME}/vultrcli ] )
   # then
   #     /bin/mkdir ${HOME}/vultrcli
   # fi
   # /bin/tar xvfz ${HOME}/vultrcli.tar.gz  -C ${HOME}/vultrcli
   # /bin/mv ${HOME}/vultrcli/vultr /usr/bin
   # /bin/rm -r ${HOME}/vultrcli
   # /bin/rm ${HOME}/vultrcli.tar.gz  
fi


