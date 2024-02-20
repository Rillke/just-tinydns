#!/bin/sh
set -x

pid1=0
pid2=0
pid3=0

# SIGTERM-handler
term_handler() {
  if [ $pid1 -ne 0 ]; then
    kill -SIGTERM "$pid1"
    wait "$pid1"
  fi
  if [ $pid2 -ne 0 ]; then
    kill -SIGTERM "$pid2"
    wait "$pid2"
  fi
  if [ $pid3 -ne 0 ]; then
    kill -SIGTERM "$pid3"
    wait "$pid3"
  fi
  exit 143; # 128 + 15 -- SIGTERM
}

trap 'kill ${!}; term_handler' SIGTERM

# compile DNS server config entries
cd /srv/dns/root
make

# compile axfrdns config (will answer with DNS server entries)
cd /srv/axfrdns
make
# run DNS server on TCP
./run &
pid1="$!"

# run DNS server on UDP
cd /srv/dns
./run &
pid2="$!"

# dyndns changes
/watch-changes.sh &
pid3="$!"

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done

