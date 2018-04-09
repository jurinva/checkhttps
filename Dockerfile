FROM alpine
RUN rm -rf /var/cache/apk/* && rm -rf /tmp/* && apk update && apk add --no-cache bash curl gawk openssl
# openssh-client
COPY checkhttps.sh /usr/bin/
CMD ["/bin/sh"]
