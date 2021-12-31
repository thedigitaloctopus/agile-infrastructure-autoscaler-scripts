#!/bin/sh

alldnsproxyips=""
CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"
DNS_CHOICE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DNSCHOICE'`"

autoscalerips=""
autoscalerips="`/bin/ls ${HOME}/config/autoscalerip | /usr/bin/tr '\n' ' '`/32"
autoscalerips="${allips} `/bin/ls ${HOME}/config/autoscalerpublicip | /usr/bin/tr '\n' ' '`/32"

if ( [ "${DNS_CHOICE}" = "cloudflare" ] )
then
    if ( [ "${CLOUDHOST}" = "exoscale" ] )
    then
        alldnsproxyips="103.21.244.0/22,103.22.200.0/22,103.31.4.0/22,104.16.0.0/13,104.24.0.0/14,108.162.192.0/18,141.101.64.0/18,162.158.0.0/15,172.64.0.0/13,173.245.48.0/20,188.114.96.0/20,190.93.240.0/20,197.234.240.0/22,198.41.128.0/17,131.0.72.0/22,199.27.128.0/21"
        alldnsproxyips="${autoscalerips},${allldnsproxyips}"
    fi
    if ( [ "${CLOUDHOST}" = "linode" ] )
    then
        alldnsproxyips="\"103.21.244.0/22\",\"103.22.200.0/22\",\"103.31.4.0/22\",\"104.16.0.0/13\",\"104.24.0.0/14\",\"108.162.192.0/18\",\"141.101.64.0/18\",\"162.158.0.0/15\",\"172.64.0.0/13\",\"173.245.48.0/20\",\"188.114.96.0/20\",\"190.93.240.0/20\",\"197.234.240.0/22\",\"198.41.128.0/17\",\"131.0.72.0/22\",\"199.27.128.0/21\""
        alldnsproxyips="${autoscalerips},${allldnsproxyips}"
    fi
fi
