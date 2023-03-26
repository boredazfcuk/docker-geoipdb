#!/bin/ash

Initialise(){
   if [ "${#}" -eq 1 ] && [ "${1}" = "--update-only" ]; then update_only="True"; fi
   # app_repo="sherpya/geolite2legacy"
   # geoip_db_url="https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=${maxmind_licence_key}&suffix=zip"
   geoip_db_url="https://mailfud.org/geoip-legacy/GeoIP.dat.gz"
   echo
   echo "$(date '+%c') INFO:    ***** Starting GeoIPDb container *****"
   echo "$(date '+%c') INFO:    $(cat /etc/*-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//g' | sed 's/"//g')"
   if [ ! -e "${geoip_db_dir}" ]; then echo "$(date '+%c') WARNING: Database directory does not exist, creating ${geoip_db_dir}"; mkdir -p "${geoip_db_dir}"; fi
   # if [ -z "${maxmind_licence_key}" ]; then echo "$(date '+%c') ERROR:   Maxmind licence key not specified. Cannot continue - Exiting"; sleep 60; exit 1; fi
   # echo "$(date '+%c') INFO:    GeoLite2Legacy directory: ${app_base_dir}"
   echo "$(date '+%c') INFO:    GeoIP Database directory: ${geoip_db_dir}"
   echo "$(date '+%c') INFO:    Update only: ${update_only:=False}"
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

# GeoLite2Legacy(){
   # if [ ! -d "${app_base_dir}/.git" ]; then
      # echo "$(date '+%c') INFO:    Installing ${app_repo}"
      # mkdir -p "${app_base_dir}"
      # git clone --quiet --branch master "https://github.com/${app_repo}.git" "${app_base_dir}"
   # elif [ "$(date '+%a')" = "Mon" ]; then
      # echo "$(date '+%c') INFO:    Checking ${app_repo} for updates"
      # cd "${app_base_dir}" || exit 1
      # git pull
      # cd / || exit 1
   # fi
# }

UpdateDatabase(){
   if [ -z "$(find "${geoip_db_dir}" -type f -name 'GeoIP.dat')" ] || [ "$(find "${geoip_db_dir}" -type f -name 'GeoIP.dat' -mmin +$((60*24*6)) | wc -l)" -ne 0 ]; then
      echo "$(date '+%c') INFO:    Installing GeoIP Country database"
      # echo "$(date '+%c') INFO:    This product includes GeoLite2 data created by MaxMind, available from https://www.maxmind.com"
      local zip_temp_dir="$(mktemp -d)"
      local db_temp_dir="$(mktemp -d)"
      if [ -e "${geoip_db_dir}/GeoIP.dat" ]; then rm "${geoip_db_dir}/GeoIP.dat"; fi
      wget -qO "${zip_temp_dir}/GeoIP.dat.gz" "${geoip_db_url}"
#      python "${app_base_dir}/geolite2legacy.py" -i "${zip_temp_dir}/GeoLite2-Country-CSV.zip" -f "${app_base_dir}/geoname2fips.csv" -o "${db_temp_dir}/GeoIP.dat"
      gunzip "${zip_temp_dir}/GeoIP.dat.gz"
      mv -f "${zip_temp_dir}/GeoIP.dat" "${geoip_db_dir}"
      rm -fr "${zip_temp_dir}" "${db_temp_dir}"
      echo "$(date '+%c') INFO:    GeoIP Country database installation complete"
   else
      echo "$(date '+%c') INFO:    GeoIP Country database installed and up-to-date"
   fi
}

# UpdateDatabase(){
   # if [ -z "$(find "${geoip_db_dir}" -type f -name 'GeoIP.dat')" ] || [ "$(find "${geoip_db_dir}" -type f -name 'GeoIP.dat' -mmin +$((60*24*6)) | wc -l)" -ne 0 ]; then
      # echo "$(date '+%c') INFO:    Installing GeoIP Country database"
      # echo "$(date '+%c') INFO:    This product includes GeoLite2 data created by MaxMind, available from https://www.maxmind.com"
      # local zip_temp_dir="$(mktemp -d)"
      # local db_temp_dir="$(mktemp -d)"
      # if [ -e "${geoip_db_dir}/GeoIP.dat" ]; then rm "${geoip_db_dir}/GeoIP.dat"; fi
      # wget -qO "${zip_temp_dir}/GeoLite2-Country-CSV.zip" "${geoip_db_url}"
      # python "${app_base_dir}/geolite2legacy.py" -i "${zip_temp_dir}/GeoLite2-Country-CSV.zip" -f "${app_base_dir}/geoname2fips.csv" -o "${db_temp_dir}/GeoIP.dat"
      # mv -f "${db_temp_dir}/GeoIP.dat" "${geoip_db_dir}"
      # rm -fr "${zip_temp_dir}" "${db_temp_dir}"
      # echo "$(date '+%c') INFO:    GeoIP Country database installation complete"
   # else
      # echo "$(date '+%c') INFO:    GeoIP Country database installed and up-to-date"
   # fi
# }

LaunchCrontab(){
   echo "$(date '+%c') INFO:    Starting crontab"
   exec /usr/sbin/crond -f -L /dev/stdout
}

##### Script #####
Initialise
# GeoLite2Legacy
UpdateDatabase
if [ "${update_only}" = "False" ]; then LaunchCrontab; fi
