FROM alpine:3.12
MAINTAINER boredazfcuk
ARG app_dependencies="git tzdata unzip python3 py3-ipaddr"
ENV app_base_dir="/GeoLite2Legacy" \
   geoip_db_dir="/usr/share/GeoIP"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED FOR GEOIPDB *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Add group, user and required directories" && \
   mkdir -p "${app_base_dir}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install application dependencies" && \
   apk add --no-cache --no-progress ${app_dependencies} && \
   ln -s /usr/bin/python3 /usr/bin/python

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | Set launch script permissions" && \
   chmod +x "/usr/local/bin/entrypoint.sh" "/usr/local/bin/healthcheck.sh" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD COMPLETE *****"

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
   CMD /usr/local/bin/healthcheck.sh

VOLUME "${geoip_db_dir}"
WORKDIR "${app_base_dir}"

ENTRYPOINT /usr/local/bin/entrypoint.sh
