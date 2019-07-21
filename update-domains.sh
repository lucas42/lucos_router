#!/bin/bash
set -e
set -m

if [ -z "$ADMINEMAIL" ]; then
    echo "Need to set ADMINEMAIL (used for let's encrypt renewal emails)"
    exit 1
fi
# Start up nginx in the background
nginx -g "daemon off;" &

certbotflags="--non-interactive --nginx --agree-tos"
if [ -z "$PRODUCTION" ]; then
	certbotflags+=" --staging"
fi
certbotflags+=" -m $ADMINEMAIL"
echo "Certbot commands will use the following flags: \"$certbotflags\""

domaincount=0

# Special case is the domain for this service - see templates/router.conf for its config
mkdir -p /etc/nginx/conf.d/generated/assets || true
certbot certonly $certbotflags -d router.l42.eu && \
cp /etc/nginx/router.conf /etc/nginx/conf.d/generated/ && \
service nginx reload || true

template=$(</etc/nginx/https-template.conf)
echo "Checking domain list"

cat /etc/nginx/domain-list | while read line || [[ -n "$line" ]]
do
	# ignore blank/commented lines
	if [[ -z "$line" || "$line" =~ ^#.*$ ]]; then
		continue
	fi
	domaindetails=($line)
	DOMAIN=${domaindetails[0]}
	BACKEND=${domaindetails[1]}
	echo "Renewing domain: $DOMAIN"
	domainreplaced=${template//\{\{domain\}\}/$DOMAIN}
	backendreplaced=${domainreplaced//\{\{backend\}\}/$BACKEND}

	certbot certonly $certbotflags -d $DOMAIN && \

	echo "$backendreplaced" > /etc/nginx/conf.d/generated/$DOMAIN.conf && \
	service nginx reload || true
done

domaincount="$(ls -1q /etc/nginx/conf.d/generated/*.conf | wc -l)"
cat > /etc/nginx/conf.d/generated/assets/_info.json << EOM
	{
		"system": "lucos_router",
		"checks":{},
		"metrics":{
			"domain-count": {
				"value": $domaincount,
				"techDetail": "The number of domains served by the router"
			}
		},
		"ci": {
			"circle": "gh/lucas42/lucos_router"
		}
	}
EOM

# Bring nginx to the foreground
fg %1