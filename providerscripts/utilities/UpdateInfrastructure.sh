#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 11/11/2021
# Description: When a machine is rebooted, it pulls down the latest version of the 
# infrastructure repositories
#######################################################################################
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
########################################################################################
########################################################################################
#set -x

cd ${HOME}
if ( [ -d agile-infrastructure-autoscaler-scripts ] )
then
    /bin/rm -r agile-infrastructure-autoscaler-scripts
fi
infrastructure_repository_owner="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYOWNER'`"
/usr/bin/git clone https://github.com/${infrastructure_repository_owner}/agile-infrastructure-autoscaler-scripts.git
cd agile-infrastructure-autoscaler-scripts
/bin/cp -r * ${HOME}
cd ..
/bin/rm -r agile-infrastructure-autoscaler-scripts
