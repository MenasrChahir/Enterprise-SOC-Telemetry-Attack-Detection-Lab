FROM alpine:3.20
RUN echo "https://mirror.yandex.ru/mirrors/alpine/v3.20/main" > /etc/apk/repositories \
    && echo "https://mirror.yandex.ru/mirrors/alpine/v3.20/community" >> /etc/apk/repositories \
    && apk update --no-cache \
    && apk add --no-cache hping3 ca-certificates
CMD ["sleep", "infinity"]
