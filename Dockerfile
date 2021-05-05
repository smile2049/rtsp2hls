ARG DEBIAN_VERSION=stretch-slim

FROM debian:${DEBIAN_VERSION} AS builder

ARG NGINX_VERSION=1.17.5
ARG NGINX_RTMP_MODULE_VERSION=1.2.1
ARG FFMPEG_VERSION=4.2.1

# Install build dependencies
RUN apt-get update && \
	apt-get install -y \
    wget build-essential ca-certificates \
    openssl libssl-dev yasm \
    libpcre3-dev librtmp-dev libtheora-dev \
    libvorbis-dev libvpx-dev libfreetype6-dev \
    libmp3lame-dev libx264-dev libx265-dev && \
    rm -rf /var/lib/apt/lists/*

# Download and extract NGINX
RUN mkdir -p /tmp/build && \
	cd /tmp/build && \
	wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
	tar -zxf nginx-${NGINX_VERSION}.tar.gz && \
	rm nginx-${NGINX_VERSION}.tar.gz

# Download and extract NGINX RTMP module
RUN cd /tmp/build && \
    wget https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
    tar -zxf v${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
	rm v${NGINX_RTMP_MODULE_VERSION}.tar.gz

# Build NGINX and NGINX RTMP module
RUN cd /tmp/build/nginx-${NGINX_VERSION} && \
    ./configure \
    --sbin-path=/usr/local/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx/nginx.pid \
    --lock-path=/var/lock/nginx.lock \
    --http-client-body-temp-path=/tmp/nginx-client-body \
    --with-http_ssl_module \
    --with-threads \
    --add-module=/tmp/build/nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION} && \
    make -j $(getconf _NPROCESSORS_ONLN) && \
    make install

# Download and extract FFMPEG
RUN mkdir -p /tmp/build && \
    cd /tmp/build && \
    wget http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz && \
    tar -zxf ffmpeg-${FFMPEG_VERSION}.tar.gz && \
    rm ffmpeg-${FFMPEG_VERSION}.tar.gz

# Build FFMPEG
RUN cd /tmp/build/ffmpeg-${FFMPEG_VERSION} && \
    ./configure \
    --enable-version3 \
    --enable-gpl \
    --enable-small \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libvpx \
    --enable-libtheora \
    --enable-libvorbis \
    --enable-librtmp \
    --enable-postproc \
    --enable-swresample \
    --enable-libfreetype \
    --enable-libmp3lame \
    --disable-debug \
    --disable-doc \
    --disable-ffplay \
    --extra-libs="-lpthread -lm" && \
    make -j $(getconf _NPROCESSORS_ONLN) && \
    make install

# Remove dir with sources
RUN rm -rf /tmp/build

FROM node:alpine AS node-builder

# Build Node.js app
WORKDIR /app
COPY . .
RUN npm install && npm run build

FROM node:16-${DEBIAN_VERSION} AS bundler

WORKDIR /app

# Install dependencies
RUN apt-get update && \
	apt-get install -y \
	ca-certificates openssl libpcre3-dev \
	librtmp1 libtheora0 libvorbis-dev libmp3lame0 \
	libvpx4 libx264-dev libx265-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy NGINX and NGINX RTMP module
COPY --from=builder /usr/local /usr/local
RUN true
COPY --from=builder /etc/nginx /etc/nginx
RUN true
COPY --from=builder /var/log/nginx /var/log/nginx
RUN true
COPY --from=builder /var/lock /var/lock
RUN true
COPY --from=builder /var/run/nginx /var/run/nginx

# Copy NGINX config
RUN true
COPY ./nginx.conf /etc/nginx/nginx.conf

# Make directory for HLS fragments
RUN mkdir -p /tmp/hls/live

# Pass NGINX logs to stdout and stderr
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Copy built Node.js app and node_modules
COPY --from=node-builder /app/node_modules ./node_modules
COPY --from=node-builder /app/build ./build

# Copy startup script
COPY ./start.sh ./start.sh
RUN chmod +x ./start.sh

EXPOSE 8080
EXPOSE 8000

CMD ["./start.sh"]
