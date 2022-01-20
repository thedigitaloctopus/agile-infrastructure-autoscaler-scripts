#!/bin/sh

if ( [ "${CLOUDHOST}" = "vultr" ] )
then
    if ( [ "`/usr/bin/vultr instance list | /bin/grep UUID`" != "" ] )
    then
    
    fi
fi
