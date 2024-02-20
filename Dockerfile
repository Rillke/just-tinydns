FROM alpine:edge
# A more up-to-date-version might be:
# https://github.com/xcsrz/just-tinydns/tree/master

ENV GID tinydns
ENV UID tinydns
ENV IP 0.0.0.0
ENV ROOT /etc/tinydns

RUN \
  apk add --no-cache gcc g++ git make linux-headers libc-dev ucspi-tcp ucspi-tcp6 ca-certificates inotify-tools bash \
  && update-ca-certificates \
  && apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ daemontools

RUN \
  git clone https://github.com/henryk/tinydnssec.git \
  && cd tinydnssec \
  && make \
  && make setup check

RUN \
  adduser -HD $UID \
  && adduser -HD dnslog \
  && adduser -HD Gaxfrdns \
  && adduser -HD Gdnslog

RUN \
  tinydns-conf $UID dnslog /srv/dns $IP \
  && axfrdns-conf Gaxfrdns Gdnslog /srv/axfrdns /srv/dns $IP \
  && echo ':allow,AXFR=""' > /srv/axfrdns/tcp

COPY start.sh /start.sh
COPY rebuild.sh /rebuild.sh
COPY update.sh /update.sh
COPY watch-changes.sh /watch-changes.sh

RUN chmod +x /start.sh
RUN chmod +x /rebuild.sh
RUN chmod +x /update.sh
RUN chmod +x /watch-changes.sh

COPY zone.dns /srv/dns/root/data

EXPOSE 53/udp
EXPOSE 53/tcp

CMD '/start.sh'

