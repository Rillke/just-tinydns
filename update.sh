#!/usr/bin/env bash
# Shamelessly stolen from
# http://belski.net/archives/40-Get-home,-even-being-miles-away.html
# of the original script: Anatol Belski
# Modifications: Don't duplicate entries, more verbose output, cleanup
# Modifications are MIT licensed.

TINYDNS_UP_LOCK=/tmp/tinydns.up.lock
TINYDNS_SV_ROOT=/srv/dns/root
UPDATES_DIR=/tmp/ddns_updates
DATA_TMP="$TINYDNS_SV_ROOT/data.tmp"
DATA_NEW="$TINYDNS_SV_ROOT/data"

mkdir -p ${UPDATES_DIR}
chmod a+rwx ${UPDATES_DIR}

if [ -f "${TINYDNS_UP_LOCK}" ]
then
    echo Another update is running, exitinng
    exit 0
fi

if [ -z "$(ls -A ${UPDATES_DIR})" ]
then
    # no updates, nothing to do
    echo "Nothing to update"
    exit 0
fi

echo "=================================="
date
echo "----------------------------------"
echo "Writing lock"
touch "$TINYDNS_UP_LOCK"
trap '{ rm -f -- "$TINYDNS_UP_LOCK"; }' EXIT
rm -f "${DATA_TMP}"

# first loop to read the lines from data
# that means - new hosts only can be added manually to tinydns data file
cd "${TINYDNS_SV_ROOT}" || ( echo "Can't cd into ${TINYDNS_SV_ROOT}" ; exit 1 )
while read -r LINE
do

    if [ -z "$(ls -A ${UPDATES_DIR})" ]
    then
        # probably all the updates was applied, so take as is
        echo "No more changes. Copying $LINE"
        echo "${LINE}" >> "${DATA_TMP}"
        continue
    fi

    ADDED=false

    for FL_PATH in "${UPDATES_DIR}"/*
    do
        DOMAIN=$(basename "$FL_PATH")
        REC=$(echo "$LINE" | cut -d: -f1)
        ADDED=false

        if [ "=$DOMAIN" == "$REC" ]
        then
            # 60 seconds TTL for all, that's it for now
            IP=$(cat "$FL_PATH")
            echo "Update for $DOMAIN:$IP"
            echo "=$DOMAIN:$IP:60" >> "${DATA_TMP}"
            rm "$FL_PATH"
            ADDED=true
        fi
    done

    if ! [ "$ADDED" = true ]
    then
        # not this domain, leave untouched
        echo "Copying $LINE"
        echo "${LINE}" >> "${DATA_TMP}"
    fi
done < "${DATA_NEW}"

cat "${DATA_TMP}" > "$DATA_NEW"
make 1> /dev/null

if [ -n "$(ls -A ${UPDATES_DIR})" ]
then
   for FL_PATH in "${UPDATES_DIR}"/*
   do
      DOMAIN=$(basename "$FL_PATH")
      IP=$(cat "$FL_PATH")
      echo "$DOMAIN is not yet registered for tinydns usage"
      echo "please do: cd $TINYDNS_SV_ROOT && ./add-host '$DOMAIN' $IP"
      echo "This is for security reasons. Discarding update request."
      rm "$FL_PATH"
   done
fi

echo "Removing lock"
rm "$TINYDNS_UP_LOCK"
echo "----------------------------------"
exit 0

