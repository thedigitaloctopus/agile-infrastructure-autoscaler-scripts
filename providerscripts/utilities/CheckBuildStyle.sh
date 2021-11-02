#!/bin/sh

export HOME="`/bin/cat /home/homedir.dat`"

key_value="`/bin/grep "^${1}" ${HOME}/.ssh/buildstyles.dat`"

if ( [ "${key_value}" != "" ] )
then
    /bin/echo "1"
else
    /bin/echo "0" 
fi
