FROM alpine:3.10

LABEL maintainer="jordenyt <jordenyt@gmail.com>"

ARG TZ='Asia/Hong_Kong'

ENV TZ ${TZ}
ENV SS_DOWNLOAD_URL https://github.com/shadowsocks/shadowsocks-libev.git 
ENV KCP_DOWNLOAD_URL https://github.com/xtaci/kcptun/releases/download/v20200201/kcptun-linux-arm7-20200201.tar.gz
ENV PLUGIN_OBFS_DOWNLOAD_URL https://github.com/shadowsocks/simple-obfs.git
ENV PLUGIN_V2RAY_DOWNLOAD_URL https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.0/v2ray-plugin-linux-arm-v1.3.0.tar.gz
ENV LINUX_HEADERS_DOWNLOAD_URL=http://dl-cdn.alpinelinux.org/alpine/v3.10/main/armv7/linux-headers-4.19.36-r0.apk

RUN apk upgrade \
    && apk add bash tzdata rng-tools runit \
    && apk add --virtual .build-deps \
        autoconf \
        automake \
        build-base \
        curl \
        c-ares-dev \
        libev-dev \
        libtool \
        libsodium-dev \
        mbedtls-dev \
        pcre-dev \
        tar \
        git \
    && curl -sSL ${LINUX_HEADERS_DOWNLOAD_URL} > /linux-headers.apk \
    && apk add --virtual .build-deps-kernel /linux-headers.apk \
    && git clone ${SS_DOWNLOAD_URL} \
    && (cd shadowsocks-libev \
    && git checkout master \
    && git submodule update --init --recursive \
    && ./autogen.sh \
    && ./configure --prefix=/usr --disable-documentation \
    && make install) \
    && git clone ${PLUGIN_OBFS_DOWNLOAD_URL} \
    && (cd simple-obfs \
    && git submodule update --init --recursive \
    && ./autogen.sh \
    && ./configure --disable-documentation \
    && make install) \
    && curl -o v2ray_plugin.tar.gz -sSL ${PLUGIN_V2RAY_DOWNLOAD_URL} \
    && tar -zxf v2ray_plugin.tar.gz \
    && mv v2ray-plugin_linux_arm7 /usr/bin/v2ray-plugin \
    && curl -o kcptun-linux.tar.gz -sSLO ${KCP_DOWNLOAD_URL} \
    && tar -zxf kcptun-linux.tar.gz \
    && mv server_linux_arm7 /usr/bin/kcpserver \
    && mv client_linux_arm7 /usr/bin/kcpclient \
    && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && adduser -h /tmp -s /sbin/nologin -S -D -H shadowsocks \
    && adduser -h /tmp -s /sbin/nologin -S -D -H kcptun \
    && apk del .build-deps .build-deps-kernel \
	&& apk add --no-cache \
      $(scanelf --needed --nobanner /usr/bin/ss-* /usr/local/bin/obfs-* \
      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
      | sort -u) \
    && rm -rf /linux-headers.apk \
        kcptun-linux.tar.gz \
        shadowsocks-libev \
        simple-obfs \
        v2ray_plugin.tar.gz \
        /etc/service \
        /var/cache/apk/*

SHELL ["/bin/bash"]

COPY runit /etc/service
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
