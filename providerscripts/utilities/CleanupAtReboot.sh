#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 11/04/2019
# Description: If a machine is rebooted, you may want to do some cleanup before the next 
# session starts. You can put your cleanup code in here and it will be called on reboot
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

${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "autoscalerpublicip/*"
${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "autoscalerip/*"

