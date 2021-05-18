ARG ALPINE_VERSION=latest

FROM alpine:$ALPINE_VERSION

ARG CPPFLAGS="-D_FORTIFY_SOURCE=2"
ARG CFLAGS="-mtune=generic -O2 -pipe -fno-plt"
ARG CXXFLAGS="-mtune=generic -O2 -pipe -fno-plt"
ARG LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"
ARG MAKEFLAGS="-j1"

WORKDIR /root

RUN echo && echo ':: Installing dependencies' && \
  apk add --no-cache \
    flatbuffers \
    hyperscan \
    iptables \
    ip6tables \
    libdnet \
    libmnl \
    libnetfilter_queue \
    libpcap \
    libtirpc \
    libuuid \
    libunwind \
    luajit \
    lz4 \
    openssl \
    pcre \
    perl-git \
    perl-crypt-ssleay \
    perl-lwp-protocol-https \
    perl-switch \
    xz \
    zlib

ENV GPERFTOOLS_VERSION=2.9.1
RUN apk add --no-cache \
    curl \
    g++ \
    gcc \
    git \
    linux-headers \
    make \
    musl-dev && \
  curl -LO "https://github.com/gperftools/gperftools/releases/download/gperftools-${GPERFTOOLS_VERSION}/gperftools-${GPERFTOOLS_VERSION}.tar.gz" && \
  tar -xf "gperftools-${GPERFTOOLS_VERSION}.tar.gz" && \
  cd "gperftools-${GPERFTOOLS_VERSION}" && \
  ./configure --prefix=/usr --enable-frame-pointers && \
  make && \
  make install && \
  install -Dm644 COPYING "/usr/share/licenses/gperftools/COPYING" && \
  apk del \
    curl \
    g++ \
    gcc \
    git \
    linux-headers \
    make \
    musl-dev && \
  cd && rm -rf gperftools-*

ENV HWLOC_VERSION=2.4.1
RUN apk add --no-cache \
    autoconf \
    automake \
    bash \
    curl \
    gcc \
    libtool \
    make \
    musl-dev \
    patch \
    pkgconfig && \
  curl -LO https://www.open-mpi.org/software/hwloc/v${HWLOC_VERSION%.*}/downloads/hwloc-${HWLOC_VERSION}.tar.bz2 && \
  tar -xf hwloc-${HWLOC_VERSION}.tar.bz2 && \
  cd hwloc-${HWLOC_VERSION} && \
  autoreconf -fiv && \
  ./configure --prefix=/usr --sbindir=/usr/bin --enable-plugins --sysconfdir=/etc && \
  make && \
  #make check && \
  make install && \
  install -Dm 644 COPYING -t "/usr/share/licenses/hwloc" && \
  apk del \
    autoconf \
    automake \
    curl \
    bash \
    curl \
    gcc \
    libtool \
    make \
    musl-dev \
    patch \
    pkgconfig && \
  cd && rm -rf hwloc-*

ENV LIBDAQ_VERSION=3.0.3
RUN echo && echo ':: Installing libdaq build dependencies' && \
  apk add --no-cache \
    autoconf \
    automake \
    ca-certificates \
    curl \
    gcc \
    iptables-dev \
    libmnl-dev \
    libpcap-dev \
    #libc6-compat \
    libtool \
    make \
    musl-dev \
    pkgconfig && \
  echo && echo ':: Getting libdaq sources' && \
  curl -Lf "https://github.com/snort3/libdaq/archive/refs/tags/v${LIBDAQ_VERSION}.tar.gz" -o libdaq.tar.gz && \
  tar -xf libdaq.tar.gz && \
  cd "libdaq-${LIBDAQ_VERSION}" && \
  echo && echo ':: Building libdaq' && \
  ./bootstrap && \
  ./configure --prefix=/usr && \
  make && \
  echo && echo ':: Installing libdaq' && \
  make install && \
  echo && echo ':: Cleaning up build dependencies' && \
  apk del \
    autoconf \
    automake \
    ca-certificates \
    curl \
    gcc \
    iptables-dev \
    libmnl-dev \
    libpcap-dev \
    libtool \
    make \
    musl-dev \
    pkgconfig && \
  echo && echo ':: Cleaning up sources' && \
  cd && rm -rf libdaq-*

ENV SNORT_VERSION=3.1.4.0
RUN apk add --no-cache \
    cmake \
    curl \
    flatbuffers-dev \
    flex \
    flex-dev \
    g++ \
    hyperscan-dev \
    libdnet-dev \
    libpcap-dev \
    libunwind-dev \
    libtirpc-dev \
    luajit-dev \
    openssl-dev \
    pcre-dev \
    make \
    xz-dev \
    zlib-dev && \
  curl -Lf "https://github.com/snort3/snort3/archive/refs/tags/${SNORT_VERSION}.tar.gz" -o snort3.tar.gz && \
  tar -xf snort3.tar.gz && \
  cd "snort3-${SNORT_VERSION}" && \
  ./configure_cmake.sh \
    --prefix=/usr \
    --enable-tcmalloc \
    --with-daq-libraries=/usr/lib/daq/ \
    --disable-static-daq && \
  make -C build && \
  make -C build install && \
  cp -a /usr/etc/snort /etc && \
  rm -rf /usr/etc && \
  sed -i -e "/^HOME_NET\\s\\+=/ a include 'homenet.lua'" \
    -e 's/^\(HOME_NET\s\+=\)/--\1/g' \
    "${pkgdir}"/etc/snort/snort.lua && \
  sed -i -e "s/^\\(RULE_PATH\\s\\+=\\).*/\\1 'rules'/g" \
    -e "s/^\\(BUILTIN_RULE_PATH\\s\\+=\\).*/\\1 'builtin_rules'/g" \
    -e "s/^\\(PLUGIN_RULE_PATH\\s\\+=\\).*/\\1 'so_rules'/g" \
    -e "s/^\\(WHITE_LIST_PATH\\s\\+=\\).*/\\1 'lists'/g" \
    -e "s/^\\(BLACK_LIST_PATH\\s\\+=\\).*/\\1 'lists'/g" \
    "${pkgdir}"/etc/snort/snort_defaults.lua && \
  mkdir /var/log/snort && \
  apk del \
    cmake \
    curl \
    flatbuffers-dev \
    flex \
    flex-dev \
    g++ \
    hyperscan-dev \
    libdnet-dev \
    libpcap-dev \
    libunwind-dev \
    libtirpc-dev \
    luajit-dev \
    openssl-dev \
    pcre-dev \
    make \
    xz-dev \
    zlib-dev && \
  cd && rm -rf snort3-*

ENV SNORT_OPENAPPID=17843
RUN apk add --no-cache curl && \
  curl -L "https://snort.org/downloads/openappid/${SNORT_OPENAPPID}" \
    -o "snort-openappid-${SNORT_OPENAPPID}.tar.gz" && \
  mkdir "snort-openappid-${SNORT_OPENAPPID}" && \
  tar -C "snort-openappid-${SNORT_OPENAPPID}" \
    -xf "snort-openappid-${SNORT_OPENAPPID}.tar.gz" && \
  install -d -m755 /usr/lib/openappid/custom/{libs,lua,port} && \
  cp -a "snort-openappid-${SNORT_OPENAPPID}/odp" \
    /usr/lib/openappid/ && \
  apk del curl && \
  rm -rf snort-openappid-*

ENV PULLEDPORK_VERSION=0.7.4
RUN apk add --no-cache curl fcron && \
  curl -L "https://github.com/shirkdog/pulledpork/archive/v${PULLEDPORK_VERSION}.tar.gz" \
    -o "pulledpork-${PULLEDPORK_VERSION}.tar.gz" && \
  tar -xf "pulledpork-${PULLEDPORK_VERSION}.tar.gz" && \
  cd "pulledpork-${PULLEDPORK_VERSION}" && \
  install -Dm644 -t /etc/pulledpork etc/* && \
  install -Dm755 -t /usr/bin pulledpork.pl && \
  apk del curl && \
  cd && rm -rf pulledpork-*

ARG S6_OVERLAY_VERSION=2.2.0.3
RUN apk add --no-cache curl && \
  curl -sSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz" | tar -xzf - -C / && \
  apk del --no-cache curl

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
  S6_SERVICES_GRACETIME=10000 \
  S6_KILL_GRACETIME=6000 \
  SNORT_FILTER_IPTABLES_FORWARD=0 \
  SNORT_FILTER_IPTABLES_INPUT=0 \
  SNORT_PULLEDPORK_ON_START=0

COPY rootfs /
ENTRYPOINT ["/init"]
