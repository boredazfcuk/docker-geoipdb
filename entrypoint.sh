#!/bin/ash

Initialise(){
   if [ "${#}" -eq 1 ] && [ "${1}" = "--update-only" ]; then update_only=true; fi
   geoip_db_url="https://mailfud.org/geoip-legacy/GeoIP.dat.gz"
   echo
   echo "$(date '+%c') INFO:    ***** Starting GeoIPDb container *****"
   echo "$(date '+%c') INFO:    $(cat /etc/*-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//g' | sed 's/"//g')"
   if [ ! -e "${geoip_db_dir}" ]; then
      echo "$(date '+%c') WARNING: Database directory does not exist, creating ${geoip_db_dir}"
      mkdir -p "${geoip_db_dir}"
   fi
   echo "$(date '+%c') INFO:    GeoIP Database directory: ${geoip_db_dir}"
   echo "$(date '+%c') INFO:    Update only: ${update_only:=false}"
   if [ "$(grep -c 'entrypoint.sh' /etc/crontabs/root)" -lt 1 ]; then
      echo "$(date '+%c') INFO:    Initialise crontab"
      minute=$(((RANDOM%60)))
      {
         echo "# min   hour    day     month   weekday command"
         echo "${minute} 5 5 * 4 /usr/local/bin/entrypoint.sh --update-only >/dev/stdout 2>&1"
      } > /tmp/crontab.tmp
      crontab /tmp/crontab.tmp
      rm /tmp/crontab.tmp
   fi
}

UpdateDatabase(){
   if [ -z "$(find "${geoip_db_dir}" -type f -name 'GeoIP.dat')" ] || [ "$(find "${geoip_db_dir}" -type f -name 'GeoIP.dat' -mmin +$((60*24*6)) | wc -l)" -ne 0 ]; then
      echo "$(date '+%c') INFO:    Installing GeoIP Country database"
      local zip_temp_dir="$(mktemp -d)"
      if [ -e "${geoip_db_dir}/GeoIP.dat" ]; then
         rm "${geoip_db_dir}/GeoIP.dat"
      fi
      wget -qO "${zip_temp_dir}/GeoIP.dat.gz" "${geoip_db_url}"
      if [ $? -ne 0 ]; then
         sleep 120m
      fi
      gunzip "${zip_temp_dir}/GeoIP.dat.gz"
      mv -f "${zip_temp_dir}/GeoIP.dat" "${geoip_db_dir}"
      rm -fr "${zip_temp_dir}"
      echo "$(date '+%c') INFO:    GeoIP Country database installation complete"
   else
      echo "$(date '+%c') INFO:    GeoIP Country database installed and up-to-date"
   fi
}

LaunchCrontab(){
   echo "$(date '+%c') INFO:    Starting crontab"
   exec /usr/sbin/crond -f -L /dev/stdout
}

##### Script #####
Initialise
UpdateDatabase
if [ "${update_only}" = "false" ]; then LaunchCrontab; fi
