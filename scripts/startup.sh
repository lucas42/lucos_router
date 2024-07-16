#!/bin/sh
set -e

# Start up nginx in the background
nginx -g "daemon off;" &

# printenv doesn't quote values, which is a problem if one contains a space or newline
# So do some hacky regexes to quote stuff
env -0 | sed 's/"/\\"/g' | sed -z "s/\n/\\\\n/g" | sed 's/\x0/\n/g'| sed 's/=/="/' | sed 's/$/"/g' | sed 's/\\n/\n/g' > /etc/.env

# Update all the domains on startup
update-domains.sh

# Then re-run the script once a day using the cron
[ -p /var/log/cron.log ] || mkfifo /var/log/cron.log
echo "16 22 * * * /usr/bin/update-domains.sh >> /var/log/cron.log 2>&1" | crontab -
service cron start
cat <> /var/log/cron.log