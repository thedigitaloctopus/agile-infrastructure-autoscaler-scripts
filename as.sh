#!/bin/sh
####################################################################################################
# Author : Peter Winter
# Date   : 04/07/2016
# Description : This script will build the "autoscaler" from scratch
####################################################################################################
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

#If there is a problem with building an autoscaler, you can uncomment the set -x command and debug output will be
#presented on the screen as your autoscaler is built

#HOMEDIRFORROOT="`/bin/echo ${HOME} | /bin/sed 's/\///g' | /bin/sed 's/home//g'`"
#HOMEDIRFORROOT="`/bin/ls /home | /bin/grep '^X'`"
#/usr/bin/touch /root/.ssh/HOMEDIRFORROOT:${HOMEDIRFORROOT}
#HOMEDIR="/home/`/bin/ls /root/.ssh/HOMEDIRFORROOT:* | /usr/bin/awk -F':' '{print $NF}'`"
#export HOME="${HOMEDIR}"

USER_HOME="`/usr/bin/awk -F: '{ print $1}' /etc/passwd | /bin/grep "X*X"`"
export HOME="/home/${USER_HOME}"
export HOMEDIR=${HOME}
/bin/echo "${HOMEDIR}" > /home/homedir.dat

#First thing is to tighten up permissions in case theres any wronguns. 

#Ensure permissions are correctly adjusted for our scripts
/bin/chmod -R 750 ${HOME}/autoscaler ${HOME}/cron ${HOME}/installscripts ${HOME}/providerscripts ${HOME}/security

if ( [ ! -d ${HOME}/logs ] )
then
    /bin/mkdir ${HOME}/logs
fi

OUT_FILE="autoscaler-build-out-`/bin/date | /bin/sed 's/ //g'`"
exec 1>>${HOME}/logs/${OUT_FILE}
ERR_FILE="autoscaler-build-err-`/bin/date | /bin/sed 's/ //g'`"
exec 2>>${HOME}/logs/${ERR_FILE}

if ( [ "$1" = "" ] )
then
    /bin/echo "${0} Usage: ./as.sh <server user>" >> ${HOME}/logs/AUTOSCALER_BUILD.log
    exit
fi

SERVER_USER="${1}"

/bin/echo "${0} `/bin/date`: Beginning the build of the autoscaler" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} `/bin/date`: Building a new webserver" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} `/bin/date`: Setting up the build parameters" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log

#Load the parts of the configuration that we need into memory
WEBSITE_URL="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'WEBSITEURL'`"
CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"
INFRASTRUCTURE_REPOSITORY_USERNAME="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYUSERNAME'`"
INFRASTRUCTURE_REPOSITORY_PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYPASSWORD'`"
INFRASTRUCTURE_REPOSITORY_PROVIDER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYPROVIDER'`"
INFRASTRUCTURE_REPOSITORY_OWNER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYOWNER'`"
GIT_EMAIL_ADDRESS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'GITEMAILADDRESS'`"
DNS_USERNAME="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DNSUSERNAME'`"
DNS_SECURITY_KEY="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DNSSECURITYKEY'`"
SERVER_TIMEZONE_CONTINENT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERTIMEZONECONTINENT'`"
SERVER_TIMEZONE_CITY="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERTIMEZONECITY'`"
BUILDOS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOS'`"
SSH_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SSH_PORT'`"

#Non standard variable assignments
ROOT_DOMAIN="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{$1=""}1' | /bin/sed 's/^ //g' | /bin/sed 's/ /./g'`"
GIT_USER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'GITUSER'  | /bin/sed 's/#/ /g'` "
WEBSITE_NAME="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{print $2}'`"


#Create the config directories, these will be mounted from the autoscaler to the other server types - DB, WS and Images Servers
if ( [ ! -d ${HOME}/.ssh ] )
then
    /bin/mkdir ${HOME}/.ssh
    /bin/chmod 700 ${HOME}/.ssh
fi

if ( [ ! -d ${HOME}/cpuaggregator ] )
then
    /bin/mkdir -p ${HOME}/cpuaggregator
    /bin/chmod 700 ${HOME}/cpuaggregator
fi
if ( [ ! -d ${HOME}/runtime ] )
then
    /bin/mkdir -p ${HOME}/runtime
    /bin/chmod 700 ${HOME}/runtime
fi

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} `/bin/date`: Setting the autoscaler hostname" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
# Set the hostname for the machine
/bin/echo "${WEBSITE_NAME}AS" > /etc/hostname
/bin/hostname -F /etc/hostname

#Set the hostname the method varies by operating system
if ( [ "${BUILDOS}" = "debian" ] )
then
    /bin/sed -i "/127.0.0.1/ s/$/ ${WEBSITE_NAME}AS/" /etc/cloud/templates/hosts.debian.tmpl
    /bin/sed -i '1 i\127.0.0.1        localhost' /etc/cloud/templates/hosts.debian.tmpl

    if ( [ "`/bin/cat /etc/hosts | /bin/grep 127.0.1.1 | /bin/grep "${WEBSITE_NAME}"`" = "" ] )
    then
        /bin/sed -i "s/127.0.1.1/127.0.1.1 ${WEBSITE_NAME}ASX/g" /etc/hosts
        /bin/sed -i "s/X.*//" /etc/hosts
    fi
    /bin/sed -i "0,/127.0.0.1/s/127.0.0.1/127.0.0.1 ${WEBSITE_NAME}AS/" /etc/hosts
else
    /usr/bin/hostnamectl set-hostname ${WEBSITE_NAME}AS
fi

#Some kernel safeguards
/bin/echo "vm.panic_on_oom=1
kernel.panic=10" >> /etc/sysctl.conf

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} `/bin/date`: Updating the repositories" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/rm /var/lib/dpkg/lock
/bin/rm /var/cache/apt/archives/lock

/bin/echo "${0} `/bin/date`: Installed software required by the build" >> ${HOME}/logs/MonitoringLog.log
#Install the programs that we need to use when building the autoscaler
${HOME}/installscripts/Update.sh ${BUILDOS}
${HOME}/installscripts/InstallUFW.sh ${BUILDOS}
${HOME}/installscripts/InstallCurl.sh ${BUILDOS}
${HOME}/installscripts/InstallSSHPass.sh ${BUILDOS}
${HOME}/installscripts/InstallBC.sh ${BUILDOS}
${HOME}/installscripts/InstallJQ.sh ${BUILDOS}
${HOME}/installscripts/InstallSendEmail.sh ${BUILDOS}
${HOME}/installscripts/InstallLibioSocket.sh ${BUILDOS}
${HOME}/installscripts/InstallLibnetSsleay.sh ${BUILDOS}
${HOME}/installscripts/InstallSysStat.sh ${BUILDOS}
${HOME}/installscripts/InstallSSHFS.sh ${BUILDOS}
${HOME}/installscripts/InstallS3FS.sh ${BUILDOS}
${HOME}/installscripts/InstallRsync.sh ${BUILDOS}

if ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh ENABLEEFS:1`" = "1" ] )
then
    ${HOME}/installscripts/InstallNFS.sh ${BUILDOS}
fi

${HOME}/providerscripts/utilities/InstallMonitoringGear.sh

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} `/bin/date`: Setting timezone" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
#Set the time on the machine
/usr/bin/timedatectl set-timezone ${SERVER_TIMEZONE_CONTINENT}/${SERVER_TIMEZONE_CITY}
${HOME}/providerscripts/utilities/StoreConfigValue.sh "SERVERTIMEZONECONTINENT" "${SERVER_TIMEZONE_CONTINENT}"
${HOME}/providerscripts/utilities/StoreConfigValue.sh "SERVERTIMEZONECITY" "${SERVER_TIMEZONE_CITY}"
export TZ=":${SERVER_TIMEZONE_CONTINENT}/${SERVER_TIMEZONE_CITY}"

#Redimentary check to make sure all the software we require installed
if ( [ -f /usr/bin/curl ] && [ -f /usr/sbin/ufw ] && [ -f /usr/bin/sshpass ] && [ -f /usr/bin/bc ] && [ -f /usr/bin/jq ] )
then
    /bin/echo "${0} `/bin/date` : It seems like all the required software has been installed correctly" >> ${HOME}/logs/MonitoringLog.log
else
    /bin/echo "${0} `/bin/date` : It seems like the required software hasn't been installed correctly" >> ${HOME}/logs/MonitoringLog.log
    exit
fi

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} `/bin/date`: Installing cloudtools" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
#Install the tools for our particular cloudhost provider
. ${HOME}/providerscripts/cloudhost/InstallCloudhostTools.sh


/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} `/bin/date`: Getting infrastructure repositories from git" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
#Setup git in the root directory - where the configuration scripts are kept
cd ${HOME}
/usr/bin/git init
/bin/echo "${0} `/bin/date`: Configuring GIT" >> ${HOME}/logs/MonitoringLog.log
/usr/bin/git config --global user.name "${GIT_USER}"
/usr/bin/git config --global user.email ${GIT_EMAIL_ADDRESS}

#Get the infrastructure code - this is the Agile Deployment Toolkit Autoscaler scripts
${HOME}/bootstrap/GitPull.sh ${INFRASTRUCTURE_REPOSITORY_PROVIDER} ${INFRASTRUCTURE_REPOSITORY_USERNAME} ${INFRASTRUCTURE_REPOSITORY_PASSWORD} ${INFRASTRUCTURE_REPOSITORY_OWNER} agile-infrastructure-autoscaler-scripts >/dev/null 2>&1

#Set the permissions as we want on all the new scripts we have pulled
/usr/bin/find ${HOME} -not -path '*/\.*' -type d -print0 | xargs -0 chmod 0755 # for directories
/usr/bin/find ${HOME} -not -path '*/\.*' -type f -print0 | xargs -0 chmod 0755 # for files

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} `/bin/date`: Setting up the script which allows us to root" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/mv ${HOME}/providerscripts/utilities/Super.sh ${HOME}/.ssh
/bin/chmod 400 ${HOME}/.ssh/Super.sh

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} `/bin/date`: Installing Datastore tools" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log

. ${HOME}/providerscripts/datastore/InstallDatastoreTools.sh

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} `/bin/date`: Configuring our SSH settings" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log

#Set the ssh port we want to use
#/bin/sed -i "s/22/${SSH_PORT}/g" /etc/ssh/sshd_config
#/bin/sed -i 's/^#Port/Port/' /etc/ssh/sshd_config

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} `/bin/date`: Disabling password authentication" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log

/bin/sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
/bin/sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} `/bin/date`: Changing to our preferred SSH port" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log

if ( [ "`/bin/grep '^#Port' /etc/ssh/sshd_config`" != "" ] || [ "`/bin/grep '^Port' /etc/ssh/sshd_config`" != "" ] )
then
    /bin/sed -i "s/^Port.*/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
    /bin/sed -i "s/^#Port.*/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
else
    /bin/echo "PermitRootLogin no" >> /etc/ssh/sshd_config
fi

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} `/bin/date`: Preventing root logins" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log

#Double down on preventing logins as root. We already tried, but, make absolutely sure because we can't guarantee format of /etc/ssh/sshd_config

if ( [ "`/bin/grep '^#PermitRootLogin' /etc/ssh/sshd_config`" != "" ] || [ "`/bin/grep '^PermitRootLogin' /etc/ssh/sshd_config`" != "" ] )
then
    /bin/sed -i "s/^PermitRootLogin.*/PermitRootLogin no/g" /etc/ssh/sshd_config
    /bin/sed -i "s/^#PermitRootLogin.*/PermitRootLogin no/g" /etc/ssh/sshd_config
else
    /bin/echo "PermitRootLogin no" >> /etc/ssh/sshd_config
fi

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} `/bin/date`: Ensuring SSH connections are long lasting" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log

#Make sure that client connections to sshd are long lasting
if ( [ "`/bin/cat /etc/ssh/sshd_config | /bin/grep 'ClientAliveInterval 200' 2>/dev/null`" = "" ] )
then
    /bin/echo "
ClientAliveInterval 200
    ClientAliveCountMax 10" >> /etc/ssh/sshd_config
fi




#Set the port for SSH and harden the autentication to be ssh keys only from now on
#/bin/sed -i "s/22/${SSH_PORT}/g" /etc/ssh/sshd_config
#/bin/sed -i 's/^#Port/Port/' /etc/ssh/sshd_config
#/bin/sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
#/bin/sed -i 's/.*PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

#Make sure that client connections to our shh daemon are long lasting
#if ( [ "`/bin/cat /etc/ssh/sshd_config | /bin/grep 'ClientAliveInterval 200' 2>/dev/null`" = "" ] )
#then
#    /bin/echo "
#ClientAliveInterval 200
#    ClientAliveCountMax 10" >> /etc/ssh/sshd_config
#fi

/usr/sbin/service sshd restart

DEVELOPMENT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DEVELOPMENT'`"
PRODUCTION="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'PRODUCTION'`"

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} `/bin/date`: Initialising cron" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log

#Initialise the cron scripts. If you want to add cron jobs, modify this script to include them
. ${HOME}/providerscripts/utilities/InitialiseCron.sh

#This call is necessary as it primes the networking interface for some providers.
${HOME}/providerscripts/utilities/GetIP.sh

#${HOME}/installscripts/Upgrade.sh ${BUILDOS}

#Write the flag to say that the autoscaler has been built correctly
/bin/touch ${HOME}/runtime/AUTOSCALER_READY

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} `/bin/date`: Enabling the firewall" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log

#/bin/sed -i "s/IPV6=yes/IPV6=no/g" /etc/default/ufw
#Switch logging off on the firewall
/usr/sbin/ufw logging off
#The firewall is down until the initial configuration steps are completed. We set our restrictive rules as soon as possible
#and pull our knickers up fully after 10 minutes with a call from cron
/usr/sbin/ufw default allow incoming
/usr/sbin/ufw default allow outgoing
/usr/sbin/ufw --force enable

/bin/chown -R ${SERVER_USER}.${SERVER_USER} ${HOME}

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} `/bin/date`: Rebooting the autoscaler post installation" >> ${HOME}/logs/AUTOSCALER_BUILD.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/AUTOSCALER_BUILD.log

${HOME}/providerscripts/email/SendEmail.sh "A NEW AUTOSCALER HAS BEEN SUCCESSFULLY BUILT" "A new autoscaler machine has been built and is now going to reboot before coming available"

/bin/touch ${HOME}/runtime/DONT_MESS_WITH_THESE_FILES-SYSTEM_BREAK

#Reboot to make sure everything is initialised
/sbin/shutdown -r now
