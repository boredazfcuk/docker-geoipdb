#!/bin/ash

Initialise(){
   REPO="sherpya/geolite2legacy"
   DBURL="https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=${MAXMINDLICENCEKEY}&suffix=zip"

   echo -e "\n"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ***** Starting GeoIPDb container using sherpya's geolite2legacy to convert to the legacy format *****"

   if [ ! -e "${DBDIR}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Database directory does not exist, creating ${DBDIR}"; mkdir -p "${DBDIR}"; fi
   if [ -z "${MAXMINDLICENCEKEY}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Maxmind licence key not specified. Cannot continue - Exiting"; sleep 60; exit 1; fi

   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    GeoLite2Legacy directory: ${APPBASE}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    GeoIP Database directory: ${DBDIR}"

   if [ "$(grep -c 'update-geoip.sh' /etc/crontabs/root)" -lt 1 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Initialise crontab"
      MIN=$(((RANDOM%60)))
      echo -e "# min   hour    day     month   weekday command\n${MIN} 5 5 * 4 /usr/local/bin/update-geoip.sh >/dev/stdout 2>&1" > /tmp/crontab.tmp
      crontab /tmp/crontab.tmp
      rm /tmp/crontab.tmp
   fi
}

GeoLite2Legacy(){
   if [ ! -d "${APPBASE}/.git" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Installing ${REPO}"
      mkdir -p "${APPBASE}"
      git clone --quiet --branch master "https://github.com/${REPO}.git" "${APPBASE}"
   elif [ "$(date '+%a')" = "Mon" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Checking ${REPO} for updates"
      cd "${APPBASE}" || exit 1
      git pull
      cd / || exit 1
   fi
}

UpdateDatabase(){
   if [ -z "$(find "${DBDIR}" -type f -name 'GeoIP.dat')" ] || [ "$(find "${DBDIR}" -type f -name 'GeoIP.dat' -mmin +$((60*24*6)) | wc -l)" -ne 0 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Installing GeoIP Country database"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    This product includes GeoLite2 data created by MaxMind, available from https://www.maxmind.com"
      local ZIPTEMP="$(mktemp -d)"
      local DBTEMP="$(mktemp -d)"
      if [ -e "${DBDIR}/GeoIP.dat" ]; then rm "${DBDIR}/GeoIP.dat"; fi
      wget -qO "${ZIPTEMP}/GeoLite2-Country-CSV.zip" "${DBURL}"
      python "${APPBASE}/geolite2legacy.py" -i "${ZIPTEMP}/GeoLite2-Country-CSV.zip" -f "${APPBASE}/geoname2fips.csv" -o "${DBTEMP}/GeoIP.dat"
      mv -f "${DBTEMP}/GeoIP.dat" "${DBDIR}"
      rm -fr "${ZIPTEMP}" "${DBTEMP}"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    GeoIP Country database installation complete"
   fi
}

##### Script #####
Initialise
GeoLite2Legacy
UpdateDatabase