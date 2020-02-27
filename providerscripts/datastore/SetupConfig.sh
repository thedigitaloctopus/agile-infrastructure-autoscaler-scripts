#!/bin/sh
####################################################################################
# Description: This script mounts a bucket from a cloud based datastore and uses it
# as a shared config directory to pass configuration settings around between machines
# Author: Peter Winter
# Date :  9/4/2016
###################################################################################
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
####################################################################################
####################################################################################

#set -x

if ( [ "`/bin/ls ${HOME}/config 2>&1 | /bin/grep "Transport endpoint is not connected"`" != "" ] )
then
    /bin/umount -f ${HOME}/config
fi

if ( [ "`/bin/mount | /bin/grep ${HOME}/config`" != "" ] )
then
    exit
fi

BUILDOS="`/bin/ls ${HOME}/.ssh/BUILDOS:* | /usr/bin/awk -F':' '{print $NF}'`"
DATASTORE_PROVIDER="`/bin/ls ${HOME}/.ssh/DATASTORECHOICE:* | /usr/bin/awk -F':' '{print $NF}'`"
WEBSITE_URL="`/bin/ls ${HOME}/.ssh/WEBSITEURL:* | /usr/bin/awk -F':' '{print $NF}'`"
configbucket="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{ for(i = 1; i <= NF; i++) { print $i; } }' | /usr/bin/cut -c1-3 | /usr/bin/tr '\n' '-' | /bin/sed 's/-//g'`"
configbucket="${configbucket}-config"
endpoint="`/bin/cat ~/.s3cfg | /bin/grep host_base | /usr/bin/awk '{print $NF}'`"


if ( [ "${DATASTORE_PROVIDER}" = "amazonS3" ] )
then
    export AWSACCESSKEYID=`/bin/cat ~/.s3cfg | /bin/grep 'access_key' | /usr/bin/awk '{print $NF}'`
    export AWSSECRETACCESSKEY=`/bin/cat ~/.s3cfg | /bin/grep 'secret_key' | /usr/bin/awk '{print $NF}'`
    
    if ( [ "`/bin/mount | /bin/grep ${HOME}/config`" = "" ] )
    then
       if ( [ -f ${HOME}/.ssh/ENABLEEFS:1 ] )
       then
           aws_region="`/bin/cat ${HOME}/.aws/config | /bin/grep region | /usr/bin/awk '{print $NF}'`"
           /bin/mkdir ~/.aws 2>/dev/null
           /bin/cp ${HOME}/.aws/* ~/.aws 2>/dev/null

           /usr/bin/aws efs describe-file-systems | /usr/bin/jq '.FileSystems[] | .CreationToken + " " + .FileSystemId' | /bin/sed 's/\"//g' | while read identifier
           do
                if ( [ "`/bin/echo ${identifier} | /bin/grep ${configbucket}`" != "" ] )
                then
                    id="`/bin/echo ${identifier} | /usr/bin/awk '{print $NF}'`"
                    efsmounttarget="`/usr/bin/aws efs describe-mount-targets --file-system-id ${id} | /usr/bin/jq '.MountTargets[].IpAddress' | /bin/sed 's/"//g'`"
                    /bin/mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efsmounttarget}:/   ${HOME}/config
                 fi
            done
        else
            /usr/bin/s3cmd mb s3://${configbucket}
            /usr/bin/s3fs -o nonempty -ourl=https://${endpoint} ${configbucket} ${HOME}/config
        fi
    fi
fi

if ( [ "${DATASTORE_PROVIDER}" = "digitalocean" ] )
then
    export AWSACCESSKEYID=`/bin/cat ~/.s3cfg | /bin/grep 'access_key' | /usr/bin/awk '{print $NF}'`
    export AWSSECRETACCESSKEY=`/bin/cat ~/.s3cfg | /bin/grep 'secret_key' | /usr/bin/awk '{print $NF}'`
    /usr/bin/s3cmd mb s3://${configbucket}
    /usr/bin/s3fs -o nonempty -ourl=https://${endpoint} ${configbucket} ${HOME}/config
fi

if ( [ "${DATASTORE_PROVIDER}" = "exoscale" ] )
then
    export AWSACCESSKEYID=`/bin/cat ~/.s3cfg | /bin/grep 'access_key' | /usr/bin/awk '{print $NF}'`
    export AWSSECRETACCESSKEY=`/bin/cat ~/.s3cfg | /bin/grep 'secret_key' | /usr/bin/awk '{print $NF}'`
    /usr/bin/s3cmd mb s3://${configbucket}
    /usr/bin/s3fs -o nonempty -ourl=https://${endpoint} ${configbucket} ${HOME}/config
fi

if ( [ "${DATASTORE_PROVIDER}" = "linode" ] )
then
    export AWSACCESSKEYID=`/bin/cat ~/.s3cfg | /bin/grep 'access_key' | /usr/bin/awk '{print $NF}'`
    export AWSSECRETACCESSKEY=`/bin/cat ~/.s3cfg | /bin/grep 'secret_key' | /usr/bin/awk '{print $NF}'`
    /usr/bin/s3cmd mb s3://${configbucket}
    /usr/bin/s3fs -o nonempty -ourl=https://${endpoint} ${configbucket} ${HOME}/config
fi

if ( [ "${DATASTORE_PROVIDER}" = "vultr" ] )
then
    export AWSACCESSKEYID=`/bin/cat ~/.s3cfg | /bin/grep 'access_key' | /usr/bin/awk '{print $NF}'`
    export AWSSECRETACCESSKEY=`/bin/cat ~/.s3cfg | /bin/grep 'secret_key' | /usr/bin/awk '{print $NF}'`
    /usr/bin/s3cmd mb s3://${configbucket}
    /usr/bin/s3fs -o nonempty -ourl=https://${endpoint} ${configbucket} ${HOME}/config
fi

if ( [ ! -f ${HOME}/runtime/INITIALCONFIGSET ] )
then
    /bin/rm -r ${HOME}/config/*
    if ( [ "$?" = "0" ] )
    then
        /bin/touch ${HOME}/runtime/INITIALCONFIGSET
    fi
fi

if ( [ ! -d ${HOME}/config/beingbuiltips ] )
then
    /bin/mkdir -p ${HOME}/config/beingbuiltips
    /bin/chmod 700 ${HOME}/config/beingbuiltips
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

if ( [ ! -d ${HOME}/config/webserveripcouples ] )
then
    /bin/mkdir -p ${HOME}/config/webserveripcouples
    /bin/chmod 700 ${HOME}/config/webserveripcouples
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

/bin/echo "THESE DIRECTORIES ARE HERE FOR USE DURING THE OPERATION OF THE DIFFERENT CLASSES OF MACHINES IN THE ADTK" > ${HOME}/config/README
/bin/echo "ESSENTIAL INFORMATION IS SHARED BETWEEN THE MACHINES USING THESE SHARED DIRECTRIES MOUNTED FROM A DATASTORE" >> ${HOME}/config/README
/bin/echo "THE CONFIGURATION FILES STORED HERE ARE THE AUTHORITATIVE CONFIGURATION FOR YOUR APPLICATION" >> ${HOME}/config/README

