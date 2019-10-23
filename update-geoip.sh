#!/bin/ash

Initialise(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ***** Starting GeoIPDb container using sherpya's geolite2legacy to convert to the legacy format *****"

   if [ ! -e "${DBDIR}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Database directory does not exist, creating ${DBDIR}"; mkdir -p "${DBDIR}"; fi

   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    GeoLite2Legacy directory: ${APPBASE}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    GeoIP Database directory: ${DBDIR}"

   if [ $(grep -c "update-geoip.sh" /etc/crontabs/root) -lt 1 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Initialise crontab"
      MIN=$(((RANDOM%60)))
      echo -e "# min   hour    day     month   weekday command\n${MIN} 5 * * 4 /usr/local/bin/update-geoip.sh >/dev/stdout 2>&1" > /tmp/crontab.tmp
      crontab /tmp/crontab.tmp
      rm /tmp/crontab.tmp
   fi
}

GeoLite2Legacy(){
   if [ ! -d "${APPBASE}/.git" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Installing ${REPO}"
      mkdir -p "${APPBASE}"
      git clone -b master "https://github.com/${REPO}.git" "${APPBASE}"
   elif [ "$(date '+%a')" = "Mon" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Checking ${REPO} for updates"
      cd "${APPBASE}" || exit 1
      git pull
      cd / || exit 1
   fi
}

UpdateDatabases(){
   if [ -z "$(find "${DBDIR}" -type f -name 'GeoIP.dat')" ] || [ "$(find "${DBDIR}" -type f -name 'GeoIP.dat' -mmin +$((60*24*6)) | wc -l)" -ne 0 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Installing GeoIP Country database"
      local ZIPTEMP="$(mktemp -d)"
      local DBTEMP="$(mktemp -d)"
      if [ -e "${DBDIR}/GeoIP.dat" ]; then rm "${DBDIR}/GeoIP.dat"; fi
      wget -qO "${ZIPTEMP}/GeoLite2-Country-CSV.zip" "${DBURL}/GeoLite2-Country-CSV.zip"
      python "${APPBASE}/geolite2legacy.py" -i "${ZIPTEMP}/GeoLite2-Country-CSV.zip" -f "${APPBASE}/geoname2fips.csv" -o "${DBTEMP}/GeoIP.dat"
      mv -f "${DBTEMP}/GeoIP.dat" "${DBDIR}"
      rm -fr "${ZIPTEMP}" "${DBTEMP}"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    GeoIP Country database installation complete"
   fi
   if [ -z "$(find "${DBDIR}" -type f -name 'GeoLiteCity.dat')" ] || [ "$(find "${DBDIR}" -type f -name 'GeoLiteCity.dat' -mmin +$((60*24*6)) | wc -l)" -ne 0 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Installing GeoIP City database"
      local ZIPTEMP="$(mktemp -d)"
      local DBTEMP="$(mktemp -d)"
      if [ -e "${DBDIR}/GeoLiteCity.dat" ]; then rm "${DBDIR}/GeoLiteCity.dat"; fi
      wget -q -O "${ZIPTEMP}/GeoLite2-City-CSV.zip" "${DBURL}/GeoLite2-City-CSV.zip"
      python "${APPBASE}/geolite2legacy.py" -i "${ZIPTEMP}/GeoLite2-City-CSV.zip" -f "${APPBASE}/geoname2fips.csv" -o "${DBTEMP}/GeoLiteCity.dat"
      mv -f "${DBTEMP}/GeoLiteCity.dat" "${DBDIR}"
      rm -fr "${ZIPTEMP}" "${DBTEMP}"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    GeoIP City database installation complete"
   fi
   if [ -z "$(find "${DBDIR}" -type f -name 'GeoIPASNum.dat')" ] || [ "$(find "${DBDIR}" -type f -name 'GeoIPASNum.dat' -mmin +$((60*24*6)) | wc -l)" -ne 0 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Installing GeoIP ASNum database"
      if [ -e "${DBDIR}/GeoIPASNum.dat" ]; then rm "${DBDIR}/GeoIPASNum.dat"; fi
      wget -qO "${ZIPTEMP}/GeoLite2-ASN-CSV.zip" "${DBURL}/GeoLite2-ASN-CSV.zip"
      python "${APPBASE}/geolite2legacy.py" -i "${ZIPTEMP}/GeoLite2-ASN-CSV.zip" -o "${DBTEMP}/GeoIPASNum.dat"
      mv -f "${DBTEMP}/GeoIPASNum.dat" "${DBDIR}"
      rm -fr "${ZIPTEMP}" "${DBTEMP}"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    GeoIP ASNum database installation complete"
   fi
}

##### Script #####
Initialise
GeoLite2Legacy
UpdateDatabases
