#!/bin/sh

export HOME="`/bin/cat /home/homedir.dat`"

if ( [ "${1}" != "" ] && [ "${2}" != "" ] )
then
    /bin/sed -i "/^${1}:/d" ${HOME}/.ssh/autoscaler_configuration_settings.dat
    /bin/echo "${1}:${2}" >> ${HOME}/.ssh/autoscaler_configuration_settings.dat
elif ( [ "${1}" != "" ] && [ "${2}" = "" ] )
then
    /bin/sed -i "/^${1}$/d" ${HOME}/.ssh/autoscaler_configuration_settings.dat
    /bin/echo "${1}" >> ${HOME}/.ssh/autoscaler_configuration_settings.dat
fi
