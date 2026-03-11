FROM nginx:1.29.6

RUN rm /etc/nginx/conf.d/*
RUN rm -rf /usr/share/nginx/html

RUN dpkg --add-architecture amd64
RUN dpkg --add-architecture armhf
RUN apt-get update
RUN apt-get install cron python3-certbot-nginx -y

# Create a group for services that need to read TLS private keys.
# Fixed GID 1500 so other containers can use the same GID without sharing /etc/group.
RUN groupadd --gid 1500 certreaders

COPY conf/default.conf     /etc/nginx/conf.d/
COPY conf/nginx.conf       /etc/nginx/
COPY templates/router.conf /etc/nginx/router-template.conf
COPY templates/error.conf  /etc/nginx/error-template.conf
COPY templates/https.conf  /etc/nginx/https-template.conf
COPY scripts/*     /usr/bin/

CMD /usr/bin/startup.sh