ARG ALPINE_VERSION=3.20
ARG ARCHITECTURE
ARG FREERDP_VERSION=3.8.0

FROM alpine:${ALPINE_VERSION} AS freerdp

RUN apk add \
        alsa-lib-dev \
        bsd-compat-headers \
        cmake \
        cups-dev \
        fuse3-dev \
        g++ \
        gsm-dev \
        gst-plugins-base-dev \
        icu-dev \
        krb5-dev \
        libjpeg-turbo-dev \
        libusb-dev \
        libxcursor-dev \
        libxdamage-dev \
        libxi-dev \
        libxinerama-dev \
        libxkbcommon-dev \
        libxkbfile-dev \
        libxv-dev \
        linux-headers \
        openssl-dev \
        samurai \
        sdl2-dev \
        sdl2_ttf-dev \
        wayland-dev \
        webkit2gtk-4.1-dev

RUN apk add pulseaudio-dev

WORKDIR /build/freerdp

ARG FREERDP_VERSION

RUN wget -qO- "https://github.com/FreeRDP/FreeRDP/tarball/${FREERDP_VERSION}" \
    | tar -xzf - --strip-components=1

RUN export CFLAGS="$CFLAGS -D_BSD_SOURCE -flto=auto" \
    && cmake -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DBUILTIN_CHANNELS=OFF \
        -DWITH_ALSA=ON \
        -DWITH_CHANNELS=ON \
        -DWITH_CUPS=ON \
        -DWITH_DIRECTFB=OFF \
        -DWITH_FFMPEG=OFF \
        -DWITH_GSM=ON \
        -DWITH_GSTREAMER_1_0=ON \
        -DWITH_IPP=OFF \
        -DWITH_JPEG=ON \
        -DWITH_NEON=OFF \
        -DWITH_OPENSSL=ON \
        -DWITH_PCSC=OFF \
        -DWITH_PULSE=ON \
        -DWITH_SERVER=ON \
        -DWITH_SWSCALE=OFF \
        -DWITH_WAYLAND=ON \
        -DWITH_X11=ON \
        -DWITH_XCURSOR=OFF \
        -DWITH_XEXT=ON \
        -DWITH_XI=ON \
        -DWITH_XINERAMA=ON \
        -DWITH_XKBFILE=ON \
        -DWITH_XRENDER=ON \
        -DWITH_XV=ON \
        -DWITH_ZLIB=ON \
    && cmake --build build \
    && DESTDIR=/build/freerdp/output/ cmake --install build

FROM alpine:${ALPINE_VERSION}

RUN apk add \
        dbus-x11 \
        freeglut \
        gsm \
        krb5 \
        libturbojpeg \
        libx11 \
        libxcb \
        libxdamage \
        libxext \
        libxinerama \
        libxtst \
        libxv \
        mesa-utils \
        seatd \
        vulkan-loader \
        weston \
        weston-backend-headless \
        weston-xwayland \
        xcb-util-keysyms \
        xrandr \
        xvfb \
        xwayland

# TODO
RUN apk add pipewire pipewire-pulse pipewire-alsa wireplumber
RUN apk add alsa-utils alsaconf
RUN apk add pulseaudio pulseaudio-utils

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && apk add \
        "s6-overlay"

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && cat /etc/apk/repositories \
    && apk add \
        kodi-inputstream-adaptive \
        kodi-x11 \
        mkrundir \
        skalibs-dev

RUN rm -rf /var/cache/apk/*

COPY --link --from=freerdp /build/freerdp/output/ /

COPY /rootfs/ /

ENTRYPOINT ["/entrypoint.sh"]

# RDP
EXPOSE 3389
