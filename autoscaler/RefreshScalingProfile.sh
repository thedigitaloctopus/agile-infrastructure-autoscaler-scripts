
#With s3fs if the user updates the profile.cnf file without changing the number of bytes s3fs assumes it didn't change
#So, if we find it has been updated on one of the machines, add an extra space to it in order to signal a change
if ( [ -f ${HOME}/config/scalingprofile/profile.cnf ] )
then
    if ( [ "`/usr/bin/find ${HOME}/config/scalingprofile/profile.cnf -mmin -2`" != "" ] )
    then
       /bin/echo " " >> ${HOME}/config/scalingprofile/profile.cnf
       /bin/sleep 140
    fi
fi
