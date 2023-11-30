FROM alpine
RUN apk update && apk upgrade && apk add --update lighttpd
COPY ./conf/* /etc/lighttpd/
COPY ./html/* /var/www/html/
EXPOSE 80
CMD ["lighttpd","-D","-f","/etc/lighttpd/lighttpd.conf"]