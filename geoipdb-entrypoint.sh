#!/bin/ash

Initialise(){
   geoip_db_url="https://mailfud.org/geoip-legacy/GeoIP.dat.gz"
   echo
   echo "INFO:    ***** Starting GeoIPDb container *****"
   echo "INFO:    $(cat /etc/*-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//g' | sed 's/"//g')"
   if [ ! -e "${geoip_db_dir}" ]; then
      echo "WARNING: Database directory does not exist, creating ${geoip_db_dir}"
      mkdir -p "${geoip_db_dir}"
   fi
   echo "INFO:    GeoIP Database directory: ${geoip_db_dir}"
   if [ "$(grep -c 'geoip-entrypoint.sh' /etc/crontabs/root)" -lt 1 ]; then
      echo "INFO:    Initialise crontab"
      minute=$(((RANDOM%60)))
      echo "INFO:    GeoIPDB will update daily @ 6:${minute}"
      {
         echo "# min   hour    day     month   weekday command"
         echo "${minute} 6 * * * /usr/local/bin/geoipdb-entrypoint.sh --update-only"
      } > /tmp/crontab.tmp
      crontab /tmp/crontab.tmp
      rm /tmp/crontab.tmp
   fi
}

CreateDatabase(){
   local zip_temp_dir="$(mktemp -d)"
   echo "INFO:    Downloading GeoIP Country database..."
   wget -qO "${zip_temp_dir}/GeoIP.dat.gz" "${geoip_db_url}"
   if [ $? -ne 0 ]; then
      echo "Database download failed. Waiting for 2 hours to prevent hammering"
      sleep 120m
   else
      if [ -e "${geoip_db_dir}/GeoIP.dat" ]; then
         echo "INFO:    Removing old GeoIP Country database"
         rm "${geoip_db_dir}/GeoIP.dat"
      fi
      gunzip "${zip_temp_dir}/GeoIP.dat.gz"
      mv -f "${zip_temp_dir}/GeoIP.dat" "${geoip_db_dir}"
      touch "${geoip_db_dir}/GeoIP.dat"
      rm -fr "${zip_temp_dir}"
      echo "INFO:    GeoIP Country database installation complete"
   fi
}

CheckDatabase(){
   echo "INFO:    Checking GeoIP Country database is installed and up-to-date"
   if [ -z "$(find "${geoip_db_dir}" -type f -name 'GeoIP.dat')" ]; then
      echo "INFO:    Creating GeoIP Country database"
      CreateDatabase
   elif [ "$(find "${geoip_db_dir}" -type f -name 'GeoIP.dat' -mmin +$((60*24*8)) | wc -l)" -ne 0 ]; then
      echo "INFO:    Updating GeoIP Country database"
      CreateDatabase
   else
      echo "INFO:    GeoIP Country database already installed and up-to-date"
   fi
}

LaunchCrontab(){
   echo "INFO:    Starting crontab"
   exec /usr/sbin/crond -f -L /dev/stdout
}

##### Script #####
if [ "${#}" -eq 1 ] && [ "${1}" = "--update-only" ]; then
   CheckDatabase
else 
   Initialise
   CheckDatabase
   LaunchCrontab
fi