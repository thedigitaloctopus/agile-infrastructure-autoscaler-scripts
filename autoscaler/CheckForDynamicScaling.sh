#!/bin/sh


instanceid="`/usr/bin/aws ec2 describe-instances --filter 'Name=tag:ScalingStyle,Values=Dynamic' 'Name=instance-state-name,Values=running' | /usr/bin/jq '.Reservations[].Instances[].InstanceId'`"

if ( [ "${instanceid}" = "" ] )
then
    /bin/echo "0"
else
    /bin/echo "1"
fi
