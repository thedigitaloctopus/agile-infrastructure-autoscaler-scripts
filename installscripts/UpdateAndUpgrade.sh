#!/bin/sh

HOME="`/bin/cat /home/homedir.dat`"

${HOME}/installscripts/Update.sh ${1}
${HOME}/installscripts/Upgrade.sh ${1}
