FROM nginx
LABEL  author=star574
ADD html.tar.gz /usr/share/nginx/html
EXPOSE 80
ENTRYPOINT nginx -g "daemon off"