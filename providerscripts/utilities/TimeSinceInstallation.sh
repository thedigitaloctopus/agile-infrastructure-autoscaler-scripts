#!/bin/sh

file_name="/etc/ssh/ssh_host_dsa_key.pub"

old=`/usr/bin/stat -c %Z $file_name` 
now=`/usr/bin/date +%s` 
age="`/usr/bin/expr ${now} - ${old}`"
age_in_mins="`/usr/bin/expr ${age} \/ 60`"

/bin/echo ${age_in_mins}
