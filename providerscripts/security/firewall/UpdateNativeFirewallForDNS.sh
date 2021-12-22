DNS_CHOICE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DNSCHOICE'`"

if ( [ "${DNS_CHOICE}" = "cloudflare" ] )
then
    allproxyips="103.21.244.0/22 103.22.200.0/22 103.31.4.0/22 104.16.0.0/13 104.24.0.0/14 108.162.192.0/18 141.101.64.0/18 162.158.0.0/15 172.64.0.0/13 173.245.48.0/20 188.114.96.0/20 to any port 80
190.93.240.0/20 197.234.240.0/22 198.41.128.0/17 131.0.72.0/22 199.27.128.0/21"

    /bin/echo "${allproxyips}" > ${HOME}/runtime/ipsforproxyserversfirewall
    ${HOME}/providerscripts/server/UpdateNativeFirewall.sh
fi
