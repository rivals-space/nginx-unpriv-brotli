FROM alpine:3.17

ARG NGINX_VERSION=1.25.1


RUN set -eux ; \
    apk --update add --no-cache --virtual .build-deps \
      openssl-dev \
      pcre2-dev \
      zlib-dev \
      wget \
      build-base \
      brotli-dev \
    ; \
    apk --update add --no-cache \
      pcre2 \
      brotli-libs \
      perl \
    ; \
    mkdir -p /tmp/src ; \
    cd /tmp/src ; \
    wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -O nginx.tar.gz ; \
    wget https://github.com/google/ngx_brotli/archive/refs/heads/master.tar.gz -O brotli-nginx-module.tar.gz ; \
    tar -zxvf nginx.tar.gz ; \
    tar -zxvf brotli-nginx-module.tar.gz; \
    cd /tmp/src/nginx-${NGINX_VERSION}; \
    export CFLAGS="-Wno-deprecated-declarations"; \
    ./configure \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-http_realip_module \
        --with-http_stub_status_module \
        --with-http_perl_module \
        --add-module=/tmp/src/ngx_brotli-master \
        --conf-path=/etc/nginx/nginx.conf \
        --pid-path=/tmp/nginx.pid \
        --http-log-path=/var/log/nginx/access.log \
        --error-log-path=/var/log/nginx/error.log \
        --sbin-path=/usr/sbin/nginx  \
    ; \
    make; \
    make install; \
    apk del --no-cache .build-deps build-base; \
    rm -rf /tmp/src; \
    rm -rf /var/cache/apk/*; \
    ln -sf /dev/stdout /var/log/nginx/access.log; \
    ln -sf /dev/stderr /var/log/nginx/error.log; \
    addgroup -S nginx -g 991; \
    adduser -S nginx -G nginx -DH -u 991

USER nginx

COPY --chown=nginx:nginx nginx-conf/etc /etc/nginx
COPY --chown=nginx:nginx nginx-conf/html /usr/share/nginx/html

CMD ["nginx", "-g", "daemon off;"]
