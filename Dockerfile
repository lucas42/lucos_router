FROM nginx

RUN rm /etc/nginx/conf.d/*
RUN rm -rf /usr/share/nginx/html

COPY default.conf /etc/nginx/conf.d/default.conf