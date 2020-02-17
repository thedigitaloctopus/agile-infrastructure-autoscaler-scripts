

SCALING_MODE="`/bin/cat ${HOME}/config/scalingprofile/profile.cnf | /bin/grep "SCALING_MODE" | /usr/bin/awk -F'=' '{print $NF}'`"
MAX_WEBSERVERS="`/bin/cat ${HOME}/config/scalingprofile/profile.cnf | /bin/grep "MAX_WEBSERVERS" | /usr/bin/awk -F'=' '{print $NF}'`"
MIN_WEBSERVERS="`/bin/cat ${HOME}/config/scalingprofile/profile.cnf | /bin/grep "MIN_WEBSERVERS" | /usr/bin/awk -F'=' '{print $NF}'`"

if ( [ "${SCALING_MODE}" != "dynamic" ] )
then
    exit
fi

CLOUDHOST="`/bin/ls ${HOME}/.ssh/CLOUDHOST:* | /usr/bin/awk -F':' '{print $NF}'`"

if ( [ ! -f /root/.aws/config ] || [ ! -f /root/.aws/credentials ] )
then
    /bin/mkdir -p /root/.aws > /dev/null
    /bin/cp ${HOME}/.aws/* /root/.aws
fi

minsize=${MIN_WEBSERVERS}
maxsize=${MAX_WEBSERVERS}

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
    :
fi

if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
    :
fi

if ( [ "${CLOUDHOST}" = "linode" ] )
then
    :
fi

if ( [ "${CLOUDHOST}" = "vultr" ] )
then
    :
fi

if ( [ "${CLOUDHOST}" = "aws" ] )
then
    if ( [ "`/usr/bin/aws autoscaling describe-auto-scaling-groups | /usr/bin/jq ".AutoScalingGroups[].LaunchConfigurationName" | /bin/sed 's/"//g'| /bin/grep "AgileDeploymentToolkitAutoscalingGroup"`" != "" ] )
    then
        live_minsize="`/usr/bin/aws autoscaling describe-auto-scaling-groups | /usr/bin/jq ".AutoScalingGroups[].MinSize"`"
        live_maxsize="`/usr/bin/aws autoscaling describe-auto-scaling-groups | /usr/bin/jq ".AutoScalingGroups[].MaxSize"`"

        if ( [ "${minsize}" != "${live_minsize}" ] || [ "${maxsize}" != "${live_maxsize}" ] )
        then
            /usr/bin/aws autoscaling update-auto-scaling-group --auto-scaling-group-name "AgileDeploymentToolkitAutoscalingGroup" --min-size=${minsize} --max-size=${maxsize}
        fi
    else
        id="`${HOME}/providerscripts/server/ListServerIDs.sh webserver ${CLOUDHOST} | /usr/bin/head -1`"
        /usr/bin/aws autoscaling create-auto-scaling-group --auto-scaling-group-name "AgileDeploymentToolkitAutoscalingGroup" --min-size ${minsize} --max-size ${maxsize} --instance-id ${id} --tags "Key=ScalingStyle,Value=Dynamic"
    fi  
fi
