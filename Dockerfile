FROM ubuntu:zesty
MAINTAINER Hippolyte Barraud <hippolyte.barraud@gmail.com>

ENV DEPENDENCIES_SHADOWSOCKS git-core gettext build-essential autoconf apt-utils automake libtool libssl-dev libpcre3-dev asciidoc xmlto zlib1g-dev libev-dev libudns-dev ca-certificates
ENV DEPENDENCIES_KCPTUN golang
ENV BASEDIR_SHADOWSOCKS /tmp/shadowsocks-libev
ENV SERVER_PORT 9534

ENV BASEDIR_LIBSODIUM /tmp/libsodium

# Set up building environment
RUN apt-get update \
 && apt-get install --no-install-recommends -y $DEPENDENCIES_SHADOWSOCKS $DEPENDENCIES_KCPTUN

# Install libsodium
RUN git clone https://github.com/jedisct1/libsodium $BASEDIR_LIBSODIUM
WORKDIR $BASEDIR_LIBSODIUM
RUN ./autogen.sh \
 && ./configure --prefix=/usr \
 && make \
 && make install

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
RUN rm -rf $BASEDIR_SHADOWSOCKS/shadowsocks-libev \
 && rm -rf $BASEDIR_LIBSODIUM/libsodium \
 && apt-get --purge autoremove -y $DEPENDENCIES_SHADOWSOCKS

# Port in the config file won't take affect. Instead we'll use 8388.
EXPOSE $SERVER_PORT/tcp $SERVER_PORT/udp

# Override the host and port in the config file.
ADD entrypoint /
ENTRYPOINT ["/entrypoint"]