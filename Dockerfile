FROM microsoft/dotnet:2.1-runtime-deps

ENV NGINX_VERSION 1.13.9
ENV NGINX_RTMP_VERSION 1.2.1
ENV AZCOPY_URL https://azcopy.azureedge.net/azcopy-7-2-0/azcopy_7.2.0-netcore_linux_x64.tar.gz

ENV PACKAGES libunwind8 wget
ENV DEV_PACKAGES rsync build-essential libpcre3-dev libssl-dev zlib1g-dev

EXPOSE 1935
EXPOSE 80

RUN apt-get update && apt-get install -y --no-install-recommends ${PACKAGES} ${DEV_PACKAGES}

# Get nginx source.
RUN cd /tmp && \
  wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
  tar zxf nginx-${NGINX_VERSION}.tar.gz && \
  rm nginx-${NGINX_VERSION}.tar.gz

# Get nginx-rtmp module.
RUN cd /tmp && \
  wget https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_VERSION}.tar.gz && \
  tar zxf v${NGINX_RTMP_VERSION}.tar.gz && rm v${NGINX_RTMP_VERSION}.tar.gz

# Compile nginx with nginx-rtmp module.
RUN cd /tmp/nginx-${NGINX_VERSION} && \
  ./configure \
  --prefix=/opt/nginx \
  --add-module=/tmp/nginx-rtmp-module-${NGINX_RTMP_VERSION} \
  --conf-path=/opt/nginx/nginx.conf \
  --error-log-path=/opt/nginx/logs/error.log \
  --http-log-path=/opt/nginx/logs/access.log \
  --with-debug && \
  cd /tmp/nginx-${NGINX_VERSION} && make && make install


# download azcopy
RUN wget -O azcopy.tar.gz ${AZCOPY_URL}  \
    && tar -xf azcopy.tar.gz && rm -f azcopy.tar.gz \
    && ./install.sh && rm -f install.sh \
    && rm -rf azcopy

# tidy up
RUN rm -rf /var/cache/* /tmp/* /var/lib/apt/lists/* && apt-get purge -y --auto-remove ${DEV_PACKAGES}

# Init video dir
RUN mkdir /videos && chmod 0777 /videos

# Add NGINX config
ADD nginx.conf /opt/nginx/nginx.conf

# Shell scripts
ADD *.sh /opt/

# Static assets
ADD assets /www/static

# Test videos
ADD videos /www/videos

# Startup script
CMD ["/opt/startup.sh"]
