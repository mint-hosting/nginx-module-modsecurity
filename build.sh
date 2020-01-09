#!/bin/bash

# Set path variables
BUILD_DIST_DIR=$PWD/$BUILD_BASE_DIR/build
NGINX_GIT_CLONE_PATH=$PWD/$BUILD_BASE_DIR/tmp/nginx
MODSECURITY_GIT_CLONE_PATH=$PWD/$BUILD_BASE_DIR/tmp/modsecurity
MODSECURITY_NGINX_GIT_CLONE_PATH=$PWD/$BUILD_BASE_DIR/tmp/modsecurityNginx

# Instruct bash to output commands
set -x

# Install dependencies
apt update && apt install -y jq git curl gnupg2 ca-certificates apt-utils autoconf automake build-essential git libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre++-dev libtool libxml2-dev libyajl-dev pkgconf wget zlib1g-dev

# Set nginx variables - latest version and the source download url
nginx_download_uri=$(curl -s $NGINX_GIT_TAGS_URI | jq -r '.[0].tarball_url')
NGINX_RELEASE_VERSION=$(curl -s $${NGINX_GIT_TAGS_URI} | jq -r '.[0].name' | cut -d"-" -f2)

# Create required directories
mkdir -p $BUILD_BASE_DIR
mkdir -p $BUILD_DIST_DIR
mkdir -p $MODSECURITY_GIT_CLONE_PATH
mkdir -p $MODSECURITY_NGINX_GIT_CLONE_PATH
mkdir -p $NGINX_GIT_CLONE_PATH

# Clone Brotli and build the module
git clone --single-branch --branch v3/master $MODSECURITY_GIT_REPO_URI $MODSECURITY_GIT_CLONE_PATH      
(cd $MODSECURITY_GIT_CLONE_PATH && git submodule init)
(cd $MODSECURITY_GIT_CLONE_PATH && git submodule update)
(cd $MODSECURITY_GIT_CLONE_PATH && ./build.sh)
(cd $MODSECURITY_GIT_CLONE_PATH && ./configure)
(cd $MODSECURITY_GIT_CLONE_PATH && make)
(cd $MODSECURITY_GIT_CLONE_PATH && make install)
git clone $MODSECURITY_NGINX_GIT_REPO_URI $MODSECURITY_NGINX_GIT_CLONE_PATH
(cd $NGINX_GIT_CLONE_PATH && wget https://nginx.org/download/nginx-$NGINX_RELEASE_VERSION.tar.gz)
(cd $NGINX_GIT_CLONE_PATH && tar xzvf nginx-$NGINX_RELEASE_VERSION.tar.gz)
(cd $NGINX_GIT_CLONE_PATH/nginx-$NGINX_RELEASE_VERSION && ./configure --with-compat --add-dynamic-module=$MODSECURITY_NGINX_GIT_CLONE_PATH)
(cd $NGINX_GIT_CLONE_PATH/nginx-$NGINX_RELEASE_VERSION && make modules && make install) 

# Copy the .so module files to dist folder
cp $NGINX_GIT_CLONE_PATH/nginx-$NGINX_RELEASE_VERSION/objs/ngx_http_modsecurity_module.so $BUILD_DIST_DIR

# Add additional info about nginx version and os version
echo $NGINX_RELEASE_VERSION > $BUILD_DIST_DIR/.nginx
echo $BUILD_OS_VERSION > $BUILD_DIST_DIR/.os