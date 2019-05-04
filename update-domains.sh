#!/bin/bash
set -e
set -m

if [ -z "$ADMINEMAIL" ]; then
    echo "Need to set ADMINEMAIL (used for let's encrypt renewal emails)"
    exit 1
fi  

# Start up nginx in the background
nginx -g "daemon off;" &

echo "Checking domain list"
domainlist=$(cat /etc/nginx/domain-list)

for DOMAIN in $domainlist;
do
	echo "Renewing domain: $DOMAIN"
	certbot --staging --non-interactive --nginx -d $DOMAIN --agree-tos -m $ADMINEMAIL && \
	
	# TODO: replace domain name into template
	cat /etc/nginx/https-template.conf >> /etc/nginx/conf.d/$DOMAIN.conf && \
	service nginx reload || true
done

# Bring nginx to the foreground
fg %1