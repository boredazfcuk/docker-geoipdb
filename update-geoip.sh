#!/bin/ash

Initialise(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') | ***** Starting GeoIPDb container using sherpya's geolite2legacy to convert to the legacy format *****"

   if [ ! -e "${DBDIR}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Database directory does not exist, creating ${DBDIR}"; mkdir -p "${DBDIR}"; fi

   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    GeoLite2Legacy directory: ${APPDATA}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    GeoIP Database directory: ${DBDIR}"

#   if [ $(grep -c "update-geoip" /var/spool/root) -lt 1 ]; then
#      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Initialise crontab"
#      MIN=$(((RANDOM%60)))
#      echo -e "SHELL=/bin/ash\n\n# m h  dom mon dow   command\n${MIN} 5 * * 4 /usr/local/bin/update-geoip.sh" > /tmp/crontab.tmp
#      crontab /tmp/crontab.tmp
#      rm /tmp/crontab.tmp
#   }
}

GeoLite2Legacy(){
   if [ ! -e "${APPBASE}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Installing ${REPO}"
      mkdir -p "${APPBASE}"
      git clone -b master "https://github.com/${REPO}.git" "${APPBASE}"
   else
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Checking ${REPO}... "
      cd "${APPBASE}" || exit 1
      git pull
      cd / || exit 1
   fi
}

UpdateDatabases(){
   local ZIPTEMP=$(mktemp -d)
   local DBTEMP=$(mktemp -d)
   if [ -z "$(find "${DBDIR}" -type f -name 'GeoIP.dat')" ] || [ "$(find "${DBDIR}" -type f -name 'GeoIP.dat' -mtime +5 | wc -l)" -ne 0 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Install GeoIP Country database"
      if [ -e "${DBDIR}/GeoIP.dat" ]; then rm "${DBDIR}/GeoIP.dat"; fi
      curl -sS -L "${DBURL}/GeoLite2-Country-CSV.zip" > "${ZIPTEMP}/GeoLite2-Country-CSV.zip"
      python "${APPBASE}/geolite2legacy.py" -i "${ZIPTEMP}/GeoLite2-Country-CSV.zip" -f "${APPBASE}/geoname2fips.csv" -o "${DBTEMP}/GeoIP.dat"
      mv -f "${DBTEMP}/GeoIP.dat" "${DBDIR}"
   fi
   if [ -z "$(find "${DBDIR}" -type f -name 'GeoLiteCity.dat')" ] || [ "$(find "${DBDIR}" -type f -name 'GeoLiteCity.dat' -mtime +5 | wc -l)" -ne 0 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Install GeoIP City database"
      if [ -e "${DBDIR}/GeoLiteCity.dat" ]; then rm "${DBDIR}/GeoLiteCity.dat"; fi
      curl -sS -L "${DBURL}/GeoLite2-City-CSV.zip" > "${ZIPTEMP}/GeoLite2-City-CSV.zip"
      python "${APPBASE}/geolite2legacy.py" -i "${ZIPTEMP}/GeoLite2-City-CSV.zip" -f "${APPBASE}/geoname2fips.csv" -o "${DBTEMP}/GeoLiteCity.dat"
      mv -f "${DBTEMP}/GeoLiteCity.dat" "${DBDIR}"
   fi
   if [ -z "$(find "${DBDIR}" -type f -name 'GeoIPASNum.dat')" ] || [ "$(find "${DBDIR}" -type f -name 'GeoIPASNum.dat' -mtime +5 | wc -l)" -ne 0 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Install GeoIP ASNum database"
      if [ -e "${DBDIR}/GeoIPASNum.dat" ]; then rm "${DBDIR}/GeoIPASNum.dat"; fi
      curl -sS -L "${DBURL}/GeoLite2-ASN-CSV.zip" > "${ZIPTEMP}/GeoLite2-ASN-CSV.zip"
      python "${APPBASE}/geolite2legacy.py" -i "${ZIPTEMP}/GeoLite2-ASN-CSV.zip" -o "${DBTEMP}/GeoIPASNum.dat"
      mv -f "${DBTEMP}/GeoIPASNum.dat" "${DBDIR}"
   fi
   rm -fr "${ZIPTEMP}" "${DBTEMP}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ***** GeoIP Database Update Complete *****"
}

##### Script #####
Initialise
GeoLite2Legacy
UpdateDatabases
