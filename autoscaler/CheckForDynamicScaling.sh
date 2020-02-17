#!/bin/sh

#set -x

instanceid="`/usr/bin/aws ec2 describe-instances --filter 'Name=tag:ScalingStyle,Values=Dynamic' 'Name=instance-state-name,Values=running' | /usr/bin/jq '.Reservations[].Instances[].InstanceId' | /bin/sed 's/"//g' | /usr/bin/head -1`"

if ( [ ! -d ${HOME}/config/dynamicscalingprocessing ] )
then
    /bin/mkdir -p ${HOME}/config/dynamicscalingprocessing
fi

if ( [ ! -f ${HOME}/config/dynamicscalingprocessing/${instanceid} ] )
then
    /bin/touch ${HOME}/config/dynamicscalingprocessing/${instanceid}
    /bin/echo "0"
else
    /bin/echo "1"
fi
