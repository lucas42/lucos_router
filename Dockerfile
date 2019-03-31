FROM nginx

RUN rm /etc/nginx/conf.d/*
RUN rm -rf /usr/share/nginx/html

COPY conf /etc/nginx/conf.d