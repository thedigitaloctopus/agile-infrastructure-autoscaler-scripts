#!/bin/sh
###############################################################################################
# Description: This script will set up your crontab for you
# Date: 28/01/2017
# Author: Peter Winter
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
#######################################################################################
#######################################################################################
#set -x

#Setup crontab
/bin/echo "${0} `/bin/date`: Configuring crontab" >> ${HOME}/logs/MonitoringLog.log

/bin/echo "MAILTO=''" > /var/spool/cron/crontabs/root

#These scripts are set to run every minute
/bin/echo "*/1 * * * * export HOME="${HOMEDIR}" && /bin/sleep 30 && ${HOME}/providerscripts/utilities/UpdateIP.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/1 * * * * export HOME="${HOMEDIR}" && /usr/bin/find ${HOME}/runtime/UPDATEDSSL -type f -mmin +15 -delete" >> /var/spool/cron/crontabs/root
/bin/echo "*/1 * * * * export HOME="${HOMEDIR}" && /usr/bin/find ${HOME}/runtime -name *lock* -type f -mmin +35 -delete" >> /var/spool/cron/crontabs/root
/bin/echo "*/1 * * * * export HOME="${HOMEDIR}" && ${HOME}/security/MonitorForNewSSLCertificate.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/1 * * * * export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/BroadcastSSLAccount.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/1 * * * * export HOME="${HOMEDIR}" && ${HOME}/providerscripts/datastore/ObtainBuildClientIP.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/1 * * * * export HOME="${HOMEDIR}" && ${HOME}/cron/SetupFirewallFromCron.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/1 * * * * export HOME="${HOMEDIR}" && ${HOME}/autoscaler/PurgeDetachedIPs.sh" >> /var/spool/cron/crontabs/root

#These scripts are set to run every 5 minutes
/bin/echo "*/5 * * * * export HOME="${HOMEDIR}" && ${HOME}/security/MonitorFirewall.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/5 * * * * export HOME="${HOMEDIR}" && ${HOME}/autoscaler/MonitorForSlowBuilds.sh" >> /var/spool/cron/crontabs/root

#This script will run every 10 minutes
/bin/echo "*/10 * * * * export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/EnforcePermissions.sh" >> /var/spool/cron/crontabs/root

#These scripts will run at set times
/bin/echo "30 2 * * * /usr/sbin/ufw --force reset" >> /var/spool/cron/crontabs/root

/bin/echo "@daily export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/PerformSoftwareUpdate.sh" >> /var/spool/cron/crontabs/root

#These scripts will run at a reboot event
/bin/echo "@reboot export HOME="${HOMEDIR}" && ${HOME}/providerscripts/cloudhost/ConfigureProvider.sh" >> /var/spool/cron/crontabs/root

SERVER_TIMEZONE_CONTINENT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERTIMEZONECONTINENT'`"
SERVER_TIMEZONE_CITY="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERTIMEZONECITY'`"

/bin/echo "@reboot export TZ=\":${SERVER_TIMEZONE_CONTINENT}/${SERVER_TIMEZONE_CITY}\"" >> /var/spool/cron/crontabs/root
/bin/echo "@reboot export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/CleanupAtReboot.sh" >> /var/spool/cron/crontabs/root
/bin/echo "@reboot export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/SetHostname.sh" >> /var/spool/cron/crontabs/root
/bin/echo "@reboot /bin/sleep 600 && export HOME="${HOMEDIR}" && ${HOME}/security/KnickersUp.sh" >> /var/spool/cron/crontabs/root
/bin/echo "@reboot export HOME=${HOMEDIR} && /usr/bin/find ${HOME}/runtime -name *lock* -type f -delete" >> /var/spool/cron/crontabs/root
/bin/echo "@reboot export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/GetIP.sh" >> /var/spool/cron/crontabs/root
/bin/echo "@reboot export HOME=${HOMEDIR} && ${HOME}/providerscripts/utilities/UpdateInfrastructure.sh" >>/var/spool/cron/crontabs/root

#If we are building for production, then these scripts are also installed in the crontab. If it's for development then they are not
#installed.
if ( [ "${PRODUCTION}" = "1" ] )
then
    /bin/echo "*/2 * * * * export HOME="${HOMEDIR}" && ${HOME}/cron/AutoscaleFromCron.sh" >> /var/spool/cron/crontabs/root
    /bin/echo "*/1 * * * * export HOME="${HOMEDIR}" && ${HOME}/cron/DeadOrAliveFromCron.sh" >> /var/spool/cron/crontabs/root
    /bin/echo "30 7 * * *  export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/DailyScaleup.sh 3" >> /var/spool/cron/crontabs/root
    /bin/echo "30 17 * * * export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/DailyScaledown.sh 2" >> /var/spool/cron/crontabs/root
fi

#Install our new crontab
/usr/bin/crontab /var/spool/cron/crontabs/root
