cd ${HOME}
if ( [ -d agile-infrastructure-autoscaler-scripts ] )
then
    /bin/rm -r agile-infrastructure-autoscaler-scripts
fi
infrastructure_repository_owner="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYOWNER'`"
/usr/bin/git clone https://github.com/${infrastructure_repository_owner}/agile-infrastructure-autoscaler-scripts.git
cd agile-infrastructure-autoscaler-scripts
/bin/cp -r * ${HOME}
cd ..
/bin/rm -r agile-infrastructure-autoscaler-scripts
