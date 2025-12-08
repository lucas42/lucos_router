#!/bin/bash
set -e

mkdir -p /etc/nginx/domain-sets

curl "https://configy.l42.eu/hosts/http?fields=id,domain" -s -H "Accept:text/csv;header=absent" | while read -r host_line
do
	IFS=$','; split=($host_line); unset IFS;
	host_id=${split[0]}
	host_domain=${split[1]}
	echo "# Config for host $host_id" > /etc/nginx/domain-sets/$host_domain
	echo "# Auto-generated using data from lucos_configy" >> /etc/nginx/domain-sets/$host_domain
	curl "https://configy.l42.eu/systems/host/${host_id}?fields=domain,http_port" -s -H "Accept:text/csv;header=absent" | while read -r system_line
	do
		IFS=$','; split=($system_line); unset IFS;
		system_domain=${split[0]}
		system_port=${split[1]}
		if [[ "$system_port" != "null" ]]; then
			echo "$system_domain http://172.17.0.1:$system_port" >> /etc/nginx/domain-sets/$host_domain
		fi
	done
	if [[ "$host_id" == "xwing" ]]; then
		echo "nas.l42.eu https://192.168.8.143" >> /etc/nginx/domain-sets/$host_domain
	fi
	if [[ "$host_id" == "avalon" ]]; then
		echo "tfluke.uk https://lucas42.github.io" >> /etc/nginx/domain-sets/$host_domain
		echo "www.tfluke.uk https://lucas42.github.io" >> /etc/nginx/domain-sets/$host_domain
		echo "phys.l42.eu https://lucas42.github.io" >> /etc/nginx/domain-sets/$host_domain
	fi
done