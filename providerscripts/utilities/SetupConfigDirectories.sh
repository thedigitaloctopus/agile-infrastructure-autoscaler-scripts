#!/bin/sh

if ( [ ! -d ${HOME}/config/beingbuiltips ] )
then
    /bin/mkdir -p ${HOME}/config/beingbuiltips
    /bin/chmod 700 ${HOME}/config/beingbuiltips
fi
if ( [ ! -d ${HOME}/config/webserverpublicips ] )
then
    /bin/mkdir -p ${HOME}/config/webserverpublicips
    /bin/chmod 700 ${HOME}/config/webserverpublicips
fi
if ( [ ! -d ${HOME}/config/webserverips ] )
then
    /bin/mkdir -p ${HOME}/config/webserverips
    /bin/chmod 700 ${HOME}/config/webserverips
fi

if ( [ ! -d ${HOME}/config/databaseip ] )
then
    /bin/mkdir -p ${HOME}/config/databaseip
    /bin/chmod 700 ${HOME}/config/databaseip
fi
if ( [ ! -d ${HOME}/config/databasepublicip ] )
then
    /bin/mkdir -p ${HOME}/config/databasepublicip
    /bin/chmod 700 ${HOME}/config/databasepublicip
fi
if ( [ ! -d ${HOME}/config/bootedwebserverips ] )
then
    /bin/mkdir -p ${HOME}/config/bootedwebserverips
    /bin/chmod 700 ${HOME}/config/bootedwebserverips
fi
if ( [ ! -d ${HOME}/config/shuttingdownwebserverips ] )
then
    /bin/mkdir -p ${HOME}/config/shuttingdownwebserverips
    /bin/chmod 700 ${HOME}/config/shuttingdownwebserverips
fi
if ( [ ! -d ${HOME}/config/autoscalerip ] )
then
    /bin/mkdir -p ${HOME}/config/autoscalerip
    /bin/chmod 700 ${HOME}/config/autoscalerip
fi
if ( [ ! -d ${HOME}/config/autoscalerpublicip ] )
then
    /bin/mkdir -p ${HOME}/config/autoscalerpublicip
    /bin/chmod 700 ${HOME}/config/autoscalerpublicip
fi
if ( [ ! -d ${HOME}/config/buildclientip ] )
then
    /bin/mkdir -p ${HOME}/config/buildclientip
    /bin/chmod 700 ${HOME}/config/buildclientip
fi
if ( [ ! -d ${HOME}/config/credentials ] )
then
    /bin/mkdir -p ${HOME}/config/credentials
    /bin/chmod 700 ${HOME}/config/credentials
fi

if ( [ ! -d ${HOME}/config/webrootsynctunnel ] )
then
    /bin/mkdir -p ${HOME}/config/webrootsynctunnel
    /bin/chmod 700 ${HOME}/config/webrootsynctunnel
fi

if ( [ ! -d ${HOME}/config/ssl ] )
then
    /bin/mkdir -p ${HOME}/config/ssl
    /bin/chmod 700 ${HOME}/config/ssl
fi
