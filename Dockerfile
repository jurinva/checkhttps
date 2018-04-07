FROM alpine
RUN apk add --no-cache bash curl httpie nano openssl openssh-client
COPY checkhttps.sh /usr/bin/
CMD ["/bin/sh"]
