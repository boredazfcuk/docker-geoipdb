FROM alpine:latest
LABEL maintainer="boredazfcuk"
ARG app_dependencies="tzdata geoip"

ENV app_base_dir="/GeoLite2Legacy" \
   geoip_db_dir="/usr/share/GeoIP"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED FOR GEOIPDB *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Add group, user and required directories" && \
   mkdir -p "${app_base_dir}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install application dependencies" && \
   apk add --no-cache --no-progress ${app_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD COMPLETE *****"

COPY --chmod=0755 geoipdb-entrypoint.sh /usr/local/bin/geoipdb-entrypoint.sh
COPY --chmod=0755 healthcheck.sh /usr/local/bin/healthcheck.sh

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
   CMD /usr/local/bin/healthcheck.sh

VOLUME "${geoip_db_dir}"
WORKDIR "${app_base_dir}"

ENTRYPOINT /usr/local/bin/geoipdb-entrypoint.sh
