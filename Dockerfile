FROM nginx

RUN rm /etc/nginx/conf.d/*
RUN rm -rf /usr/share/nginx/html

RUN dpkg --add-architecture amd64
RUN dpkg --add-architecture armhf
RUN printf "deb http://deb.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/backports.list
RUN apt-get update
RUN apt-get -t stretch-backports install certbot python-certbot-nginx -y

COPY conf                  /etc/nginx/conf.d
COPY templates/router.conf /etc/nginx/router-template.conf
COPY templates/https.conf  /etc/nginx/https-template.conf
COPY domain-sets           /etc/nginx/domain-sets
COPY update-domains.sh     /usr/bin/update-domains.sh

CMD /usr/bin/update-domains.sh