#!/bin/sh

/bin/cat  webserver_configuration_settings.dat | /bin/grep SERVERUSERPASSWORD | /usr/bin/awk -F':' '{print $NF}' | /usr/bin/sudo -S /bin/echo "Going Super hold on to your hat" 
/bin/echo
/bin/echo

/bin/echo "#####################################################################################"
/bin/echo "#####################YOU ARE NOW RUNNING AS ROOT#####################################"
/bin/echo "#####################################################################################"

/usr/bin/sudo su
