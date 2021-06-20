#!/bin/sh

export HOME="`/bin/cat /home/homedir.dat`"

if ( [ "${1}" != "" ] )
then
    /bin/grep "${1}:" ${HOME}/.ssh/autoscaler_configuration_settings.dat | /usr/bin/awk -F':' '{$1=""; print $0}'
fi
