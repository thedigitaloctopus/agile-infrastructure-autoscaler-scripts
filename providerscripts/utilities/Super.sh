#!/bin/sh

/bin/cat  autoscaler_configuration_settings.dat | /bin/grep SERVERUSERPASSWORD | /usr/bin/awk -F':' '{print $NF}' | /usr/bin/sudo -S /bin/echo "Going Super hold on to your hat" 

/usr/bin/sudo su

if ( [ "$?" = "0" ] )
then
    /bin/echo
    /bin/echo

    /bin/echo "#####################################################################################"
    /bin/echo "#####################YOU ARE NOW RUNNING AS ROOT#####################################"
    /bin/echo "#####################################################################################"
 else
    /bin/echo
    /bin/echo

    /bin/echo "#####################################################################################"
    /bin/echo "#####################FAILED TO ACHIEVE ROOT##########################################"
    /bin/echo "#####################################################################################"
fi
