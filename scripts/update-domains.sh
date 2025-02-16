#!/bin/bash
set -e
set -m
export $(cat /etc/.env | xargs)

if [ -z "$ADMINEMAIL" ]; then
    echo "Need to set ADMINEMAIL (used for let's encrypt renewal emails)"
    exit 1
fi
if [ -z "$HOSTDOMAIN" ]; then
    echo "Need to set HOSTDOMAIN (used to decide which list of domains is used) Permitted values:"
    ls /etc/nginx/domain-sets
    exit 1
fi
HOSTDOMAIN=`echo "$HOSTDOMAIN" | sed s/-v\[0-9\]//g` # Strip out the versioning part from any ip v4 or ip v6 specific hostnames
if [ ! -f "/etc/nginx/domain-sets/$HOSTDOMAIN" ]; then
    echo "Unable to find domain set for HOSTDOMAIN $HOSTDOMAIN Permitted values:"
    ls /etc/nginx/domain-sets
    exit 1
fi

certbotflags="--non-interactive --nginx --agree-tos --deploy-hook post-to-loganne.sh"
if [ "$CERT_SERVER" ]; then
	rm -rf /etc/letsencrypt/accounts/$CERT_SERVER
	certbotflags+=" --server https://$CERT_SERVER/dir --no-verify-ssl"
elif [ -z "$PRODUCTION" ]; then
	certbotflags+=" --staging"
fi
certbotflags+=" -m $ADMINEMAIL"
echo "Certbot commands will use the following flags: \"$certbotflags\""

domaincount=0

# Special case is the hostname of the box - see templates/router.conf for its config

routertemplate=$(</etc/nginx/router-template.conf)
hostdomainreplaced=${routertemplate//\{\{domain\}\}/$HOSTDOMAIN}
mkdir -p /etc/nginx/conf.d/generated/assets
certbot certonly $certbotflags -d $HOSTDOMAIN
echo "$hostdomainreplaced" > /etc/nginx/conf.d/generated/$HOSTDOMAIN.conf
service nginx reload || true

# Ensure there's callback config for hosts which aren't recognised
errortemplate=$(</etc/nginx/error-template.conf)
errorhostdomainreplaced=${errortemplate//\{\{domain\}\}/$HOSTDOMAIN}
mkdir -p /etc/nginx/conf.d/generated/error-assets
# Start with 000 in an attempt to have it take presedence over other config
echo "$errorhostdomainreplaced" > /etc/nginx/conf.d/generated/000-error.conf
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
cat > /etc/nginx/conf.d/generated/error-assets/_info.json << EOM
	{
		"system": "lucos_router",
		"checks": {
			"host": {
				"techDetail": "Host recoginised by router",
				"ok": false,
				"debug": "The router hasn't managed to load any config relating to requested host.  This could be due to a failure during initialisation, the host not being listed in the relevant domain-set, OR because the router hasn't finished loading yet."
			}
		}
	}
EOM

# Update the schedule tracker to report success (failure would exit before now due to `set -e` at the top)
system=`echo "lucos_router_$HOSTDOMAIN" | sed s/\\\\..\\*//`
curl -s "https://schedule-tracker.l42.eu/report-status" --json "{\"system\":\"$system\",\"frequency\":86400,\"status\":\"success\"}"