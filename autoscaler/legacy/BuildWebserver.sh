#!/bin/sh
############################################################################################
# Author: Peter Winter
# Date  : 04/07/2016
# Description : This script will build a webserver from scratch as part of an autoscaling event
# It depends on the provider scripts and will build according to the provider it is configured for
########################################################################################################################
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

#If we are trying to build a webserver before the toolkit has been fully installed, we don't want to do anything, so exit
if ( [ ! -f ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
    exit
fi

#The output of the build process is added to a log file so that you have a record of what has been built and
#if there were any problems that need addressing
/bin/echo "===================================================================================================" >>${HOME}/logs/AUTOSCALER_BUILD.log
exec >>${HOME}/logs/AUTOSCALER_BUILD.log
exec 2>&1

LOG_FILE="webserver_log_`/bin/date | /bin/sed 's/ //g'`"
ERR_FILE="webserver_err_`/bin/date | /bin/sed 's/ //g'`"

#Check there is a directory for logging
if ( [ ! -d ${HOME}/logs ] )
then
    /bin/mkdir -p ${HOME}/logs
fi

DONE="0"
ip=""
TRIES=0

#Pull the configuration into memory for easy access

KEY_ID="`/bin/ls ${HOME}/.ssh | /bin/grep "KEYID" | /usr/bin/awk -F':' '{print $NF}'`"
BUILD_CHOICE="`/bin/ls ${HOME}/.ssh/BUILDCHOICE:* | /usr/bin/awk -F':' '{print $NF}'`"
REGION="`/bin/ls ${HOME}/.ssh/REGION:* | /usr/bin/awk -F':' '{print $NF}'`"
SIZE="`/bin/ls ${HOME}/.ssh/SIZE:* | /usr/bin/awk -F':' '{print $NF}'`"
BUILD_IDENTIFIER="`/bin/ls ${HOME}/.ssh/BUILDIDENTIFIER:* | /usr/bin/awk -F':' '{print $NF}'`"
CLOUDHOST="`/bin/ls ${HOME}/.ssh/CLOUDHOST:* | /usr/bin/awk -F':' '{print $NF}'`"
ALGORITHM="`/bin/ls ${HOME}/.ssh/ALGORITHM:* | /usr/bin/awk -F':' '{print $NF}'`"
WEBSITE_URL="`/bin/ls ${HOME}/.ssh/WEBSITEURL:* | /usr/bin/awk -F':' '{print $NF}'`"
WEBSITE_NAME="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{print $2}'`"
z="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{$1=""}1' | /bin/sed 's/^ //g' | /bin/sed 's/ /./g'`"
name="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{print $1}'`"
WEBSITE_DISPLAY_NAME="`/bin/ls ${HOME}/.ssh/WEBSITEDISPLAYNAME:* | /bin/sed 's/_/ /g' | /usr/bin/awk -F':' '{print $NF}'`"
DNS_CHOICE="`/bin/ls ${HOME}/.ssh/DNSCHOICE:* | /usr/bin/awk -F':' '{print $NF}'`"
DNS_SECURITY_KEY="`/bin/ls ${HOME}/.ssh/DNSSECURITYKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
DNS_USERNAME="`/bin/ls ${HOME}/.ssh/DNSUSERNAME:* | /usr/bin/awk -F':' '{print $NF}'`"
GIT_USER="`/bin/ls ${HOME}/.ssh/GITUSER:* | /usr/bin/awk -F':' '{print $NF}'`"
GIT_EMAIL_ADDRESS="`/bin/ls ${HOME}/.ssh/GITEMAILADDRESS:* | /usr/bin/awk -F':' '{print $NF}'`"

INFRASTRUCTURE_REPOSITORY_PROVIDER="`/bin/ls ${HOME}/.ssh/INFRASTRUCTUREREPOSITORYPROVIDER:* | /usr/bin/awk -F':' '{print $NF}'`"
INFRASTRUCTURE_REPOSITORY_USERNAME="`/bin/ls ${HOME}/.ssh/INFRASTRUCTUREREPOSITORYUSERNAME:* | /usr/bin/awk -F':' '{print $NF}'`"
INFRASTRUCTURE_REPOSITORY_PASSWORD="`/bin/ls ${HOME}/.ssh/INFRASTRUCTUREREPOSITORYPASSWORD:* | /usr/bin/awk -F':' '{print $NF}'`"
INFRASTRUCTURE_REPOSITORY_OWNER="`/bin/ls ${HOME}/.ssh/INFRASTRUCTUREREPOSITORYOWNER:* | /usr/bin/awk -F':' '{print $NF}'`"
APPLICATION_REPOSITORY_PROVIDER="`/bin/ls ${HOME}/.ssh/APPLICATIONREPOSITORYPROVIDER:* | /usr/bin/awk -F':' '{print $NF}'`"
APPLICATION_REPOSITORY_OWNER="`/bin/ls ${HOME}/.ssh/APPLICATIONREPOSITORYOWNER:* | /usr/bin/awk -F':' '{print $NF}'`"
APPLICATION_REPOSITORY_USERNAME="`/bin/ls ${HOME}/.ssh/APPLICATIONREPOSITORYUSERNAME:* | /usr/bin/awk -F':' '{print $NF}'`"
APPLICATION_REPOSITORY_PASSWORD="`/bin/ls ${HOME}/.ssh/APPLICATIONREPOSITORYPASSWORD:* | /usr/bin/awk -F':' '{print $NF}'`"
APPLICATION_REPOSITORY_TOKEN="`/bin/ls ${HOME}/.ssh/APPLICATIONREPOSITORYTOKEN:* | /usr/bin/awk -F':' '{print $NF}'`"


SERVER_USER="`/bin/ls ${HOME}/.ssh/SERVERUSER:* | /usr/bin/awk -F':' '{print $NF}'`"
SERVER_USER_PASSWORD="`/bin/ls ${HOME}/.ssh/SERVERUSERPASSWORD:* | /usr/bin/awk -F':' '{print $NF}'`"
CLOUDHOST_PASSWORD="`/bin/ls ${HOME}/.ssh/CLOUDHOSTPASSWORD:* | /usr/bin/awk -F':' '{print $NF}'`"
BUILD_ARCHIVE="`/bin/ls ${HOME}/.ssh/BUILDARCHIVE:* | /usr/bin/awk -F':' '{print $NF}'`"
NO_IMAGE_SERVERS="`/bin/ls ${HOME}/.ssh/NO_IMAGE_SERVERS:* | /usr/bin/awk -F':' '{print $NF}'`"
IN_MEMORY_CACHE="`/bin/ls ${HOME}/.ssh/INMEMORYCACHE:* | /usr/bin/awk -F':' '{print $NF}'`"
DATASTORE_CHOICE="`/bin/ls ${HOME}/.ssh/DATASTORECHOICE:* | /usr/bin/awk -F':' '{print $NF}'`"
WEBSERVER_CHOICE="`/bin/ls ${HOME}/.ssh/WEBSERVERCHOICE:* | /usr/bin/awk -F':' '{print $NF}'`"

APPLICATION_IDENTIFIER="`/bin/ls ${HOME}/.ssh/APPLICATIONIDENTIFIER:* | /usr/bin/awk -F':' '{print $NF}'`"
APPLICATION_LANGUAGE="`/bin/ls ${HOME}/.ssh/APPLICATIONLANGUAGE:* | /usr/bin/awk -F':' '{print $NF}'`"
SOURCECODE_REPOSITORY="`/bin/ls ${HOME}/.ssh/APPLICATIONBASELINESOURCECODEREPOSITORY:* | /usr/bin/awk -F':' '{print $NF}'`"


/bin/touch ${HOME}/.ssh/ASIP:`${HOME}/providerscripts/utilities/GetIP.sh`

#If it doesn't successfully build the webserver, try building another one up to a maximum of 3 attempts
/bin/echo "${0} `/bin/date`: Building a new webserver" >> ${HOME}/logs/MonitoringLog.log

# Set up the webservers properties, like its name and so on.
RND="`/bin/cat /dev/urandom | /usr/bin/tr -dc 'a-zA-Z0-9' | /usr/bin/fold -w 4 | /usr/bin/head -n 1`"
SERVER_TYPE="webserver"
SERVER_NUMBER="`${HOME}/providerscripts/server/NumberOfServers.sh "${SERVER_TYPE}" ${CLOUDHOST}`"
WEBSITE_URL="`/bin/ls ${HOME}/.ssh | grep WEBSITEURL | /usr/bin/awk -F':' '{print $NF}'`"
webserver_name="webserver-${RND}-${WEBSITE_NAME}-${BUILD_IDENTIFIER}"
SERVER_INSTANCE_NAME="`/bin/echo ${webserver_name} | /usr/bin/cut -c -32 | /bin/sed 's/-$//g'`"
SSH_PORT="`/bin/ls ${HOME}/.ssh/SSH_PORT:* | /usr/bin/awk -F':' '{print $NF}'`"

#What type of machine are we building - this will determine the size and so on with the cloudhost
SERVER_TYPE_ID="`${HOME}/providerscripts/server/GetServerTypeID.sh ${SIZE} "${SERVER_TYPE}" ${CLOUDHOST}`"

#Hell, what operating system are we running
ostype="`${HOME}/providerscripts/cloudhost/GetOperatingSystemVersion.sh ${SIZE} ${CLOUDHOST}`"

#Attempt to create a vanilla machine on which to build our webserver
buildmethod="`${HOME}/providerscripts/server/CreateServer.sh "${ostype}" "${REGION}" "${SERVER_TYPE_ID}" "${SERVER_INSTANCE_NAME}" "${KEY_ID}" ${CLOUDHOST} "root" ${CLOUDHOST_PASSWORD}`"

count="0"
while ( [ "$?" != "0" ] && [ "${count}" -lt "10" ] )
do
    /bin/sleep 5
    buildmethod="`${HOME}/providerscripts/server/CreateServer.sh "${ostype}" "${REGION}" "${SERVER_TYPE_ID}" "${SERVER_INSTANCE_NAME}" "${KEY_ID}" ${CLOUDHOST} "root" ${CLOUDHOST_PASSWORD}`"
    count="`/usr/bin/expr ${count} + 1`"
done

if ( [ "${count}" = "10" ] )
then
    /bin/echo "${0} `/bin/date`: Failed to build server" >> ${HOME}/logs/MonitoringLog.log
    exit
fi

count="0"

# There is a delay between the server being created and started and it "coming online". The way we can tell it is online is when
# It returns an ip address, so try, several times to retrieve the ip address of the server
while ( [ "`/bin/echo ${ip} | /bin/grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`" = "" ] && [ "${count}" -lt "30" ] || [ "${ip}" = "0.0.0.0" ] )
do
    /bin/sleep 5
    ip="`${HOME}/providerscripts/server/GetServerIPAddresses.sh ${SERVER_INSTANCE_NAME} ${CLOUDHOST}`"
    private_ip="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh ${SERVER_INSTANCE_NAME} ${CLOUDHOST}`"
    /bin/touch ${HOME}/config/webserverips/${private_ip}
    count="`/usr/bin/expr ${count} + 1`"
done

if ( [ "${ip}" = "" ] )
then
    /bin/echo "${0} `/bin/date`: Server didn't come online " >> ${HOME}/logs/MonitoringLog.log
    exit
fi

#We add our IP address to a list of machines in the 'being built' stage. We can check this flag elsewhere when we want to
#distinguish between ip address of webservers which have been built and are still being built.
/usr/bin/touch ${HOME}/config/beingbuiltips/${private_ip}

#This webserver needs access to the autoscaler to mount the directory ${HOME}/config
/usr/sbin/ufw allow from ${private_ip} to any port ${SSH_PORT}

# Build our webserver
if ( [ "`/bin/echo ${buildmethod} | /bin/grep 'SNAPPED'`" = "" ] )
then
    #If we are here, then we are not building from a snapshot
    webserver_name="${SERVER_INSTANCE_NAME}"
    #Test to see if our server can be accessed using our build key
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=30 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o "PasswordAuthentication no" root@${ip} "exit"

    if ( [ "$?" != "0" ] )
    then
        #If we get to here, it means the ssh key failed, lets, then, try authenticating by password
        if ( [ ! -f /usr/bin/sshpass ] )
        then
            /usr/bin/apt-get -qq install sshpass
        fi
        count="0"
        if ( [ "${CLOUDHOST_PASSWORD}" != "" ] )
        then
            /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/ssh -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${ip} "DEBIAN_FRONTEND=noninteractive /bin/mkdir -p /root/.ssh" >/dev/null 2>&1
            /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/ssh -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${ip} "DEBIAN_FRONTEND=noninteractive /bin/mkdir -p /home/${SERVER_USER}/.ssh"
            while ( [ "$?" != "0" ] )
            do
                /bin/echo "Haven't successfully connected to the Webserver, maybe it is still initialising, trying again...."
                /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/ssh -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${CLOUDHOST_USERNAME}@${ip} "DEBIAN_FRONTEND=noninteractive /bin/mkdir -p /home/${SERVER_USER}/.ssh" >/dev/null 2>&1
                /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/ssh -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${CLOUDHOST_USERNAME}@${ip} "DEBIAN_FRONTEND=noninteractive /bin/mkdir -p /root/.ssh" >/dev/null 2>&1
                /bin/sleep 5
                count="`/usr/bin/expr ${count} + 1`"
            done

            if ( [ "${count}" = "10" ] )
            then
                /bin/echo "${0} `/bin/date`: Failed to build server" >> ${HOME}/logs/MonitoringLog.log
                exit
            fi
        else
            /bin/echo "${0} `/bin/date`: Failed to build server -cloudhost password not set" >> ${HOME}/logs/MonitoringLog.log
            exit
        fi
        #Set up our ssh keys
        /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/ssh -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${CLOUDHOST_USERNAME}@${ip} "DEBIAN_FRONTEND=noninteractive /bin/mkdir -p /home/${SERVER_USER}/.ssh" >/dev/null 2>&1
        /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/ssh -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${CLOUDHOST_USERNAME}@${ip} "DEBIAN_FRONTEND=noninteractive /bin/chmod 700 /home/${SERVER_USER}/.ssh" >/dev/null 2>&1
        /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/ssh -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${CLOUDHOST_USERNAME}@${ip} "DEBIAN_FRONTEND=noninteractive /bin/chmod 700 /root/.ssh" >/dev/null 2>&1
        /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/scp -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}.pub ${CLOUDHOST_USERNAME}@${ip}:/root/.ssh/authorized_keys >/dev/null 2>&1
        /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/scp -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}.pub ${CLOUDHOST_USERNAME}@${ip}:/home/${SERVER_USER}/.ssh/authorized_keys >/dev/null 2>&1
    else
        #set up our ssh keys
        /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}.pub root@${ip}:/root/.ssh/authorized_keys >/dev/null 2>&1
        /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}.pub root@${ip}:/home/${SERVER_USER}/.ssh/authorized_keys >/dev/null 2>&1
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${ip} "/bin/mkdir -p /home/${SERVER_USER}/.ssh"
    fi
    #Add our own user. root access is disabled, so we will have to connect through our own unprivileged user
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${ip} "/usr/bin/apt-get install sudo"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${ip} "/usr/sbin/useradd ${SERVER_USER}"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${ip} "/bin/echo ${SERVER_USER}:${SERVER_USER_PASSWORD} | /usr/sbin/chpasswd"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${ip} "/usr/bin/gpasswd -a ${SERVER_USER} sudo"
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}.pub root@${ip}:/home/${SERVER_USER}/.ssh/authorized_keys
    /bin/cat ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_INFRASTRUCTURE_KEY.pub | /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${ip} "/bin/cat - >> /home/${SERVER_USER}/.ssh/authorized_keys"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${ip} "/bin/chown -R ${SERVER_USER}.${SERVER_USER} /home/${SERVER_USER}/"
    #  /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${ip} "/usr/bin/apt-get -qq update && /usr/bin/apt-get install -qq git"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${ip} "/usr/bin/apt-get install -qq git"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${ip} "/bin/sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${ip} "/usr/sbin/service ssh restart"

    #Mark this as an autoscaled machine as distinct from one built during the initial build
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} '/bin/touch ${HOME}/.ssh/AUTOSCALED'

    #INFRASTRUCTURE PUBLIC KEY ADDED TO WEBSERVER
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_INFRASTRUCTURE_KEY.pub ${SERVER_USER}@${ip}:${HOME}/.ssh/authorized_keys.tmp
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} '/bin/cat ${HOME}/.ssh/authorized_keys.tmp >> ${HOME}/.ssh/authorized_keys'
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} '/bin/rm ${HOME}/.ssh/authorized_keys.tmp'
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} '/bin/chmod 400 ${HOME}/.ssh/authorized_keys'

    #INFRASTRUCTURE PRIVATE KEY ADDED TO WEBSERVER
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_INFRASTRUCTURE_KEY ${SERVER_USER}@${ip}:${HOME}/.ssh/id_${ALGORITHM}
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_INFRASTRUCTURE_KEY ${SERVER_USER}@${ip}:${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_INFRASTRUCTURE_KEY
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${SERVER_USER}@${ip}:${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/chmod 400 ${HOME}/.ssh/id_${ALGORITHM}"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/chmod 400 ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_INFRASTRUCTURE_KEY"

    if ( [ -f ${HOME}/.ssh/DATABASEINSTALLATIONTYPE:DBaaS-secured ] )
    then
        /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/dbaas_server_key.pem ${SERVER_USER}@${ip}:${HOME}/.ssh/dbaas_server_key.pem
    fi

    #CONFIG FILE
    ${HOME}/providerscripts/cloudhost/ConfigureProvider.sh ${CLOUDHOST} ${BUILD_IDENTIFIER} ${ALGORITHM} ${ip} ${SERVER_USER}

    #INSTALLING GIT
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "cd /home/${SERVER_USER}"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} '/usr/bin/git init'
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} '/bin/mkdir ${HOME}/bootstrap'
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/providerscripts/git/GitFetch.sh ${SERVER_USER}@${ip}:${HOME}/bootstrap
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/providerscripts/git/GitCheckout.sh ${SERVER_USER}@${ip}:${HOME}/bootstrap
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/providerscripts/git/GitPull.sh ${SERVER_USER}@${ip}:${HOME}/bootstrap
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} '/bin/chmod 700 ${HOME}/bootstrap/*'
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${HOME}/bootstrap/GitFetch.sh ${INFRASTRUCTURE_REPOSITORY_PROVIDER} ${INFRASTRUCTURE_REPOSITORY_USERNAME} ${INFRASTRUCTURE_REPOSITORY_PASSWORD} ${INFRASTRUCTURE_REPOSITORY_OWNER} agile-infrastructure-webserver-scripts"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${HOME}/bootstrap/GitCheckout.sh ${INFRASTRUCTURE_REPOSITORY_PROVIDER} ws.sh"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${HOME}/bootstrap/GitCheckout.sh ${INFRASTRUCTURE_REPOSITORY_PROVIDER} providerscripts/datastore/ConfigureDatastoreProvider.sh"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} '/bin/chmod -R 700 ${HOME}/providerscripts/*'
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} '/bin/chmod 700 ${HOME}/*.sh'


    #Configure our datastore for this server
    ${HOME}/providerscripts/datastore/ConfigureDatastoreProvider.sh ${DATASTORE_CHOICE} ${ip} ${CLOUDHOST} ${BUILD_IDENTIFIER} ${ALGORITHM} ${SERVER_USER}

    #IP addresses
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/IMIP:* ${SERVER_USER}@${ip}:${HOME}/.ssh
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/DBIP:* ${SERVER_USER}@${ip}:${HOME}/.ssh
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/ASIP:* ${SERVER_USER}@${ip}:${HOME}/.ssh

    #Configuration values
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/touch ${HOME}/.ssh/MYPUBLICIP:${ip}"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/touch ${HOME}/.ssh/MYIP:${private_ip}"

    #Copy across all our configuration values
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/BUILDOS:* ${HOME}/.ssh/BUILDOSVERSION:* ${HOME}/.ssh/BUILDCLIENTIP:* ${HOME}/.ssh/ALGORITHM:* ${HOME}/.ssh/BUILDARCHIVE:* ${HOME}/.ssh/BUILDCHOICE:* ${HOME}/.ssh/CLOUDHOST:* ${HOME}/.ssh/CLOUDHOSTPASSWORD:* ${HOME}/.ssh/DATASTORECHOICE:* ${HOME}/.ssh/INMEMORYCACHE:* ${HOME}/.ssh/KEYID:* ${HOME}/.ssh/NO_IMAGE_SERVERS:* ${HOME}/.ssh/REGION:* ${HOME}/.ssh/REPOSITORYPASSWORD:* ${HOME}/.ssh/SIZE:* ${HOME}/.ssh/SNAPAUTOSCALE:* ${HOME}/.ssh/SOURCECODEREPOSITORY:* ${HOME}/.ssh/WEBSERVERCHOICE:* ${HOME}/.ssh/WEBSITEDISPLAYNAME:* ${HOME}/.ssh/APPLICATIONIDENTIFIER:* ${HOME}/.ssh/APPLICATIONLANGUAGE:* ${HOME}/.ssh/APPLICATIONBASELINESOURCECODEREPOSITORY:* ${HOME}/.ssh/GITUSER:* ${HOME}/.ssh/GITEMAILADDRESS:* ${HOME}/.ssh/BUILDIDENTIFIER:* ${HOME}/.ssh/SUPERSAFEWEBROOT:* ${HOME}/.ssh/DIRECTORIESTOMOUNT:* ${HOME}/.ssh/DB_PORT:* ${HOME}/.ssh/SSH_PORT:* ${HOME}/.ssh/SSLGENERATIONMETHOD:* ${HOME}/.ssh/SSLGENERATIONSERVICE:* ${HOME}/.ssh/DBaaSHOSTNAME:* ${HOME}/.ssh/DBaaSUSERNAME:* ${HOME}/.ssh/DBaaSPASSWORD:* ${HOME}/.ssh/DBaaSDBNAME:* ${HOME}/.ssh/DBaaSREMOTESSHPROXYIP:* ${HOME}/.ssh/DEFAULTDBaaSOSUSER:* ${HOME}/.ssh/DATABASEDBaaSINSTALLATIONTYPE:* ${HOME}/.ssh/SERVERTIMEZONECITY:* ${HOME}/.ssh/SERVERTIMEZONECONTINENT:* ${SERVER_USER}@${ip}:${HOME}/.ssh/
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/touch ${HOME}/.ssh/INFRASTRUCTUREREPOSITORYPROVIDER:${INFRASTRUCTURE_REPOSITORY_PROVIDER} ; /bin/touch ${HOME}/.ssh/INFRASTRUCTUREREPOSITORYUSERNAME:${INFRASTRUCTURE_REPOSITORY_USERNAME} ; /bin/touch ${HOME}/.ssh/INFRASTRUCTUREREPOSITORYPASSWORD:${INFRASTRUCTURE_REPOSITORY_PASSWORD} ; /bin/touch ${HOME}/.ssh/INFRASTRUCTUREREPOSITORYOWNER:${INFRASTRUCTURE_REPOSITORY_OWNER} ; /bin/touch ${HOME}/.ssh/APPLICATIONREPOSITORYTOKEN:${APPLICATION_REPOSITORY_TOKEN} ; /bin/touch ${HOME}/.ssh/APPLICATIONREPOSITORYPROVIDER:${APPLICATION_REPOSITORY_PROVIDER} ; /bin/touch ${HOME}/.ssh/APPLICATIONREPOSITORYUSERNAME:${APPLICATION_REPOSITORY_USERNAME} ; /bin/touch ${HOME}/.ssh/APPLICATIONREPOSITORYPASSWORD:${APPLICATION_REPOSITORY_PASSWORD} ; /bin/touch ${HOME}/.ssh/APPLICATIONREPOSITORYOWNER:${APPLICATION_REPOSITORY_OWNER}"
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/WEBSITEURL:* ${HOME}/.ssh/FROMADDRESS:* ${HOME}/.ssh/TOADDRESS:* ${HOME}/.ssh/EMAILUSERNAME:* ${HOME}/.ssh/EMAILPASSWORD:* ${HOME}/.ssh/EMAILPROVIDER:* ${HOME}/.ssh/APPLICATION:* ${HOME}/.ssh/SERVERUSER:* ${HOME}/.ssh/SERVERUSERPASSWORD:* ${HOME}/.ssh/DNSUSERNAME:* ${HOME}/.ssh/DNSEMAILADDRESS:* ${HOME}/.ssh/DNSSECURITYKEY:* ${HOME}/.ssh/DNSCHOICE:* ${HOME}/.ssh/WEBSITEURL:* ${HOME}/.ssh/DATABASEINSTALLATIONTYPE:* ${SERVER_USER}@${ip}:${HOME}/.ssh/

    MACHINETYPE="`/bin/ls ${HOME}/.ssh/MACHINETYPE:* | /usr/bin/awk -F':' '{print $NF}'`"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/bin/touch ${HOME}/${MACHINETYPE}"


    #Setup SSL Certificate
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /bin/mkdir -p ${HOME}/ssl//live/${WEBSITE_URL}"
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/fullchain.pem ${SERVER_USER}@${ip}:/home/${SERVER_USER}/.ssh/fullchain.pem
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/privkey.pem ${SERVER_USER}@${ip}:/home/${SERVER_USER}/.ssh/privkey.pem
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${HOME}/.ssh/${WEBSITE_URL}.json ${SERVER_USER}@${ip}:/home/${SERVER_USER}/.ssh/${WEBSITE_URL}.json
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /bin/cp /home/${SERVER_USER}/.ssh/fullchain.pem ${HOME}/ssl/live/${WEBSITE_URL}/fullchain.pem"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /bin/cp /home/${SERVER_USER}/.ssh/privkey.pem ${HOME}/ssl/live/${WEBSITE_URL}/privkey.pem"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /bin/cp /home/${SERVER_USER}/.ssh/${WEBSITE_URL}.json ${HOME}/ssl/live/${WEBSITE_URL}/${WEBSITE_URL}.json"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /bin/chown root.root ${HOME}/ssl/live/${WEBSITE_URL}/fullchain.pem"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /bin/chmod 400  ${HOME}/ssl/live/${WEBSITE_URL}/fullchain.pem"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /bin/chown root.root ${HOME}/ssl/live/${WEBSITE_URL}/privkey.pem"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /bin/chmod 400  ${HOME}/ssl/live/${WEBSITE_URL}/privkey.pem"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /bin/chown root.root ${HOME}/ssl/live/${WEBSITE_URL}/${WEBSITE_URL}.json"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /bin/chmod 400  ${HOME}/ssl/live/${WEBSITE_URL}/${WEBSITE_URL}.json"
    if ( [ "${BUILD_CHOICE}" = "0" ] )
    then
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E ${HOME}/ws.sh 'virgin' ${SERVER_USER}"
elif ( [ "${BUILD_CHOICE}" = "1" ] )
    then
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E ${HOME}/ws.sh 'baseline' ${SERVER_USER}"
elif ( [ "${BUILD_CHOICE}" = "2" ] )
    then
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E  ${HOME}/ws.sh 'hourly' ${SERVER_USER}"
elif ( [ "${BUILD_CHOICE}" = "3" ] )
    then
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E  ${HOME}/ws.sh 'daily' ${SERVER_USER}"
elif ( [ "${BUILD_CHOICE}" = "4" ] )
    then
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E  ${HOME}/ws.sh 'monthly' ${SERVER_USER}"
elif ( [ "${BUILD_CHOICE}" = "5" ] )
    then
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E  ${HOME}/ws.sh 'bimonthly' ${SERVER_USER}"
    fi
else
    #If we got to here, then the server has been built from a snapshot. In this case, reboot it
    /usr/bin/touch ${HOME}/config/bootedwebserverips/${private_ip}
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${ip} "/sbin/shutdown -r now"
fi
#Remove our flag saying that this is still in the being built state
/bin/rm ${HOME}/config/beingbuiltips/${private_ip}
