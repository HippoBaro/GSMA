FROM ubuntu:zesty
MAINTAINER Hippolyte Barraud <hippolyte.barraud@gmail.com>

ENV BUILD_DEPENDENCIES_SHADOWSOCKS git-core gettext build-essential autoconf apt-utils automake libtool libssl-dev libpcre3-dev asciidoc xmlto zlib1g-dev libev-dev libudns-dev libsodium-dev libmbedtls-dev ca-certificates
ENV DEPENDENCIES_KCPTUN golang
ENV BASEDIR_SHADOWSOCKS /tmp/shadowsocks-libev
ENV SERVER_PORT 9534

#ENV BASEDIR_LIBSODIUM /tmp/libsodium

# Set up building environment
RUN apt-get update \
 && apt-get install --no-install-recommends -y $BUILD_DEPENDENCIES_SHADOWSOCKS $DEPENDENCIES_KCPTUN

# SHADOWSOCKS
# Get the latest code, build and install
RUN git clone https://github.com/shadowsocks/shadowsocks-libev.git $BASEDIR_SHADOWSOCKS
WORKDIR $BASEDIR_SHADOWSOCKS
RUN git submodule update --init --recursive \
 && ./autogen.sh \
 && ./configure \
 && make \
 && make install

# KPCTUN
ENV GOPATH /usr/go
RUN go get -u github.com/xtaci/kcptun/server

# Tear down building environment and delete git repository
WORKDIR /
#RUN rm -rf $BASEDIR_SHADOWSOCKS/shadowsocks-libev \
# && rm -rf $BASEDIR_LIBSODIUM/libsodium \
# && apt-get --purge autoremove -y $BUILD_DEPENDENCIES_SHADOWSOCKS

# Port in the config file won't take affect. Instead we'll use 8388.
EXPOSE $SERVER_PORT/tcp $SERVER_PORT/udp

# Override the host and port in the config file.
ADD entrypoint /
RUN ["chmod", "+x", "/entrypoint"]
ENTRYPOINT ["/entrypoint"]