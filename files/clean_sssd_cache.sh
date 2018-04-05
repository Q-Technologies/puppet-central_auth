#!/bin/bash
#
service sssd stop
rm -rf /var/lib/sss/db/*
rm -rf /var/lib/sss/mc/*
service sssd start
echo "Cleaned sssd cache" >> /var/log/sssd_clean.log
