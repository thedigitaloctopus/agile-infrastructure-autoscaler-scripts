#!/bin/sh
############################################################################################
# Author: Peter Winter
# Date  : 04/07/2016
# Description : This script will build a webserver from scratch as part of an autoscaling event
# It depends on the provider scripts and will build according to the provider it is configured for
# If we are configured to use snapshots, then the build will be completed using a snapshot (which
# must exist) otherwise, we perform a vanilla build of our webserver from scratch.
# The advantage of building from snapshots is they are quicker to build which may or many not be
# an issue depending on how responsive you want your application to be
##############################################################################################
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
#############################################################################################
#############################################################################################
set -x

#If we are trying to build a webserver before the toolkit has been fully installed, we don't want to do anything, so exit
if ( [ ! -f ${HOME}/config/INSTALLEDSUCCESSFULLY ] )
then
    exit
fi

start=`/bin/date +%s`

SERVER_USER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERUSER'`"
SERVER_USER_PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERUSERPASSWORD'`"
DEFAULT_USER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DEFAULTUSER'`"

if ( [ "${DEFAULT_USER}" = "root" ] )
then
    SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "
else
    SUDO="DEBIAN_FRONTEND=noninteractive /usr/bin/sudo -S -E "
fi
CUSTOM_USER_SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "
OPTIONS=" -o ConnectTimeout=10 -o ConnectionAttempts=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "
OPTIONS1=" -o ConnectTimeout=10 -o ConnectionAttempts=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "

#Check there is a directory for logging
if ( [ ! -d ${HOME}/logs ] )
then
    /bin/mkdir -p ${HOME}/logs
fi

logdate="`/usr/bin/date | /usr/bin/awk '{print $1 $2 $3 $NF}'`"
logdir="scaling-events-${logdate}"

if ( [ ! -d ${HOME}/logs/${logdir} ] )
then
    /bin/mkdir -p ${HOME}/logs/${logdir}
fi


DONE="0"
ip=""
TRIES=0

#Pull the configuration into memory for easy access
KEY_ID="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'KEYID'`"
BUILD_CHOICE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDCHOICE'`"
BUILDOS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOS'`"
REGION="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'REGION'`"
SIZE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SIZE'`"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"
ALGORITHM="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ALGORITHM'`"
WEBSITE_URL="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'WEBSITEURL'`"
DNS_CHOICE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DNSCHOICE'`"
DNS_SECURITY_KEY="`${HOME}/providerscripts/utilities/ExtractConfigValues.sh 'DNSSECURITYKEY' stripped | /bin/sed 's/ /:/g'`"
DNS_USERNAME="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DNSUSERNAME'`"
GIT_USER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'GITUSER'`"
GIT_EMAIL_ADDRESS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'GITEMAILADDRESS'`"
INFRASTRUCTURE_REPOSITORY_PROVIDER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYPROVIDER'`"
INFRASTRUCTURE_REPOSITORY_USERNAME="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYUSERNAME'`"
INFRASTRUCTURE_REPOSITORY_PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYPASSWORD'`"
INFRASTRUCTURE_REPOSITORY_OWNER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYOWNER'`"
APPLICATION_REPOSITORY_PROVIDER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'APPLICATIONREPOSITORYPROVIDER'`"
APPLICATION_REPOSITORY_OWNER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'APPLICATIONREPOSITORYOWNER'`"
APPLICATION_REPOSITORY_USERNAME="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'APPLICATIONREPOSITORYUSERNAME'`"
APPLICATION_REPOSITORY_PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'APPLICATIONREPOSITORYPASSWORD'`"
APPLICATION_REPOSITORY_TOKEN="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'APPLICATIONREPOSITORYTOKEN'`"
CLOUDHOST_PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOSTPASSWORD'`"
BUILD_ARCHIVE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDARCHIVECHOICE'`"
DATASTORE_CHOICE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DATASTORECHOICE'`"
WEBSERVER_CHOICE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'WEBSERVERCHOICE'`"
APPLICATION_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'APPLICATIONIDENTIFIER'`"
APPLICATION_LANGUAGE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'APPLICATIONLANGUAGE'`"
SOURCECODE_REPOSITORY="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'APPLICATIONBASELINESOURCECODEREPOSITORY'`"
SSH_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SSHPORT'`"
DB_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DBPORT'`"
BUILD_CLIENT_IP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDCLIENTIP'`"
ASIP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ASIP'`"
${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh 'AUTOSCALED' 

if ( [ "${ASIP}" = "" ] )
then
    if ( [ "`/bin/ls ${HOME}/config/autoscalerip | /usr/bin/tr '\n' ' ' | /usr/bin/wc-w`" = "1" ] )
    then
        ASIP="`/bin/ls ${HOME}/config/autoscalerip`"
    else
        ASIP="multiple"
    fi
fi
AS_PUBLIC_IP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ASPUBLICIP'`"
if ( [ "${AS_PUBLIC_IP}" = "" ] )
then
    if ( [ "`/bin/ls ${HOME}/config/autoscalerpublicip | /usr/bin/tr '\n' ' ' | /usr/bin/wc-w`" = "1" ] )
    then
        AS_PUBLIC_IP="`/bin/ls ${HOME}/config/autoscalerpublicip`"
    else
        AS_PUBLIC_IP="mutiple"
    fi
fi
DBIP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DBIP'`"
if ( [ "${DBIP}" = "" ] )
then
     ASIP="`/bin/ls ${HOME}/config/databaseip`"
fi
DB_PUBLIC_IP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DBPUBLICIP'`"
if ( [ "${DB_PUBLIC_IP}" = "" ] )
then
     DB_PUBLIC_IP="`/bin/ls ${HOME}/config/databasepublicip`"
fi
ASIPS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ASIPS'`"
if ( [ "${ASIPS}" = "" ] )
then
    ASIPS="`/bin/ls ${HOME}/config/autoscalerpublicip`"
fi
ASIP_PRIVATES="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ASIP_PRIVATES'`"
if ( [ "${ASIP_PRIVATES}" = "" ] )
then
    ASIP_PRIVATES"`/bin/ls ${HOME}/config/autoscalerip`"
fi

#Autoscalers need access to all webserver's port 22 from the get go
for autoscaler_ip in ${ASIPS}
do
    ${HOME}/providerscripts/security/firewall/UpdateNativeFirewall.sh ${autoscaler_ip} 22
done

#Non standard Variable assignments
WEBSITE_NAME="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{print $2}'`"
z="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{$1=""}1' | /bin/sed 's/^ //g' | /bin/sed 's/ /./g'`"
name="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{print $1}'`"
WEBSITE_DISPLAY_NAME="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'WEBSITEDISPLAYNAME' | /bin/sed 's/_/ /g'`"

# Set up the webservers properties, like its name and so on.
RND="`/bin/cat /dev/urandom | /usr/bin/tr -dc 'a-zA-Z0-9' | /usr/bin/fold -w 4 | /usr/bin/head -n 1`"
SERVER_TYPE="webserver"
SERVER_NUMBER="`${HOME}/providerscripts/server/NumberOfServers.sh "${SERVER_TYPE}" ${CLOUDHOST}`"
webserver_name="webserver-${RND}-${WEBSITE_NAME}-${BUILD_IDENTIFIER}"
SERVER_INSTANCE_NAME="`/bin/echo ${webserver_name} | /usr/bin/cut -c -32 | /bin/sed 's/-$//g'`"

logdir="${logdir}/${webserver_name}"

if ( [ ! -d ${HOME}/logs/${logdir} ] )
then
    /bin/mkdir -p ${HOME}/logs/${logdir}
fi

#The log files for the server build are written here...
LOG_FILE="webserver_out_`/bin/date | /bin/sed 's/ //g'`"
exec 1>>${HOME}/logs/${logdir}/${LOG_FILE}
ERR_FILE="webserver_err_`/bin/date | /bin/sed 's/ //g'`"
exec 2>>${HOME}/logs/${logdir}/${ERR_FILE}

#If it doesn't successfully build the webserver, try building another one up to a maximum of 3 attempts
/bin/echo "${0} `/bin/date`: ###############################################" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
/bin/echo "${0} `/bin/date`: Building a new webserver" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

#What type of machine are we building - this will determine the size and so on with the cloudhost
SERVER_TYPE_ID="`${HOME}/providerscripts/server/GetServerTypeID.sh ${SIZE} "${SERVER_TYPE}" ${CLOUDHOST}`"

#Hell, what operating system are we running
ostype="`${HOME}/providerscripts/cloudhost/GetOperatingSystemVersion.sh ${SIZE} ${CLOUDHOST}`"

#Attempt to create a vanilla machine on which to build our webserver
#The build method tells us if we are using a snapshot or not
buildmethod="`${HOME}/providerscripts/server/CreateServer.sh "${ostype}" "${REGION}" "${SERVER_TYPE_ID}" "${SERVER_INSTANCE_NAME}" "${KEY_ID}" ${CLOUDHOST} "${DEFAULT_USER}" ${CLOUDHOST_PASSWORD}`"

count="0"
while ( [ "$?" != "0" ] && [ "${count}" -lt "10" ] )
do
    /bin/sleep 5
    buildmethod="`${HOME}/providerscripts/server/CreateServer.sh "${ostype}" "${REGION}" "${SERVER_TYPE_ID}" "${SERVER_INSTANCE_NAME}" "${KEY_ID}" ${CLOUDHOST} "${DEFAULT_USER}" ${CLOUDHOST_PASSWORD}`"
    count="`/usr/bin/expr ${count} + 1`"
done

if ( [ "${count}" = "10" ] )
then
    /bin/echo "${0} `/bin/date`: Failed to build server" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
    exit
fi

count="0"

# There is a delay between the server being created and started and it "coming online". The way we can tell it is online is when
# It returns an ip address, so try, several times to retrieve the ip address of the server
# We are prepared to wait a total of 300 seconds for the machine to come online
while ( [ "`/bin/echo ${ip} | /bin/grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`" = "" ] && [ "${count}" -lt "30" ] || [ "${ip}" = "0.0.0.0" ] )
do
    /bin/sleep 20
    ip="`${HOME}/providerscripts/server/GetServerIPAddresses.sh ${SERVER_INSTANCE_NAME} ${CLOUDHOST}`"
    /bin/touch ${HOME}/config/webserverpublicips/${ip}
    private_ip="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh ${SERVER_INSTANCE_NAME} ${CLOUDHOST}`"
    /bin/touch ${HOME}/config/webserverips/${private_ip}
    count="`/usr/bin/expr ${count} + 1`"
done

if ( [ "${ip}" = "" ] )
then
    #This should never happen, and I am not sure what to do about it if it does. If we don't have an ip address, how can
    #we destroy the machine? I simply exit, therefore.
    /bin/echo "${0} `/bin/date`: Server didn't come online " >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
    exit
fi

if ( [ ! -d ${HOME}/runtime/protectedfromtermination ] )
then
    /bin/mkdir -p ${HOME}/runtime/protectedfromtermination
fi

/bin/touch ${HOME}/runtime/protectedfromtermination/${ip}

DBaaS_DBSECURITYGROUP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DBaaSDBSECURITYGROUP'`"

if ( [ "${DBaaS_DBSECURITYGROUP}" != "" ] )
then
    IP_TO_ALLOW="${ip}"
    . ${HOME}/providerscripts/server/AllowDBAccess.sh
fi

INMEMORYCACHING_SECURITY_GROUP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INMEMORYCACHINGSECURITYGROUP'`"
INMEMORYCACHING_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INMEMORYCACHINGPORT'`"
INMEMORYCACHING_HOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INMEMORYCACHINGHOST'`"

if ( [ "${INMEMORYCACHING_SECURITY_GROUP}" != "" ] )
then
    IP_TO_ALLOW="${ip}"
    . ${HOME}/providerscripts/server/AllowCachingAccess.sh
fi

#We add our IP address to a list of machines in the 'being built' stage. We can check this flag elsewhere when we want to
#distinguish between ip address of webservers which have been built and are still being built.
#The autoscaler monitors for this when it is looking for slow builds. The being built part of things is cleared out when
#we reach the end of the build process so if this persists for an excessive amount of time, the "slow builds" script on the
#autoscaler knows that something is hanging or has gone wrong with the build and it clears things up.
/usr/bin/touch ${HOME}/config/beingbuiltips/${private_ip}
/usr/bin/touch ${HOME}/config/beingbuiltpublicips/${ip}
/usr/bin/touch ${HOME}/config/webserverips/${private_ip}
/usr/bin/touch ${HOME}/config/webserverpublicips/${ip}

#/bin/echo " ${ip} ${private_ip} " >> ${HOME}/runtime/ipsforfirewall
${HOME}/providerscripts/security/firewall/UpdateNativeFirewall.sh ${ip} ${private_ip}
. ${HOME}/providerscripts/security/firewall/TightenDBaaSFirewall.sh

/usr/sbin/ufw allow from ${private_ip}
/usr/sbin/ufw allow from ${ip}

# Build our webserver
if ( [ "`/bin/echo ${buildmethod} | /bin/grep 'SNAPPED'`" = "" ] )
then
    #If we are here, then we are not building from a snapshot
    webserver_name="${SERVER_INSTANCE_NAME}"
    #Test to see if our server can be accessed using our build key
    count="0"

    $?="-1" 2>/dev/null

    while ( [ "$?" != "0" ] && [ "${count}" -lt "10" ] && [ "${CLOUDHOST_PASSWORD}" = "" ] )
    do
        count="`/usr/bin/expr ${count} + 1`"
        /bin/sleep 10
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS1} -o "PasswordAuthentication no" ${DEFAULT_USER}@${ip} "exit"
    done

    if ( [ "${count}" = "10" ] || [ "${CLOUDHOST_PASSWORD}" != "" ] )
    then
        #If we get to here, it means the ssh key failed, lets, then, try authenticating by password
        if ( [ ! -f /usr/bin/sshpass ] )
        then
            if ( [ "${BUILDOS}" = "ubuntu" ] || [ "${BUILDOS}" = "debian" ] )
            then
                /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq install sshpass
            fi
        fi
        count="0"
        if ( [ "${CLOUDHOST_PASSWORD}" != "" ] )
        then
            /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/ssh ${OPTIONS} ${DEFAULT_USER}@${ip} "DEBIAN_FRONTEND=noninteractive /bin/mkdir -p /root/.ssh" >/dev/null 2>&1
            /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/ssh ${OPTIONS} ${DEFAULT_USER}@${ip} "DEBIAN_FRONTEND=noninteractive /bin/mkdir -p /home/${SERVER_USER}/.ssh"
            while ( [ "$?" != "0" ] )
            do
                /bin/echo "Haven't successfully connected to the Webserver, maybe it is still initialising, trying again...."
                /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/ssh ${OPTIONS} ${CLOUDHOST_USERNAME}@${ip} "DEBIAN_FRONTEND=noninteractive /bin/mkdir -p /home/${SERVER_USER}/.ssh" >/dev/null 2>&1
                /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/ssh ${OPTIONS} ${CLOUDHOST_USERNAME}@${ip} "DEBIAN_FRONTEND=noninteractive /bin/mkdir -p /root/.ssh" >/dev/null 2>&1
                /bin/sleep 5
                count="`/usr/bin/expr ${count} + 1`"
            done

            if ( [ "${count}" = "10" ] )
            then
                /bin/echo "${0} `/bin/date`: Failed to build server" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
                exit
            fi
        else
            /bin/echo "${0} `/bin/date`: Failed to build server -cloudhost password not set" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
            exit
        fi
        #Set up our ssh keys
        /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/ssh ${OPTIONS} ${CLOUDHOST_USERNAME}@${ip} "DEBIAN_FRONTEND=noninteractive /bin/mkdir -p /home/${SERVER_USER}/.ssh" >/dev/null 2>&1
        /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/ssh ${OPTIONS} ${CLOUDHOST_USERNAME}@${ip} "DEBIAN_FRONTEND=noninteractive /bin/chmod 700 /home/${SERVER_USER}/.ssh" >/dev/null 2>&1
        /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/ssh ${OPTIONS} ${CLOUDHOST_USERNAME}@${ip} "DEBIAN_FRONTEND=noninteractive /bin/chmod 700 /root/.ssh" >/dev/null 2>&1
        /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/scp ${OPTIONS} ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}.pub ${CLOUDHOST_USERNAME}@${ip}:/root/.ssh/authorized_keys >/dev/null 2>&1
        /usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/scp ${OPTIONS} ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}.pub ${CLOUDHOST_USERNAME}@${ip}:/home/${SERVER_USER}/.ssh/authorized_keys >/dev/null 2>&1
    else
        #set up our ssh keys
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${DEFAULT_USER}@${ip} "${SUDO} /bin/mkdir -p /home/${SERVER_USER}/.ssh"

        #Fine to here.........
        #/bin/cat ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}.pub | /usr/bin/ssh ${OPTIONS} ${DEFAULT_USER}@${ip} "${SUDO} /bin/cat - >> /root/.ssh/authorized_keys"
        /bin/cat ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}.pub | /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${DEFAULT_USER}@${ip} "${SUDO} /bin/chmod 777 /home/${DEFAULT_USER}/.ssh ; /bin/cat - >> /home/${DEFAULT_USER}/.ssh/authorized_keys ; ${SUDO} /bin/chmod 700 /home/${DEFAULT_USER}/.ssh"
        /bin/cat ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}.pub | /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${DEFAULT_USER}@${ip} "${SUDO} /bin/chmod 777 /home/${SERVER_USER}/.ssh ; /bin/cat - >> /home/${SERVER_USER}/.ssh/authorized_keys ; ${SUDO} /bin/chmod  700 /home/${SERVER_USER}/.ssh"
    fi

    # These look complicated but really all it is is a list of scp and ssh commands with appropriate connection parameters and
    # the private key that is need to connect.

    #Add our own user. root access is disabled, so we will have to connect through our own unprivileged user
    if ( [ "${BUILDOS}" = "ubuntu" ] || [ "${BUILDOS}" = "debian" ] )
    then
       /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}  ${OPTIONS} ${DEFAULT_USER}@${ip} "DEBIAN_FRONTEND=noninteractive /bin/sh -c '${SUDO} /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq -y update'"
    
       while ( [ "$?" != "0" ] )
       do
           /bin/sleep 10
           /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}  ${OPTIONS} ${DEFAULT_USER}@${ip} "DEBIAN_FRONTEND=noninteractive /bin/sh -c '${SUDO} /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq -y update'"
       done
    fi
    
    if ( [ "${BUILDOS}" = "ubuntu" ] || [ "${BUILDOS}" = "debian" ] )
    then 
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${DEFAULT_USER}@${ip} "${SUDO} /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 install -qq -y git"
    fi
    
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${DEFAULT_USER}@${ip} "${SUDO} /usr/sbin/useradd ${SERVER_USER}"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${DEFAULT_USER}@${ip} "/bin/echo ${SERVER_USER}:${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/chpasswd"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${DEFAULT_USER}@${ip} "${SUDO} /usr/bin/gpasswd -a ${SERVER_USER} sudo"
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}.pub ${DEFAULT_USER}@${ip}:/home/${SERVER_USER}/.ssh/authorized_keys
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${DEFAULT_USER}@${ip} "${SUDO} /bin/chown -R ${SERVER_USER}.${SERVER_USER} /home/${SERVER_USER}/"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${DEFAULT_USER}@${ip} "${SUDO} /bin/sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${DEFAULT_USER}@${ip} "i${SUDO} /usr/sbin/service ssh restart"

    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${SERVER_USER}@${ip}:${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "/bin/chmod 400 ${HOME}/.ssh/id_${ALGORITHM}"
    
    #Configure the provider details
    ${HOME}/providerscripts/cloudhost/ConfigureProvider.sh ${CLOUDHOST} ${BUILD_IDENTIFIER} ${ALGORITHM} ${ip} ${SERVER_USER}

    #INSTALLING GIT
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "cd /home/${SERVER_USER}"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} '/usr/bin/git init'
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} '/bin/mkdir ${HOME}/bootstrap'
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${HOME}/providerscripts/git/GitFetch.sh ${SERVER_USER}@${ip}:${HOME}/bootstrap
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${HOME}/providerscripts/git/GitCheckout.sh ${SERVER_USER}@${ip}:${HOME}/bootstrap
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${HOME}/providerscripts/git/GitPull.sh ${SERVER_USER}@${ip}:${HOME}/bootstrap
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} '/bin/chmod 700 ${HOME}/bootstrap/*'
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${HOME}/bootstrap/GitFetch.sh ${INFRASTRUCTURE_REPOSITORY_PROVIDER} ${INFRASTRUCTURE_REPOSITORY_USERNAME} ${INFRASTRUCTURE_REPOSITORY_PASSWORD} ${INFRASTRUCTURE_REPOSITORY_OWNER} agile-infrastructure-webserver-scripts"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${HOME}/bootstrap/GitCheckout.sh ${INFRASTRUCTURE_REPOSITORY_PROVIDER} ws.sh"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${HOME}/bootstrap/GitCheckout.sh ${INFRASTRUCTURE_REPOSITORY_PROVIDER} providerscripts/datastore/ConfigureDatastoreProvider.sh"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${HOME}/bootstrap/GitPull.sh ${INFRASTRUCTURE_REPOSITORY_PROVIDER} ${INFRASTRUCTURE_REPOSITORY_USERNAME} ${INFRASTRUCTURE_REPOSITORY_PASSWORD} ${INFRASTRUCTURE_REPOSITORY_OWNER} agile-infrastructure-webserver-scripts"
    

    
    #Mark this as an autoscaled machine as distinct from one built during the initial build
    #/usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh 'AUTOSCALED'"

    #Configure our datastore for this server. This will enable us to use tools like s3cmd from our webserver for backups etc
    ${HOME}/providerscripts/datastore/ConfigureDatastoreProvider.sh ${DATASTORE_CHOICE} ${ip} ${CLOUDHOST} ${BUILD_IDENTIFIER} ${ALGORITHM} ${SERVER_USER}

    #Configuration values
    ${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh 'MYPUBLICIP' "${ip}"
    ${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh 'MYIP' "${private_ip}"
    ${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh 'BUILDCLIENTIP' "${BUILD_CLIENT_IP}"
    ${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh 'ASIP' "${ASIP}"
    ${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh 'ASPUBLICIP' "${AS_PUBLIC_IP}"
    ${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh 'DBIP' "${DBIP}"
    ${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh 'DBPUBLICIP' "${DB_PUBLIC_IP}"
 
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${HOME}/.ssh/webserver_configuration_settings.dat ${SERVER_USER}@${ip}:${HOME}/.ssh/
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${HOME}/.ssh/buildstyles.dat ${SERVER_USER}@${ip}:${HOME}/.ssh/
 
    
    MACHINE_TYPE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'MACHINETYPE'`"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /usr/bin/touch ${HOME}/${MACHINE_TYPE}"

    #Setup SSL Certificate
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /bin/mkdir -p ${HOME}/ssl//live/${WEBSITE_URL}"
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${HOME}/.ssh/fullchain.pem ${SERVER_USER}@${ip}:/home/${SERVER_USER}/.ssh/fullchain.pem
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${HOME}/.ssh/privkey.pem ${SERVER_USER}@${ip}:/home/${SERVER_USER}/.ssh/privkey.pem
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${HOME}/.ssh/${WEBSITE_URL}.json ${SERVER_USER}@${ip}:/home/${SERVER_USER}/.ssh/${WEBSITE_URL}.json
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /bin/cp /home/${SERVER_USER}/.ssh/fullchain.pem ${HOME}/ssl/live/${WEBSITE_URL}/fullchain.pem"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /bin/cp /home/${SERVER_USER}/.ssh/privkey.pem ${HOME}/ssl/live/${WEBSITE_URL}/privkey.pem"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /bin/cp /home/${SERVER_USER}/.ssh/${WEBSITE_URL}.json ${HOME}/ssl/live/${WEBSITE_URL}/${WEBSITE_URL}.json"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /bin/chown root.root ${HOME}/ssl/live/${WEBSITE_URL}/fullchain.pem"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /bin/chmod 400  ${HOME}/ssl/live/${WEBSITE_URL}/fullchain.pem"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /bin/chown root.root ${HOME}/ssl/live/${WEBSITE_URL}/privkey.pem"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /bin/chmod 400  ${HOME}/ssl/live/${WEBSITE_URL}/privkey.pem"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /bin/chown root.root ${HOME}/ssl/live/${WEBSITE_URL}/${WEBSITE_URL}.json"
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /bin/chmod 400  ${HOME}/ssl/live/${WEBSITE_URL}/${WEBSITE_URL}.json"

    #We have lots of backup choices to build from, hourly, daily and so on, so this will pick which backup we want to build from
    if ( [ "${BUILD_CHOICE}" = "0" ] )
    then
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/ws.sh 'virgin' ${SERVER_USER}"
    elif ( [ "${BUILD_CHOICE}" = "1" ] )
    then
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/ws.sh 'baseline' ${SERVER_USER}"
    elif ( [ "${BUILD_CHOICE}" = "2" ] )
    then
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO}  ${HOME}/ws.sh 'hourly' ${SERVER_USER}"
    elif ( [ "${BUILD_CHOICE}" = "3" ] )
    then
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO}  ${HOME}/ws.sh 'daily' ${SERVER_USER}"
    elif ( [ "${BUILD_CHOICE}" = "4" ] )
    then
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO}  ${HOME}/ws.sh 'weekly' ${SERVER_USER}"
    elif ( [ "${BUILD_CHOICE}" = "5" ] )
    then
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO}  ${HOME}/ws.sh 'monthly' ${SERVER_USER}"
    elif ( [ "${BUILD_CHOICE}" = "6" ] )
    then
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO}  ${HOME}/ws.sh 'bimonthly' ${SERVER_USER}"
    fi
else
    /bin/echo "${0} `/bin/date`: Building a new machine from a snapshot" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

    #If we got to here, then the server has been built from a snapshot.
    /usr/bin/touch ${HOME}/config/bootedwebserverips/${private_ip}

    #We want to make sure that our server has spawned correctly from our snapshot so give it plenty of time to connect. If the connection fails
    #then, as I have seen, something has gone wrong with spawning from a snapshot, so destroy the machine and the next run of the autoscaler
    #will spawn a fresh one, hopefully, without issue
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=30 -o ConnectionAttempts=20 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p ${SSH_PORT} ${SERVER_USER}@${ip} "exit"

    if ( [ "$?" != "0" ] )
    then
        /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=30 -o ConnectionAttempts=20 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p ${SSH_PORT} ${SERVER_USER}@${ip} "exit"
    fi

    if ( [ "$?" != "0" ] )
    then

        if ( [ "${CLOUDHOST}" = "vultr" ] )
        then
            #This is untidy, lol,
            #because vultr cloudhost doesn't let you destroy machines until they have been running for 5 mins or more
            /bin/sleep 300
        fi

        /bin/echo "${0} `/bin/date` : ${ip} is being destroyed because it couldn't be connected to after spawning it from a snapshot" >> ${HOME}/logs/${logdir}/MonitoringLog.log
        ${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
        
        DBaaS_DBSECURITYGROUP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DBaaSDBSECURITYGROUP'`"

        if ( [ "${DBaaS_DBSECURITYGROUP}" != "" ] )
        then
            IP_TO_DENY="${ip}"
            . ${HOME}/providerscripts/server/DenyDBAccess.sh
        fi
        
        INMEMORYCACHING_SECURITY_GROUP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INMEMORYCACHINGSECURITYGROUP'`"
        INMEMORYCACHING_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INMEMORYCACHINGPORT'`"

        if ( [ "${INMEMORYCACHING_SECURITY_GROUP}" != "" ] )
        then
            IP_TO_DENY="${ip}"
            . ${HOME}/providerscripts/server/DenyCachingAccess.sh
        fi

        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "beingbuiltips/${private_ip}"
        ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "beingbuiltpublicips/${ip}"
        
        if ( [ -f ${HOME}/runtime/autoscalelock.file ] )
        then
            /bin/rm ${HOME}/runtime/autoscalelock.file
        fi
        exit
    fi
    
   /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} -p ${SSH_PORT} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /home/${SERVER_USER}/providerscripts/utilities/RefreshNetworking.sh"
   /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} -p ${SSH_PORT} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /sbin/shutdown -r now"

   /usr/bin/ping -c 10 ${ip}

   while ( [ "$?" != "0" ] )
   do
        /usr/bin/ping -c 10 ${ip}
   done

   while ( [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /bin/ls ${HOME}/runtime/WEBSERVER_READY"`" != "${HOME}/runtime/WEBSERVER_READY" ] )
   do
       /bin/sleep 30
   done
 
   # /usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/SyncFromWebrootTunnel.sh"
   # /usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/applicationscripts/SyncLatestApplication.sh ${APPLICATION_REPOSITORY_PROVIDER} ${APPLICATION_REPOSITORY_USERNAME} ${APPLICATION_REPOSITORY_PASSWORD} ${APPLICATION_REPOSITORY_OWNER} ${BUILD_ARCHIVE} ${DATASTORE_CHOICE} ${BUILD_IDENTIFIER} ${WEBSITE_NAME}"
    
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh 'MYPUBLICIP' \"${ip}\""
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh 'MYIP' \"${private_ip}\""
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh 'BUILDCLIENTIP' \"${BUILD_CLIENT_IP}\""
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh 'ASIPS' \"${ASIPS}\""
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh 'ASIP_PRIVATES' \"${ASIP_PRIVATES}\""
     /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh 'ASIP' \"${ASIP}\""    
     /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh 'ASPUBLICIP' \"${AS_PUBLIC_IP}\""  
     /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh 'DBIP' \"${DBIP}\""
    /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh 'DBPUBLICIP' \"${DB_PUBLIC_IP}\"" 
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} -P ${SSH_PORT} ${HOME}/.ssh/webserver_configuration_settings.dat ${SERVER_USER}@${ip}:${HOME}/.ssh/
    /usr/bin/scp -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} -P ${SSH_PORT} ${HOME}/.ssh/buildstyles.dat ${SERVER_USER}@${ip}:${HOME}/.ssh/
#   /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} -p ${SSH_PORT} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh \"AUTOSCALED\""
#   /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} -p ${SSH_PORT} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /home/${SERVER_USER}/providerscripts/utilities/RefreshNetworking.sh"
 #  /usr/bin/ssh -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} ${OPTIONS} -p ${SSH_PORT} ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} /sbin/shutdown -r now"
fi

if ( [ "`/bin/echo ${buildmethod} | /bin/grep 'SNAPPED'`" = "" ] )
then

    #Wait for the machine to become responsive before we check its integrity

    /usr/bin/ping -c 10 ${ip}

    while ( [ "$?" != "0" ] )
    do
        /usr/bin/ping -c 10 ${ip}
    done

    /bin/sleep 10

    /usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=60 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "exit"

    if ( [ "$?" != "0" ] )
    then
        /usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=60 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "exit"
    fi

    /bin/echo "${0} `/bin/date`: It can take a minute or so for a new machine to initialise after it is back online post reboot, so just gonna nap for 30 seconds..." >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

    /bin/sleep 30

    /usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/application/processing/PerformPostProcessingByApplication.sh ${SERVER_USER}"

    /bin/echo "${0} `/bin/date`: The main build has completed now just have to check that it's been dun right" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

    #Do some checks to make sure the machine has come online and so on
    tries="0"
    while ( [ "${tries}" -lt "20" ] && ( [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/AreAssetsMounted.sh"`" != "MOUNTED" ] || [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/CheckServerAlive.sh"`" != "ALIVE" ] ) )
    do
        /bin/echo "${0} `/bin/date`: Doing integrity checks for ${ip}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
        /bin/sleep 10
        tries="`/usr/bin/expr ${tries} + 1`"
    done

    if ( [ "${tries}" = "20" ] )
    then
        /bin/echo "${0} `/bin/date`: Failed integrity checks for ${ip}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
    fi

    /usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/SyncFromWebrootTunnel.sh"

    /usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/SyncToWebrootTunnel.sh"
fi

#Do a check, as best we can to make sure that the website application is actually running correctly
loop="0"
while ( [ "${loop}" -lt "7" ] )
do
    if ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh APPLICATIONLANGUAGE:PHP`" = "1" ] )
    then
        file="index.php"
    else
        file=""
    fi

    if ( [ "`/usr/bin/curl -I --max-time 60 --insecure https://${ip}:443/${file} | /bin/grep -E 'HTTP/2 200|HTTP/2 301|HTTP/2 302|200 OK|302 Found|301 Moved Permanently'`" = "" ] )
    then
        /bin/echo "${0} `/bin/date`: Expecting ${ip} to be online, but can't curl it yet...." >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
        /bin/sleep 30
        loop="`/usr/bin/expr ${loop} + 1`"
    else
        /bin/echo "${0} `/bin/date`: ${ip} is online wicked..." >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
        break
    fi
done

if ( [ "${loop}" = "7" ] || [ "${tries}" = "20" ] )
then
    #If either of these are true, then somehow the machine/application didn't come online and so we need to destroy the machine
    if ( [ "${CLOUDHOST}" = "vultr" ] )
    then
        #because vultr cloudhost doesn't let you destroy machines until they have been running for 5 mins or more
        /bin/sleep 300
    fi
    /bin/echo "${0} `/bin/date` : ${ip} is being destroyed because it didn't come online." >> ${HOME}/logs/MonitoringLog.log
    /bin/echo "${0} `/bin/date`: ${ip} is being destroyed because it didn't come online" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
    ${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
    
    DBaaS_DBSECURITYGROUP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DBaaSDBSECURITYGROUP'`"

    if ( [ "${DBaaS_DBSECURITYGROUP}" != "" ] )
    then
        IP_TO_DENY="${ip}"
        . ${HOME}/providerscripts/server/DenyDBAccess.sh
    fi
    
    INMEMORYCACHING_SECURITY_GROUP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INMEMORYCACHINGSECURITYGROUP'`"
    INMEMORYCACHING_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INMEMORYCACHINGPORT'`"

    if ( [ "${INMEMORYCACHING_SECURITY_GROUP}" != "" ] )
    then
        IP_TO_DENY="${ip}"
        . ${HOME}/providerscripts/server/DenyCachingAccess.sh
    fi
else
    #For safety, our new machine needs to "settle down", lol, so, let's sleep for a couple of minutes to be nice to it
    #before we consider it alive and kicking
    /bin/sleep 120
    #If we got to here then we are a successful build as as best as we can tell, everything is online
    #So, we add the ip address of our new machine to our DNS provider and that machine is then ready
    #to start serving requests
    /bin/echo "${0} `/bin/date`: ${ip} is fully online and it's public ip is being added to the DNS provider" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

    ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "beingbuiltips/${private_ip}"
    ${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "beingbuiltpublicips/${ip}"
    
    ${HOME}/autoscaler/AddIPToDNS.sh ${ip}
    /bin/echo "${ip}"
fi

/bin/echo "${0} `/bin/date`: Either way, successful or not the build process for machine with ip: ${ip} has completed" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
#Make very sure that we remove our flag saying that this is still in the being built state

${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "beingbuiltips/${private_ip}"
${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "beingbuiltpublicips/${ip}"

#${HOME}/providerscripts/security/firewall/UpdateNativeFirewall.sh

#Output how long the build took
end=`/bin/date +%s`
runtime="`/usr/bin/expr ${end} - ${start}`"
/bin/echo "${0} This script took `/bin/date -u -d @${runtime} +\"%T\"` to complete" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
