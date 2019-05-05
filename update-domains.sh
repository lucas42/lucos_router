#!/bin/bash
set -e
set -m

if [ -z "$ADMINEMAIL" ]; then
    echo "Need to set ADMINEMAIL (used for let's encrypt renewal emails)"
    exit 1
fi  

# Start up nginx in the background
nginx -g "daemon off;" &

template=$(</etc/nginx/https-template.conf)
echo "Checking domain list"

cat /etc/nginx/domain-list | while read line || [[ -n "$line" ]]
do
	# ignore blank lines
	if [ -z "$line" ]; then
		continue
	fi
	domaindetails=($line)
	DOMAIN=${domaindetails[0]}
	BACKEND=${domaindetails[1]}
	echo "Renewing domain: $DOMAIN"
	domainreplaced=${template//\{\{domain\}\}/$DOMAIN}
	backendreplaced=${domainreplaced//\{\{backend\}\}/$BACKEND}

	certbot certonly --non-interactive --nginx -d $DOMAIN --agree-tos -m $ADMINEMAIL && \

	echo "$backendreplaced" > /etc/nginx/conf.d/$DOMAIN.conf && \
	service nginx reload || true
done

# Bring nginx to the foreground
fg %1