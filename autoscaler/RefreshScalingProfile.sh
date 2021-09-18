#With s3fs if the user updates the profile.cnf file without changing the number of bytes s3fs assumes it didn't change
#So, if we find it has been updated on one of the machines, add an extra space to it in order to signal a change
if ( [ -f ${HOME}/config/scalingprofile/profile.cnf ] )
then
    if ( [ "`/bin/grep -cvP '\S' ${HOME}/config/scalingprofile/profile.cnf`" -gt "60" ] )
    then
        /bin/sed -i '/^ $/d' ${HOME}/config/scalingprofile/profile.cnf
    else
       /bin/echo " " >> ${HOME}/config/scalingprofile/profile.cnf
    fi
fi
