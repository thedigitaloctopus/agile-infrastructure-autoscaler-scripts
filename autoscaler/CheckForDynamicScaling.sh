#!/bin/sh


instanceid="`/usr/bin/aws ec2 describe-instances --filter 'Name=tag:ScalingStyle,Values=Dynamic' 'Name=instance-state-name,Values=running' | /usr/bin/jq '.Reservations[].Instances[].InstanceId'`"

if ( [ ! -d ${HOME}/config/dynamicscalingprocessing ] )
then
    /bin/mkdir -p ${HOME}/config/dynamicscalingprocessing
fi

if ( [ "${instanceid}" = "" ] || [ -f ${HOME}/config/dynamicscalingprocessing/${instanceid} ] )
then
    /bin/echo "0"
else
    /bin/touch ${HOME}/config/dynamicscalingprocessing/${instanceid}
    /bin/echo "1"
fi
