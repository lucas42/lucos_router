FROM nginx

RUN rm /etc/nginx/conf.d/*
RUN rm -rf /usr/share/nginx/html

RUN printf "deb http://deb.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/backports.list
RUN apt-get update
RUN apt-get -t stretch-backports install certbot python-certbot-nginx -y

COPY conf /etc/nginx/conf.d
COPY templates/https.conf /etc/nginx/https-template.conf
COPY domain-list          /etc/nginx/domain-list
COPY update-domains.sh    /usr/bin/update-domains.sh

CMD /usr/bin/update-domains.sh