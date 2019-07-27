#!/bin/bash
set -e
set -m

if [ -z "$ADMINEMAIL" ]; then
    echo "Need to set ADMINEMAIL (used for let's encrypt renewal emails)"
    exit 1
fi
if [ -z "$HOSTDOMAIN" ]; then
    echo "Need to set HOSTDOMAIN (used to decide which list of domains is used) Permitted values:"
    ls /etc/nginx/domain-sets
    exit 1
fi
if [ ! -f "/etc/nginx/domain-sets/$HOSTDOMAIN" ]; then
    echo "Unable to find domain set for HOSTDOMAIN $HOSTDOMAIN Permitted values:"
    ls /etc/nginx/domain-sets
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

# Special case is the hostname of the box - see templates/router.conf for its config

routertemplate=$(</etc/nginx/router-template.conf)
hostdomainreplaced=${routertemplate//\{\{domain\}\}/$HOSTDOMAIN}
mkdir -p /etc/nginx/conf.d/generated/assets || true
certbot certonly $certbotflags -d $HOSTDOMAIN && \
echo "$hostdomainreplaced" > /etc/nginx/conf.d/generated/$HOSTDOMAIN.conf && \
service nginx reload || true

template=$(</etc/nginx/https-template.conf)
echo "Checking domain list"

cat /etc/nginx/domain-sets/$HOSTDOMAIN | while read line || [[ -n "$line" ]]
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