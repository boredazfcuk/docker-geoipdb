#!/bin/ash

if [ $(find "${DBDIR}" -type f -name "Geo*.dat" | wc -l) -ne 3 ]; then
   echo "GeoIP files missing"
   exit 1
fi

if [ $(find "${DBDIR}" -type f -name "Geo*.dat" -mmin +$((60*24*8)) | wc -l) -ne 0 ]; then
   echo "GeoIP files older than 8 days"
   exit 1
fi

exit 0