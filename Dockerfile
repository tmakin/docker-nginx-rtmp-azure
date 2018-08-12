FROM python:3.7.0-alpine3.8

ENV YAMDI_VERSION 1.9
ENV NGINX_VERSION 1.13.9
ENV NGINX_RTMP_VERSION 1.2.1
ENV AZCOPY_URL https://azcopy.azureedge.net/azcopy-7-2-0/azcopy_7.2.0-netcore_linux_x64.tar.gz

ENV PACKAGES openssl libffi bash apache2-utils
ENV DEV_PACKAGES pkgconf binutils build-base gcc libc-dev libc-dev make musl-dev openssl-dev zlib-dev libffi-dev

EXPOSE 80 1935

RUN	apk add --update --no-cache ${PACKAGES} && apk add --no-cache --virtual .dev_packages ${DEV_PACKAGES}

# Get nginx source.
RUN cd /tmp && \
  wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
  tar zxf nginx-${NGINX_VERSION}.tar.gz

# Get nginx-rtmp module.
RUN cd /tmp && \
  wget https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_VERSION}.tar.gz && \
  tar zxf v${NGINX_RTMP_VERSION}.tar.gz

# Compile nginx with nginx-rtmp module.
# --without-http_rewrite_module  removes need for pcre
RUN cd /tmp/nginx-${NGINX_VERSION} && \
  ./configure \
  --prefix=/opt/nginx \
  --add-module=/tmp/nginx-rtmp-module-${NGINX_RTMP_VERSION} \
  --conf-path=/opt/nginx/nginx.conf \
  --error-log-path=/opt/nginx/logs/error.log \
  --http-log-path=/opt/nginx/logs/access.log \
  --without-http_rewrite_module \
  --with-debug && \
  cd /tmp/nginx-${NGINX_VERSION} && make && make install


# Download and compile yamdi
RUN cd /tmp && \
    wget -O yamdi-${YAMDI_VERSION}.tar.gz https://github.com/ioppermann/yamdi/archive/1.9.tar.gz  && \
    tar zxf yamdi-${YAMDI_VERSION}.tar.gz && \
    cd yamdi-${YAMDI_VERSION} && \
    gcc yamdi.c -o yamdi -O2 -Wall && \
    make && make install

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /opt/nginx/logs/access.log \
 && ln -sf /dev/stderr /opt/nginx/logs/error.log

# azure storage tools
RUN pip install --no-cache-dir azure-storage-blob==1.3.1

# tidy up
RUN rm -rf /var/cache/* /tmp/* /var/lib/apt/lists/* && apk del .dev_packages

# Static assets
COPY www /www

# Test videos
COPY videos /recordings

# Add NGINX config
COPY nginx.conf /opt/nginx/nginx.conf

# Shell scripts
COPY scripts /opt

# Startup script
CMD ["/opt/startup.sh"]

