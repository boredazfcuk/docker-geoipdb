FROM alpine:latest
MAINTAINER boredazfcuk
ENV REPO="sherpya/geolite2legacy" \
   DBURL="https://geolite.maxmind.com/download/geoip/database" \
   APPBASE="/GeoLite2Legacy" \
   DBDIR="/usr/share/GeoIP" \
   APPDEPENDENCIES="git curl python py-ipaddr tzdata"

COPY update-geoip.sh /usr/local/bin/update-geoip.sh

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Add group, user and required directories" && \
   mkdir -p "${APPBASE}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install application dependencies" && \
   apk add --no-cache --no-progress ${APPDEPENDENCIES}  && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Installing ${REPO}" && \
   git clone -b master "https://github.com/${REPO}.git" "${APPBASE}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Set launch script permissions" && \
   chmod +x "/usr/local/bin/update-geoip.sh" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD COMPLETE *****"

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
   CMD (if [ $(find "${DBDIR}" -type f -name "Geo*.dat" | wc -l) -ne 3 ] || [ $(find "${DBDIR}" -type f -name "Geo*.dat" -mmin +$((60*24*8)) | wc -l) -ne 0 ]; then exit 1; fi)

VOLUME "${DBDIR}"
WORKDIR "${APPBASE}"

CMD /usr/local/bin/update-geoip.sh && /usr/sbin/crond -f -L /dev/stdout
