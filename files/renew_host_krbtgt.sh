#!/bin/bash
# Use the host keytab to renew the cached "krbtgt/" principle for the host
HOSTFULLNAME=`uname -n|tr [a-z] [A-Z]`
HOSTSHORTNAME=${HOSTFULLNAME%%.*}
output="$(kinit -v -kt /etc/krb5.keytab -c /tmp/krb5cc_0 "${HOSTSHORTNAME}$" 2>&1)"
if [ $? -eq 0 ] ; then
  logger -p daemon.notice -t renew_host_krbtgt  "krbtgt/host renewed completed"
else
  echo -n "$output" | logger -p daemon.error -t renew_host_krbtgt
  exit 1
fi
  
  
