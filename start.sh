#!/bin/sh

# compile DNS server config entries
cd /srv/dns/root
make

# compile axfrdns config (will answer with DNS server entries)
cd /srv/axfrdns
make
# run DNS server on TCP
./run &

# run DNS server on UDP
cd /srv/dns
./run

