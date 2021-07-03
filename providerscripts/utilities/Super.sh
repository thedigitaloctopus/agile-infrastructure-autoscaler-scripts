#!/bin/sh

/bin/grep SERVERUSERPASSWORD autoscaler_configuration_settings.dat | /usr/bin/awk -F':' '{print $NF}' | /usr/bin/sudo -S /bin/echo "Going Super hold on to your hat" 

/bin/echo
/bin/echo

/bin/echo "#####################################################################################"
/bin/echo "#####################ATTEMPTING TO RUN AS ROOT#######################################"
/bin/echo "#####################################################################################"

/usr/bin/sudo su

/bin/echo
/bin/echo

/bin/echo "#####################################################################################"
/bin/echo "#####################NO LONGER RUNNING AS ROOT#######################################"
/bin/echo "#####################################################################################"
