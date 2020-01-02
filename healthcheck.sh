#!/bin/ash

if [ $(find "${DBDIR}" -type f -name "GeoIP.dat" | wc -l) -ne 1 ]; then
   echo "Error GeoIP data missing"
   exit 1
fi

if [ $(find "${DBDIR}" -type f -name "GeoIP.dat" -mmin +$((60*24*8)) | wc -l) -ne 0 ]; then
   echo "Error GeoIP data older than 8 days"
   exit 1
fi
echo "GeoIP data present and up to date"
exit 0