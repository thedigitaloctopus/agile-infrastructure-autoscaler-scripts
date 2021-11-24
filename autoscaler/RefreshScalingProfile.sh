#!/bin/sh
#####################################################################################
# Author: Peter Winter
# Date  : 13/07/2021
# Description : #With s3fs if the user updates the profile.cnf file without changing 
# the number of bytes s3fs assumes it didn't change
# So, add an extra space to it in order to signal a change such that if it has actually changed 
# it will definitely be picked up.
#####################################################################################
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
######################################################################################
######################################################################################
#set -x
if ( [ -f ${HOME}/config/scalingprofile/profile.cnf ] )
then
    if ( [ "`/bin/grep -cvP '\S' ${HOME}/config/scalingprofile/profile.cnf`" -gt "60" ] )
    then
        /bin/sed -i '/^ $/d' ${HOME}/config/scalingprofile/profile.cnf
    else
       /bin/echo " " >> ${HOME}/config/scalingprofile/profile.cnf
    fi
fi

/bin/touch ${HOME}/config/scalingprofile/ONLY_EDIT_profile.cnf_ON_AN_AUTOSCALER
