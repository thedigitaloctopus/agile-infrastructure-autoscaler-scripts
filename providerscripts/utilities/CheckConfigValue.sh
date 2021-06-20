export HOME="`/bin/cat /home/homedir.dat`"

if ( [ "`/bin/grep "${1}:" ${HOME}/.ssh/autoscaler_configuration_settings.dat | /usr/bin/awk -F':' '{print $NF}'`" = "${2}" ] )
then
    /bin/echo "0"
else
    /bin/echo "1" 
fi
