export HOME="`/bin/cat /home/homedir.dat`"

if ( [ "${1}" != "" ] && [ "${2}" != "" ] )
then
    /bin/echo "${1}:${2}" >> ${HOME}/.ssh/autoscaler_configuration_settings.dat
fi
