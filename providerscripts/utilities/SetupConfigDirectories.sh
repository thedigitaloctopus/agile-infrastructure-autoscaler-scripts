#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 05/04/2017
# Description: This will insure that the configuration diretories are available as required
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

if ( [ ! -d ${HOME}/config/beingbuiltips ] )
then
    /bin/mkdir -p ${HOME}/config/beingbuiltips
    /bin/chmod 700 ${HOME}/config/beingbuiltips
fi
if ( [ ! -d ${HOME}/config/beingbuiltpublicips ] )
then
    /bin/mkdir -p ${HOME}/config/beingbuiltpublicips
    /bin/chmod 700 ${HOME}/config/beingbuiltpublicips
fi
if ( [ ! -d ${HOME}/config/webserverpublicips ] )
then
    /bin/mkdir -p ${HOME}/config/webserverpublicips
    /bin/chmod 700 ${HOME}/config/webserverpublicips
fi
if ( [ ! -d ${HOME}/config/webserverips ] )
then
    /bin/mkdir -p ${HOME}/config/webserverips
    /bin/chmod 700 ${HOME}/config/webserverips
fi

if ( [ ! -d ${HOME}/config/databaseip ] )
then
    /bin/mkdir -p ${HOME}/config/databaseip
    /bin/chmod 700 ${HOME}/config/databaseip
fi
if ( [ ! -d ${HOME}/config/databasepublicip ] )
then
    /bin/mkdir -p ${HOME}/config/databasepublicip
    /bin/chmod 700 ${HOME}/config/databasepublicip
fi
if ( [ ! -d ${HOME}/config/bootedwebserverips ] )
then
    /bin/mkdir -p ${HOME}/config/bootedwebserverips
    /bin/chmod 700 ${HOME}/config/bootedwebserverips
fi
if ( [ ! -d ${HOME}/config/shuttingdownwebserverips ] )
then
    /bin/mkdir -p ${HOME}/config/shuttingdownwebserverips
    /bin/chmod 700 ${HOME}/config/shuttingdownwebserverips
fi
if ( [ ! -d ${HOME}/config/autoscalerip ] )
then
    /bin/mkdir -p ${HOME}/config/autoscalerip
    /bin/chmod 700 ${HOME}/config/autoscalerip
fi
if ( [ ! -d ${HOME}/config/autoscalerpublicip ] )
then
    /bin/mkdir -p ${HOME}/config/autoscalerpublicip
    /bin/chmod 700 ${HOME}/config/autoscalerpublicip
fi
if ( [ ! -d ${HOME}/config/buildclientip ] )
then
    /bin/mkdir -p ${HOME}/config/buildclientip
    /bin/chmod 700 ${HOME}/config/buildclientip
fi
if ( [ ! -d ${HOME}/config/credentials ] )
then
    /bin/mkdir -p ${HOME}/config/credentials
    /bin/chmod 700 ${HOME}/config/credentials
fi

if ( [ ! -d ${HOME}/config/webrootsynctunnel ] )
then
    /bin/mkdir -p ${HOME}/config/webrootsynctunnel
    /bin/chmod 700 ${HOME}/config/webrootsynctunnel
fi

if ( [ ! -d ${HOME}/config/ssl ] )
then
    /bin/mkdir -p ${HOME}/config/ssl
    /bin/chmod 700 ${HOME}/config/ssl
fi
